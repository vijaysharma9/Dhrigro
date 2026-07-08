const parseCsv = (value: string | undefined, fallback: string): string[] =>
  (value || fallback)
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean);

const parseBool = (value: string | undefined, defaultValue: boolean): boolean => {
  if (value === undefined) return defaultValue;
  return value !== 'false' && value !== '0';
};

export default () => {
  const nodeEnv = process.env.NODE_ENV || 'development';
  const isProduction = nodeEnv === 'production';

  const swaggerEnabled =
    process.env.SWAGGER_ENABLED === 'true' ||
    (!isProduction && process.env.SWAGGER_ENABLED !== 'false');

  const rateLimitTtlSec = parseInt(
    process.env.RATE_LIMIT_TTL || process.env.THROTTLE_TTL || '60',
    10,
  );
  const rateLimitMax = parseInt(
    process.env.RATE_LIMIT_LIMIT || process.env.THROTTLE_LIMIT || '100',
    10,
  );

  return {
    nodeEnv,
    isProduction,
    port: parseInt(process.env.PORT || process.env.API_PORT || '3000', 10),
    apiPrefix: process.env.API_PREFIX || 'api/v1',
    app: {
      name: process.env.APP_NAME || 'Dhrigro',
      version: process.env.APP_VERSION || process.env.npm_package_version || '0.0.1',
      url: process.env.APP_URL || '',
      adminUrl: process.env.ADMIN_URL || '',
      apiUrl: process.env.API_URL || '',
    },
    corsOrigins: parseCsv(
      process.env.CORS_ORIGINS,
      'http://localhost:8080,http://localhost:8081,http://127.0.0.1:8080,http://127.0.0.1:8081',
    ),
    databaseUrl: process.env.DATABASE_URL,
    redis: {
      url: process.env.REDIS_URL || 'redis://localhost:6379',
      enabled: parseBool(process.env.REDIS_ENABLED, true),
    },
    jwt: {
      accessSecret: process.env.JWT_ACCESS_SECRET,
      refreshSecret: process.env.JWT_REFRESH_SECRET,
      accessExpires: process.env.JWT_ACCESS_EXPIRES || '15m',
      refreshExpires: process.env.JWT_REFRESH_EXPIRES || '7d',
    },
    otp: {
      expiryMinutes: parseInt(process.env.OTP_EXPIRY_MINUTES || '10', 10),
      length: parseInt(process.env.OTP_LENGTH || '6', 10),
    },
    razorpay: {
      keyId: process.env.RAZORPAY_KEY_ID,
      keySecret: process.env.RAZORPAY_KEY_SECRET,
      webhookSecret: process.env.RAZORPAY_WEBHOOK_SECRET,
    },
    firebase: {
      projectId: process.env.FIREBASE_PROJECT_ID,
      clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
      privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
    },
    cloudinary: {
      cloudName: process.env.CLOUDINARY_CLOUD_NAME,
      apiKey: process.env.CLOUDINARY_API_KEY,
      apiSecret: process.env.CLOUDINARY_API_SECRET,
    },
    cache: {
      homeTtl: parseInt(process.env.CACHE_TTL_HOME || '120', 10),
      dashboardTtl: parseInt(process.env.CACHE_TTL_DASHBOARD || '60', 10),
      productsTtl: parseInt(process.env.CACHE_TTL_PRODUCTS || '180', 10),
    },
    rateLimit: {
      ttlMs: rateLimitTtlSec * 1000,
      limit: rateLimitMax,
    },
    throttle: {
      ttl: rateLimitTtlSec * 1000,
      limit: rateLimitMax,
    },
    payment: {
      timeoutMinutes: parseInt(process.env.PAYMENT_TIMEOUT_MINUTES || '30', 10),
    },
    sentry: {
      dsn: process.env.SENTRY_DSN || '',
      enabled: Boolean(process.env.SENTRY_DSN?.trim()),
    },
    logLevel: process.env.LOG_LEVEL || 'info',
    swagger: {
      enabled: swaggerEnabled,
    },
    realtime: {
      enabled: parseBool(process.env.REALTIME_ENABLED, true),
    },
    queues: {
      enabled: parseBool(process.env.QUEUES_ENABLED, true),
    },
    metrics: {
      enabled: parseBool(process.env.METRICS_ENABLED, true),
      token: process.env.METRICS_TOKEN || '',
    },
  };
};
