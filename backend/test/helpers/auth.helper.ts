import request from 'supertest';
import { INestApplication } from '@nestjs/common';
import { API } from './test-app.factory';

export interface AuthTokens {
  accessToken: string;
  refreshToken: string;
  userId: string;
}

export async function registerCustomer(
  app: INestApplication,
  suffix = Date.now().toString().slice(-9),
): Promise<AuthTokens> {
  const phone = `9${suffix.padStart(9, '0').slice(-9)}`;
  const res = await request(app.getHttpServer())
    .post(`${API}/auth/register`)
    .send({
      phone,
      password: 'Test@123456',
      name: 'QA Customer',
    })
    .expect((r) => expect([200, 201]).toContain(r.status));

  return {
    accessToken: res.body.accessToken,
    refreshToken: res.body.refreshToken,
    userId: res.body.user.id,
  };
}

export async function loginAdmin(app: INestApplication): Promise<AuthTokens> {
  const res = await request(app.getHttpServer())
    .post(`${API}/auth/login`)
    .send({
      email: process.env.ADMIN_SEED_EMAIL || 'admin@dhrigro.com',
      password: process.env.ADMIN_SEED_PASSWORD || 'Admin@123456',
    })
    .expect((r) => expect([200, 201]).toContain(r.status));

  return {
    accessToken: res.body.accessToken,
    refreshToken: res.body.refreshToken,
    userId: res.body.user.id,
  };
}

export async function loginPartner(app: INestApplication): Promise<AuthTokens> {
  const res = await request(app.getHttpServer())
    .post(`${API}/auth/login`)
    .send({
      phone: process.env.PARTNER_SEED_PHONE || '8888888888',
      password: process.env.PARTNER_SEED_PASSWORD || 'Partner@123',
    })
    .expect((r) => expect([200, 201]).toContain(r.status));

  return {
    accessToken: res.body.accessToken,
    refreshToken: res.body.refreshToken,
    userId: res.body.user.id,
  };
}

export function authHeader(token: string) {
  return { Authorization: `Bearer ${token}` };
}
