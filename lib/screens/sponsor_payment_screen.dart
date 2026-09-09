import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/providers/app_providers.dart';
import '../app/router/route_names.dart';
import '../core/constants/payment_constants.dart';
import '../core/auth/email_verification_guard.dart';
import '../data/models/sponsor_model.dart';
import '../features/payment/widgets/sponsor_payment_option_selector.dart';
import 'payment_webview_screen.dart';

class SponsorPaymentArgs {
  const SponsorPaymentArgs({
    required this.tournamentId,
    required this.tournamentTitle,
  });

  final String tournamentId;
  final String tournamentTitle;
}

class SponsorPaymentScreen extends ConsumerStatefulWidget {
  const SponsorPaymentScreen({
    required this.args,
    super.key,
  });

  final SponsorPaymentArgs args;

  @override
  ConsumerState<SponsorPaymentScreen> createState() => _SponsorPaymentScreenState();
}

class _SponsorPaymentScreenState extends ConsumerState<SponsorPaymentScreen> {
  SponsorPaymentOption option = SponsorPaymentOption.directPrizeSupport;
  int amountShare = PaymentConstants.sponsorAmountOptionsShare.first;
  bool creating = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sponsor Payment')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            widget.args.tournamentTitle,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 18),
          SponsorPaymentOptionSelector(
            value: option,
            onChanged: (value) => setState(() => option = value),
          ),
          const SizedBox(height: 18),
          DropdownButtonFormField<int>(
            value: amountShare,
            decoration: const InputDecoration(
              labelText: 'Sponsor amount',
              border: OutlineInputBorder(),
            ),
            items: PaymentConstants.sponsorAmountOptionsShare
                .map(
                  (amount) => DropdownMenuItem(
                    value: amount,
                    child: Text('$amount Share'),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => amountShare = value);
              }
            },
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: creating ? null : _createSponsorPayment,
            icon: creating
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.campaign_rounded),
            label: Text(creating ? 'Creating payment...' : 'Proceed to PG Payment'),
          ),
        ],
      ),
    );
  }

  Future<void> _createSponsorPayment() async {
    final authUser = ref.read(firebaseAuthProvider).currentUser;
    if (authUser == null) {
      return;
    }
    final verified = await ensureEmailVerified(
      context: context,
      user: authUser,
    );
    if (!verified) {
      return;
    }

    setState(() => creating = true);
    try {
      final user = ref.read(firebaseAuthProvider).currentUser;
      if (user == null) {
        throw StateError('Signed-in user is required for sponsor payment.');
      }

      final intent = await ref.read(paymentRepositoryProvider).createSponsorPaymentIntent(
            sponsorIntent: SponsorPaymentIntent(
              uid: user.uid,
              sponsorId: user.uid,
              tournamentId: widget.args.tournamentId,
              amountShare: amountShare,
              option: option,
            ),
          );

      if (!mounted) {
        return;
      }
      final credited = await context.push<bool>(
        RouteNames.paymentWebView,
        extra: PaymentWebViewArgs(
          title: 'Sponsor PG Payment',
          paymentUrl: intent.pgUrl,
          paymentIntentId: intent.id,
        ),
      );
      if (credited == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('스폰서 결제가 대회에 반영되었습니다.')),
        );
        context.pop();
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sponsor payment failed: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => creating = false);
      }
    }
  }
}
