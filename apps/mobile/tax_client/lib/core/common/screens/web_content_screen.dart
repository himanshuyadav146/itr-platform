import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tax_client/core/common/widgets/core_scaffold.dart';
import 'package:tax_client/core/config/theme/app_colors.dart';
import 'package:tax_client/core/config/theme/app_spacing.dart';
import 'package:tax_client/core/constant/api_constants.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// In-app browser for marketing and policy pages on [ApiConstants.baseUrl].
class WebContentScreen extends StatefulWidget {
  final String path;
  final String title;

  const WebContentScreen({
    super.key,
    required this.path,
    required this.title,
  });

  @override
  State<WebContentScreen> createState() => _WebContentScreenState();
}

class _WebContentScreenState extends State<WebContentScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;

  Uri get _pageUri => Uri.parse(ApiConstants.publicPageUrl(widget.path));

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.authBackground)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() {
              _isLoading = true;
              _hasError = false;
            });
          },
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() => _isLoading = false);
          },
          onWebResourceError: (_) {
            if (!mounted) return;
            setState(() {
              _isLoading = false;
              _hasError = true;
            });
          },
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri == null) {
              return NavigationDecision.prevent;
            }
            if (_isAllowedHost(uri)) {
              return NavigationDecision.navigate;
            }
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(_pageUri);
  }

  bool _isAllowedHost(Uri uri) {
    final host = uri.host.toLowerCase();
    return host == 'allindiaitr.in' || host == 'www.allindiaitr.in';
  }

  Future<void> _reload() => _controller.loadRequest(_pageUri);

  Future<bool> _handleBack() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      return false;
    }
    if (mounted) {
      context.pop();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleBack();
      },
      child: CoreScaffold(
        title: widget.title,
        showBackButton: true,
        onBack: () => _handleBack(),
        backgroundColor: AppColors.authBackground,
        useScrollView: false,
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (_hasError)
              _WebContentErrorState(onRetry: _reload)
            else
              WebViewWidget(controller: _controller),
            if (_isLoading && !_hasError)
              const Center(
                child: CircularProgressIndicator(color: AppColors.authMint),
              ),
          ],
        ),
      ),
    );
  }
}

class _WebContentErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _WebContentErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 48,
              color: AppColors.authMuted,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Unable to load this page',
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.authHeading,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Check your connection and try again.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.authMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
