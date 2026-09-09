import 'package:flutter/material.dart';

import '../features/reward/view/winner_honor_popup.dart';

class WinnerDemoScreen extends StatefulWidget {
  const WinnerDemoScreen({super.key});

  @override
  State<WinnerDemoScreen> createState() => _WinnerDemoScreenState();
}

class _WinnerDemoScreenState extends State<WinnerDemoScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showPopup());
  }

  Future<void> _showPopup() async {
    if (!mounted) {
      return;
    }
    await WinnerHonorPopup.show(
      context: context,
      rewardValueToken: 800,
      onDonateHalf: () {},
      onDonateAll: () {},
      onClaimAll: () {},
    );
    if (mounted) {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
