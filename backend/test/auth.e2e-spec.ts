import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { createTestApp, API } from './helpers/test-app.factory';
import { authHeader, loginAdmin, registerCustomer } from './helpers/auth.helper';

describe('Auth (e2e)', () => {
  let app: INestApplication;

  beforeAll(async () => {
    app = await createTestApp();
  });

  afterAll(async () => {
    await app.close();
  });

  it('registers a new customer', async () => {
    const phone = `98765${Date.now().toString().slice(-5)}`;
    const res = await request(app.getHttpServer())
      .post(`${API}/auth/register`)
      .send({ phone, password: 'Test@123456', name: 'New User' })
      .expect((r) => expect([200, 201]).toContain(r.status));

    expect(res.body.accessToken).toBeDefined();
    expect(res.body.user.phone).toBe(phone);
    expect(res.body.user.role).toBe('CUSTOMER');
  });

  it('rejects duplicate phone registration', async () => {
    const phone = `98764${Date.now().toString().slice(-5)}`;
    await request(app.getHttpServer())
      .post(`${API}/auth/register`)
      .send({ phone, password: 'Test@123456', name: 'Dup User' })
      .expect((r) => expect([200, 201]).toContain(r.status));

    await request(app.getHttpServer())
      .post(`${API}/auth/register`)
      .send({ phone, password: 'Test@123456', name: 'Dup User 2' })
      .expect(409);
  });

  it('logs in admin with email/password', async () => {
    const tokens = await loginAdmin(app);
    expect(tokens.accessToken).toBeDefined();

    const profile = await request(app.getHttpServer())
      .get(`${API}/auth/profile`)
      .set(authHeader(tokens.accessToken))
      .expect(200);

    expect(profile.body.user.role).toBe('SUPER_ADMIN');
  });

  it('returns OTP in development mode', async () => {
    const phone = `98763${Date.now().toString().slice(-5)}`;
    const res = await request(app.getHttpServer())
      .post(`${API}/auth/otp/request`)
      .send({ phone })
      .expect((r) => expect([200, 201]).toContain(r.status));

    expect(res.body.message).toContain('OTP');
    if (process.env.NODE_ENV !== 'production') {
      expect(res.body.devOtp).toMatch(/^\d{6}$/);
    }
  });

  it('rejects invalid credentials', async () => {
    await request(app.getHttpServer())
      .post(`${API}/auth/login`)
      .send({ email: 'admin@dhrigro.com', password: 'wrong-password' })
      .expect(401);
  });

  it('refreshes tokens', async () => {
    const customer = await registerCustomer(app);
    const res = await request(app.getHttpServer())
      .post(`${API}/auth/refresh`)
      .send({ refreshToken: customer.refreshToken })
      .expect((r) => expect([200, 201]).toContain(r.status));

    expect(res.body.accessToken).toBeDefined();
    expect(res.body.refreshToken).toBeDefined();
  });

  it('blocks protected routes without JWT', async () => {
    await request(app.getHttpServer()).get(`${API}/auth/profile`).expect(401);
  });
});
