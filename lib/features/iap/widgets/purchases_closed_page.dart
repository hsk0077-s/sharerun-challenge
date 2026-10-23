import 'package:flutter/material.dart';

/// 1.0은 앱 안 결제를 받지 않는다. 구매 화면으로 들어오면 이 안내만 보여 준다.
class PurchasesClosedPage extends StatelessWidget {
  const PurchasesClosedPage({this.title = '안내', super.key});

  final String title;

  static const message = '이 버전에서는 앱 안 결제를 받지 않아요.';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            message,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
