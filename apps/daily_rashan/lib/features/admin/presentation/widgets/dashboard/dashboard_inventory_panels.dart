import 'package:flutter/material.dart';
import '../../../../../core/admin/admin_theme.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../shared/widgets/admin/admin_section_header.dart';

class DashboardLowStockPanel extends StatelessWidget {
  const DashboardLowStockPanel({
    super.key,
    required this.products,
    this.onViewInventory,
  });

  final List<dynamic> products;
  final VoidCallback? onViewInventory;

  static const int _criticalThreshold = 3;
  static const int _warningThreshold = 10;

  @override
  Widget build(BuildContext context) {
    return AdminPanelCard(
      padding: const EdgeInsets.all(AdminSpacing.md),
      header: AdminSectionHeader(
        title: 'Inventory alerts',
        subtitle: '${products.length} SKUs need attention',
        icon: Icons.warning_amber_rounded,
        trailing: onViewInventory != null
            ? TextButton(onPressed: onViewInventory, child: const Text('Manage'))
            : null,
      ),
      child: products.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: AdminSpacing.lg),
              child: Center(
                child: Text(
                  'All stock levels healthy',
                  style: TextStyle(color: AdminSemanticColors.textSecondary),
                ),
              ),
            )
          : Column(
              children: products.take(6).map((p) {
                final prod = p as Map<String, dynamic>;
                return _StockAlertRow(product: prod);
              }).toList(),
            ),
    );
  }
}

class _StockAlertRow extends StatelessWidget {
  const _StockAlertRow({required this.product});

  final Map<String, dynamic> product;

  Color get _severityColor {
    final stock = product['stock'] as int? ?? 0;
    if (stock == 0) return AppColors.errorRed;
    if (stock <= DashboardLowStockPanel._criticalThreshold) return AppColors.errorRed;
    if (stock <= DashboardLowStockPanel._warningThreshold) return AdminSemanticColors.warning;
    return AppColors.primaryGreen;
  }

  String get _severityLabel {
    final stock = product['stock'] as int? ?? 0;
    if (stock == 0) return 'OUT';
    if (stock <= DashboardLowStockPanel._criticalThreshold) return 'CRIT';
    return 'LOW';
  }

  @override
  Widget build(BuildContext context) {
    final stock = product['stock'] as int? ?? 0;
    final maxStock = 50;
    final progress = (stock / maxStock).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: AdminSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(AdminSpacing.md),
        decoration: BoxDecoration(
          color: _severityColor.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(AdminRadius.sm),
          border: Border.all(color: _severityColor.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    product['name'] as String? ?? 'Product',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _severityColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AdminRadius.pill),
                  ),
                  child: Text(
                    _severityLabel,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: _severityColor,
                    ),
                  ),
                ),
                const SizedBox(width: AdminSpacing.sm),
                Text(
                  '$stock left',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: _severityColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AdminSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AdminRadius.pill),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: AdminSemanticColors.borderSubtle,
                color: _severityColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardTopProductsPanel extends StatelessWidget {
  const DashboardTopProductsPanel({super.key, required this.topProducts});

  final List<dynamic> topProducts;

  @override
  Widget build(BuildContext context) {
    if (topProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxQty = topProducts.fold<int>(0, (m, p) {
      final q = (p as Map)['quantitySold'] as int? ?? 0;
      return q > m ? q : m;
    }).clamp(1, 999999);

    return AdminPanelCard(
      padding: const EdgeInsets.all(AdminSpacing.md),
      header: const AdminSectionHeader(
        title: 'Top sellers',
        subtitle: 'By units sold',
        icon: Icons.trending_up,
      ),
      child: Column(
        children: topProducts.take(5).map((p) {
          final item = p as Map<String, dynamic>;
          final qty = item['quantitySold'] as int? ?? 0;
          return Padding(
            padding: const EdgeInsets.only(bottom: AdminSpacing.sm),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item['productName'] as String? ?? '—',
                    style: const TextStyle(fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AdminRadius.pill),
                    child: LinearProgressIndicator(
                      value: qty / maxQty,
                      minHeight: 6,
                      backgroundColor: AdminSemanticColors.borderSubtle,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ),
                const SizedBox(width: AdminSpacing.sm),
                SizedBox(
                  width: 32,
                  child: Text(
                    '$qty',
                    textAlign: TextAlign.end,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
