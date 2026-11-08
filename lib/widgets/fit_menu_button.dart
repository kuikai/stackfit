import 'package:flutter/material.dart';

/// A ⋮ menu that stays on screen.
///
/// The last workout on Home sits against the bottom of the phone. Opening its
/// menu there hides items below the window, so this scrolls the row up first.
class FitMenuButton<T> extends StatelessWidget {
  const FitMenuButton({
    super.key,
    required this.tooltip,
    required this.itemBuilder,
    required this.onSelected,
  });

  final String tooltip;
  final List<PopupMenuEntry<T>> Function(BuildContext context) itemBuilder;
  final ValueChanged<T> onSelected;

  /// Room a full workout or section menu needs below the button.
  static const menuRoom = 320.0;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: () => _open(context),
      icon: const Icon(Icons.more_vert),
    );
  }

  Future<void> _open(BuildContext context) async {
    await _makeRoom(context);
    if (!context.mounted) {
      return;
    }
    final selected = await showMenu<T>(
      context: context,
      position: _anchor(context),
      items: itemBuilder(context),
    );
    if (selected != null) {
      onSelected(selected);
    }
  }

  Future<void> _makeRoom(BuildContext context) async {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) {
      return;
    }
    final bottom = box.localToGlobal(Offset(0, box.size.height)).dy;
    final room = MediaQuery.sizeOf(context).height - bottom;
    if (room >= menuRoom || Scrollable.maybeOf(context) == null) {
      return;
    }
    await Scrollable.ensureVisible(
      context,
      alignment: 0.08,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
    );
  }

  RelativeRect _anchor(BuildContext context) {
    final box = context.findRenderObject()! as RenderBox;
    final overlay =
        Navigator.of(context).overlay!.context.findRenderObject()! as RenderBox;
    final origin = box.localToGlobal(Offset.zero, ancestor: overlay);
    return RelativeRect.fromRect(origin & box.size, Offset.zero & overlay.size);
  }
}
