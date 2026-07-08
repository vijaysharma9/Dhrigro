import 'package:flutter/material.dart';
import '../../../core/admin/admin_theme.dart';
import '../../../core/constants/app_colors.dart';
import 'admin_skeleton.dart';

class AdminColumn<T> {
  const AdminColumn({
    required this.label,
    required this.cellBuilder,
    this.flex = 1,
    this.align = TextAlign.start,
  });

  final String label;
  final Widget Function(T row) cellBuilder;
  final int flex;
  final TextAlign align;
}

class AdminDataTable<T> extends StatelessWidget {
  const AdminDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.onRowTap,
    this.isLoading = false,
    this.emptyMessage = 'No data found',
    this.emptyIcon = Icons.inbox_outlined,
    this.emptyAction,
    this.emptyActionLabel,
    this.compact = true,
    this.stickyHeader = true,
    this.bare = false,
    this.zebraStripes = false,
    this.trailingBuilder,
    this.leadingBuilder,
    this.trailingWidth = 120,
    this.horizontalScroll = false,
    this.virtualized = false,
  });

  final List<AdminColumn<T>> columns;
  final List<T> rows;
  final void Function(T row)? onRowTap;
  final bool isLoading;
  final String emptyMessage;
  final IconData emptyIcon;
  final bool compact;
  final bool stickyHeader;
  final bool bare;
  final bool zebraStripes;
  final Widget Function(T row)? trailingBuilder;
  final Widget Function(T row)? leadingBuilder;
  final double trailingWidth;
  final bool horizontalScroll;
  final bool virtualized;
  final VoidCallback? emptyAction;
  final String? emptyActionLabel;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      final loader = const Padding(
        padding: EdgeInsets.all(AdminSpacing.lg),
        child: AdminTableSkeleton(),
      );
      return bare ? loader : AdminPanelTableShell(child: loader);
    }

    if (rows.isEmpty) {
      final empty = Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AdminSpacing.lg),
              decoration: BoxDecoration(
                border: Border.all(color: AdminSemanticColors.border),
                borderRadius: BorderRadius.circular(AdminRadius.lg),
              ),
              child: Icon(emptyIcon, size: 36, color: AdminSemanticColors.textMuted),
            ),
            const SizedBox(height: AdminSpacing.md),
            Text(
              emptyMessage,
              style: const TextStyle(
                color: AdminSemanticColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (emptyAction != null && emptyActionLabel != null) ...[
              const SizedBox(height: AdminSpacing.md),
              OutlinedButton(onPressed: emptyAction, child: Text(emptyActionLabel!)),
            ],
          ],
        ),
      );
      return bare ? empty : AdminPanelTableShell(child: empty);
    }

    final rowPadding = compact
        ? const EdgeInsets.symmetric(horizontal: AdminSpacing.lg, vertical: 10)
        : const EdgeInsets.symmetric(horizontal: AdminSpacing.lg, vertical: 14);

    Widget buildHeaderRow() {
      return Row(
        children: [
          if (leadingBuilder != null) const SizedBox(width: 48),
          ...columns.map(
            (c) => Expanded(
              flex: c.flex,
              child: Text(
                c.label.toUpperCase(),
                style: AdminTypography.tableHeader,
                textAlign: c.align,
              ),
            ),
          ),
          if (trailingBuilder != null)
            SizedBox(
              width: trailingWidth,
              child: Text(
                'ACTIONS',
                style: AdminTypography.tableHeader,
                textAlign: TextAlign.end,
              ),
            ),
        ],
      );
    }

    Widget buildDataRow(int index, T row) {
      final zebraColor = zebraStripes && index.isOdd
          ? AdminSemanticColors.borderSubtle.withValues(alpha: 0.5)
          : Colors.transparent;

      return _TableRowHover(
        zebraColor: zebraColor,
        onTap: onRowTap != null ? () => onRowTap!(row) : null,
        child: Padding(
          padding: rowPadding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (leadingBuilder != null) leadingBuilder!(row),
              ...columns.map(
                (c) => Expanded(
                  flex: c.flex,
                  child: Align(
                    alignment: c.align == TextAlign.end
                        ? Alignment.centerRight
                        : c.align == TextAlign.center
                            ? Alignment.center
                            : Alignment.centerLeft,
                    child: c.cellBuilder(row),
                  ),
                ),
              ),
              if (trailingBuilder != null)
                SizedBox(
                  width: trailingWidth,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: trailingBuilder!(row),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    final body = virtualized
        ? ListView.separated(
            itemCount: rows.length,
            separatorBuilder: (_, __) => const Divider(
              height: 1,
              thickness: 1,
              color: AdminSemanticColors.borderSubtle,
            ),
            itemBuilder: (_, i) => buildDataRow(i, rows[i]),
          )
        : ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: rows.length,
            separatorBuilder: (_, __) => const Divider(
              height: 1,
              thickness: 1,
              color: AdminSemanticColors.borderSubtle,
            ),
            itemBuilder: (_, i) => buildDataRow(i, rows[i]),
          );

    final table = Column(
      children: [
        if (stickyHeader)
          Container(
            color: AdminSemanticColors.borderSubtle,
            padding: rowPadding,
            child: buildHeaderRow(),
          ),
        if (virtualized) Expanded(child: body) else body,
      ],
    );

    final wrapped = horizontalScroll && !virtualized
        ? SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 720),
              child: table,
            ),
          )
        : table;

    return bare ? wrapped : AdminPanelTableShell(child: wrapped);
  }
}

