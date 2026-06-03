import {
  Body,
  Controller,
  Delete,
  Get,
  Header,
  Param,
  Patch,
  Post,
  Put,
  Query,
  Res,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { OrderStatus, UserRole } from '@prisma/client';
import { Response } from 'express';
import { AdminService } from './admin.service';
import { AdminOrdersService } from './services/admin-orders.service';
import { AdminUsersService } from './services/admin-users.service';
import { AdminInventoryService } from './services/admin-inventory.service';
import { AdminReportsService } from './services/admin-reports.service';
import { AdminDeliveryService } from './services/admin-delivery.service';
import { DeliveryAssignmentsService } from '../delivery-assignments/delivery-assignments.service';
import {
  AssignDeliveryDto,
  ReassignDeliveryDto,
} from '../delivery-assignments/dto/delivery-assignment.dto';
import { CouponsService } from '../coupons/coupons.service';
import { BannersService } from '../banners/banners.service';
import {
  AdminInventoryQueryDto,
  AdminOrdersQueryDto,
  AdminReportsQueryDto,
  AdminUsersQueryDto,
} from './dto/admin-query.dto';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { PermissionsGuard } from '../../common/guards/permissions.guard';
import { AdminAccess } from '../../common/decorators/admin-access.decorator';
import { STAFF_ROLES } from '../../common/rbac/permissions';
import { Roles } from '../../common/decorators/roles.decorator';
import { RolesGuard } from '../../common/guards/roles.guard';

@ApiTags('Admin')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard, PermissionsGuard)
@Roles(...STAFF_ROLES)
@Controller('admin')
export class AdminController {
  constructor(
    private adminService: AdminService,
    private adminOrdersService: AdminOrdersService,
    private adminUsersService: AdminUsersService,
    private adminInventoryService: AdminInventoryService,
    private adminReportsService: AdminReportsService,
    private adminDeliveryService: AdminDeliveryService,
    private deliveryAssignmentsService: DeliveryAssignmentsService,
    private couponsService: CouponsService,
    private bannersService: BannersService,
  ) {}

  @AdminAccess('dashboard')
  @Get('dashboard')
  getDashboard() {
    return this.adminService.getDashboardStats();
  }

  @AdminAccess('dashboard')
  @Get('permissions')
  getPermissions() {
    return { staffRoles: STAFF_ROLES };
  }

  // --- Orders ---
  @AdminAccess('orders')
  @Get('orders')
  listOrders(@Query() query: AdminOrdersQueryDto) {
    return this.adminOrdersService.listOrders(query);
  }

  @AdminAccess('orders')
  @Get('orders/export')
  @Header('Content-Type', 'text/csv')
  async exportOrders(
    @Query() query: AdminOrdersQueryDto,
    @Res() res: Response,
  ) {
    const csv = await this.adminOrdersService.exportOrdersCsv(query);
    res.setHeader(
      'Content-Disposition',
      `attachment; filename=orders-${Date.now()}.csv`,
    );
    res.send(csv);
  }

  @AdminAccess('orders')
  @Get('orders/:id')
  getOrder(@Param('id') id: string) {
    return this.adminOrdersService.getOrder(id);
  }

  @AdminAccess('orders')
  @Patch('orders/:id/status')
  updateOrderStatus(
    @Param('id') id: string,
    @Body()
    body: { status: OrderStatus; note?: string; cancelledReason?: string },
  ) {
    return this.adminOrdersService.updateStatus(
      id,
      body.status,
      body.note,
      body.cancelledReason,
    );
  }

  @AdminAccess('orders')
  @Patch('orders/:id/delivery-slot')
  assignSlot(
    @Param('id') id: string,
    @Body() body: { deliverySlotId: string },
  ) {
    return this.adminOrdersService.assignDeliverySlot(id, body.deliverySlotId);
  }

  // --- Users ---
  @AdminAccess('users')
  @Get('users')
  listUsers(@Query() query: AdminUsersQueryDto) {
    return this.adminUsersService.listUsers(query);
  }

  @AdminAccess('users')
  @Get('users/export')
  @Header('Content-Type', 'text/csv')
  async exportUsers(@Query() query: AdminUsersQueryDto, @Res() res: Response) {
    const csv = await this.adminUsersService.exportUsersCsv(query);
    res.setHeader(
      'Content-Disposition',
      `attachment; filename=users-${Date.now()}.csv`,
    );
    res.send(csv);
  }

  @AdminAccess('users')
  @Get('users/:id')
  getUser(@Param('id') id: string) {
    return this.adminUsersService.getUserDetail(id);
  }

  @AdminAccess('users')
  @Patch('users/:id/status')
  setUserStatus(
    @Param('id') id: string,
    @Body() body: { isActive: boolean },
  ) {
    return this.adminUsersService.setUserActive(id, body.isActive);
  }

  // --- Coupons ---
  @AdminAccess('coupons')
  @Get('coupons')
  listCoupons() {
    return this.couponsService.findAll();
  }

  @AdminAccess('coupons')
  @Post('coupons')
  createCoupon(@Body() body: Record<string, unknown>) {
    return this.couponsService.create(body as Parameters<CouponsService['create']>[0]);
  }

  @AdminAccess('coupons')
  @Patch('coupons/:id')
  updateCoupon(@Param('id') id: string, @Body() body: Record<string, unknown>) {
    return this.couponsService.update(id, body);
  }

  @AdminAccess('coupons')
  @Delete('coupons/:id')
  deleteCoupon(@Param('id') id: string) {
    return this.couponsService.remove(id);
  }

