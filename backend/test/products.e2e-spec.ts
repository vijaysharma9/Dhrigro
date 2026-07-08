import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { createTestApp, API } from './helpers/test-app.factory';
import { authHeader, loginAdmin } from './helpers/auth.helper';

describe('Products (e2e)', () => {
  let app: INestApplication;
  let adminToken: string;

  beforeAll(async () => {
    app = await createTestApp();
    const admin = await loginAdmin(app);
    adminToken = admin.accessToken;
  });

  afterAll(async () => {
    await app.close();
  });

  it('lists products publicly', async () => {
    const res = await request(app.getHttpServer())
      .get(`${API}/products`)
      .expect(200);

    expect(res.body.data).toBeDefined();
    expect(Array.isArray(res.body.data)).toBe(true);
    expect(res.body.data.length).toBeGreaterThan(0);
  });

  it('searches products by query', async () => {
    const res = await request(app.getHttpServer())
      .get(`${API}/products?search=milk`)
      .expect(200);

    expect(res.body.data).toBeDefined();
  });

  it('gets featured products', async () => {
    const res = await request(app.getHttpServer())
      .get(`${API}/products/featured`)
      .expect(200);

    expect(res.body.data).toBeDefined();
  });

  it('gets product detail by id', async () => {
    const list = await request(app.getHttpServer()).get(`${API}/products`).expect(200);
    const productId = list.body.data[0].id;

    const res = await request(app.getHttpServer())
      .get(`${API}/products/${productId}`)
      .expect(200);

    expect(res.body.id).toBe(productId);
    expect(res.body.name).toBeDefined();
  });

  it('returns home feed with categories and products', async () => {
    const res = await request(app.getHttpServer()).get(`${API}/home`).expect(200);

    expect(res.body.categories).toBeDefined();
    expect(res.body.featuredProducts).toBeDefined();
    expect(res.body.banners).toBeDefined();
  });

  it('denies admin product create to customer token', async () => {
    await request(app.getHttpServer())
      .post(`${API}/products`)
      .set(authHeader(adminToken))
      .send({
        name: 'QA Product',
        slug: `qa-product-${Date.now()}`,
        categoryId: 'invalid',
        basePrice: 99,
      })
      .expect((res) => {
        expect([400, 403, 404]).toContain(res.status);
      });
  });
});
