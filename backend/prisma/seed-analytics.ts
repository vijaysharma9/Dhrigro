import {
  OrderStatus,
  PaymentMethod,
  PaymentStatus,
  PrismaClient,
  UserRole,
} from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();

const FIRST_NAMES = ['Aarav', 'Priya', 'Rohan', 'Ananya', 'Vikram', 'Neha', 'Karan', 'Sneha', 'Arjun', 'Divya'];
const LAST_NAMES = ['Sharma', 'Patel', 'Singh', 'Gupta', 'Reddy', 'Iyer', 'Khan', 'Das', 'Mehta', 'Nair'];

function randomItem<T>(arr: T[]): T {
  return arr[Math.floor(Math.random() * arr.length)];
}

function randomInt(min: number, max: number): number {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

async function ensureCustomers(count: number) {
  const existing = await prisma.user.count({ where: { role: UserRole.CUSTOMER } });
  if (existing >= count) {
    return prisma.user.findMany({
      where: { role: UserRole.CUSTOMER },
      include: { addresses: true },
      take: count,
    });
  }

  const passwordHash = await bcrypt.hash('Customer@123', 12);
  const created = [];

  for (let i = existing; i < count; i++) {
    const phone = `9${String(100000000 + i).padStart(9, '0')}`;
    const name = `${randomItem(FIRST_NAMES)} ${randomItem(LAST_NAMES)}`;
    const user = await prisma.user.upsert({
      where: { phone },
      update: {},
      create: {
        phone,
        email: `customer${i + 1}@demo.dhrigro.com`,
        name,
        passwordHash,
        role: UserRole.CUSTOMER,
        isVerified: true,
        isActive: true,
        referralCode: `CUST${String(i + 1).padStart(4, '0')}`,
      },
    });

    const address = await prisma.address.create({
      data: {
        userId: user.id,
        fullName: name,
        phone,
        addressLine1: `${randomInt(1, 200)} MG Road`,
        city: randomItem(['Delhi', 'Mumbai', 'Bangalore', 'Chennai']),
        state: 'India',
        pincode: randomItem(['110001', '110002', '400001', '560001']),
        isDefault: true,
      },
    });

    created.push({ ...user, addresses: [address] });
  }

  return prisma.user.findMany({
    where: { role: UserRole.CUSTOMER },
    include: { addresses: true },
    take: count,
  });
}

async function main() {
  console.log('📊 Seeding analytics demo data…');

  const products = await prisma.product.findMany({
    where: { deletedAt: null, isActive: true },
    take: 20,
  });

  if (products.length === 0) {
    console.error('No products found. Run prisma:seed first.');
    process.exit(1);
  }

  const customers = await ensureCustomers(25);
  const partner = await prisma.user.findFirst({
    where: { role: UserRole.DELIVERY_PARTNER },
    include: { deliveryPartnerProfile: true },
  });

  const slot = await prisma.deliverySlot.findFirst();
  const coupon = await prisma.coupon.findFirst({ where: { code: 'WELCOME50' } });

  const existingAnalyticsOrders = await prisma.order.count({
    where: {
      orderNumber: { startsWith: 'DR-AN-' },
    },
  });

  if (existingAnalyticsOrders > 50) {
    console.log(`⏭️  Skipping — ${existingAnalyticsOrders} analytics orders already exist`);
    return;
  }

  const statuses: OrderStatus[] = [
    OrderStatus.DELIVERED,
    OrderStatus.DELIVERED,
    OrderStatus.DELIVERED,
    OrderStatus.OUT_FOR_DELIVERY,
    OrderStatus.PACKED,
    OrderStatus.CONFIRMED,
    OrderStatus.PENDING,
    OrderStatus.CANCELLED,
  ];

  let orderSeq = existingAnalyticsOrders + 1;

  for (let dayOffset = 30; dayOffset >= 0; dayOffset--) {
    const ordersToday = randomInt(3, 14);
    const placedDate = new Date();
    placedDate.setDate(placedDate.getDate() - dayOffset);
    placedDate.setHours(randomInt(8, 21), randomInt(0, 59), 0, 0);

    for (let o = 0; o < ordersToday; o++) {
      const customer = randomItem(customers);
      const address = customer.addresses[0];
      if (!address) continue;

      const status = randomItem(statuses);
      const paymentMethod = Math.random() > 0.35 ? PaymentMethod.COD : PaymentMethod.RAZORPAY;
      const paymentFailed = paymentMethod === PaymentMethod.RAZORPAY && Math.random() < 0.08;
      const paymentStatus = paymentFailed
        ? PaymentStatus.FAILED
        : status === OrderStatus.CANCELLED
          ? PaymentStatus.PENDING
          : PaymentStatus.PAID;

      const itemCount = randomInt(1, 4);
      const orderProducts = Array.from({ length: itemCount }, () => randomItem(products));
      let subtotal = 0;

      const orderNumber = `DR-AN-${String(orderSeq++).padStart(5, '0')}`;
      const placedAt = new Date(placedDate);
      placedAt.setMinutes(placedAt.getMinutes() + o * 12);

      const order = await prisma.order.create({
        data: {
          orderNumber,
          userId: customer.id,
          addressId: address.id,
          deliverySlotId: slot?.id,
          couponId: Math.random() > 0.85 ? coupon?.id : undefined,
          status,
          paymentMethod,
          paymentStatus,
          subtotal: 0,
          deliveryFee: 0,
          totalAmount: 0,
          placedAt,
          confirmedAt: status !== OrderStatus.PENDING ? new Date(placedAt.getTime() + 600000) : null,
          deliveredAt:
            status === OrderStatus.DELIVERED
              ? new Date(placedAt.getTime() + 86400000)
              : null,
        },
      });

      for (const product of orderProducts) {
        const qty = randomInt(1, 3);
        const unitPrice = Number(product.discountPrice ?? product.basePrice);
        const totalPrice = unitPrice * qty;
        subtotal += totalPrice;

        await prisma.orderItem.create({
          data: {
            orderId: order.id,
            productId: product.id,
            productName: product.name,
            quantity: qty,
            unitPrice,
            totalPrice,
          },
        });
      }

      const deliveryFee = subtotal >= 499 ? 0 : 29;
      const discount = order.couponId ? 50 : 0;
      const totalAmount = Math.max(subtotal + deliveryFee - discount, 0);

      await prisma.order.update({
        where: { id: order.id },
        data: {
          subtotal,
          deliveryFee,
          discountAmount: discount,
          totalAmount,
        },
      });

      await prisma.orderStatusLog.create({
        data: { orderId: order.id, status, note: 'Analytics seed' },
      });

      if (partner && status === OrderStatus.OUT_FOR_DELIVERY) {
        await prisma.deliveryAssignment.create({
          data: {
            orderId: order.id,
            deliveryPartnerId: partner.id,
            assignedAt: new Date(placedAt.getTime() + 3600000),
            status: 'ASSIGNED',
          },
        });
      }
    }
  }

  // Low stock on a few products for dashboard alerts
  const lowStockProducts = products.slice(0, 3);
  for (const p of lowStockProducts) {
    await prisma.product.update({
      where: { id: p.id },
      data: { stock: randomInt(1, 8) },
    });
  }

  console.log('✅ Analytics seed complete');
  console.log(`   Orders: ~${orderSeq - 1} over 30 days`);
  console.log(`   Customers: ${customers.length}`);
  console.log(`   Low stock SKUs: ${lowStockProducts.length}`);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
