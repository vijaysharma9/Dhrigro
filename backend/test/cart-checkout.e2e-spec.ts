import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { createTestApp, API } from './helpers/test-app.factory';
import { authHeader, registerCustomer } from './helpers/auth.helper';

describe('Cart & Checkout (e2e)', () => {
  let app: INestApplication;
  let token: string;
  let productId: string;
  let addressId: string;

  beforeAll(async () => {
    app = await createTestApp();
    const customer = await registerCustomer(app);
    token = customer.accessToken;

    const products = await request(app.getHttpServer()).get(`${API}/products`).expect(200);
    const rice = products.body.data.find(
      (p: { slug: string }) => p.slug === 'basmati-rice-5kg',
    );
    productId = rice?.id ?? products.body.data[0].id;

    const address = await request(app.getHttpServer())
      .post(`${API}/addresses`)
      .set(authHeader(token))
      .send({
        fullName: 'QA Customer',
        phone: '9876543210',
        addressLine1: '123 Test Street',
        city: 'Delhi',
        state: 'Delhi',
        pincode: '110001',
        isDefault: true,
      })
      .expect(201);
    addressId = address.body.id;
  });

  afterAll(async () => {
    await app.close();
  });

  it('starts with empty cart', async () => {
    const res = await request(app.getHttpServer())
      .get(`${API}/cart`)
      .set(authHeader(token))
      .expect(200);

    expect(res.body.items ?? []).toHaveLength(0);
  });

  it('adds item to cart', async () => {
    const res = await request(app.getHttpServer())
      .post(`${API}/cart/items`)
      .set(authHeader(token))
      .send({ productId, quantity: 1 })
      .expect(201);

    expect(res.body.items.length).toBeGreaterThan(0);
  });

  it('applies coupon WELCOME50', async () => {
    const res = await request(app.getHttpServer())
      .post(`${API}/cart/coupon`)
      .set(authHeader(token))
      .send({ code: 'WELCOME50' })
      .expect(201);

    expect(res.body.coupon?.code ?? res.body.couponCode).toBe('WELCOME50');
  });

  it('places COD order', async () => {
    const res = await request(app.getHttpServer())
      .post(`${API}/orders`)
      .set(authHeader(token))
      .send({
        addressId,
        paymentMethod: 'COD',
        deliveryType: 'NEXT_DAY_MORNING',
      })
      .expect(201);

    expect(res.body.id).toBeDefined();
    expect(res.body.orderNumber).toBeDefined();
    expect(res.body.status).toBeDefined();
  });

  it('lists customer orders', async () => {
    const res = await request(app.getHttpServer())
      .get(`${API}/orders`)
      .set(authHeader(token))
      .expect(200);

    expect(res.body.data?.length ?? res.body.length).toBeGreaterThan(0);
  });

  it('rejects cart access without auth', async () => {
    await request(app.getHttpServer()).get(`${API}/cart`).expect(401);
  });
});
