import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../core/utils.dart';
import '../models/models.dart';
import 'history_load_chart.dart';
import 'session_tile.dart';
import 'skin_panel.dart';

/// One workout on History: name, load chart, and each session's date.
///
/// Starts open. The header folds the rows and leaves the chart up.
/// [onDeleteAll] puts a trash icon on the right of the header.
class HistoryWorkoutSection extends StatefulWidget {
  const HistoryWorkoutSection({
    super.key,
    required this.group,
    this.showHeader = true,
    this.belowChart,
    this.onDeleteAll,
  });

  final HistoryWorkoutGroup group;

  /// False on the per-workout page, where the app bar already has the name.
  final bool showHeader;

  /// Extra block under the chart. The per-workout page passes its stats.
  final Widget? belowChart;

  /// Deletes every log of this workout. Null hides the trash icon.
  final VoidCallback? onDeleteAll;

  @override
  State<HistoryWorkoutSection> createState() => _HistoryWorkoutSectionState();
}

class _HistoryWorkoutSectionState extends State<HistoryWorkoutSection> {
  bool _open = true;

  @override
  Widget build(BuildContext context) {
    final look = context.skinLook;
    return SkinPanel(
      margin: EdgeInsets.only(bottom: look.listGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.showHeader) _header(context),
          HistoryLoadChart(sessions: widget.group.sessions),
          if (widget.belowChart != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
              child: widget.belowChart,
            ),
          if (_open) _rows(),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    final theme = Theme.of(context);
    final group = widget.group;
    final count = group.sessions.length;
    final times = count == 1 ? '1 time' : '$count times';
    final latest = AppUtils.formatSessionDate(group.sessions.first.completedAt);
    final onDeleteAll = widget.onDeleteAll;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 4, 0),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _open = !_open),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(_open ? Icons.expand_less : Icons.expand_more),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$times · $latest',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (onDeleteAll != null)
            IconButton(
              key: ValueKey('delete-workout-logs-${group.workoutId}'),
              tooltip: 'Delete logs',
              visualDensity: VisualDensity.compact,
              onPressed: onDeleteAll,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
    );
  }

  Widget _rows() {
    final sessions = widget.group.sessions;
    return Column(
      children: [
        for (var index = 0; index < sessions.length; index++) ...[
          if (index > 0) const Divider(height: 1),
          SessionTile(session: sessions[index], showWorkoutName: false),
        ],
      ],
    );
  }
}
