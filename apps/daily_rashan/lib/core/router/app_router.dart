import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/screens/otp_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/home/presentation/screens/main_shell_screen.dart';
import '../../features/products/presentation/screens/product_detail_screen.dart';
import '../../features/products/presentation/screens/products_list_screen.dart';
import '../../features/products/presentation/screens/category_browse_screen.dart';
import '../../features/cart/presentation/screens/cart_screen.dart';
import '../../features/checkout/presentation/screens/checkout_screen.dart';
import '../../features/orders/presentation/screens/orders_screen.dart';
import '../../features/orders/presentation/screens/order_detail_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/admin/presentation/screens/admin_auth_gate.dart';
import '../../features/delivery/presentation/screens/delivery_auth_gate.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/onboarding/presentation/screens/location_onboarding_screen.dart';
import '../../features/orders/presentation/screens/order_success_screen.dart';
import '../../features/offers/presentation/screens/offers_center_screen.dart';
import '../../features/support/presentation/screens/support_center_screen.dart';
import '../../features/search/presentation/screens/search_screen.dart';
import '../firebase/push_notification_service.dart';
import '../constants/app_strings.dart';
import '../constants/app_colors.dart';
import '../customer/customer_prefs_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Re-run redirects when auth/prefs change via a refreshListenable instead of
  // recreating the GoRouter. Recreating it (by ref.watch-ing the providers)
  // resets navigation to initialLocation ('/splash'), which is why performing a
  // search — which mutates customerPrefs to store the term — bounced the user
  // back to the home screen.
  final refresh = ValueNotifier<int>(0);
  ref.listen(authStateProvider, (_, __) => refresh.value++);
  ref.listen(customerPrefsProvider, (_, __) => refresh.value++);
  ref.onDispose(refresh.dispose);

  final router = GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: kDebugMode,
    refreshListenable: refresh,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final prefsState = ref.read(customerPrefsProvider);
      final isAuthLoading = authState.isLoading;
      final user = authState.valueOrNull;
      final isAuth = user != null;
      final path = state.matchedLocation;

      if (isAuthLoading) return null;

      final publicRoutes = [
        '/splash',
        '/onboarding',
        '/login',
        '/signup',
        '/otp',
        '/forgot-password',
      ];

      final prefs = prefsState.valueOrNull;
      final onboardingDone = prefs?.onboardingDone ?? false;

      if (path == '/splash') return null;

      if (kIsWeb && path == '/admin') return '/login';

      if (!onboardingDone &&
          path != '/onboarding' &&
          !isAuth &&
          publicRoutes.contains(path) == false) {
        // Allow splash to decide; block deep links before onboarding
      }

      if (!isAuth && !publicRoutes.contains(path)) {
        return '/login';
      }

      if (!isAuth && path == '/splash') return null;

      if (isAuth && publicRoutes.contains(path) && path != '/splash') {
        if (user.isDeliveryPartner) return '/delivery';
        if (user.isStaff) {
          if (kIsWeb) return '/login';
          return '/admin';
        }
        if (!(prefs?.hasLocation ?? false)) return '/location-setup';
        return '/home';
      }

      if (isAuth &&
          !user.isStaff &&
          !user.isDeliveryPartner &&
          !(prefs?.hasLocation ?? false) &&
          path != '/location-setup' &&
          path != '/profile') {
        return '/location-setup';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, __) => const _SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/location-setup',
        builder: (_, __) => const LocationOnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (_, __) => const SignupScreen(),
      ),
      GoRoute(
        path: '/otp',
        builder: (_, state) => OtpScreen(
          phone: state.uri.queryParameters['phone'] ?? '',
        ),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/orders/success',
        builder: (_, state) => OrderSuccessScreen(
          orderId: state.uri.queryParameters['orderId'] ?? '',
          orderNumber: state.uri.queryParameters['orderNumber'],
          totalAmount: state.uri.queryParameters['total'],
        ),
      ),
      GoRoute(
        path: '/offers',
        builder: (_, __) => const OffersCenterScreen(),
      ),
      GoRoute(
        path: '/support',
        builder: (_, __) => const SupportCenterScreen(),
      ),
      GoRoute(
        path: '/search',
        builder: (_, state) => SearchScreen(
          initialQuery: state.uri.queryParameters['query'],
        ),
      ),
      ShellRoute(
        builder: (_, __, child) => MainShellScreen(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (_, __) => const HomeScreen(),
          ),
          GoRoute(
            path: '/categories',
            builder: (_, __) => const CategoryBrowseScreen(),
          ),
          GoRoute(
            path: '/cart',
            builder: (_, __) => const CartScreen(),
          ),
          GoRoute(
            path: '/orders',
            builder: (_, __) => const OrdersScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (_, __) => const ProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/products',
        builder: (_, state) => ProductsListScreen(
          categoryId: state.uri.queryParameters['categoryId'],
          initialSearch: state.uri.queryParameters['search'],
        ),
      ),
      GoRoute(
        path: '/products/:id',
        builder: (_, state) => ProductDetailScreen(
          productId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/checkout',
        builder: (_, __) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/orders/:id',
        builder: (_, state) => OrderDetailScreen(
          orderId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/admin',
        builder: (_, __) => const AdminAuthGate(),
      ),
      GoRoute(
        path: '/delivery',
        builder: (_, __) => const DeliveryAuthGate(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (_, __) => const NotificationsScreen(),
      ),
    ],
  );

  ref.listen(notificationTapProvider, (_, orderId) {
    if (orderId != null) {
      router.go('/orders/$orderId');
      ref.read(notificationTapProvider.notifier).state = null;
    }
  });

  ref.onDispose(router.dispose);

  return router;
});

class _SplashScreen extends ConsumerStatefulWidget {
  const _SplashScreen();

  @override
  ConsumerState<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<_SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1800), _navigate);
  }

  Future<void> _navigate() async {
    if (!mounted) return;
    final prefs = await ref.read(customerPrefsProvider.future);
    final user = ref.read(authStateProvider).valueOrNull;

    if (!prefs.onboardingDone) {
      if (mounted) context.go('/onboarding');
      return;
    }

    if (user != null) {
      if (user.isDeliveryPartner) {
        if (mounted) context.go('/delivery');
      } else if (user.isStaff) {
        if (kIsWeb) {
          await ref.read(authStateProvider.notifier).logout();
          if (mounted) context.go('/login');
        } else if (mounted) {
          context.go('/admin');
        }
      } else if (!prefs.hasLocation) {
        if (mounted) context.go('/location-setup');
      } else {
        if (mounted) context.go('/home');
      }
    } else {
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryGreen, Color(0xFF2ECC71)],
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGreen.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.shopping_basket, color: Colors.white, size: 44),
            ),
            const SizedBox(height: 24),
            Text(
              AppStrings.appName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.navyBlue,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.tagline,
              style: const TextStyle(color: AppColors.textGrey),
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ],
        ),
      ),
    );
  }
}
