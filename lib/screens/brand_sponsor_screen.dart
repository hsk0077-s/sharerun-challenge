import 'package:flutter/material.dart';

import '../core/strings/app_strings.dart';
import '../core/theme/theme.dart';
import '../features/shop/widgets/store_look.dart';

/// 브랜드 스폰서 챌린지. 지금은 진행 중인 스폰서가 없어서 "준비 중" 안내만 보여 준다.
/// 실제 스폰서가 생기면 서버 데이터로 채운다.
class BrandSponsorScreen extends StatelessWidget {
  const BrandSponsorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.srcTokens.colors;
    return Scaffold(
      backgroundColor: c.canvas,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                color: c.ink,
                iconSize: 20,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const StoreTag('SPONSOR'),
                    const SizedBox(height: 8),
                    Text(
                      AppStrings.lobbySponsorRoomTitle,
                      style: storeText(28, c.ink, w: FontWeight.w900),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${AppStrings.lobbySponsorPreparing}이에요',
                      style: storeText(18, c.primary, w: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AppStrings.lobbySponsorRoomSub,
                      style: storeText(14, c.muted, h: 1.5),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
