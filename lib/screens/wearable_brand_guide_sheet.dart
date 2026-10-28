import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../l10n/guide_chrome.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

/// 브랜드별 워치·스마트밴드 → Health Connect 연결 안내 한 건.
@immutable
class WearableBrand {
  const WearableBrand({
    required this.id,
    required this.name,
    required this.app,
    required this.keywords,
    required this.steps,
    this.note,
  });

  final String id;
  final String name;

  /// 기기 데이터를 모아 주는 공식(또는 연동) 앱 이름.
  final String app;

  /// 검색용 별칭 (소문자 비교).
  final List<String> keywords;
  final List<String> steps;
  final String? note;

  bool matches(String query, {String? localizedName}) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    final localized = localizedName?.toLowerCase() ?? '';
    return name.toLowerCase().contains(q) ||
        app.toLowerCase().contains(q) ||
        localized.contains(q) ||
        keywords.any((k) => k.toLowerCase().contains(q));
  }
}

const wearableBrands = <WearableBrand>[
  WearableBrand(
    id: 'xiaomi',
    name: '샤오미 미밴드 / 레드미 워치',
    app: 'Mi Fitness (구형은 Zepp Life)',
    keywords: [
      '샤오미',
      'xiaomi',
      'mi band',
      '미밴드',
      '레드미',
      'redmi',
      'mi fitness',
      'zepp life',
    ],
    steps: [
      'Mi Fitness 앱에서 밴드/워치를 페어링하고 한 번 동기화해 주세요. (구형 Zepp Life는 [프로필 → 타사 데이터 → Zepp Life]로 이전 가능)',
      'Mi Fitness 하단 [프로필(Profile)] → [타사 데이터(Third-party data)] (또는 [설정 → 타사 데이터 / 연결된 앱]) → [Health Connect(헬스 커넥트)]에서 걸음 수·심박수 쓰기를 허용해 주세요.',
      '아래 버튼으로 쉐어런의 Health Connect 읽기 권한을 허용하거나, 기기 [심박수 공유(Share HR)]를 켜고 실시간 BLE 심박 센서로 직접 연결해 주세요.',
    ],
    note: 'iOS는 Mi Fitness [프로필 → 타사 데이터 → 건강(Apple Health)]을 켜 주세요.',
  ),
  WearableBrand(
    id: 'amazfit',
    name: '어메이즈핏 (Amazfit)',
    app: 'Zepp',
    keywords: ['어메이즈핏', 'amazfit', 'zepp', '제프', '지프', 't-rex', 'balance', 'bip'],
    steps: [
      'Zepp 앱에서 어메이즈핏 워치/밴드를 페어링하고 동기화해 주세요.',
      'Zepp 하단 [프로필(Profile)] → [타사 계정 연결(Third-party account linking / Add accounts)] → [Health Connect(헬스 커넥트)]를 켜고 걸음 수·심박수 쓰기를 허용해 주세요.',
      '아래 버튼으로 쉐어런의 Health Connect 읽기 권한을 허용하거나, 워치 [심박수 공유(Heart Rate Push)]를 켜고 BLE 심박 센서로 직접 연결해 주세요.',
    ],
    note: 'iOS는 Zepp [프로필 → 타사 계정 연결 → Apple 건강(Health)]을 켜 주세요.',
  ),
  WearableBrand(
    id: 'garmin',
    name: '가민 (Garmin)',
    app: 'Garmin Connect',
    keywords: ['가민', 'garmin', 'garmin connect', '포러너', 'forerunner', 'fenix', 'epix', 'venu'],
    steps: [
      'Garmin Connect 앱에서 가민 워치를 동기화해 주세요.',
      'Garmin Connect 하단 [더보기(More ···)] → [설정(Settings)] → [연결된 앱(Connected Apps)] → [헬스 커넥트(Health Connect)]에서 심박수·걸음 수 쓰기 권한을 허용해 주세요.',
      '아래 버튼으로 쉐어런의 Health Connect 읽기 권한을 허용하거나, 워치 [UP 길게 → 건강 및 웰니스/센서 → 손목 심박수 → 심박수 전송(Broadcast HR)]을 켜고 BLE로 직접 연결해 주세요.',
    ],
    note: 'Garmin → Health Connect는 단방향(가민에서 내보내기) 공식 지원입니다.',
  ),
  WearableBrand(
    id: 'fitbit',
    name: '핏빗 / 픽셀 워치',
    app: 'Fitbit',
    keywords: ['핏빗', 'fitbit', '픽셀', 'pixel', 'pixel watch', '구글'],
    steps: [
      'Fitbit 앱에서 핏빗 또는 픽셀 워치를 동기화해 주세요.',
      'Fitbit [오늘(Today)] 탭 좌측 상단 [기기 아이콘(Device)] → [연결 추가(Add connections)] → [Health Connect 설정(Set up Health Connect)] (또는 [설정(⚙) → Health Connect → Health Connect와 동기화])을 켜 주세요.',
      '아래 버튼으로 쉐어런의 Health Connect 읽기 권한을 허용해 주세요.',
    ],
  ),
  WearableBrand(
    id: 'samsung',
    name: '삼성 갤럭시 워치',
    app: 'Samsung Health',
    keywords: ['삼성', '갤럭시', 'galaxy', 'samsung', 'samsung health', '갤워치', '워치'],
    steps: [
      'Samsung Health 앱에서 갤럭시 워치를 연결하고 한 번 동기화해 주세요.',
      'Samsung Health 우측 상단 [더보기(⋮)] → [설정(Settings)] → [헬스 커넥트(Health Connect)] → [앱 권한(App permissions)]에서 걸음 수·심박수 공유를 켜 주세요.',
      '아래 버튼으로 쉐어런의 Health Connect 읽기 권한을 허용해 주세요. (갤럭시 워치 단독 앱은 6자리 연결 코드로도 바로 연동됩니다.)',
    ],
  ),
  WearableBrand(
    id: 'coros_suunto',
    name: '코로스 / 순토 (COROS · Suunto)',
    app: 'COROS · Suunto · Health Sync',
    keywords: ['코로스', 'coros', '순토', 'suunto', 'health sync', '헬스싱크', 'pace', 'race'],
    steps: [
      'COROS 또는 Suunto 앱에서 워치를 동기화해 주세요.',
      'Android에서는 [Health Sync] 브리지 앱으로 COROS/Suunto 기록을 [Health Connect]로 내보내거나, 워치에서 [심박수 브로드캐스트(Broadcast HR)]를 켜 주세요.',
      '아래 버튼으로 Health Connect 권한을 허용하거나, 기기 연동 화면의 [실시간 블루투스 심박 센서(BLE)]에서 워치를 직접 연결해 주세요.',
    ],
    note: 'iOS는 COROS/Suunto 앱 [프로필 → 설정 → 타사 앱 → Apple 건강(Health)]을 켜면 바로 연동됩니다.',
  ),
];