  // --- Banners ---
  @AdminAccess('banners')
  @Get('banners')
  listBanners() {
    return this.bannersService.findAll();
  }

  @AdminAccess('banners')
  @Post('banners')
  createBanner(@Body() body: Record<string, unknown>) {
    return this.bannersService.create(body as Parameters<BannersService['create']>[0]);
  }

  @AdminAccess('banners')
  @Patch('banners/:id')
  updateBanner(@Param('id') id: string, @Body() body: Record<string, unknown>) {
    return this.bannersService.update(id, body);
  }

  @AdminAccess('banners')
  @Delete('banners/:id')
  deleteBanner(@Param('id') id: string) {
    return this.bannersService.remove(id);
  }

  // --- Inventory ---
  @AdminAccess('inventory')
  @Get('inventory')
  listInventory(@Query() query: AdminInventoryQueryDto) {
    return this.adminInventoryService.listInventory(query);
  }

  @AdminAccess('inventory')
  @Patch('inventory/:productId')
  updateStock(
    @Param('productId') productId: string,
    @Body() body: { stock: number; isActive?: boolean },
  ) {
    return this.adminInventoryService.updateStock(
      productId,
      body.stock,
      body.isActive,
    );
  }

  @AdminAccess('inventory')
  @Post('inventory/bulk')
  bulkStock(@Body() body: { updates: { productId: string; stock: number; isActive?: boolean }[] }) {
    return this.adminInventoryService.bulkUpdateStock(body.updates);
  }

  // --- Delivery ---
  @AdminAccess('delivery')
  @Get('delivery/settings')
  getDeliverySettings() {
    return this.adminDeliveryService.getSettings();
  }

  @AdminAccess('delivery')
  @Patch('delivery/settings')
  updateDeliverySettings(@Body() body: Record<string, unknown>) {
    return this.adminDeliveryService.updateSettings(body);
  }

  @AdminAccess('delivery')
  @Get('delivery/slots')
  listSlots() {
    return this.adminDeliveryService.listAllSlots();
  }

  @AdminAccess('delivery')
  @Post('delivery/slots')
  createSlot(@Body() body: Record<string, unknown>) {
    return this.adminDeliveryService.createSlot(body as Parameters<AdminDeliveryService['createSlot']>[0]);
  }

  @AdminAccess('delivery')
  @Patch('delivery/slots/:id')
  updateSlot(@Param('id') id: string, @Body() body: Record<string, unknown>) {
    return this.adminDeliveryService.updateSlot(id, body);
  }

  @AdminAccess('delivery')
  @Delete('delivery/slots/:id')
  deleteSlot(@Param('id') id: string) {
    return this.adminDeliveryService.deleteSlot(id);
  }

  @AdminAccess('delivery')
  @Get('delivery/pincodes')
  listPincodes() {
    return this.adminDeliveryService.listPincodes();
  }

  @AdminAccess('delivery')
  @Post('delivery/pincodes')
  addPincode(@Body() body: { pincode: string; city?: string }) {
    return this.adminDeliveryService.addPincode(body.pincode, body.city);
  }

  @AdminAccess('delivery')
  @Delete('delivery/pincodes/:id')
  removePincode(@Param('id') id: string) {
    return this.adminDeliveryService.removePincode(id);
  }

  @AdminAccess('delivery')
  @Get('delivery/analytics')
  deliveryAnalytics() {
    return this.adminDeliveryService.slotAnalytics();
  }

  @AdminAccess('delivery')
  @Get('delivery/operations-analytics')
  deliveryOperationsAnalytics() {
    return this.deliveryAssignmentsService.getDeliveryAnalytics();
  }

  @AdminAccess('delivery')
  @Get('delivery/partners')
  listDeliveryPartners() {
    return this.deliveryAssignmentsService.listPartnersForAdmin();
  }

  @AdminAccess('delivery')
  @Post('delivery/assign')
  assignDelivery(@Body() body: AssignDeliveryDto) {
    return this.deliveryAssignmentsService.assignOrder(
      body.orderId,
      body.deliveryPartnerId,
      body.notes,
    );
  }

  @AdminAccess('delivery')
  @Patch('delivery/reassign')
  reassignDelivery(@Body() body: ReassignDeliveryDto) {
    return this.deliveryAssignmentsService.reassignOrder(
      body.orderId,
      body.deliveryPartnerId,
      body.notes,
    );
  }

  // --- Reports ---
  @AdminAccess('reports')
  @Get('reports/orders')
  ordersReport(@Query() query: AdminReportsQueryDto) {
    return this.adminReportsService.ordersReport(query);
  }

  @AdminAccess('reports')
  @Get('reports/revenue')
  revenueReport(@Query() query: AdminReportsQueryDto) {
    return this.adminReportsService.revenueReport(query);
  }

  @AdminAccess('reports')
  @Get('reports/top-products')
  topProductsReport(@Query() query: AdminReportsQueryDto) {
    return this.adminReportsService.topProductsReport(query);
  }

  @AdminAccess('reports')
  @Get('reports/export/:type')
  @Header('Content-Type', 'text/csv')
  async exportReport(
    @Param('type') type: string,
    @Query() query: AdminReportsQueryDto,
    @Res() res: Response,
  ) {
    const csv = await this.adminReportsService.exportReport(type, query);
    res.setHeader(
      'Content-Disposition',
      `attachment; filename=${type}-report-${Date.now()}.csv`,
    );
    res.send(csv);
  }
}
