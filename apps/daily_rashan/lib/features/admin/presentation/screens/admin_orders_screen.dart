import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/admin/admin_api_utils.dart';
import '../../../../core/admin/admin_theme.dart';
import '../../../../core/utils/csv_download.dart';
import '../../../../shared/widgets/admin/admin_bulk_toolbar.dart';
import '../../../../shared/widgets/admin/admin_data_table.dart';
import '../../../../shared/widgets/admin/admin_ops_widgets.dart';
import '../../../../shared/widgets/admin/admin_page_layout.dart';
import '../../../../shared/widgets/admin/admin_search_bar.dart';
import '../../../../shared/widgets/admin/admin_state_widgets.dart';
import '../../../../shared/widgets/admin/admin_toast.dart';
import '../../../../shared/widgets/admin/order_status_chip.dart';
import '../../data/admin_repository.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_order_detail_sheet.dart';
import '../utils/order_invoice_printer.dart';

const _orderStatuses = [
  'PENDING',
  'CONFIRMED',
  'PACKED',
  'OUT_FOR_DELIVERY',
  'DELIVERED',
  'CANCELLED',
];

class AdminOrdersScreen extends ConsumerStatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  ConsumerState<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends ConsumerState<AdminOrdersScreen> {
  late final DebouncedSearch _debouncedSearch;
  final _searchFocus = FocusNode();
  int _focusedRow = 0;

  @override
  void initState() {
    super.initState();
    _debouncedSearch = DebouncedSearch((q) {
      ref.read(adminOrdersQueryProvider.notifier).update(
            (s) => s.copyWith(search: q, page: 1),
          );
    });
  }

  @override
  void dispose() {
    _debouncedSearch.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _toggleSelect(String id) {
    final set = {...ref.read(adminOrderSelectionProvider)};
    if (set.contains(id)) {
      set.remove(id);
    } else {
      set.add(id);
    }
    ref.read(adminOrderSelectionProvider.notifier).state = set;
  }

  Future<void> _bulkStatus(String status) async {
    final ids = ref.read(adminOrderSelectionProvider);
    if (ids.isEmpty) return;
    try {
      for (final id in ids) {
        await ref.read(adminRepositoryProvider).updateOrderStatus(id, status: status);
      }
      ref.read(adminOrderSelectionProvider.notifier).state = {};
      ref.invalidate(adminOrdersListProvider);
      if (mounted) AdminToast.success(context, 'Updated ${ids.length} orders');
    } catch (e) {
      if (mounted) AdminToast.errorFrom(context, e);
    }
  }

  Future<void> _bulkExport() async {
    await _exportCsv();
  }

  Future<void> _bulkAssign() async {
    final ids = ref.read(adminOrderSelectionProvider);
    if (ids.isEmpty) return;
    if (ids.length == 1) {
      showAdminOrderDetailSheet(
        context,
        orderId: ids.first,
        onUpdated: () {
          ref.invalidate(adminOrdersListProvider);
          ref.read(adminOrderSelectionProvider.notifier).state = {};
        },
      );
      return;
    }
    AdminToast.info(context, 'Open each order to assign partner (${ids.length} selected)');
  }

  Future<void> _printInvoice(String orderId) async {
    try {
      final order = await ref.read(adminRepositoryProvider).getOrder(orderId);
      await OrderInvoicePrinter.printOrders([order]);
      if (mounted) AdminToast.success(context, 'Invoice ready to print');
    } catch (e) {
      if (mounted) AdminToast.errorFrom(context, e);
    }
  }

  Future<void> _bulkPrint() async {
    final ids = ref.read(adminOrderSelectionProvider).toList();
    if (ids.isEmpty) return;
    try {
      final repo = ref.read(adminRepositoryProvider);
      final orders = await Future.wait(ids.map(repo.getOrder));
      await OrderInvoicePrinter.printOrders(orders);
      if (mounted) {
        AdminToast.success(
          context,
          ids.length == 1 ? 'Invoice ready to print' : '${ids.length} invoices ready to print',
        );
      }
    } catch (e) {
      if (mounted) AdminToast.errorFrom(context, e);
    }
  }

  Widget _presetChip(String label, OrderOpsFilter filter, OrderOpsFilter current) {
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: current == filter,
      onSelected: (_) {
        ref.read(adminOrdersQueryProvider.notifier).state =
            AdminOrdersQuery.preset(filter);
      },
    );
  }

  void _resetFilters() {
    ref.read(adminOrdersQueryProvider.notifier).state = const AdminOrdersQuery();
  }

