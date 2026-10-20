import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/models.dart';

/// Home entry point to the built-in plan library.
class PlanLibraryTile extends StatelessWidget {
  const PlanLibraryTile({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final look = context.skinLook;
    final planCount = PlanLibrary.all.length;
    final categories = PlanLibrary.categories.take(5).join(', ');

    return Card(
      margin: EdgeInsets.only(bottom: look.listGap),
      color: colorScheme.primary.withValues(alpha: 0.12),
      child: InkWell(
        borderRadius: look.cornerRadius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: Row(
            children: [
              Icon(
                Icons.auto_awesome_motion_outlined,
                color: colorScheme.primary,
                size: 28,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Workout plans',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$planCount ready-made plans · $categories and more',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.62),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
