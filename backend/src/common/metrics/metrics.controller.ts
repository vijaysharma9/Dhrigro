import { Controller, Get, Header, Headers, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Public } from '../decorators/public.decorator';
import { MetricsService } from './metrics.service';

@Controller('metrics')
export class MetricsController {
  constructor(
    private readonly metrics: MetricsService,
    private readonly config: ConfigService,
  ) {}

  @Public()
  @Get()
  @Header('Content-Type', 'text/plain; version=0.0.4; charset=utf-8')
  async getMetrics(@Headers('x-metrics-token') token?: string) {
    const expected = this.config.get<string>('metrics.token');
    if (expected && token !== expected) {
      throw new UnauthorizedException('Invalid metrics token');
    }
    return this.metrics.getMetrics();
  }
}