/// "내 워치·스마트밴드 연결 방법 찾기" 바텀시트.
///
/// [onConnect]는 시트를 닫은 뒤 호출되며 Health Connect(iOS는 Apple 건강) 연결을 시작한다.
Future<void> showWearableBrandGuide(
  BuildContext context, {
  required VoidCallback onConnect,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.surfaceWhite,
    builder: (sheetContext) => WearableBrandGuide(
      onConnect: () {
        Navigator.of(sheetContext).pop();
        onConnect();
      },
    ),
  );
}

class WearableBrandGuide extends StatefulWidget {
  const WearableBrandGuide({super.key, required this.onConnect});

  final VoidCallback onConnect;

  static const searchFieldKey = Key('wearable-guide-search');
  static const connectButtonKey = Key('wearable-guide-connect');
  static const emptyKey = Key('wearable-guide-empty');
  static Key brandKey(String id) => Key('wearable-brand-$id');
  static Key stepKey(int index) => Key('wearable-step-$index');

  @override
  State<WearableBrandGuide> createState() => _WearableBrandGuideState();
}

class _WearableBrandGuideState extends State<WearableBrandGuide> {
  var _query = '';
  WearableBrand? _selected;

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: selected == null ? _buildList() : _buildDetail(selected),
      ),
    );
  }

  Widget _buildList() {
    final chrome = GuideChrome.of(Localizations.localeOf(context));
    final results = wearableBrands
        .where((b) => b.matches(_query, localizedName: chrome.brands[b.id]?.name))
        .toList();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          ShareRunLocalizations.ofLocale(Localizations.localeOf(context))
              .wearableGuideEntry,
          style: AppTextStyles.header1.copyWith(fontSize: 18),
        ),
        const SizedBox(height: 12),
        TextField(
          key: WearableBrandGuide.searchFieldKey,
          onChanged: (v) => setState(() => _query = v),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search_rounded),
            hintText: GuideChrome.of(Localizations.localeOf(context)).searchHint,
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 8),
        Flexible(
          child: results.isEmpty
              ? Padding(
                  key: WearableBrandGuide.emptyKey,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    GuideChrome.of(Localizations.localeOf(context)).empty,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textGrey),
                  ),
                )
              : ListView(
                  shrinkWrap: true,
                  children: [
                    for (final brand in results)
                      ListTile(
                        key: WearableBrandGuide.brandKey(brand.id),
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.watch_rounded,
                            color: AppColors.primaryMint),
                        title: Text(chrome.brands[brand.id]?.name ?? brand.name),
                        subtitle: Text(brand.app),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => setState(() => _selected = brand),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildDetail(WearableBrand brand) {
    final isIos = defaultTargetPlatform == TargetPlatform.iOS;
    final chrome = GuideChrome.of(Localizations.localeOf(context));
    final text = chrome.brands[brand.id];
    final steps = text?.steps ?? brand.steps;
    final note = text?.note ?? brand.note;
    final title = text?.name ?? brand.name;
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: chrome.back,
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                onPressed: () => setState(() => _selected = null),
              ),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.header1.copyWith(fontSize: 18),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 12),
            child: Text(
              '${chrome.usingApp}: ${brand.app}',
              style: AppTextStyles.caption.copyWith(color: AppColors.textGrey),
            ),
          ),
          for (var i = 0; i < steps.length; i++)
            Padding(
              key: WearableBrandGuide.stepKey(i + 1),
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: AppColors.primaryMint,
                    foregroundColor: AppColors.nightOnLime,
                    child: Text('${i + 1}',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(steps[i],
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textBlack, height: 1.45)),
                  ),
                ],
              ),
            ),
          if (note != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                note,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textGreyLight),
              ),
            ),
          const SizedBox(height: 16),
          FilledButton(
            key: WearableBrandGuide.connectButtonKey,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryMint,
              foregroundColor: AppColors.nightOnLime,
            ),
            onPressed: widget.onConnect,
            child: Text(isIos ? chrome.ctaIos : chrome.ctaAndroid),
          ),
        ],
      ),
    );
  }
}
