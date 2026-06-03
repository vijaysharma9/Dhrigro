-- Delivery partner role and operations
CREATE TYPE "DeliveryAssignmentStatus" AS ENUM ('ASSIGNED', 'PICKED', 'ON_THE_WAY', 'DELIVERED', 'FAILED');

ALTER TYPE "UserRole" ADD VALUE IF NOT EXISTS 'DELIVERY_PARTNER';

ALTER TABLE "DeliverySettings" ADD COLUMN IF NOT EXISTS "partnerEarningPerDelivery" DECIMAL(10,2) NOT NULL DEFAULT 25;

ALTER TABLE "Order" ADD COLUMN IF NOT EXISTS "deliveryOtp" TEXT;
ALTER TABLE "Order" ADD COLUMN IF NOT EXISTS "deliveryOtpExpiresAt" TIMESTAMP(3);
ALTER TABLE "Order" ADD COLUMN IF NOT EXISTS "deliveryOtpSentAt" TIMESTAMP(3);

CREATE TABLE "DeliveryPartnerProfile" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "vehicleType" TEXT,
    "licenseNumber" TEXT,
    "isOnline" BOOLEAN NOT NULL DEFAULT false,
    "isAvailable" BOOLEAN NOT NULL DEFAULT true,
    "currentLatitude" DOUBLE PRECISION,
    "currentLongitude" DOUBLE PRECISION,
    "totalDeliveries" INTEGER NOT NULL DEFAULT 0,
    "rating" DECIMAL(3,2) NOT NULL DEFAULT 5,
    "earnings" DECIMAL(12,2) NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "DeliveryPartnerProfile_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "DeliveryAssignment" (
    "id" TEXT NOT NULL,
    "orderId" TEXT NOT NULL,
    "deliveryPartnerId" TEXT NOT NULL,
    "status" "DeliveryAssignmentStatus" NOT NULL DEFAULT 'ASSIGNED',
    "assignedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "acceptedAt" TIMESTAMP(3),
    "pickedAt" TIMESTAMP(3),
    "deliveredAt" TIMESTAMP(3),
    "notes" TEXT,
    "failureReason" TEXT,
    "earningAmount" DECIMAL(10,2),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "DeliveryAssignment_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "DeliveryPartnerProfile_userId_key" ON "DeliveryPartnerProfile"("userId");
CREATE INDEX "DeliveryPartnerProfile_isOnline_isAvailable_idx" ON "DeliveryPartnerProfile"("isOnline", "isAvailable");

CREATE UNIQUE INDEX "DeliveryAssignment_orderId_key" ON "DeliveryAssignment"("orderId");
CREATE INDEX "DeliveryAssignment_deliveryPartnerId_status_idx" ON "DeliveryAssignment"("deliveryPartnerId", "status");
CREATE INDEX "DeliveryAssignment_status_idx" ON "DeliveryAssignment"("status");

ALTER TABLE "DeliveryPartnerProfile" ADD CONSTRAINT "DeliveryPartnerProfile_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "DeliveryAssignment" ADD CONSTRAINT "DeliveryAssignment_orderId_fkey" FOREIGN KEY ("orderId") REFERENCES "Order"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "DeliveryAssignment" ADD CONSTRAINT "DeliveryAssignment_deliveryPartnerId_fkey" FOREIGN KEY ("deliveryPartnerId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "DeliveryAssignment" ADD CONSTRAINT "DeliveryAssignment_profile_fkey" FOREIGN KEY ("deliveryPartnerId") REFERENCES "DeliveryPartnerProfile"("userId") ON DELETE RESTRICT ON UPDATE CASCADE;
