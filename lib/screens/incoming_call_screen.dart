import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../models/dashboard_model.dart';
import '../services/call_service.dart';

class IncomingCallScreen extends StatefulWidget {
  final PendingRequest call;

  const IncomingCallScreen({super.key, required this.call});

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen>
    with TickerProviderStateMixin {
  // Ring pulse animation
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Slide-in entrance animation
  late AnimationController _entranceController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  // Icon bob animation
  late AnimationController _iconBobController;
  late Animation<double> _iconBob;

  // Incoming dots animation
  late AnimationController _dotsController;

  @override
  void initState() {
    super.initState();

    // Pulsing rings
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _pulseAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeOut));

    // Entrance
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
          ),
        );
    _entranceController.forward();

    // Icon bob
    _iconBobController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _iconBob = Tween<double>(begin: -4, end: 4).animate(
      CurvedAnimation(parent: _iconBobController, curve: Curves.easeInOut),
    );

    // Dots
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _entranceController.dispose();
    _iconBobController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  void _accept() {
    final callService = context.read<CallService>();
    callService.acceptCall();
    Navigator.of(context).pop('accepted');
  }

  void _decline() {
    final callService = context.read<CallService>();
    callService.declineCall();
    Navigator.of(context).pop('declined');
  }

  @override
  Widget build(BuildContext context) {
    final isBill = widget.call.type == 'request_bill';
    final accentColor = isBill ? AppTheme.rose : AppTheme.primary;

    DateTime? created;
    try {
      created = DateTime.parse(widget.call.createdAt);
    } catch (_) {}

    final callService = context.watch<CallService>();
    final queueCount = callService.queueCount;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isBill
                  ? [
                      const Color(0xFF1A0A1E),
                      const Color(0xFF2D0F23),
                      const Color(0xFF0D1B2A),
                    ]
                  : [
                      const Color(0xFF0A1628),
                      const Color(0xFF0F1A2E),
                      const Color(0xFF0A0614),
                    ],
            ),
          ),
          child: Stack(
            children: [
              // Background particles
              ..._buildParticles(accentColor),

              // Main content
              SafeArea(
                child: SlideTransition(
                  position: _slideUp,
                  child: FadeTransition(
                    opacity: _fadeIn,
                    child: Column(
                      children: [
                        const SizedBox(height: 40),

                        // "Incoming Call" label with animated dots
                        _buildIncomingLabel(accentColor),

                        const Spacer(flex: 2),

                        // Pulsing ring + call icon
                        _buildCallAvatar(accentColor, isBill),

                        const SizedBox(height: 32),

                        // Call type
                        Text(
                          isBill ? 'Bill Request' : 'Customer Calling',
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Table info
                        _buildTableInfo(accentColor),

                        if (created != null) ...[
                          const SizedBox(height: 12),
                          _buildTimeInfo(created),
                        ],

                        // Queue indicator
                        if (queueCount > 0) ...[
                          const SizedBox(height: 16),
                          _buildQueueIndicator(queueCount),
                        ],

                        const Spacer(flex: 3),

                        // Action buttons
                        _buildActionButtons(accentColor),

                        const SizedBox(height: 50),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  INCOMING LABEL WITH ANIMATED DOTS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildIncomingLabel(Color accentColor) {
    return AnimatedBuilder(
      animation: _dotsController,
      builder: (context, _) {
        final dotCount = (_dotsController.value * 4).floor() % 4;
        final dots = '.' * dotCount;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accentColor.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.8),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Incoming Call$dots',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: accentColor,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  PULSING CALL AVATAR
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildCallAvatar(Color accentColor, bool isBill) {
    return SizedBox(
      width: 180,
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer pulse rings
          ...List.generate(3, (i) {
            return AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                final delay = i * 0.3;
                final value = ((_pulseAnimation.value + delay) % 1.0);
                return Container(
                  width: 120 + (value * 60),
                  height: 120 + (value * 60),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.3 * (1 - value)),
                      width: 2 * (1 - value),
                    ),
                  ),
                );
              },
            );
          }),

          // Glow
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.25),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
          ),

          // Main circle
          AnimatedBuilder(
            animation: _iconBob,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _iconBob.value),
                child: child,
              );
            },
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isBill
                      ? [const Color(0xFFF43F5E), const Color(0xFFE11D48)]
                      : [const Color(0xFF06B6D4), const Color(0xFF3B82F6)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Icon(
                isBill
                    ? Icons.receipt_long_rounded
                    : Icons.notifications_active_rounded,
                color: Colors.white,
                size: 44,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  TABLE INFO
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildTableInfo(Color accentColor) {
    final hasTable =
        widget.call.tableNumber != null && widget.call.tableNumber!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasTable
                ? Icons.table_restaurant_rounded
                : Icons.location_on_rounded,
            color: hasTable ? accentColor : Colors.white.withValues(alpha: 0.5),
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            widget.call.tableDisplay,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: hasTable ? FontWeight.w700 : FontWeight.w500,
              color: hasTable
                  ? accentColor
                  : Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  TIME INFO
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildTimeInfo(DateTime created) {
    final minutesAgo = DateTime.now().difference(created).inMinutes;
    final isUrgent = minutesAgo >= 5;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.access_time_rounded,
          size: 14,
          color: isUrgent
              ? AppTheme.alert
              : Colors.white.withValues(alpha: 0.4),
        ),
        const SizedBox(width: 4),
        Text(
          minutesAgo == 0
              ? 'Just now'
              : '$minutesAgo min${minutesAgo > 1 ? 's' : ''} ago',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: isUrgent ? FontWeight.w700 : FontWeight.w500,
            color: isUrgent
                ? AppTheme.alert
                : Colors.white.withValues(alpha: 0.4),
          ),
        ),
      ],
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  QUEUE INDICATOR
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildQueueIndicator(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.queue_rounded, color: AppTheme.warning, size: 14),
          const SizedBox(width: 6),
          Text(
            '+$count more call${count > 1 ? 's' : ''} waiting',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.warning,
            ),
          ),
        ],
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  ACTION BUTTONS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildActionButtons(Color accentColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Decline
          _callButton(
            icon: Icons.close_rounded,
            label: 'Decline',
            gradient: const LinearGradient(
              colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
            ),
            shadowColor: const Color(0xFFEF4444),
            onTap: _decline,
          ),

          // Accept
          _callButton(
            icon: Icons.check_rounded,
            label: 'Accept',
            gradient: LinearGradient(
              colors: accentColor == AppTheme.rose
                  ? [const Color(0xFF10B981), const Color(0xFF059669)]
                  : [const Color(0xFF10B981), const Color(0xFF059669)],
            ),
            shadowColor: const Color(0xFF10B981),
            onTap: _accept,
            isAccept: true,
          ),
        ],
      ),
    );
  }

  Widget _callButton({
    required IconData icon,
    required String label,
    required Gradient gradient,
    required Color shadowColor,
    required VoidCallback onTap,
    bool isAccept = false,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: AnimatedBuilder(
            animation: isAccept ? _iconBobController : _pulseController,
            builder: (context, child) {
              final scale = isAccept ? 1.0 + (_iconBob.value.abs() / 80) : 1.0;
              return Transform.scale(scale: scale, child: child);
            },
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: gradient,
                boxShadow: [
                  BoxShadow(
                    color: shadowColor.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: Colors.white, size: 32),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  //  BACKGROUND PARTICLES
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  List<Widget> _buildParticles(Color accentColor) {
    return [
      // Top-right glow
      Positioned(
        top: -60,
        right: -40,
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.1),
                blurRadius: 100,
                spreadRadius: 20,
              ),
            ],
          ),
        ),
      ),
      // Bottom-left glow
      Positioned(
        bottom: 100,
        left: -60,
        child: Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.08),
                blurRadius: 80,
                spreadRadius: 15,
              ),
            ],
          ),
        ),
      ),
      // Center glow (behind avatar)
      Positioned(
        top: MediaQuery.of(context).size.height * 0.25,
        left: 0,
        right: 0,
        child: Center(
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, _) {
              return Container(
                width: 250 + (_pulseAnimation.value * 30),
                height: 250 + (_pulseAnimation.value * 30),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(
                        alpha: 0.05 * (1 - _pulseAnimation.value),
                      ),
                      blurRadius: 120,
                      spreadRadius: 30,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    ];
  }
}
