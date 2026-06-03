import { PrismaClient, UserRole, DeliveryType } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Seeding database...');

  const adminEmail = process.env.ADMIN_SEED_EMAIL || 'admin@dailyrashan.com';
  const adminPassword = process.env.ADMIN_SEED_PASSWORD || 'Admin@123456';
  const adminPhone = process.env.ADMIN_SEED_PHONE || '9999999999';

  const passwordHash = await bcrypt.hash(adminPassword, 12);

  const admin = await prisma.user.upsert({
    where: { email: adminEmail },
    update: {},
    create: {
      email: adminEmail,
      phone: adminPhone,
      name: 'Super Admin',
      passwordHash,
      role: UserRole.SUPER_ADMIN,
      isVerified: true,
      isActive: true,
      referralCode: 'ADMIN001',
    },
  });

  console.log(`✅ Admin user: ${admin.email}`);

  const deliverySettings = await prisma.deliverySettings.findFirst();
  if (!deliverySettings) {
    await prisma.deliverySettings.create({
      data: {
        sameDayEnabled: true,
        sameDayFee: 49,
        defaultDeliveryFee: 0,
        minOrderAmount: 199,
        freeDeliveryAbove: 499,
      },
    });
  }

  const pincodes = ['110001', '110002', '400001', '560001', '600001'];
  for (const pincode of pincodes) {
    await prisma.serviceablePincode.upsert({
      where: { pincode },
      update: {},
      create: { pincode, city: 'Metro City', isActive: true },
    });
  }

  const slotCount = await prisma.deliverySlot.count();
  if (slotCount === 0) {
    await prisma.deliverySlot.createMany({
      data: [
        {
          name: 'Morning Delivery',
          startTime: '06:00',
          endTime: '09:00',
          deliveryType: DeliveryType.NEXT_DAY_MORNING,
          dayOffset: 1,
        },
        {
          name: 'Same Day Evening',
          startTime: '18:00',
          endTime: '21:00',
          deliveryType: DeliveryType.SAME_DAY,
          dayOffset: 0,
        },
      ],
    });
  }

  const categories = [
    { name: 'Fruits & Vegetables', slug: 'fruits-vegetables', sortOrder: 1 },
    { name: 'Dairy & Breakfast', slug: 'dairy-breakfast', sortOrder: 2 },
    { name: 'Snacks & Beverages', slug: 'snacks-beverages', sortOrder: 3 },
    { name: 'Staples & Grains', slug: 'staples-grains', sortOrder: 4 },
    { name: 'Personal Care', slug: 'personal-care', sortOrder: 5 },
    { name: 'Household', slug: 'household', sortOrder: 6 },
  ];

  const categoryMap: Record<string, string> = {};

  for (const cat of categories) {
    const created = await prisma.category.upsert({
      where: { slug: cat.slug },
      update: {},
      create: {
        name: cat.name,
        slug: cat.slug,
        sortOrder: cat.sortOrder,
        imageUrl: `https://placehold.co/200x200/1FA54A/FFFFFF?text=${encodeURIComponent(cat.name)}`,
      },
    });
    categoryMap[cat.slug] = created.id;
  }

  const products = [
    {
      name: 'Fresh Tomatoes',
      slug: 'fresh-tomatoes',
      categorySlug: 'fruits-vegetables',
      basePrice: 35,
      discountPrice: 29,
      stock: 100,
      unit: 'kg',
      isFeatured: true,
      isBestSeller: true,
    },
    {
      name: 'Amul Taaza Milk 1L',
      slug: 'amul-taaza-milk-1l',
      categorySlug: 'dairy-breakfast',
      basePrice: 58,
      stock: 200,
      unit: 'pack',
      isFeatured: true,
      isTrending: true,
    },
    {
      name: 'Britannia Good Day Cookies',
      slug: 'britannia-good-day',
      categorySlug: 'snacks-beverages',
      basePrice: 30,
      discountPrice: 25,
      stock: 150,
      isBestSeller: true,
    },
    {
      name: 'Basmati Rice 5kg',
      slug: 'basmati-rice-5kg',
      categorySlug: 'staples-grains',
      basePrice: 450,
      discountPrice: 399,
      stock: 80,
      isFeatured: true,
    },
    {
      name: 'Surf Excel Matic 2kg',
      slug: 'surf-excel-matic',
      categorySlug: 'household',
      basePrice: 320,
      discountPrice: 289,
      stock: 60,
      isTrending: true,
    },
    {
      name: 'Bananas',
      slug: 'bananas',
      categorySlug: 'fruits-vegetables',
      basePrice: 48,
      stock: 120,
      unit: 'dozen',
      isBestSeller: true,
    },
  ];

  for (const p of products) {
    await prisma.product.upsert({
      where: { slug: p.slug },
      update: {},
      create: {
        name: p.name,
        slug: p.slug,
        categoryId: categoryMap[p.categorySlug],
        basePrice: p.basePrice,
        discountPrice: p.discountPrice,
        stock: p.stock,
        unit: p.unit || 'piece',
        images: [
          `https://placehold.co/400x400/1FA54A/FFFFFF?text=${encodeURIComponent(p.name)}`,
        ],
        isFeatured: p.isFeatured ?? false,
        isBestSeller: p.isBestSeller ?? false,
        isTrending: p.isTrending ?? false,
        deliveryEstimate: 'Next morning by 9 AM',
      },
    });
  }

  const bannerCount = await prisma.banner.count();
  if (bannerCount === 0) {
    await prisma.banner.create({
      data: {
        title: 'Fresh Groceries',
        subtitle: 'Delivered next morning',
        imageUrl:
          'https://placehold.co/800x300/1FA54A/FFFFFF?text=Daily+Rashan',
        sortOrder: 1,
        isActive: true,
      },
    });
  }

  await prisma.coupon.upsert({
    where: { code: 'WELCOME50' },
    update: {},
    create: {
      code: 'WELCOME50',
      description: '50 off on first order',
      discountType: 'FLAT',
      discountValue: 50,
      minOrderAmount: 299,
      usageLimit: 1000,
      isActive: true,
    },
  });

  const partnerPhone = process.env.PARTNER_SEED_PHONE || '8888888888';
  const partnerPassword = process.env.PARTNER_SEED_PASSWORD || 'Partner@123';
  const partnerHash = await bcrypt.hash(partnerPassword, 12);

  const partner = await prisma.user.upsert({
    where: { phone: partnerPhone },
    update: {},
    create: {
      phone: partnerPhone,
      email: 'partner@dailyrashan.com',
      name: 'Demo Delivery Partner',
      passwordHash: partnerHash,
      role: UserRole.DELIVERY_PARTNER,
      isVerified: true,
      isActive: true,
      referralCode: 'PARTNER01',
    },
  });

  await prisma.deliveryPartnerProfile.upsert({
    where: { userId: partner.id },
    update: {},
    create: {
      userId: partner.id,
      vehicleType: 'Bike',
      licenseNumber: 'DL-DEMO-001',
      isOnline: true,
      isAvailable: true,
    },
  });

  console.log(`✅ Delivery partner: ${partner.phone} / ${partnerPassword}`);
  console.log('✅ Seed completed successfully');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
