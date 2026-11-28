import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../ui/user_visible_failure.dart';

class AsyncValueSection<T> extends StatelessWidget {
  const AsyncValueSection({
    required this.asyncValue,
    required this.dataBuilder,
    this.loadingBuilder,
    this.errorBuilder,
    super.key,
  });

  final AsyncValue<T> asyncValue;
  final Widget Function(BuildContext context, T data) dataBuilder;
  final WidgetBuilder? loadingBuilder;
  final Widget Function(BuildContext context, Object error)? errorBuilder;

  @override
  Widget build(BuildContext context) {
    return asyncValue.when(
      data: (data) => dataBuilder(context, data),
      loading: () =>
          loadingBuilder?.call(context) ??
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
      error: (error, _) =>
          errorBuilder?.call(context, error) ??
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBlack,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              userVisibleFailure(
                context,
                error,
                key: 'widget.async_value_section.body',
                ko: '데이터를 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.',
              ),
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
    );
  }
}
