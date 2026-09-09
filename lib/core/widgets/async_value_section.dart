import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';

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
      loading: () => loadingBuilder?.call(context) ??
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
              '데이터를 불러오지 못했습니다: $error',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
    );
  }
}
