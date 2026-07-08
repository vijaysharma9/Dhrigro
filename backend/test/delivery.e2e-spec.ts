import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { createTestApp, API } from './helpers/test-app.factory';
import { authHeader, loginPartner, registerCustomer } from './helpers/auth.helper';

describe('Delivery (e2e)', () => {
  let app: INestApplication;
  let partnerToken: string;

  beforeAll(async () => {
    app = await createTestApp();
    const partner = await loginPartner(app);
    partnerToken = partner.accessToken;
  });

  afterAll(async () => {
    await app.close();
  });

  it('partner can fetch profile', async () => {
    const res = await request(app.getHttpServer())
      .get(`${API}/delivery/profile`)
      .set(authHeader(partnerToken))
      .expect(200);

    expect(res.body.user ?? res.body).toBeDefined();
  });

  it('partner can toggle availability', async () => {
    const res = await request(app.getHttpServer())
      .patch(`${API}/delivery/availability`)
      .set(authHeader(partnerToken))
      .send({ isOnline: true, isAvailable: true })
      .expect(200);

    expect(res.body.isOnline ?? res.body.profile?.isOnline).toBeDefined();
  });

  it('partner can list assigned orders', async () => {
    const res = await request(app.getHttpServer())
      .get(`${API}/delivery/orders/assigned`)
      .set(authHeader(partnerToken))
      .expect(200);

    expect(Array.isArray(res.body.data ?? res.body)).toBe(true);
  });

  it('checks pincode serviceability', async () => {
    const res = await request(app.getHttpServer())
      .get(`${API}/delivery/check-pincode?pincode=110001`)
      .expect(200);

    expect(res.body.serviceable).toBe(true);
  });

  it('blocks delivery routes for customers', async () => {
    const customer = await registerCustomer(app);
    await request(app.getHttpServer())
      .get(`${API}/delivery/orders/assigned`)
      .set(authHeader(customer.accessToken))
      .expect(403);
  });
});
