import 'package:flutter/material.dart';

/// 앱이 시작되지 못했을 때 보여 주는 최소 화면. 테마나 서비스에 기대지 않는다.
class BootErrorApp extends StatefulWidget {
  const BootErrorApp({super.key, required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  State<BootErrorApp> createState() => _BootErrorAppState();
}

class _BootErrorAppState extends State<BootErrorApp> {
  var _busy = false;

  Future<void> _retry() async {
    setState(() => _busy = true);
    try {
      await widget.onRetry();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '앱을 시작하지 못했어요',
                    key: Key('boot-error-title'),
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '인터넷 연결을 확인한 뒤 다시 시도해 주세요. '
                    '계속 안 되면 앱을 완전히 종료했다가 다시 열어 주세요.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    key: const Key('boot-error-retry'),
                    onPressed: _busy ? null : _retry,
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
