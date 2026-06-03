import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

enum DeliveryTab { orders, history, earnings, profile }

class DeliveryShell extends StatelessWidget {
  const DeliveryShell({
    super.key,
    required this.tab,
    required this.onTabChanged,
    required this.child,
    this.isOnline = false,
    this.onToggleOnline,
  });

  final DeliveryTab tab;
  final ValueChanged<DeliveryTab> onTabChanged;
  final Widget child;
  final bool isOnline;
  final ValueChanged<bool>? onToggleOnline;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Daily Rashan Delivery'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          if (onToggleOnline != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Row(
                children: [
                  Text(
                    isOnline ? 'Online' : 'Offline',
                    style: const TextStyle(fontSize: 12),
                  ),
                  Switch(
                    value: isOnline,
                    onChanged: onToggleOnline,
                    activeColor: Colors.white,
                  ),
                ],
              ),
            ),
        ],
      ),
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab.index,
        onDestinationSelected: (i) => onTabChanged(DeliveryTab.values[i]),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.delivery_dining_outlined),
            label: 'Orders',
          ),
          NavigationDestination(icon: Icon(Icons.history), label: 'History'),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            label: 'Earnings',
          ),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}
