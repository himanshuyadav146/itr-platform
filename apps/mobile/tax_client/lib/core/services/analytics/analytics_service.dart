import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';

/// Central Firebase Analytics helpers.
///
/// All logging is fire-and-forget: failures are swallowed, calls never throw to
/// callers, and UX must not await these methods (they return [void]).
class AnalyticsService {
  AnalyticsService._();

  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Safe navigator observer — never lets Analytics exceptions crash navigation.
  static final NavigatorObserver observer = _SafeAnalyticsObserver();

  /// Route path or GoRoute name → human-readable screen name (Screen Name → View).
  static const Map<String, String> screenNames = {
    '/': 'home',
    'home': 'home',
    '/splash': 'splash',
    'splash': 'splash',
    '/login': 'login',
    'login': 'login',
    '/register': 'signup',
    'signup': 'signup',
    'register': 'signup',
    '/forgot-password': 'forgot_password',
    'forgot_password': 'forgot_password',
    '/profile': 'profile',
    'profile': 'profile',
    '/settings': 'settings',
    'settings': 'settings',
    '/orders': 'orders',
    'orders': 'orders',
    '/refer_earn': 'refer_earn',
    'refer_earn': 'refer_earn',
    '/more': 'more',
    'more': 'more',
    '/personal_info': 'personal_info',
    'personal_info': 'personal_info',
    '/itr_list': 'itr_list',
    'itr_list': 'itr_list',
    '/document_upload': 'document_upload',
    'document_upload': 'document_upload',
    '/payment': 'payment',
    'payment': 'payment',
    '/status': 'status',
    'status': 'status',
    '/tax_calculator': 'tax_calculator',
    'tax_calculator': 'tax_calculator',
    '/web': 'web_content',
    'web_content': 'web_content',
  };

  /// CTA name constants (CTA Name → Click).
  static const String ctaLoginAuthenticate = 'login_authenticate';
  static const String ctaLoginForgotPassword = 'login_forgot_password';
  static const String ctaLoginGoToSignup = 'login_go_to_signup';
  static const String ctaSignupCreateAccount = 'signup_create_account';
  static const String ctaSignupGoToLogin = 'signup_go_to_login';
  static const String ctaForgotPasswordSubmit = 'forgot_password_submit';
  static const String ctaHomeFileItr = 'home_file_itr';
  static const String ctaHomeEVerify = 'home_e_verify';
  static const String ctaHomePackages = 'home_view_packages';
  static const String ctaHomeTaxCalculator = 'home_tax_calculator';
  static const String ctaHomeOrders = 'home_orders';
  static const String ctaHomeDocuments = 'home_documents';
  static const String ctaHomePayment = 'home_payment';
  static const String ctaHomeContactSupport = 'home_contact_support';
  static const String ctaHomeStatus = 'home_status';

  static String screenNameForRoute(String route) {
    final path = route.split('?').first;
    return screenNames[path] ??
        screenNames[path.replaceFirst(RegExp(r'^/'), '')] ??
        path.replaceAll('/', '_').replaceFirst(RegExp(r'^_'), '');
  }

  static String? screenNameFromRouteSettings(RouteSettings settings) {
    final raw = settings.name;
    if (raw == null || raw.isEmpty) return null;
    final name = screenNameForRoute(raw);
    return name.isEmpty ? null : name;
  }

  /// Screen Name → View. Never throws; never blocks the caller.
  static void logScreenView(String screenName) {
    _runSafely(() => _analytics.logScreenView(screenName: screenName));
  }

  /// CTA Name → Click. Never throws; never blocks the caller.
  static void logCtaClick({
    required String ctaName,
    String? screenName,
  }) {
    _runSafely(
      () => _analytics.logEvent(
        name: 'cta_click',
        parameters: <String, Object>{
          'cta_name': _sanitize(ctaName),
          if (screenName != null) 'screen_name': _sanitize(screenName),
        },
      ),
    );
  }

  /// Login success/failure. Never throws; never blocks the caller.
  static void logLogin({required bool success}) {
    _runSafely(() async {
      if (success) {
        await _analytics.logLogin(loginMethod: 'email');
      } else {
        await _analytics.logEvent(
          name: 'login_failed',
          parameters: const <String, Object>{'method': 'email'},
        );
      }
    });
  }

  /// Sign-up success/failure. Never throws; never blocks the caller.
  static void logSignUp({required bool success}) {
    _runSafely(() async {
      if (success) {
        await _analytics.logSignUp(signUpMethod: 'email');
      } else {
        await _analytics.logEvent(
          name: 'sign_up_failed',
          parameters: const <String, Object>{'method': 'email'},
        );
      }
    });
  }

  /// Runs analytics off the critical path with a short timeout.
  static void _runSafely(Future<void> Function() action) {
    Future<void>(() async {
      try {
        await action().timeout(const Duration(seconds: 3));
      } catch (e) {
        debugPrint('Analytics ignored: $e');
      }
    });
  }

  static String _sanitize(String value) {
    if (value.length <= 100) return value;
    return value.substring(0, 100);
  }
}

/// Mirrors [FirebaseAnalyticsObserver] but swallows all errors.
class _SafeAnalyticsObserver extends NavigatorObserver {
  void _send(Route<dynamic>? route) {
    if (route == null) return;
    try {
      final screenName =
          AnalyticsService.screenNameFromRouteSettings(route.settings);
      if (screenName != null) {
        AnalyticsService.logScreenView(screenName);
      }
    } catch (e) {
      debugPrint('Analytics screen observer ignored: $e');
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _send(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _send(newRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _send(previousRoute);
  }
}
