import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme.dart';

enum ToastType { success, error, info, warning }

/// Show a beautiful animated toast notification
void showAppToast(
  BuildContext context, {
  required String message,
  String? subtitle,
  ToastType type = ToastType.success,
  Duration duration = const Duration(seconds: 3),
  bool haptic = true,
}) {
  if (haptic) {
    switch (type) {
      case ToastType.success:
        HapticFeedback.mediumImpact();
      case ToastType.error:
        HapticFeedback.heavyImpact();
      case ToastType.warning:
        HapticFeedback.lightImpact();
      case ToastType.info:
        HapticFeedback.selectionClick();
    }
  }

  final overlay = Overlay.of(context);
  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (_) => _ToastWidget(
      message: message,
      subtitle: subtitle,
      type: type,
      duration: duration,
      onDismiss: () => entry.remove(),
    ),
  );

  overlay.insert(entry);
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final String? subtitle;
  final ToastType type;
  final Duration duration;
  final VoidCallback onDismiss;

  const _ToastWidget({
    required this.message,
    this.subtitle,
    required this.type,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _autoHideTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      reverseDuration: const Duration(milliseconds: 300),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -1.5), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Curves.easeOutBack,
            reverseCurve: Curves.easeInCubic,
          ),
        );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();

    _autoHideTimer = Timer(widget.duration, _dismiss);
  }

  void _dismiss() {
    _autoHideTimer?.cancel();
    _controller.reverse().then((_) {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _autoHideTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = _toastConfig;
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: topPadding + 12,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: GestureDetector(
            onVerticalDragUpdate: (details) {
              if (details.delta.dy < -5) _dismiss();
            },
            onTap: _dismiss,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      config.color.withValues(alpha: 0.15),
                      AppTheme.surfaceCard.withValues(alpha: 0.95),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: config.color.withValues(alpha: 0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: config.color.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Icon
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            config.color,
                            config.color.withValues(alpha: 0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(11),
                        boxShadow: [
                          BoxShadow(
                            color: config.color.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(config.icon, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 14),
                    // Text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.message,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          if (widget.subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              widget.subtitle!,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Progress indicator
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 1.0, end: 0.0),
                      duration: widget.duration,
                      builder: (context, value, _) {
                        return SizedBox(
                          width: 3,
                          height: 30,
                          child: RotatedBox(
                            quarterTurns: 2,
                            child: LinearProgressIndicator(
                              value: value,
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.1,
                              ),
                              valueColor: AlwaysStoppedAnimation(
                                config.color.withValues(alpha: 0.6),
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  _ToastConfig get _toastConfig {
    switch (widget.type) {
      case ToastType.success:
        return _ToastConfig(
          color: const Color(0xFF10B981),
          icon: Icons.check_circle_rounded,
        );
      case ToastType.error:
        return _ToastConfig(
          color: const Color(0xFFF43F5E),
          icon: Icons.error_rounded,
        );
      case ToastType.warning:
        return _ToastConfig(
          color: const Color(0xFFF59E0B),
          icon: Icons.warning_rounded,
        );
      case ToastType.info:
        return _ToastConfig(
          color: const Color(0xFF06B6D4),
          icon: Icons.info_rounded,
        );
    }
  }
}

class _ToastConfig {
  final Color color;
  final IconData icon;
  const _ToastConfig({required this.color, required this.icon});
}
