import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class AdminColumn<T> {
  const AdminColumn({
    required this.label,
    required this.cellBuilder,
    this.flex = 1,
  });

  final String label;
  final Widget Function(T row) cellBuilder;
  final int flex;
}

class AdminDataTable<T> extends StatelessWidget {
  const AdminDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.onRowTap,
    this.isLoading = false,
    this.emptyMessage = 'No data found',
  });

  final List<AdminColumn<T>> columns;
  final List<T> rows;
  final void Function(T row)? onRowTap;
  final bool isLoading;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (rows.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            children: [
              Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text(emptyMessage, style: const TextStyle(color: AppColors.textGrey)),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.borderLight),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            color: const Color(0xFFF9FAFB),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: columns
                  .map(
                    (c) => Expanded(
                      flex: c.flex,
                      child: Text(
                        c.label,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: rows.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: AppColors.borderLight),
            itemBuilder: (_, i) {
              final row = rows[i];
              return InkWell(
                onTap: onRowTap != null ? () => onRowTap!(row) : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: columns
                        .map(
                          (c) => Expanded(
                            flex: c.flex,
                            child: c.cellBuilder(row),
                          ),
                        )
                        .toList(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class AdminPaginationBar extends StatelessWidget {
  const AdminPaginationBar({
    super.key,
    required this.page,
    required this.totalPages,
    required this.onPageChanged,
  });

  final int page;
  final int totalPages;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: page > 1 ? () => onPageChanged(page - 1) : null,
          icon: const Icon(Icons.chevron_left),
        ),
        Text('Page $page of ${totalPages > 0 ? totalPages : 1}'),
        IconButton(
          onPressed: page < totalPages ? () => onPageChanged(page + 1) : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}
