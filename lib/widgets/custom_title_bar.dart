import 'dart:io';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../core/theme/app_theme.dart';

/// Custom draggable title bar for desktop platforms.
class CustomTitleBar extends StatelessWidget {
  const CustomTitleBar({super.key});

  @override
  Widget build(BuildContext context) {
    if (!_isDesktop) return const SizedBox.shrink();

    return DragToMoveArea(
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          border: Border(
            bottom: BorderSide(color: AppTheme.border.withValues(alpha: 0.6)),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.accent, AppTheme.accentLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.shield_outlined, size: 14, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Text(
              'ZeroTrustClient',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
                letterSpacing: 0.2,
              ),
            ),
            const Spacer(),
            if (Platform.isWindows || Platform.isLinux) ...[
              _WindowButton(
                icon: Icons.remove,
                onPressed: () => windowManager.minimize(),
              ),
              _WindowButton(
                icon: Icons.crop_square,
                onPressed: () async {
                  if (await windowManager.isMaximized()) {
                    await windowManager.unmaximize();
                  } else {
                    await windowManager.maximize();
                  }
                },
              ),
              _WindowButton(
                icon: Icons.close,
                isClose: true,
                onPressed: () => windowManager.close(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool get _isDesktop =>
      Platform.isLinux || Platform.isWindows || Platform.isMacOS;
}

class _WindowButton extends StatefulWidget {
  const _WindowButton({
    required this.icon,
    required this.onPressed,
    this.isClose = false,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final bool isClose;

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    Color? bg;
    if (_hovered) {
      bg = widget.isClose ? AppTheme.error : Colors.white.withValues(alpha: 0.08);
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Container(
          width: 36,
          height: 28,
          margin: const EdgeInsets.only(left: 2),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            widget.icon,
            size: 14,
            color: widget.isClose && _hovered
                ? Colors.white
                : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}
