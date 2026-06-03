import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class CartService {
  constructor(private prisma: PrismaService) {}

  private async getOrCreateCart(userId: string) {
    const include = {
      items: {
        include: {
          product: { include: { variants: true } },
          variant: true,
        },
      },
      coupon: true,
    } as const;

    let cart = await this.prisma.cart.findUnique({
      where: { userId },
      include,
    });

    if (!cart) {
      cart = await this.prisma.cart.create({
        data: { userId },
        include,
      });
    }

    return cart;
  }

  private getItemPrice(
    product: { basePrice: unknown; discountPrice: unknown },
    variant?: { price: unknown; discountPrice: unknown } | null,
  ): number {
    if (variant) {
      return Number(variant.discountPrice ?? variant.price);
    }
    return Number(product.discountPrice ?? product.basePrice);
  }

  calculateTotals(
    items: Array<{
      quantity: number;
      savedForLater: boolean;
      product: { basePrice: unknown; discountPrice: unknown };
      variant?: { price: unknown; discountPrice: unknown } | null;
    }>,
    coupon?: { discountType: string; discountValue: unknown; maxDiscount?: unknown } | null,
    deliveryFee = 0,
    sameDayFee = 0,
  ) {
    const activeItems = items.filter((i) => !i.savedForLater);
    const subtotal = activeItems.reduce((sum, item) => {
      const price = this.getItemPrice(item.product, item.variant);
      return sum + price * item.quantity;
    }, 0);

    let discountAmount = 0;
    if (coupon && subtotal > 0) {
      if (coupon.discountType === 'PERCENTAGE') {
        discountAmount = (subtotal * Number(coupon.discountValue)) / 100;
        if (coupon.maxDiscount) {
          discountAmount = Math.min(discountAmount, Number(coupon.maxDiscount));
        }
      } else {
        discountAmount = Number(coupon.discountValue);
      }
    }

    const total =
      subtotal - discountAmount + deliveryFee + sameDayFee;

    return {
      subtotal: Math.round(subtotal * 100) / 100,
      discountAmount: Math.round(discountAmount * 100) / 100,
      deliveryFee,
      sameDayFee,
      total: Math.round(total * 100) / 100,
      itemCount: activeItems.reduce((s, i) => s + i.quantity, 0),
    };
  }

  async getCart(userId: string, deliveryFee = 0, sameDayFee = 0) {
    const cart = await this.getOrCreateCart(userId);
    const totals = this.calculateTotals(
      cart.items,
      cart.coupon,
      deliveryFee,
      sameDayFee,
    );

    return {
      id: cart.id,
      items: cart.items.map((item) => ({
        id: item.id,
        productId: item.productId,
        variantId: item.variantId,
        quantity: item.quantity,
        savedForLater: item.savedForLater,
        unitPrice: this.getItemPrice(item.product, item.variant),
        lineTotal:
          this.getItemPrice(item.product, item.variant) * item.quantity,
        product: {
          id: item.product.id,
          name: item.product.name,
          images: item.product.images,
          unit: item.product.unit,
          stock: item.product.stock,
        },
        variant: item.variant,
      })),
      coupon: cart.coupon,
      ...totals,
    };
  }

  async addItem(
    userId: string,
    productId: string,
    quantity = 1,
    variantId?: string,
  ) {
    const product = await this.prisma.product.findFirst({
      where: { id: productId, isActive: true, deletedAt: null },
    });
    if (!product) throw new NotFoundException('Product not found');

    const cart = await this.getOrCreateCart(userId);

    const existing = await this.prisma.cartItem.findFirst({
      where: {
        cartId: cart.id,
        productId,
        variantId: variantId ?? null,
      },
    });

    if (existing) {
      await this.prisma.cartItem.update({
        where: { id: existing.id },
        data: { quantity: existing.quantity + quantity, savedForLater: false },
      });
    } else {
      await this.prisma.cartItem.create({
        data: {
          cartId: cart.id,
          productId,
          variantId,
          quantity,
        },
      });
    }

    return this.getCart(userId);
  }

  async updateItem(
    userId: string,
    itemId: string,
    data: { quantity?: number; savedForLater?: boolean },
  ) {
    const cart = await this.getOrCreateCart(userId);
    const item = cart.items.find((i) => i.id === itemId);
    if (!item) throw new NotFoundException('Cart item not found');

    if (data.quantity !== undefined && data.quantity < 1) {
      return this.removeItem(userId, itemId);
    }

    await this.prisma.cartItem.update({
      where: { id: itemId },
      data,
    });

    return this.getCart(userId);
  }

  async removeItem(userId: string, itemId: string) {
    const cart = await this.getOrCreateCart(userId);
    const item = cart.items.find((i) => i.id === itemId);
    if (!item) throw new NotFoundException('Cart item not found');

    await this.prisma.cartItem.delete({ where: { id: itemId } });
    return this.getCart(userId);
  }

  async applyCoupon(userId: string, code: string) {
    const coupon = await this.prisma.coupon.findFirst({
      where: {
        code: code.toUpperCase(),
        isActive: true,
        OR: [{ expiresAt: null }, { expiresAt: { gt: new Date() } }],
      },
    });

    if (!coupon) {
      throw new BadRequestException('Invalid coupon code');
    }

    if (coupon.usageLimit && coupon.usedCount >= coupon.usageLimit) {
      throw new BadRequestException('Coupon usage limit reached');
    }

    const cart = await this.getOrCreateCart(userId);
    await this.prisma.cart.update({
      where: { id: cart.id },
      data: { couponId: coupon.id },
    });

    return this.getCart(userId);
  }

  async removeCoupon(userId: string) {
    const cart = await this.getOrCreateCart(userId);
    await this.prisma.cart.update({
      where: { id: cart.id },
      data: { couponId: null },
    });
    return this.getCart(userId);
  }

  async clearCart(userId: string) {
    const cart = await this.getOrCreateCart(userId);
    await this.prisma.cartItem.deleteMany({ where: { cartId: cart.id } });
    return this.getCart(userId);
  }
}
