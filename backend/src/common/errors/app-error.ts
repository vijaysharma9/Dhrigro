import { HttpException, HttpStatus } from '@nestjs/common';

export enum ErrorCode {
  VALIDATION_ERROR = 'VALIDATION_ERROR',
  UNAUTHORIZED = 'UNAUTHORIZED',
  FORBIDDEN = 'FORBIDDEN',
  NOT_FOUND = 'NOT_FOUND',
  PAYMENT_FAILED = 'PAYMENT_FAILED',
  PAYMENT_DUPLICATE = 'PAYMENT_DUPLICATE',
  PAYMENT_TIMEOUT = 'PAYMENT_TIMEOUT',
  WEBHOOK_REPLAY = 'WEBHOOK_REPLAY',
  RATE_LIMIT = 'RATE_LIMIT',
  INTERNAL_ERROR = 'INTERNAL_ERROR',
}

export class AppError extends HttpException {
  constructor(
    public readonly code: ErrorCode,
    message: string,
    status: HttpStatus = HttpStatus.BAD_REQUEST,
    public readonly details?: Record<string, unknown>,
  ) {
    super(
      {
        code,
        message,
        details,
      },
      status,
    );
  }
}
