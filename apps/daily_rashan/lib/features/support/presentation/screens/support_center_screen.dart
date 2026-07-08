import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';

class SupportCenterScreen extends StatelessWidget {
  const SupportCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const Text(
            'How can we help?',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: AppSpacing.lg),
          _Section(
            title: 'FAQs',
            items: const [
              _SupportItem('How do I track my order?', Icons.help_outline),
              _SupportItem('What are delivery timings?', Icons.schedule),
              _SupportItem('How do refunds work?', Icons.payments),
            ],
          ),
          _Section(
            title: 'Order issues',
            items: const [
              _SupportItem('Missing items', Icons.inventory_2_outlined),
              _SupportItem('Wrong items delivered', Icons.swap_horiz),
              _SupportItem('Cancel my order', Icons.cancel_outlined),
            ],
          ),
          _Section(
            title: 'Delivery issues',
            items: const [
              _SupportItem('Late delivery', Icons.delivery_dining),
              _SupportItem('Partner did not call', Icons.phone_missed),
            ],
          ),
          _Section(
            title: 'Payment issues',
            items: const [
              _SupportItem('Payment failed', Icons.error_outline),
              _SupportItem('Refund not received', Icons.account_balance_wallet),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: () => _showTicketSheet(context),
            icon: const Icon(Icons.confirmation_number_outlined),
            label: const Text('Raise a support ticket'),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.chat),
            label: const Text('Chat with support — coming soon'),
          ),
        ],
      ),
    );
  }

  void _showTicketSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Create support ticket',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: AppSpacing.md),
            const TextField(
              decoration: InputDecoration(labelText: 'Describe your issue'),
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ticket submitted — we\'ll respond soon')),
                );
              },
              child: const Text('Submit ticket'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.items});

  final String title;
  final List<_SupportItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.sm),
          child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        ...items.map((item) => Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: ListTile(
                leading: Icon(item.icon, color: AppColors.primaryGreen),
                title: Text(item.label),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () {},
              ),
            )),
      ],
    );
  }
}

class _SupportItem {
  const _SupportItem(this.label, this.icon);
  final String label;
  final IconData icon;
}
