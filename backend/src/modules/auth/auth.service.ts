import {
  BadRequestException,
  ConflictException,
  Injectable,
  Logger,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { UserRole } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import {
  ForgotPasswordDto,
  LoginDto,
  OtpRequestDto,
  OtpVerifyDto,
  RegisterDto,
  ResetPasswordDto,
} from './dto/auth.dto';
import { JwtPayload } from './strategies/jwt.strategy';

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);

  constructor(
    private prisma: PrismaService,
    private jwtService: JwtService,
    private configService: ConfigService,
  ) {}

  private async hashPassword(password: string): Promise<string> {
    return bcrypt.hash(password, 12);
  }

  private async comparePassword(
    password: string,
    hash: string,
  ): Promise<boolean> {
    return bcrypt.compare(password, hash);
  }

  private generateOtp(): string {
    const length = this.configService.get<number>('otp.length') || 6;
    return Math.floor(Math.pow(10, length - 1) + Math.random() * 9 * Math.pow(10, length - 1)).toString();
  }

  private async createTokens(user: {
    id: string;
    email?: string | null;
    phone?: string | null;
    role: UserRole;
  }) {
    const payload: JwtPayload = {
      sub: user.id,
      email: user.email || undefined,
      phone: user.phone || undefined,
      role: user.role,
    };

    const accessToken = this.jwtService.sign(payload, {
      secret: this.configService.get('jwt.accessSecret'),
      expiresIn: this.configService.get('jwt.accessExpires'),
    });

    const refreshToken = this.jwtService.sign(payload, {
      secret: this.configService.get('jwt.refreshSecret'),
      expiresIn: this.configService.get('jwt.refreshExpires'),
    });

    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 7);

    await this.prisma.refreshToken.create({
      data: { token: refreshToken, userId: user.id, expiresAt },
    });

    return { accessToken, refreshToken };
  }

  async register(dto: RegisterDto) {
    const existing = await this.prisma.user.findFirst({
      where: {
        OR: [
          { phone: dto.phone },
          ...(dto.email ? [{ email: dto.email }] : []),
        ],
        deletedAt: null,
      },
    });

    if (existing) {
      throw new ConflictException('User already exists with this phone or email');
    }

    const passwordHash = await this.hashPassword(dto.password);
    const referralCode = `DR${Date.now().toString(36).toUpperCase()}`;

    const user = await this.prisma.user.create({
      data: {
        phone: dto.phone,
        email: dto.email,
        name: dto.name,
        passwordHash,
        role: UserRole.CUSTOMER,
        referralCode,
        isVerified: false,
      },
      select: {
        id: true,
        email: true,
        phone: true,
        name: true,
        role: true,
        isVerified: true,
      },
    });

    await this.prisma.cart.create({ data: { userId: user.id } });

    const tokens = await this.createTokens(user);
    return { user, ...tokens };
  }

  async login(dto: LoginDto) {
    if (!dto.email && !dto.phone) {
      throw new BadRequestException('Email or phone is required');
    }

    const user = await this.prisma.user.findFirst({
      where: {
        OR: [
          ...(dto.email ? [{ email: dto.email }] : []),
          ...(dto.phone ? [{ phone: dto.phone }] : []),
        ],
        deletedAt: null,
        isActive: true,
      },
    });

    if (!user?.passwordHash) {
      throw new UnauthorizedException('Invalid credentials');
    }

    const valid = await this.comparePassword(dto.password, user.passwordHash);
    if (!valid) {
      throw new UnauthorizedException('Invalid credentials');
    }

    const tokens = await this.createTokens(user);
    return {
      user: {
        id: user.id,
        email: user.email,
        phone: user.phone,
        name: user.name,
        role: user.role,
        isVerified: user.isVerified,
      },
      ...tokens,
    };
  }

  async requestOtp(dto: OtpRequestDto) {
    const otp = this.generateOtp();
    const expiryMinutes =
      this.configService.get<number>('otp.expiryMinutes') || 10;
    const expiresAt = new Date();
    expiresAt.setMinutes(expiresAt.getMinutes() + expiryMinutes);

    await this.prisma.otpRecord.create({
      data: {
        phone: dto.phone,
        otp,
        purpose: dto.purpose || 'LOGIN',
        expiresAt,
      },
    });

    // SMS-ready: integrate Twilio/MSG91 here
    this.logger.log(`OTP for ${dto.phone}: ${otp} (dev mode)`);

    return {
      message: 'OTP sent successfully',
      expiresIn: expiryMinutes * 60,
      ...(process.env.NODE_ENV !== 'production' ? { devOtp: otp } : {}),
    };
  }

  async verifyOtp(dto: OtpVerifyDto) {
    const record = await this.prisma.otpRecord.findFirst({
      where: {
        phone: dto.phone,
        purpose: dto.purpose || 'LOGIN',
        isUsed: false,
        expiresAt: { gt: new Date() },
      },
      orderBy: { createdAt: 'desc' },
    });

    if (!record || record.otp !== dto.otp) {
      throw new BadRequestException('Invalid or expired OTP');
    }

    await this.prisma.otpRecord.update({
      where: { id: record.id },
      data: { isUsed: true },
    });

    let user = await this.prisma.user.findFirst({
      where: { phone: dto.phone, deletedAt: null },
    });

    if (!user) {
      user = await this.prisma.user.create({
        data: {
          phone: dto.phone,
          role: UserRole.CUSTOMER,
          isVerified: true,
          referralCode: `DR${Date.now().toString(36).toUpperCase()}`,
        },
      });
      await this.prisma.cart.create({ data: { userId: user.id } });
    } else {
      user = await this.prisma.user.update({
        where: { id: user.id },
        data: { isVerified: true },
      });
    }

    const tokens = await this.createTokens(user);
    return {
      user: {
        id: user.id,
        email: user.email,
        phone: user.phone,
        name: user.name,
        role: user.role,
        isVerified: user.isVerified,
      },
      ...tokens,
    };
  }

  async forgotPassword(dto: ForgotPasswordDto) {
    if (!dto.email && !dto.phone) {
      throw new BadRequestException('Email or phone is required');
    }

    const user = await this.prisma.user.findFirst({
      where: {
        OR: [
          ...(dto.email ? [{ email: dto.email }] : []),
          ...(dto.phone ? [{ phone: dto.phone }] : []),
        ],
        deletedAt: null,
      },
    });

    if (!user?.phone) {
      return { message: 'If account exists, OTP has been sent' };
    }

    return this.requestOtp({ phone: user.phone, purpose: 'RESET_PASSWORD' });
  }

  async resetPassword(dto: ResetPasswordDto) {
    const record = await this.prisma.otpRecord.findFirst({
      where: {
        phone: dto.phone,
        purpose: 'RESET_PASSWORD',
        isUsed: false,
        expiresAt: { gt: new Date() },
      },
      orderBy: { createdAt: 'desc' },
    });

    if (!record || record.otp !== dto.otp) {
      throw new BadRequestException('Invalid or expired OTP');
    }

    await this.prisma.otpRecord.update({
      where: { id: record.id },
      data: { isUsed: true },
    });

    const passwordHash = await this.hashPassword(dto.newPassword);
    await this.prisma.user.update({
      where: { phone: dto.phone },
      data: { passwordHash },
    });

    return { message: 'Password reset successfully' };
  }

  async refreshTokens(refreshToken: string) {
    try {
      const payload = this.jwtService.verify<JwtPayload>(refreshToken, {
        secret: this.configService.get('jwt.refreshSecret'),
      });

      const stored = await this.prisma.refreshToken.findUnique({
        where: { token: refreshToken },
      });

      if (!stored || stored.expiresAt < new Date()) {
        throw new UnauthorizedException('Invalid refresh token');
      }

      await this.prisma.refreshToken.delete({ where: { id: stored.id } });

      const user = await this.prisma.user.findUnique({
        where: { id: payload.sub },
      });

      if (!user || !user.isActive) {
        throw new UnauthorizedException('User not found');
      }

      return this.createTokens(user);
    } catch {
      throw new UnauthorizedException('Invalid refresh token');
    }
  }

  async logout(userId: string, refreshToken?: string) {
    if (refreshToken) {
      await this.prisma.refreshToken.deleteMany({
        where: { userId, token: refreshToken },
      });
    } else {
      await this.prisma.refreshToken.deleteMany({ where: { userId } });
    }
    return { message: 'Logged out successfully' };
  }

  async updateFcmToken(userId: string, fcmToken: string) {
    await this.prisma.user.update({
      where: { id: userId },
      data: { fcmToken },
    });
    return { message: 'FCM token updated' };
  }

  async getProfile(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        email: true,
        phone: true,
        name: true,
        role: true,
        isVerified: true,
        avatarUrl: true,
        loyaltyPoints: true,
        referralCode: true,
        createdAt: true,
      },
    });
    return { user };
  }
}
