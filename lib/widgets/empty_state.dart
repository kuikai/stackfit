import 'package:flutter/material.dart';

/// Centered empty-state message with optional action.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.fitness_center_outlined,
    this.action,
    this.onIconPressed,
    this.iconLabel,
  });

  final String title;
  final String message;
  final IconData icon;
  final Widget? action;

  /// When set, the circle icon opens this action.
  final VoidCallback? onIconPressed;

  /// Spoken name for the icon button. Falls back to [title].
  final String? iconLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _IconBadge(
              icon: icon,
              color: colorScheme.primary,
              onPressed: onIconPressed,
              label: iconLabel ?? title,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.62),
                height: 1.45,
              ),
            ),
            if (action != null) ...[const SizedBox(height: 24), action!],
          ],
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({
    required this.icon,
    required this.color,
    required this.onPressed,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 34, color: color),
    );
    if (onPressed == null) {
      return badge;
    }

    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: badge,
        ),
      ),
    );
  }
}
