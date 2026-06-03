CREATE TABLE "PaymentAuditLog" (
    "id" TEXT NOT NULL,
    "orderId" TEXT,
    "userId" TEXT,
    "eventType" TEXT NOT NULL,
    "status" TEXT,
    "payload" JSONB,
    "source" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "PaymentAuditLog_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "NotificationDeliveryLog" (
    "id" TEXT NOT NULL,
    "userId" TEXT,
    "title" TEXT NOT NULL,
    "status" TEXT NOT NULL,
    "error" TEXT,
    "payload" JSONB,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "NotificationDeliveryLog_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "PaymentAuditLog_orderId_idx" ON "PaymentAuditLog"("orderId");
CREATE INDEX "PaymentAuditLog_eventType_createdAt_idx" ON "PaymentAuditLog"("eventType", "createdAt");
CREATE INDEX "NotificationDeliveryLog_userId_createdAt_idx" ON "NotificationDeliveryLog"("userId", "createdAt");
CREATE INDEX "NotificationDeliveryLog_status_idx" ON "NotificationDeliveryLog"("status");
