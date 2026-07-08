import {
  ConnectedSocket,
  MessageBody,
  OnGatewayConnection,
  OnGatewayDisconnect,
  OnGatewayInit,
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
} from '@nestjs/websockets';
import { Logger } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { Server, Socket } from 'socket.io';
import { STAFF_ROLES } from '../rbac/permissions';
import { UserRole } from '@prisma/client';
import { SocketRealtimeService } from './socket-realtime.service';
import { REALTIME_ROOMS, RealtimeEvent } from './realtime-events';

interface SocketUser {
  sub: string;
  role: UserRole;
}

@WebSocketGateway({
  cors: {
    origin: (process.env.CORS_ORIGINS || 'http://localhost:8081').split(','),
    credentials: true,
  },
  namespace: '/realtime',
  transports: ['websocket', 'polling'],
})
export class RealtimeGateway
  implements OnGatewayInit, OnGatewayConnection, OnGatewayDisconnect
{
  private readonly logger = new Logger(RealtimeGateway.name);

  @WebSocketServer()
  server!: Server;

  constructor(
    private jwt: JwtService,
    private config: ConfigService,
    private realtime: SocketRealtimeService,
  ) {}

  afterInit() {
    this.realtime.setBroadcast((event) => this.broadcast(event));
    this.logger.log('Realtime gateway initialized');
  }

  async handleConnection(client: Socket) {
    try {
      const token =
        (client.handshake.auth?.token as string) ||
        (client.handshake.query?.token as string);

      if (!token) {
        client.disconnect(true);
        return;
      }

      const payload = await this.jwt.verifyAsync<SocketUser>(token, {
        secret: this.config.get<string>('jwt.accessSecret'),
      });

      (client.data as { user: SocketUser }).user = payload;

      if (STAFF_ROLES.includes(payload.role)) {
        await client.join(REALTIME_ROOMS.admin);
      }
      if (payload.role === UserRole.DELIVERY_PARTNER) {
        await client.join(REALTIME_ROOMS.partner(payload.sub));
      }

      this.realtime.setConnectionCount(this.server.sockets.sockets.size);
      this.logger.debug(`WS connected ${payload.sub} (${payload.role})`);
    } catch {
      client.disconnect(true);
    }
  }

  handleDisconnect() {
    this.realtime.setConnectionCount(this.server.sockets.sockets.size);
  }

  @SubscribeMessage('subscribe_order')
  handleSubscribeOrder(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { orderId: string },
  ) {
    if (data?.orderId) {
      void client.join(REALTIME_ROOMS.order(data.orderId));
    }
    return { ok: true };
  }

  @SubscribeMessage('ping')
  handlePing() {
    return { pong: true, ts: Date.now() };
  }

  private broadcast(event: RealtimeEvent) {
    const room = event.room ?? REALTIME_ROOMS.admin;
    this.server.to(room).emit('event', event);
  }
}
