import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CartService } from './cart.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';

@ApiTags('Cart')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('cart')
export class CartController {
  constructor(private cartService: CartService) {}

  @Get()
  getCart(@CurrentUser('id') userId: string) {
    return this.cartService.getCart(userId);
  }

  @Post('items')
  addItem(
    @CurrentUser('id') userId: string,
    @Body() body: { productId: string; quantity?: number; variantId?: string },
  ) {
    return this.cartService.addItem(
      userId,
      body.productId,
      body.quantity,
      body.variantId,
    );
  }

  @Patch('items/:itemId')
  updateItem(
    @CurrentUser('id') userId: string,
    @Param('itemId') itemId: string,
    @Body() body: { quantity?: number; savedForLater?: boolean },
  ) {
    return this.cartService.updateItem(userId, itemId, body);
  }

  @Delete('items/:itemId')
  removeItem(
    @CurrentUser('id') userId: string,
    @Param('itemId') itemId: string,
  ) {
    return this.cartService.removeItem(userId, itemId);
  }

  @Post('coupon')
  applyCoupon(
    @CurrentUser('id') userId: string,
    @Body() body: { code: string },
  ) {
    return this.cartService.applyCoupon(userId, body.code);
  }

  @Delete('coupon')
  removeCoupon(@CurrentUser('id') userId: string) {
    return this.cartService.removeCoupon(userId);
  }

  @Delete()
  clearCart(@CurrentUser('id') userId: string) {
    return this.cartService.clearCart(userId);
  }
}
