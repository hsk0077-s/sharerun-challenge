import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';

class PaceCalculatorCard extends StatefulWidget {
  const PaceCalculatorCard({super.key});

  @override
  State<PaceCalculatorCard> createState() => _PaceCalculatorCardState();
}

class _PaceCalculatorCardState extends State<PaceCalculatorCard> {
  final _distanceController = TextEditingController(text: '10');
  final _hoursController = TextEditingController(text: '0');
  final _minutesController = TextEditingController(text: '55');
  final _secondsController = TextEditingController(text: '0');

  @override
  void dispose() {
    _distanceController.dispose();
    _hoursController.dispose();
    _minutesController.dispose();
    _secondsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = _calculateGoalPace();
    final tokens = context.srcTokens;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.speed_rounded, color: tokens.colors.primary),
            SizedBox(width: tokens.spacing.xs),
            Text(
              '목표 페이스 계산기',
              style: textTheme.titleMedium?.copyWith(color: tokens.colors.ink),
            ),
          ],
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _distanceController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: '목표 거리 (km)',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),
        SizedBox(height: tokens.spacing.sm),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _hoursController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '시',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            SizedBox(width: tokens.spacing.xs),
            Expanded(
              child: TextField(
                controller: _minutesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '분',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            SizedBox(width: tokens.spacing.xs),
            Expanded(
              child: TextField(
                controller: _secondsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '초',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        SizedBox(height: tokens.spacing.md),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(tokens.spacing.md),
          decoration: BoxDecoration(
            color: tokens.colors.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(tokens.radii.lg),
            border: Border.all(
              color: tokens.colors.primary.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            result ?? '유효한 거리와 목표 시간을 입력하세요.',
            style: textTheme.titleSmall?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: result == null ? tokens.colors.muted : tokens.colors.primary,
            ),
          ),
        ),
      ],
    );
  }

  String? _calculateGoalPace() {
    final distance = double.tryParse(_distanceController.text.replaceAll(',', '.'));
    final hours = int.tryParse(_hoursController.text) ?? 0;
    final minutes = int.tryParse(_minutesController.text) ?? 0;
    final seconds = int.tryParse(_secondsController.text) ?? 0;
    if (distance == null || distance <= 0) {
      return null;
    }

    final totalSeconds = hours * 3600 + minutes * 60 + seconds;
    if (totalSeconds <= 0) {
      return null;
    }

    final paceSeconds = totalSeconds / distance;
    final paceMin = paceSeconds ~/ 60;
    final paceSec = (paceSeconds % 60).round().clamp(0, 59);
    final finish = '${hours}h ${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
    return '목표 페이스: $paceMin:${paceSec.toString().padLeft(2, '0')} /km\n'
        '예상 완주: $finish (${distance.toStringAsFixed(1)} km)';
  }
}
