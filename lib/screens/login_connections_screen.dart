import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/api_exception.dart';
import '../core/strings/app_strings.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../data/api/identity_api_client.dart';
import '../features/auth/existing_account_question.dart';
import '../features/auth/login_connection_providers.dart';

/// 설정 > 로그인 연결. 이 계정으로 들어올 수 있는 방법을 보고, 카카오를 붙이고 뗀다.
/// 구글은 보여 주기만 하고, 카카오와 네이버는 붙이고 뗀다(구글로 로그인한 계정이면 연결됨으로 나온다).
class LoginConnectionsScreen extends ConsumerStatefulWidget {
  const LoginConnectionsScreen({super.key});

  static const googleRowKey = Key('login-connection-google');
  static const googleActionKey = Key('login-connection-google-action');
  static const kakaoRowKey = Key('login-connection-kakao');
  static const kakaoActionKey = Key('login-connection-kakao-action');
  static const naverRowKey = Key('login-connection-naver');
  static const naverActionKey = Key('login-connection-naver-action');
  static const unlinkConfirmKey = Key('login-connection-unlink-confirm');

  @override
  ConsumerState<LoginConnectionsScreen> createState() =>
      _LoginConnectionsScreenState();
}

class _LoginConnectionsScreenState
    extends ConsumerState<LoginConnectionsScreen> {
  List<String>? _providers;
  String? _loadError;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loadError = null);
    try {
      final providers =
          await ref.read(identityApiClientProvider).fetchProviders();
      if (!mounted) return;
      setState(() => _providers = providers);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadError = ApiErrorMessage.from(e));
    }
  }

  void _say(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  bool get _canUnlink => (_providers?.length ?? 0) > 1;

  Future<void> _link({
    required String methodName,
    required Future<String?> Function() askToken,
    required Future<void> Function(String token) send,
  }) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final api = ref.read(identityApiClientProvider);
      final AccountLinkPreview preview = await api.fetchLinkPreview();
      if (!mounted) return;
      if (!preview.canLink || preview.nickname.trim().isEmpty) {
        _say(AppStrings.existingAccountEmpty);
        return;
      }
      final ok = await showAccountLinkConfirm(
        context,
        methodName: methodName,
        nickname: preview.nickname,
        shareBalance: preview.shareBalance,
        declineLabel: '취소',
      );
      if (ok != true || !mounted) return;
      final token = await askToken();
      if (token == null || !mounted) return;
      await send(token);
      if (!mounted) return;
      _say(AppStrings.linkAttached(methodName));
      await _load();
    } catch (e) {
      if (mounted) _say(ApiErrorMessage.from(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _unlink({
    required String name,
    required Future<void> Function() send,
  }) async {
    if (_busy) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$name 연결 해제'),
        content: Text(
          '해제하면 이 $name 계정으로는 이 쉐어런 계정에 들어올 수 없어요. 다른 로그인 방법으로는 계속 쓸 수 있어요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            key: LoginConnectionsScreen.unlinkConfirmKey,
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('해제'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await send();
      if (!mounted) return;
      _say('$name 연결을 해제했어요.');
      await _load();
    } catch (e) {
      if (mounted) _say(ApiErrorMessage.from(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _linkKakao() => _link(
        methodName: '카카오',
        askToken: ref.read(kakaoAccessTokenProvider),
        send: ref.read(identityApiClientProvider).linkKakao,
      );

  Future<void> _linkNaver() => _link(
        methodName: '네이버',
        askToken: ref.read(naverAccessTokenProvider),
        send: ref.read(identityApiClientProvider).linkNaver,
      );

  Future<void> _unlinkKakao() => _unlink(
        name: '카카오',
        send: ref.read(identityApiClientProvider).unlinkKakao,
      );

  Future<void> _unlinkNaver() => _unlink(
        name: '네이버',
        send: ref.read(identityApiClientProvider).unlinkNaver,
      );

  Future<void> _unlinkGoogle() => _unlink(
        name: '구글',
        send: ref.read(identityApiClientProvider).unlinkGoogle,
      );

  @override
  Widget build(BuildContext context) {
    final providers = _providers;
    final googleLinked = providers?.contains('google') ?? false;
    final kakaoLinked = providers?.contains('kakao') ?? false;
    final naverLinked = providers?.contains('naver') ?? false;
    return Scaffold(
      backgroundColor: AppColors.settingsBackground,
      appBar: AppBar(
        backgroundColor: AppColors.settingsBackground,
        elevation: 0,
        foregroundColor: AppColors.textBlack,
        title: Text(
          '로그인 연결',
          style: AppTextStyles.header1.copyWith(fontSize: 20),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            '같은 계정으로 여러 방법으로 로그인할 수 있어요. 연결해 두면 어떤 방법으로 들어와도 같은 SHARE와 기록이 보여요. 마지막 로그인 방법은 해제할 수 없어요.',
            style: AppTextStyles.caption.copyWith(color: AppColors.textGrey),
          ),
          const SizedBox(height: 14),
          if (providers == null && _loadError == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_loadError != null)
            Column(
              children: [
                Text(_loadError!, style: AppTextStyles.caption),
                TextButton(onPressed: _load, child: const Text('다시 불러오기')),
              ],
            )
          else
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                children: [
                  ListTile(
                    key: LoginConnectionsScreen.googleRowKey,
                    leading: const Icon(Icons.g_mobiledata_rounded, size: 32),
                    title: const Text('구글'),
                    subtitle: Text(
                      googleLinked ? '연결됨' : '연결 안 됨',
                      style: AppTextStyles.caption,
                    ),
                    trailing: googleLinked
                        ? TextButton(
                            key: LoginConnectionsScreen.googleActionKey,
                            onPressed: _busy || !_canUnlink ? null : _unlinkGoogle,
                            child: const Text('해제'),
                          )
                        : null,
                  ),
                  const Divider(height: 1, color: AppColors.borderLight),
                  ListTile(
                    key: LoginConnectionsScreen.kakaoRowKey,
                    leading: const Icon(Icons.chat_bubble_rounded),
                    title: const Text('카카오'),
                    subtitle: Text(
                      kakaoLinked ? '연결됨' : '연결 안 됨',
                      style: AppTextStyles.caption,
                    ),
                    trailing: TextButton(
                      key: LoginConnectionsScreen.kakaoActionKey,
                      onPressed: _busy || (kakaoLinked && !_canUnlink)
                          ? null
                          : (kakaoLinked ? _unlinkKakao : _linkKakao),
                      child: Text(kakaoLinked ? '해제' : '연결하기'),
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.borderLight),
                  ListTile(
                    key: LoginConnectionsScreen.naverRowKey,
                    leading: const Icon(Icons.north_east_rounded),
                    title: const Text('네이버'),
                    subtitle: Text(
                      naverLinked ? '연결됨' : '연결 안 됨',
                      style: AppTextStyles.caption,
                    ),
                    trailing: TextButton(
                      key: LoginConnectionsScreen.naverActionKey,
                      onPressed: _busy || (naverLinked && !_canUnlink)
                          ? null
                          : (naverLinked ? _unlinkNaver : _linkNaver),
                      child: Text(naverLinked ? '해제' : '연결하기'),
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.borderLight),
                  const ListTile(
                    leading: Icon(Icons.apple),
                    title: Text('애플'),
                    trailing: Text('준비 중', style: AppTextStyles.caption),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
