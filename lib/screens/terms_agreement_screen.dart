import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/router/route_names.dart';
import '../core/strings/app_strings.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_shapes.dart';
import '../core/theme/app_text_styles.dart';
import '../core/widgets/src_agreement_tile.dart';
import '../core/widgets/src_button.dart';
import '../core/widgets/src_gradient_background.dart';

/// 약관 동의 화면 (Screen 2) — src-2 온보딩 약관 목업.
class TermsAgreementScreen extends StatefulWidget {
  const TermsAgreementScreen({super.key});

  @override
  State<TermsAgreementScreen> createState() => _TermsAgreementScreenState();
}

class _TermsAgreementScreenState extends State<TermsAgreementScreen> {
  var _allAgree = false;
  var _serviceTerms = false;
  var _privacyTerms = false;
  var _locationTerms = false;
  var _healthTerms = false;

  bool get _requiredAllChecked =>
      _serviceTerms && _privacyTerms && _locationTerms;

  bool get _everyItemChecked =>
      _requiredAllChecked && _healthTerms;

  void _syncAllAgreeFlag() {
    _allAgree = _everyItemChecked;
  }

  void _onAllAgreeChanged(bool value) {
    setState(() {
      _allAgree = value;
      _serviceTerms = value;
      _privacyTerms = value;
      _locationTerms = value;
      _healthTerms = value;
    });
  }

  void _onItemChanged({
    required void Function(bool) write,
    required bool value,
  }) {
    setState(() {
      write(value);
      _syncAllAgreeFlag();
    });
  }

  void _onContinue() {
    if (!_requiredAllChecked) {
      return;
    }
    Navigator.pushNamed(context, RouteNames.smartWatchSync);
  }

  /// Direct entry (e.g. pushReplacement after login) has no prior route.
  /// Popping an empty stack causes a black screen / crash — defend here.
  void _handleBack() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    // No prior route: bounce to login (avoids black screen).
    // If login route registration ever fails, background the app instead.
    try {
      navigator.pushReplacementNamed(RouteNames.login);
    } catch (_) {
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        backgroundColor: AppColors.bgGradientEnd,
        body: SRCGradientBackground(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppShapes.termsHorizontalPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      color: AppColors.textBlack,
                      onPressed: _handleBack,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    AppStrings.termsTitle,
                    style: AppTextStyles.termsTitle,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    AppStrings.termsSubtitle,
                    style: AppTextStyles.termsSubtitle,
                  ),
                  const SizedBox(height: 28),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SRCAgreementBox(
                            label: AppStrings.termsAllAgree,
                            value: _allAgree,
                            onChanged: _onAllAgreeChanged,
                            checkboxOnRight: true,
                          ),
                          const SizedBox(height: 20),
                          SRCAgreementRow(
                            label: AppStrings.termsRequiredService,
                            value: _serviceTerms,
                            onChanged: (v) => _onItemChanged(
                              write: (val) => _serviceTerms = val,
                              value: v,
                            ),
                          ),
                          SRCAgreementRow(
                            label: AppStrings.termsRequiredPrivacy,
                            value: _privacyTerms,
                            onChanged: (v) => _onItemChanged(
                              write: (val) => _privacyTerms = val,
                              value: v,
                            ),
                          ),
                          SRCAgreementRow(
                            label: AppStrings.termsRequiredLocation,
                            value: _locationTerms,
                            onChanged: (v) => _onItemChanged(
                              write: (val) => _locationTerms = val,
                              value: v,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Divider(
                              height: 1,
                              color: AppColors.borderLight,
                            ),
                          ),
                          SRCAgreementBox(
                            label: AppStrings.termsOptionalHealth,
                            value: _healthTerms,
                            onChanged: (v) => _onItemChanged(
                              write: (val) => _healthTerms = val,
                              value: v,
                            ),
                            labelStyle: AppTextStyles.agreementLabel,
                            trailing: const HealthPulseIcon(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SRCButton(
                    label: AppStrings.termsContinue,
                    variant: SRCButtonVariant.primary,
                    enabled: _requiredAllChecked,
                    onPressed: _requiredAllChecked ? _onContinue : null,
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
