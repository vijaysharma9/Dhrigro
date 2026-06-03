export interface ValidatedEnv {
  nodeEnv: string;
  port: number;
  databaseUrl: string;
  jwtAccessSecret: string;
  jwtRefreshSecret: string;
}

const REQUIRED_ALWAYS = ['DATABASE_URL', 'JWT_ACCESS_SECRET', 'JWT_REFRESH_SECRET'] as const;

const REQUIRED_PRODUCTION = [
  'RAZORPAY_WEBHOOK_SECRET',
] as const;

export function validateEnv(): ValidatedEnv {
  const nodeEnv = process.env.NODE_ENV || 'development';
  const missing: string[] = [];

  for (const key of REQUIRED_ALWAYS) {
    if (!process.env[key]?.trim()) missing.push(key);
  }

  if (nodeEnv === 'production') {
    for (const key of REQUIRED_PRODUCTION) {
      if (!process.env[key]?.trim()) missing.push(key);
    }

    const access = process.env.JWT_ACCESS_SECRET || '';
    const refresh = process.env.JWT_REFRESH_SECRET || '';
    if (access.length < 32 || refresh.length < 32) {
      throw new Error(
        'JWT_ACCESS_SECRET and JWT_REFRESH_SECRET must be at least 32 characters in production',
      );
    }
  }

  if (missing.length > 0) {
    throw new Error(
      `Missing required environment variables for ${nodeEnv}: ${missing.join(', ')}`,
    );
  }

  return {
    nodeEnv,
    port: parseInt(process.env.API_PORT || '3000', 10),
    databaseUrl: process.env.DATABASE_URL!,
    jwtAccessSecret: process.env.JWT_ACCESS_SECRET!,
    jwtRefreshSecret: process.env.JWT_REFRESH_SECRET!,
  };
}
