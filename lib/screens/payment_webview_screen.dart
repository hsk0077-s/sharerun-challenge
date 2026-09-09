import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../app/providers/app_providers.dart';
import '../app/theme/app_colors.dart';
import '../data/models/payment_intent_status_model.dart';

class PaymentWebViewArgs {
  const PaymentWebViewArgs({
    required this.title,
    required this.paymentUrl,
    required this.paymentIntentId,
  });

  final String title;
  final Uri paymentUrl;
  final String paymentIntentId;
}

class PaymentWebViewScreen extends ConsumerStatefulWidget {
  const PaymentWebViewScreen({
    required this.args,
    super.key,
  });

  final PaymentWebViewArgs args;

  @override
  ConsumerState<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends ConsumerState<PaymentWebViewScreen> {
  late final WebViewController controller;
  var loading = true;
  var _handledCompletion = false;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) {
              setState(() => loading = false);
            }
          },
        ),
      )
      ..loadRequest(widget.args.paymentUrl);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      paymentIntentStatusProvider(widget.args.paymentIntentId),
      (previous, next) {
        final current = next.value;
        if (current == null || _handledCompletion) {
          return;
        }
        if (current.isCredited) {
          _completeWithSuccess(current);
        }
      },
    );

    final status = ref.watch(
      paymentIntentStatusProvider(widget.args.paymentIntentId),
    ).value;

    return Scaffold(
      appBar: AppBar(title: Text(widget.args.title)),
      bottomNavigationBar: _PaymentStatusBar(
        message: status?.userMessage ?? '결제 상태를 확인하는 중입니다.',
        credited: status?.isCredited ?? false,
        failed: status?.isTerminalFailure ?? false,
        onClose: () => context.pop(false),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: controller),
          if (loading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }

  void _completeWithSuccess(PaymentIntentStatusModel status) {
    if (_handledCompletion || !mounted) {
      return;
    }
    _handledCompletion = true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(status.userMessage)),
    );
    context.pop(true);
  }
}

class _PaymentStatusBar extends StatelessWidget {
  const _PaymentStatusBar({
    required this.message,
    required this.credited,
    required this.failed,
    required this.onClose,
  });

  final String message;
  final bool credited;
  final bool failed;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardBlack,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                message,
                style: TextStyle(
                  color: credited
                      ? AppColors.neonLime
                      : failed
                          ? AppColors.dangerRed
                          : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: onClose,
                child: const Text('닫기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