  Future<void> _exportCsv() async {
    final query = ref.read(adminOrdersQueryProvider);
    try {
      final csv = await ref.read(adminRepositoryProvider).exportOrdersCsv(
            search: query.search,
            status: query.status,
            fromDate: query.fromDate,
            toDate: query.toDate,
          );
      await downloadCsv('orders.csv', csv);
      if (mounted) AdminToast.success(context, 'Orders CSV downloaded');
    } catch (e) {
      if (mounted) AdminToast.errorFrom(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(adminOrdersListProvider);
    final query = ref.watch(adminOrdersQueryProvider);
    final selection = ref.watch(adminOrderSelectionProvider);
    final isMobile = MediaQuery.sizeOf(context).width < 768;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.slash): () => _searchFocus.requestFocus(),
      },
      child: Focus(
        autofocus: true,
        onKeyEvent: (_, event) {
          if (event is! KeyDownEvent) return KeyEventResult.ignored;
          final rows = ref.read(adminOrdersListProvider).valueOrNull?['data'] as List? ?? [];
          if (rows.isEmpty) return KeyEventResult.ignored;
          if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
              event.logicalKey == LogicalKeyboardKey.keyJ) {
            setState(() => _focusedRow = (_focusedRow + 1).clamp(0, rows.length - 1));
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
              event.logicalKey == LogicalKeyboardKey.keyK) {
            setState(() => _focusedRow = (_focusedRow - 1).clamp(0, rows.length - 1));
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.enter) {
            final o = rows[_focusedRow] as Map<String, dynamic>;
            showAdminOrderDetailSheet(
              context,
              orderId: o['id'] as String,
              onUpdated: () => ref.invalidate(adminOrdersListProvider),
            );
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: AdminPageLayout(
      title: 'Orders',
      subtitle: 'Fulfill and track customer orders',
      actions: [
        OutlinedButton.icon(
          onPressed: _exportCsv,
          icon: const Icon(Icons.download_outlined, size: 18),
          label: Text(isMobile ? 'Export' : 'Export CSV'),
        ),
      ],
      filters: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminFiltersToolbar(
            children: [
              SizedBox(
                width: isMobile ? double.infinity : 280,
                child: AdminSearchBar(
                  hint: 'Search order #, name, phone (/)',
                  focusNode: _searchFocus,
                  onChanged: _debouncedSearch,
                ),
              ),
              SizedBox(
                width: isMobile ? double.infinity : 140,
                child: DropdownButtonFormField<String?>(
                  value: query.status,
                  decoration: const InputDecoration(labelText: 'Status', isDense: true),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All statuses')),
                    ..._orderStatuses.map((s) => DropdownMenuItem(value: s, child: Text(s))),
                  ],
                  onChanged: (v) {
                    ref.read(adminOrdersQueryProvider.notifier).update(
                          (s) => s.copyWith(status: v, page: 1),
                        );
                  },
                ),
              ),
              SizedBox(
                width: isMobile ? double.infinity : 130,
                child: DropdownButtonFormField<String?>(
                  value: query.paymentMethod,
                  decoration: const InputDecoration(labelText: 'Payment', isDense: true),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All')),
                    DropdownMenuItem(value: 'COD', child: Text('COD')),
                    DropdownMenuItem(value: 'RAZORPAY', child: Text('Razorpay')),
                  ],
                  onChanged: (v) {
                    ref.read(adminOrdersQueryProvider.notifier).update(
                          (s) => s.copyWith(paymentMethod: v, page: 1, clearPayment: v == null),
                        );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AdminSpacing.sm),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _presetChip('Delayed', OrderOpsFilter.delayed, query.opsFilter),
              _presetChip('Unassigned', OrderOpsFilter.unassigned, query.opsFilter),
              _presetChip('COD today', OrderOpsFilter.codToday, query.opsFilter),
              _presetChip('Failed pay', OrderOpsFilter.failedPayments, query.opsFilter),
              _presetChip('High value', OrderOpsFilter.highValue, query.opsFilter),
              if (query.opsFilter != OrderOpsFilter.none)
                ActionChip(
                  label: const Text('Clear preset'),
                  onPressed: _resetFilters,
                ),
            ],
          ),
        ],
      ),
      child: ordersAsync.when(
        loading: () => const AdminLoadingState(message: 'Loading orders…'),
        error: (e, _) => AdminErrorState(
          error: e,
          title: 'Could not load orders',
          onRetry: () => ref.invalidate(adminOrdersListProvider),
        ),
        data: (res) {
          final rows = AdminApiUtils.asMapList(res['data']);
          final meta = AdminApiUtils.asMapOrNull(res['meta']) ?? <String, dynamic>{};

          if (rows.isEmpty) {
            return AdminEmptyState(
              title: 'No orders found',
              message: 'Try adjusting filters or search terms.',
              icon: Icons.inventory_2_outlined,
              actionLabel: 'Reset filters',
              onAction: _resetFilters,
            );
          }

          return Stack(
            children: [
              Column(
                children: [
                  if (rows.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(AdminSpacing.lg, AdminSpacing.sm, AdminSpacing.lg, 0),
                      child: Row(
                        children: [
                          Checkbox(
                            value: selection.length == rows.length && rows.isNotEmpty,
                            tristate: true,
                            onChanged: (_) {
                              if (selection.length == rows.length) {
                                ref.read(adminOrderSelectionProvider.notifier).state = {};
                              } else {
                                ref.read(adminOrderSelectionProvider.notifier).state =
                                    rows.map((o) => o['id'] as String).toSet();
                              }
                            },
                          ),
                          Text(
                            'Select all on page',
                            style: TextStyle(fontSize: 11, color: AdminSemanticColors.textMuted),
                          ),
                          const Spacer(),
                          Text(
                            'J/K navigate · Enter open · / search',
                            style: TextStyle(fontSize: 10, color: AdminSemanticColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: AdminDataTable<Map<String, dynamic>>(
                      virtualized: !isMobile,
                      zebraStripes: true,
                      horizontalScroll: isMobile,
                      trailingWidth: 132,
                      leadingBuilder: (o) => SizedBox(
                        width: 48,
                        child: Checkbox(
                          value: selection.contains(o['id']),
                          onChanged: (_) => _toggleSelect(o['id'] as String),
                        ),
                      ),
                      trailingBuilder: (o) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AdminIconActionBtn(
                          icon: Icons.visibility_outlined,
                          tooltip: 'View',
                          onPressed: () => showAdminOrderDetailSheet(
                            context,
                            orderId: o['id'] as String,
                            onUpdated: () => ref.invalidate(adminOrdersListProvider),
                          ),
                        ),
                        AdminIconActionBtn(
                          icon: Icons.local_shipping_outlined,
                          tooltip: 'Assign',
                          onPressed: () => showAdminOrderDetailSheet(
                            context,
                            orderId: o['id'] as String,
                            onUpdated: () => ref.invalidate(adminOrdersListProvider),
                          ),
                        ),
                        AdminIconActionBtn(
                          icon: Icons.print_outlined,
                          tooltip: 'Print invoice',
                          onPressed: () => _printInvoice(o['id'] as String),
                        ),
                      ],
                    ),
                    columns: [
                      AdminColumn(
                        label: 'Order / Customer',
                        flex: 3,
                        cellBuilder: (o) {
                          final u = AdminApiUtils.asMapOrNull(o['user']);
                          return Row(
                            children: [
                              AdminAvatar(name: u?['name'] as String?, size: 34),
                              const SizedBox(width: AdminSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      u?['name'] as String? ?? 'Guest',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      u?['phone'] as String? ?? '',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AdminSemanticColors.textMuted,
                                      ),
                                    ),
                                    Text(
                                      '#${o['orderNumber']}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: AdminSemanticColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      AdminColumn(
                        label: 'Status',
                        cellBuilder: (o) => OrderStatusChip(status: o['status'] as String? ?? ''),
                      ),
                      AdminColumn(
                        label: 'Tags',
                        flex: 2,
                        cellBuilder: (o) => Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: buildOrderMetaChips(o),
                        ),
                      ),
                      AdminColumn(
                        label: 'Total',
                        align: TextAlign.end,
                        cellBuilder: (o) => Text(
                          '₹${o['totalAmount']}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      AdminColumn(
                        label: 'Placed',
                        flex: 2,
                        cellBuilder: (o) => Text(
                          formatOrderPlaced(o['placedAt'] as String?),
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                    rows: rows,
                    onRowTap: (o) => showAdminOrderDetailSheet(
                      context,
                      orderId: o['id'] as String,
                      onUpdated: () => ref.invalidate(adminOrdersListProvider),
                    ),
                    emptyMessage: 'No orders found',
                    emptyIcon: Icons.shopping_bag_outlined,
                  ),
                ),
                  AdminPaginationBar(
                    page: meta['page'] as int? ?? 1,
                    totalPages: meta['totalPages'] as int? ?? 1,
                    totalItems: meta['total'] as int?,
                    onPageChanged: (p) {
                      ref.read(adminOrdersQueryProvider.notifier).update(
                            (s) => s.copyWith(page: p),
                          );
                    },
                  ),
                ],
              ),
              if (selection.isNotEmpty)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: AdminBulkToolbar(
                    count: selection.length,
                    onClear: () => ref.read(adminOrderSelectionProvider.notifier).state = {},
                    actions: [
                      TextButton.icon(
                        onPressed: () => _bulkStatus('CONFIRMED'),
                        icon: const Icon(Icons.check, color: Colors.white, size: 16),
                        label: const Text('Confirm', style: TextStyle(color: Colors.white)),
                      ),
                      TextButton.icon(
                        onPressed: () => _bulkStatus('PACKED'),
                        icon: const Icon(Icons.inventory_2_outlined, color: Colors.white, size: 16),
                        label: const Text('Packed', style: TextStyle(color: Colors.white)),
                      ),
                      TextButton.icon(
                        onPressed: _bulkAssign,
                        icon: const Icon(Icons.local_shipping_outlined, color: Colors.white, size: 16),
                        label: const Text('Assign', style: TextStyle(color: Colors.white)),
                      ),
                      TextButton.icon(
                        onPressed: _bulkExport,
                        icon: const Icon(Icons.download_outlined, color: Colors.white, size: 16),
                        label: const Text('Export', style: TextStyle(color: Colors.white)),
                      ),
                      TextButton.icon(
                        onPressed: _bulkPrint,
                        icon: const Icon(Icons.print_outlined, color: Colors.white, size: 16),
                        label: const Text('Print', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
        ),
      ),
    );
  }
}