class AdminPanelTableShell extends StatelessWidget {
  const AdminPanelTableShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AdminSemanticColors.surfaceCard,
        borderRadius: BorderRadius.circular(AdminRadius.md),
        border: Border.all(color: AdminSemanticColors.border),
        boxShadow: AdminShadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _TableRowHover extends StatefulWidget {
  const _TableRowHover({
    required this.child,
    this.onTap,
    this.zebraColor,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color? zebraColor;

  @override
  State<_TableRowHover> createState() => _TableRowHoverState();
}

class _TableRowHoverState extends State<_TableRowHover> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: _hover
              ? AppColors.primaryGreen.withValues(alpha: 0.06)
              : widget.zebraColor ?? Colors.transparent,
          boxShadow: _hover
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: InkWell(
          onTap: widget.onTap,
          hoverColor: Colors.transparent,
          child: widget.child,
        ),
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
    this.totalItems,
  });

  final int page;
  final int totalPages;
  final ValueChanged<int> onPageChanged;
  final int? totalItems;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AdminSpacing.lg,
        vertical: AdminSpacing.sm,
      ),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AdminSemanticColors.borderSubtle)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            totalItems != null
                ? '$totalItems items · Page $page of ${totalPages > 0 ? totalPages : 1}'
                : 'Page $page of ${totalPages > 0 ? totalPages : 1}',
            style: const TextStyle(
              fontSize: 12,
              color: AdminSemanticColors.textSecondary,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PageBtn(
                icon: Icons.chevron_left,
                enabled: page > 1,
                onTap: () => onPageChanged(page - 1),
              ),
              const SizedBox(width: AdminSpacing.xs),
              _PageBtn(
                icon: Icons.chevron_right,
                enabled: page < totalPages,
                onTap: () => onPageChanged(page + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PageBtn extends StatelessWidget {
  const _PageBtn({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? AdminSemanticColors.borderSubtle : Colors.transparent,
      borderRadius: BorderRadius.circular(AdminRadius.sm),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(AdminRadius.sm),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            size: 18,
            color: enabled
                ? AdminSemanticColors.textPrimary
                : AdminSemanticColors.textMuted,
          ),
        ),
      ),
    );
  }
}

class AdminFiltersToolbar extends StatelessWidget {
  const AdminFiltersToolbar({
    super.key,
    required this.children,
    this.actions,
  });

  final List<Widget> children;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AdminSpacing.md),
      decoration: BoxDecoration(
        color: AdminSemanticColors.surfaceCard,
        borderRadius: BorderRadius.circular(AdminRadius.md),
        border: Border.all(color: AdminSemanticColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: AdminSpacing.md,
              runSpacing: AdminSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: children,
            ),
          ),
          if (actions != null) ...[
            const SizedBox(width: AdminSpacing.md),
            ...actions!,
          ],
        ],
      ),
    );
  }
}
