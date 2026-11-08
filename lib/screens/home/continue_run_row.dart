import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/models.dart';
import '../../widgets/skin_panel.dart';

/// A plan day left unfinished, shown because it is not in the workout list.
class ContinueRunRow extends StatelessWidget {
  const ContinueRunRow({
    super.key,
    required this.run,
    required this.onContinue,
    required this.onStartOver,
  });

  final InProgressWorkout run;
  final VoidCallback onContinue;
  final VoidCallback onStartOver;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final look = context.skinLook;
    return SkinPanel(
      margin: EdgeInsets.only(bottom: look.listGap),
      overPortrait: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              run.workout.name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              'In progress',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: onContinue,
                    child: const Text('Continue'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onStartOver,
                    child: const Text('Start over'),
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
