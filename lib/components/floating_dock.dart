import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FloatingDock extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const FloatingDock({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 10,
            bottom: 10 + MediaQuery.of(context).padding.bottom,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.6), width: 1.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
              BoxShadow(
                color: const Color.fromARGB(255, 255, 2, 14).withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _DockItem(
                icon: currentIndex == 0
                    ? Icons.home_rounded
                    : Icons.home_outlined,
                label: 'Home',
                isActive: currentIndex == 0,
                onTap: () => _handleTap(0),
              ),
              _DockItem(
                icon: currentIndex == 1
                    ? Icons.emoji_events_rounded
                    : Icons.emoji_events_outlined,
                label: 'Result',
                isActive: currentIndex == 1,
                onTap: () => _handleTap(1),
              ),
              _DockItem(
                icon: currentIndex == 2
                    ? Icons.description_rounded
                    : Icons.description_outlined,
                label: 'Forms',
                isActive: currentIndex == 2,
                onTap: () => _handleTap(2),
              ),
              _DockItem(
                icon: currentIndex == 3
                    ? Icons.notifications_rounded
                    : Icons.notifications_none_rounded,
                label: 'Notices',
                isActive: currentIndex == 3,
                onTap: () => _handleTap(3),
              ),
              _DockItem(
                icon: currentIndex == 4
                    ? Icons.settings_rounded
                    : Icons.settings_outlined,
                label: 'Settings',
                isActive: currentIndex == 4,
                onTap: () => _handleTap(4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleTap(int index) {
    HapticFeedback.lightImpact();
    onTabSelected(index);
  }
}

class _DockItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _DockItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_DockItem> createState() => _DockItemState();
}

class _DockItemState extends State<_DockItem> {
  bool _isHovered = false;

  void _setHover(bool value) {
    if (mounted && _isHovered != value) {
      setState(() {
        _isHovered = value;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const activeColor = Color.fromARGB(255, 247, 4, 4);
    const inactiveColor = Color(0xFF94A3B8);
    const hoverColor = Colors.redAccent; // The requested red color

    final isActive = widget.isActive;

    // Determine the color based on state
    final iconColor = isActive
        ? activeColor
        : _isHovered
        ? hoverColor
        : inactiveColor;

    return MouseRegion(
      onEnter: (_) => _setHover(true),
      onExit: (_) => _setHover(false),
      child: GestureDetector(
        onTapDown: (_) => _setHover(true), // Trigger hover on touch press
        onTapUp: (_) => _setHover(false), // Release hover on touch release
        onTapCancel: () => _setHover(false), // Release hover on scroll/cancel
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: isActive ? 16 : 12,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: isActive
                ? activeColor.withOpacity(0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: TweenAnimationBuilder<Color?>(
                  key: ValueKey(
                    widget.icon.codePoint,
                  ), // Ensures switcher only triggers on icon iconData change, not color!
                  tween: ColorTween(begin: inactiveColor, end: iconColor),
                  duration: const Duration(milliseconds: 200),
                  builder: (context, color, child) {
                    return Icon(widget.icon, color: color, size: 26);
                  },
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                child: isActive
                    ? Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Text(
                          widget.label,
                          style: const TextStyle(
                            color: activeColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
