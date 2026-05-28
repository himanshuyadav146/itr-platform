import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tax_client/features/auth/presentation/screens/login_screen.dart';
import 'package:tax_client/features/home/presentation/screens/home_screen.dart';
import 'package:tax_client/features/orders/presentation/screens/orders_screen.dart';
import 'package:tax_client/features/profile/presentation/screens/profile_screen.dart';
import 'package:tax_client/features/refer_earn/presentation/screens/refer_earn_screen.dart';
import 'package:tax_client/features/settings/presentation/screens/settings_screen.dart';
import 'package:tax_client/features/more/presentation/screens/more_screen.dart';

import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/screens/forget_password_screen.dart';
import 'package:tax_client/features/personal_info/presentation/screens/personal_information_screen.dart';
import 'package:tax_client/features/personal_info/presentation/screens/itr_list_screen.dart';
import 'package:tax_client/features/personal_info/data/models/itr_personal_detail_model.dart';
import 'package:tax_client/features/payment/presentation/screens/payment_screen.dart';
import 'package:tax_client/features/tax_calculator/presentation/screens/tax_calculator_screen.dart';

import '../../features/document_upload/presentation/screens/upload_documents_screen.dart';
import 'package:tax_client/features/status/presentation/screens/status_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';

class AppRouter {
  static GoRouter? _router;

  static GoRouter? get router => _router;

  static GoRouter buildRouter({required String initialLocation}) {
    _router = GoRouter(
      initialLocation: initialLocation,
      // initialLocation: '/document_upload',
      errorBuilder: (context, state) {
        // If route not found, redirect to home or login
        return initialLocation == '/login' ? LoginScreen() : const HomeScreen();
      },
      routes: <GoRoute>[
        GoRoute(
          path: '/',
          builder: (BuildContext context, GoRouterState state) {
            return const HomeScreen();
          },
        ),
        GoRoute(
          path: '/login',
          builder: (BuildContext context, GoRouterState state) {
            return LoginScreen();
          },
        ),
        GoRoute(
          path: '/profile',
          builder: (BuildContext context, GoRouterState state) {
            return const ProfileScreen();
          },
        ),
        GoRoute(
          path: '/settings',
          builder: (BuildContext context, GoRouterState state) {
            return const SettingsScreen();
          },
        ),
        GoRoute(
          path: '/orders',
          builder: (BuildContext context, GoRouterState state) {
            return const OrdersScreen();
          },
        ),
        GoRoute(
          path: '/refer_earn',
          builder: (BuildContext context, GoRouterState state) {
            return const ReferAndEarnScreen();
          },
        ),
        GoRoute(
          path: '/more',
          builder: (BuildContext context, GoRouterState state) {
            return const MoreScreen();
          },
        ),
        GoRoute(
          path: '/personal_info',
          builder: (BuildContext context, GoRouterState state) {
            final itrData = state.extra as ItrPersonalDetailModel?;
            return PersonalInformationScreen(itrData: itrData);
          },
        ),
        GoRoute(
          path: '/itr_list',
          builder: (BuildContext context, GoRouterState state) {
            return const ItrListScreen();
          },
        ),
        GoRoute(
          path: '/register',
          builder: (BuildContext context, GoRouterState state) {
            return SignUpScreen();
          },
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (BuildContext context, GoRouterState state) {
            return const ForgetPasswordScreen();
          },
        ),
        GoRoute(
          path: '/document_upload',
          builder: (BuildContext context, GoRouterState state) {
            final fromStatus =
                state.uri.queryParameters['from']?.toLowerCase() == 'status';
            return UploadDocumentsScreen(fromStatus: fromStatus);
          },
        ),
        GoRoute(
          path: '/payment',
          builder: (BuildContext context, GoRouterState state) {
            final packageIdStr = state.uri.queryParameters['packageId'];
            final packageId = packageIdStr != null
                ? int.tryParse(packageIdStr) ?? 1
                : 1;
            return PaymentScreen(packageId: packageId);
          },
        ),
        GoRoute(
          path: '/status',
          builder: (BuildContext context, GoRouterState state) {
            ItrPersonalDetailModel? itrData;
            String? orderId;

            if (state.extra is ItrPersonalDetailModel) {
              itrData = state.extra as ItrPersonalDetailModel;
            } else if (state.extra is Map<String, dynamic>) {
              final map = state.extra as Map<String, dynamic>;
              if (map.containsKey('orderId')) {
                orderId = map['orderId'] as String?;
              }
            }

            return StatusScreen(itrData: itrData, orderId: orderId);
          },
        ),
        GoRoute(
          path: '/tax_calculator',
          builder: (BuildContext context, GoRouterState state) {
            return const TaxCalculatorScreen();
          },
        ),
        GoRoute(
          path: '/splash',
          builder: (BuildContext context, GoRouterState state) {
            return const SplashScreen();
          },
        ),
      ],
    );
    return _router!;
  }
}
