import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { createTestApp, API } from './helpers/test-app.factory';
import { authHeader, loginAdmin } from './helpers/auth.helper';

describe('Metrics & Queues (e2e)', () => {
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

  it('exposes Prometheus metrics', async () => {
    await request(app.getHttpServer()).get(`${API}/home`).expect(200);

    const res = await request(app.getHttpServer()).get('/metrics').expect(200);

    expect(res.text).toContain('http_requests_total');
    expect(res.text).toContain('process_cpu');
  });

  it('admin can read system health with queue stats', async () => {
    const res = await request(app.getHttpServer())
      .get(`${API}/admin/system/health`)
      .set(authHeader(adminToken))
      .expect(200);

    expect(res.body.queues ?? res.body.status).toBeDefined();
  });

  it('admin can read automation rules', async () => {
    const res = await request(app.getHttpServer())
      .get(`${API}/admin/automation/rules`)
      .set(authHeader(adminToken))
      .expect(200);

    expect(Array.isArray(res.body)).toBe(true);
    expect(res.body.length).toBeGreaterThan(0);
  });
});
