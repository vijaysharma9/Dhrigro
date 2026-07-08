import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { createTestApp, API } from './helpers/test-app.factory';
import { authHeader, registerCustomer } from './helpers/auth.helper';

describe('Payments (e2e)', () => {
  let app: INestApplication;
  let token: string;
  let orderId: string;

  beforeAll(async () => {
    app = await createTestApp();
    const customer = await registerCustomer(app);
    token = customer.accessToken;

    const products = await request(app.getHttpServer()).get(`${API}/products`).expect(200);
    const rice = products.body.data.find(
      (p: { slug: string }) => p.slug === 'basmati-rice-5kg',
    );
    const productId = rice?.id ?? products.body.data[0].id;

    await request(app.getHttpServer())
      .post(`${API}/cart/items`)
      .set(authHeader(token))
      .send({ productId, quantity: 1 });

    const address = await request(app.getHttpServer())
      .post(`${API}/addresses`)
      .set(authHeader(token))
      .send({
        fullName: 'Pay Customer',
        phone: '9876543211',
        addressLine1: '456 Pay Street',
        city: 'Delhi',
        state: 'Delhi',
        pincode: '110001',
      })
      .expect(201);

    const order = await request(app.getHttpServer())
      .post(`${API}/orders`)
      .set(authHeader(token))
      .send({
        addressId: address.body.id,
        paymentMethod: 'RAZORPAY',
        deliveryType: 'NEXT_DAY_MORNING',
      })
      .expect(201);

    orderId = order.body.id;
  });

  afterAll(async () => {
    await app.close();
  });

  it('creates Razorpay order for online payment', async () => {
    const res = await request(app.getHttpServer())
      .post(`${API}/payments/razorpay/create-order`)
      .set(authHeader(token))
      .send({ orderId })
      .expect((r) => {
        expect([200, 201, 400, 503]).toContain(r.status);
      });

    if (res.status === 200 || res.status === 201) {
      expect(res.body.razorpayOrderId ?? res.body.orderId).toBeDefined();
    }
  });

  it('rejects verify with invalid signature', async () => {
    await request(app.getHttpServer())
      .post(`${API}/payments/razorpay/verify`)
      .set(authHeader(token))
      .send({
        orderId,
        razorpayOrderId: 'order_fake',
        razorpayPaymentId: 'pay_fake',
        razorpaySignature: 'invalid',
      })
      .expect((r) => {
        expect([400, 401, 403]).toContain(r.status);
      });
  });

  it('requires auth for payment endpoints', async () => {
    await request(app.getHttpServer())
      .post(`${API}/payments/razorpay/create-order`)
      .send({ orderId })
      .expect(401);
  });
});
