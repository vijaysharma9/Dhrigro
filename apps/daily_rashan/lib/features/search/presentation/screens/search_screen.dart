import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/customer/customer_prefs_provider.dart';
import '../../../../core/analytics/analytics_service.dart';
import '../../../../shared/widgets/app_success_snackbar.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/premium_product_card.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../providers/search_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, this.initialQuery});

  final String? initialQuery;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _controller;
  Timer? _debounce;
  String _query = '';
  String? _sortBy;

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery ?? '';
    _controller = TextEditingController(text: _query);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _query = value.trim());
    });
  }

  void _search(String term) {
    _controller.text = term;
    setState(() => _query = term);
    ref.trackEvent(AnalyticsEvents.searchPerformed, {'query': term});
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(customerPrefsProvider).valueOrNull;
    final history = prefs?.searchHistory ?? [];
    final quantities = ref.watch(cartQuantitiesProvider);
    final hasQuery = _query.isNotEmpty;
    final resultsAsync = hasQuery
        ? ref.watch(searchResultsProvider(SearchParams(query: _query, sortBy: _sortBy)))
        : null;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search atta, milk, vegetables...',
            border: InputBorder.none,
          ),
          onChanged: _onQueryChanged,
          onSubmitted: _search,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.mic_none),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Voice search coming soon')),
              );
            },
          ),
        ],
      ),
      body: hasQuery
          ? resultsAsync!.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => EmptyStateWidget(
                icon: Icons.search_off,
                title: 'Search failed',
                subtitle: 'Check your connection and try again',
                actionLabel: 'Retry',
                onAction: () => ref.invalidate(
                  searchResultsProvider(
                    SearchParams(query: _query, sortBy: _sortBy),
                  ),
                ),
              ),
              data: (data) {
                final products = (data['data'] as List?) ?? [];
                if (products.isEmpty) {
                  return const EmptyStateWidget(
                    icon: Icons.search_off,
                    title: 'No results found',
                    subtitle: 'Try a different search or browse categories below',
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.54,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: products.length,
                  itemBuilder: (_, i) {
                    final product = products[i] as Map<String, dynamic>;
                    final id = product['id'] as String;
                    final qty = quantities[id] ?? 0;
                    return PremiumProductCard(
                      product: product,
                      layout: PremiumProductLayout.grid,
                      quantity: qty,
                      onAddToCart: () => _add(product, id),
                      onIncrement: () => ref.read(cartProvider.notifier).addOrIncrement(id),
                      onDecrement: () => ref.read(cartProvider.notifier).decrementProduct(id),
                    );
                  },
                );
              },
            )
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                if (history.isNotEmpty) ...[
                  Row(
                    children: [
                      const Text('Recent searches',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      TextButton(
                        onPressed: () =>
                            ref.read(customerPrefsProvider.notifier).clearSearchHistory(),
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: history
                        .map((t) => ActionChip(
                              label: Text(t),
                              onPressed: () => _search(t),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
                const Text('Trending searches',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: trendingSearches
                      .map((t) => ActionChip(
                            avatar: const Icon(Icons.trending_up, size: 16),
                            label: Text(t),
                            onPressed: () => _search(t),
                          ))
                      .toList(),
                ),
                const SizedBox(height: AppSpacing.xxl),
                const Text('Browse categories',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.md),
                ...['Fruits', 'Vegetables', 'Dairy', 'Snacks', 'Staples']
                    .map((c) => ListTile(
                          leading: const Icon(Icons.category_outlined,
                              color: AppColors.primaryGreen),
                          title: Text(c),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _search(c),
                        )),
              ],
            ),
    );
  }

  void _add(Map<String, dynamic> product, String id) {
    ref.read(cartProvider.notifier).addItem(id);
    showSuccessSnackBar(context, '${product['name']} added to cart');
  }
}
