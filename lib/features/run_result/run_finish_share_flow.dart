import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'run_finish_share_targets.dart';

const runFinishCardShareKey = Key('run-finish-card-share');
const runFinishModeOneKey = Key('run-finish-mode-one');
const runFinishModeManyKey = Key('run-finish-mode-many');
const runFinishSequenceGoKey = Key('run-finish-sequence-go');
const runFinishNextKey = Key('run-finish-next');
const runFinishSkipKey = Key('run-finish-skip');
const runFinishStopKey = Key('run-finish-stop');

const runFinishModeOneLabel = '하나만 올리기';
const runFinishModeManyLabel = '여러 개 순서대로 올리기';
const runFinishSequenceGoLabel = '순서대로 공유';
const runFinishSkipLabel = '건너뛰기';
const runFinishStopLabel = '그만하기';

Future<RunFinishShareMode?> showRunFinishShareMode(
  BuildContext context,
  RunFinishShareMode initial,
) {
  return showModalBottomSheet<RunFinishShareMode>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '어떻게 올릴까요?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 14),
              _ModeButton(
                buttonKey: runFinishModeOneKey,
                label: runFinishModeOneLabel,
                selected: initial == RunFinishShareMode.one,
                onTap: () =>
                    Navigator.pop(sheetContext, RunFinishShareMode.one),
              ),
              const SizedBox(height: 8),
              _ModeButton(
                buttonKey: runFinishModeManyKey,
                label: runFinishModeManyLabel,
                selected: initial == RunFinishShareMode.sequence,
                onTap: () =>
                    Navigator.pop(sheetContext, RunFinishShareMode.sequence),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.buttonKey,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final Key buttonKey;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primaryMint : AppColors.surfaceWhite,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        key: buttonKey,
        onTap: onTap,
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.primaryMint : AppColors.borderLight,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              if (selected) const Icon(Icons.check, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

Future<RunFinishShareTarget?> showRunFinishOnePicker(
  BuildContext context,
  List<RunFinishShareTarget> targets,
) {
  return showModalBottomSheet<RunFinishShareTarget>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '어디에 올릴까요?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
            ),
            for (final target in targets)
              ListTile(
                key: Key('run-finish-target-${target.id}'),
                title: Text(target.label),
                onTap: () => Navigator.pop(sheetContext, target),
              ),
          ],
        ),
      );
    },
  );
}

Future<List<RunFinishShareTarget>?> showRunFinishSequencePicker(
  BuildContext context, {
  required List<RunFinishShareTarget> targets,
  required Set<String> checkedIds,
}) {
  return showModalBottomSheet<List<RunFinishShareTarget>>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      return FractionallySizedBox(
        heightFactor: 0.72,
        child: RunFinishSequencePicker(
          targets: targets,
          initiallyChecked: checkedIds,
          onShare: (chosen) => Navigator.pop(sheetContext, chosen),
        ),
      );
    },
  );
}

class RunFinishSequencePicker extends StatefulWidget {
  const RunFinishSequencePicker({
    required this.targets,
    required this.initiallyChecked,
    required this.onShare,
    super.key,
  });

  final List<RunFinishShareTarget> targets;
  final Set<String> initiallyChecked;
  final ValueChanged<List<RunFinishShareTarget>> onShare;

  @override
  State<RunFinishSequencePicker> createState() =>
      _RunFinishSequencePickerState();
}

class _RunFinishSequencePickerState extends State<RunFinishSequencePicker> {
  late List<RunFinishShareTarget> _items = [...widget.targets];
  late Set<String> _checked = {...widget.initiallyChecked};

  @override
  Widget build(BuildContext context) {
    final chosen = [
      for (final item in _items)
        if (_checked.contains(item.id)) item,
    ];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Text(
                '순서대로 올리기',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
            Expanded(
              child: ReorderableListView(
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    _items = moveShareItem(_items, oldIndex, newIndex);
                  });
                },
                children: [
                  for (final item in _items)
                    CheckboxListTile(
                      key: ValueKey(item.id),
                      value: _checked.contains(item.id),
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(item.label),
                      onChanged: (value) {
                        setState(() {
                          if (value ?? false) {
                            _checked.add(item.id);
                          } else {
                            _checked.remove(item.id);
                          }
                        });
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              key: runFinishSequenceGoKey,
              onPressed: chosen.isEmpty ? null : () => widget.onShare(chosen),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryMint,
                foregroundColor: AppColors.textBlack,
                minimumSize: const Size.fromHeight(52),
              ),
              child: const Text(
                runFinishSequenceGoLabel,
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RunFinishSequenceBanner extends StatelessWidget {
  const RunFinishSequenceBanner({
    required this.label,
    required this.progress,
    required this.onNext,
    required this.onSkip,
    required this.onStop,
    super.key,
  });

  final String label;
  final String progress;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primaryMint,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              progress,
              key: const Key('run-finish-progress'),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            FilledButton(
              key: runFinishNextKey,
              onPressed: onNext,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.textBlack,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
              ),
              child: Text(
                '다음: $label',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    key: runFinishSkipKey,
                    onPressed: onSkip,
                    child: const Text(
                      runFinishSkipLabel,
                      style: TextStyle(
                        color: AppColors.textBlack,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    key: runFinishStopKey,
                    onPressed: onStop,
                    child: const Text(
                      runFinishStopLabel,
                      style: TextStyle(
                        color: AppColors.textBlack,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
