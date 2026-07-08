import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/presentation/providers/auth_provider.dart';

/// Idle session warning + auto-logout for admin security.
class AdminSessionGuard extends ConsumerStatefulWidget {
  const AdminSessionGuard({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AdminSessionGuard> createState() => _AdminSessionGuardState();
}

class _AdminSessionGuardState extends ConsumerState<AdminSessionGuard> {
  static const _idleTimeout = Duration(minutes: 30);
  static const _warnBefore = Duration(minutes: 2);

  DateTime _lastActivity = DateTime.now();
  bool _warnShown = false;

  @override
  void initState() {
    super.initState();
    _startIdleCheck();
  }

  void _startIdleCheck() {
    Future.doWhile(() async {
      await Future<void>.delayed(const Duration(seconds: 30));
      if (!mounted) return false;

      final idle = DateTime.now().difference(_lastActivity);
      if (idle >= _idleTimeout) {
        await ref.read(authStateProvider.notifier).logout();
        return false;
      }
      if (idle >= _idleTimeout - _warnBefore && !_warnShown && mounted) {
        _warnShown = true;
        _showIdleWarning();
      }
      return mounted;
    });
  }

  void _showIdleWarning() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Session expiring'),
        content: const Text('You will be signed out due to inactivity.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authStateProvider.notifier).logout();
            },
            child: const Text('Sign out now'),
          ),
          FilledButton(
            onPressed: () {
              _lastActivity = DateTime.now();
              _warnShown = false;
              Navigator.pop(ctx);
            },
            child: const Text('Stay signed in'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) {
        _lastActivity = DateTime.now();
        _warnShown = false;
      },
      child: widget.child,
    );
  }
}
