import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../core/page_transitions.dart';
import '../core/theme.dart';
import '../models/dashboard_model.dart';
import '../providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/animated_counter.dart';
import '../widgets/app_toast.dart';
import '../widgets/glass_card.dart';
import '../widgets/shimmer_skeletons.dart';
import '../widgets/staggered_animation.dart';
import 'menu_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final DashboardProvider _dashProvider;

  @override
  void initState() {
    super.initState();
    _dashProvider = context.read<DashboardProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    final api = auth.api;
    await _dashProvider.loadFull(api);
    // Sync waiter profile from dashboard response
    final dashData = _dashProvider.data;
    final waiterInfo = dashData?.waiterInfo;
    if (waiterInfo != null && mounted) {
      auth.updateUserFromWaiterInfo(waiterInfo, isLinked: dashData?.isLinked);
    }
    _dashProvider.startStatsPolling(api);
  }

  @override
  void dispose() {
    _dashProvider.stopStatsPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final dash = context.watch<DashboardProvider>();
    final user = auth.user; // User might be null initially
    final data = dash.data;
    final stats = dash.stats ?? data?.stats;
    final isLinked = user?.isLinked ?? dash.isLinked;

    // Use a safety check for user
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      drawer:
          const MenuScreen(), // Added Drawer for better UX if needed, or keep pushing
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppTheme.primary,
        edgeOffset:
            100, // Push refresh indicator down so it's visible over header
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildZone1Header(user, isLinked),
            if (dash.isLoading && data == null)
              SliverToBoxAdapter(
                child: isLinked
                    ? const DashboardSkeleton()
                    : const UnlinkedDashboardSkeleton(),
              )
            else if (!isLinked)
              // ── UNLINKED WAITER VIEW ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StaggeredFadeSlide(
                        index: 0,
                        child: _buildUnlinkedHeroCard(user),
                      ),
                      const SizedBox(height: 24),
                      if (stats != null)
                        StaggeredFadeSlide(
                          index: 1,
                          child: _buildZone2Hero(stats),
                        ),
                    ],
                  ),
                ),
              )
            else
              // ── LINKED WAITER VIEW (FULL DASHBOARD) ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (stats != null)
                        StaggeredFadeSlide(
                          index: 0,
                          child: _buildZone2Hero(stats),
                        ),
                      const SizedBox(height: 24),
                      if ((data?.pendingRequests.length ?? 0) > 0) ...[
                        StaggeredFadeSlide(
                          index: 1,
                          child: _buildZone3Urgent(
                            data!.pendingRequests,
                            auth.api,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      StaggeredFadeSlide(
                        index: 2,
                        child: _buildZone4Marketplace(
                          data?.unassignedOrders ?? [],
                          auth.api,
                        ),
                      ),
                      const SizedBox(height: 24),
                      if ((data?.recentFeedback.length ?? 0) > 0)
                        StaggeredFadeSlide(
                          index: 3,
                          child: _buildMotivationSection(data!.recentFeedback),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Zone 1: Premium Header with Restaurant details & Waiter Profile
  Widget _buildZone1Header(dynamic user, bool isLinked) {
    return SliverAppBar(
      expandedHeight: 220,
      backgroundColor: Colors.transparent,
      floating: false,
      pinned: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Background Gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isLinked
                      ? [
                          AppTheme.primary.withValues(alpha: 0.15),
                          AppTheme.surface,
                        ]
                      : [
                          const Color(0xFFD97706).withValues(alpha: 0.12),
                          AppTheme.surface,
                        ],
                ),
              ),
            ),
            // 2. Decor Circles
            Positioned(
              top: -100,
              right: -50,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      (isLinked ? AppTheme.secondary : const Color(0xFFD97706))
                          .withValues(alpha: 0.1),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (isLinked
                                  ? AppTheme.secondary
                                  : const Color(0xFFD97706))
                              .withValues(alpha: 0.2),
                      blurRadius: 100,
                      spreadRadius: 20,
                    ),
                  ],
                ),
              ),
            ),

            // 3. Main Content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 44, 20, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Restaurant Badge (linked) or TIPTAP Brand (unlinked)
                    if (isLinked)
                      GlassCard(
                        borderRadius: 12,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        tint: AppTheme.primary.withValues(alpha: 0.1),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.storefront_rounded,
                                color: AppTheme.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    (user.restaurantName ?? 'Restaurant')
                                        .toUpperCase(),
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on_rounded,
                                        size: 10,
                                        color: Colors.white70,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          user.restaurantLocation ??
                                              'Unknown Location',
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            color: Colors.white70,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      GlassCard(
                        borderRadius: 12,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        tint: const Color(0xFFD97706).withValues(alpha: 0.1),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFD97706),
                                    Color(0xFFFBBF24),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.link_off_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'TIPTAP WAITER',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Text(
                                    'Not linked to any restaurant',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: const Color(
                                        0xFFFBBF24,
                                      ).withValues(alpha: 0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    const Spacer(),
                    // Waiter Info Area
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Habari, ${user.name.split(' ')[0]}',
                                style: GoogleFonts.poppins(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              if (user.waiterCode != null)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.secondary.withValues(
                                      alpha: 0.2,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: AppTheme.secondary.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    'CODE: ${user.waiterCode}',
                                    style: GoogleFonts.robotoMono(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.secondary,
                                    ),
                                  ),
                                )
                              else if (user.globalWaiterNumber != null)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFD97706),
                                        Color(0xFFFBBF24),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.fingerprint_rounded,
                                        color: Colors.white,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        user.globalWaiterNumber!,
                                        style: GoogleFonts.robotoMono(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // QR Button (only when linked)
                        if (isLinked)
                          GestureDetector(
                            onTap: () =>
                                _showQRDialog(context, user.waiterQrUrl),
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                gradient: AppTheme.primaryGradient,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primary.withValues(
                                      alpha: 0.4,
                                    ),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.qr_code_rounded,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // App Bar Actions
      leading: IconButton(
        icon: const Icon(Icons.menu_rounded, color: Colors.white),
        onPressed: () =>
            Navigator.push(context, SlideRoute(page: const MenuScreen())),
      ),
      actions: [if (isLinked) _buildStatusToggle()],
    );
  }

  /// Unlinked waiter hero card — shows unique code and CTA
  Widget _buildUnlinkedHeroCard(dynamic user) {
    final code = user.globalWaiterNumber ?? 'TIPTAP-W-?????';
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E1040), Color(0xFF2D1B4E)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFD97706).withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD97706).withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Fingerprint Icon
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFD97706), Color(0xFFFBBF24)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD97706).withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.fingerprint_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),

          // Label
          Text(
            'Your Unique Code',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.5),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),

          // Code
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFD97706).withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              code,
              style: GoogleFonts.robotoMono(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: const Color(0xFFFBBF24),
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // CTA Message
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFD97706).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFD97706).withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD97706).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.share_rounded,
                    color: const Color(0xFFFBBF24).withValues(alpha: 0.8),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Share with a Manager',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      Text(
                        'Give this code to a restaurant manager to get linked and start working.',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.4),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusToggle() {
    final dash = context.watch<DashboardProvider>();
    final isOnline = dash.isOnline;
    final isToggling = dash.isTogglingStatus;

    final statusColor = isOnline ? AppTheme.success : const Color(0xFFEF4444);
    final statusLabel = isOnline ? 'Online' : 'Offline';
    final statusIcon = isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded;

    return GestureDetector(
      onTap: isToggling ? null : () => _showStatusToggleDialog(isOnline),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: statusColor.withValues(alpha: 0.4)),
          boxShadow: isOnline
              ? [
                  BoxShadow(
                    color: statusColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isToggling)
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: statusColor,
                ),
              )
            else ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: statusColor, blurRadius: isOnline ? 6 : 2),
                  ],
                ),
              ),
            ],
            const SizedBox(width: 8),
            Icon(statusIcon, size: 14, color: statusColor),
            const SizedBox(width: 4),
            Text(
              statusLabel,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStatusToggleDialog(bool currentlyOnline) {
    final goingTo = !currentlyOnline;
    final title = goingTo ? 'Go Online?' : 'Go Offline?';
    final message = goingTo
        ? 'You will start receiving customer calls and new orders.'
        : 'You will stop receiving calls and new orders. Active orders will not be affected.';
    final actionLabel = goingTo ? 'Go Online' : 'Go Offline';
    final actionColor = goingTo ? AppTheme.success : const Color(0xFFEF4444);
    final actionIcon = goingTo ? Icons.wifi_rounded : Icons.wifi_off_rounded;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: actionColor.withValues(alpha: 0.15),
                  border: Border.all(color: actionColor.withValues(alpha: 0.3)),
                ),
                child: Icon(actionIcon, color: actionColor, size: 32),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.5),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _toggleStatus(goingTo);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: actionColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        actionLabel,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleStatus(bool goOnline) async {
    final auth = context.read<AuthProvider>();
    final dash = context.read<DashboardProvider>();
    HapticFeedback.mediumImpact();
    final success = await dash.toggleOnlineStatus(auth.api, goOnline);
    if (!mounted) return;
    if (success) {
      showAppToast(
        context,
        message: goOnline ? 'You are now Online!' : 'You are now Offline',
        subtitle: goOnline
            ? 'Ready for orders & customer calls'
            : 'You will not receive new orders',
        type: goOnline ? ToastType.success : ToastType.warning,
      );
    } else {
      showAppToast(
        context,
        message: 'Failed to update status',
        subtitle: 'Please check your connection and try again',
        type: ToastType.error,
      );
    }
  }

  void _showQRDialog(BuildContext context, String? qrUrl) {
    if (qrUrl == null) return;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Waiter QR Code',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: QrImageView(
                  data: qrUrl,
                  version: QrVersions.auto,
                  size: 200,
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Close',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Zone 2: Hero Tips + 3 Stat Pills (Requests, Active, Ready)
  Widget _buildZone2Hero(DashboardStats stats) {
    return GlassCard(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.secondary.withValues(alpha: 0.4),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            AnimatedFormattedCounter(
              end: stats.tipsToday,
              prefix: 'Tsh ',
              formatter: (v) => NumberFormat('#,###').format(v.toInt()),
              style: GoogleFonts.robotoMono(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _statPill(
                    '${stats.pendingRequests}',
                    'Requests',
                    Icons.notifications_active_rounded,
                    const LinearGradient(
                      colors: [Color(0xFFEC4899), Color(0xFFF43F5E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    stats.pendingRequests > 0,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _statPill(
                    '${stats.myActiveOrders}',
                    'Active',
                    Icons.restaurant_rounded,
                    const LinearGradient(
                      colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    false,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _statPill(
                    '${stats.readyToServe}',
                    'Ready',
                    Icons.check_circle_rounded,
                    const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    false,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statPill(
    String value,
    String label,
    IconData icon,
    Gradient gradient,
    bool pulse,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 16),
              if (pulse) ...[
                const SizedBox(width: 6),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.9),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  /// Zone 3: Urgent Action Feed - Horizontal scroll, request_bill first, red border if >5min
  Widget _buildZone3Urgent(List<PendingRequest> list, api) {
    final sorted = List<PendingRequest>.from(list)
      ..sort((a, b) {
        if (a.type == 'request_bill' && b.type != 'request_bill') return -1;
        if (a.type != 'request_bill' && b.type == 'request_bill') return 1;
        return 0;
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.whatshot_rounded, color: AppTheme.alert, size: 22),
            const SizedBox(width: 8),
            Text(
              'Urgent',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: sorted.length,
            itemBuilder: (_, i) {
              final r = sorted[i];
              return Padding(
                padding: EdgeInsets.only(right: i < sorted.length - 1 ? 12 : 0),
                child: _urgentCard(r, api),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _urgentCard(PendingRequest r, api) {
    final isBill = r.type == 'request_bill';
    DateTime? created;
    try {
      created = DateTime.parse(r.createdAt);
    } catch (_) {}
    final minutesAgo = created != null
        ? DateTime.now().difference(created).inMinutes
        : 0;
    final isLate = minutesAgo >= 5;

    return SizedBox(
      width: 175,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isLate ? AppTheme.alert : Colors.transparent,
            width: 2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: GlassCard(
            padding: const EdgeInsets.all(10),
            tint: isBill
                ? AppTheme.rose.withValues(alpha: 0.15)
                : AppTheme.primary.withValues(alpha: 0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isBill
                          ? Icons.receipt_long_rounded
                          : Icons.notifications_active_rounded,
                      color: isBill ? AppTheme.rose : AppTheme.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        r.tableDisplay,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Text(
                  r.displayType,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(
                  width: double.infinity,
                  height: 28,
                  child: TextButton(
                    onPressed: () => context
                        .read<DashboardProvider>()
                        .completeRequest(api, r.id),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      minimumSize: Size.zero,
                    ),
                    child: Text(
                      'Done',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Zone 4: Marketplace - Oda Mpya / New Orders, dashed border, CLAIM
  Widget _buildZone4Marketplace(List<UnassignedOrder> list, api) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.shopping_bag_rounded, color: AppTheme.primary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Oda Mpya / New Orders',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (list.isEmpty)
          GlassCard(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Text(
                  'Hakuna oda mpya',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          )
        else
          ...list.map(
            (o) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _marketplaceCard(o, api),
            ),
          ),
      ],
    );
  }

  Widget _marketplaceCard(UnassignedOrder o, api) {
    return DottedBorder(
      borderType: BorderType.RRect,
      radius: const Radius.circular(14),
      dashPattern: const [6, 3],
      color: AppTheme.primary.withValues(alpha: 0.6),
      strokeWidth: 1.5,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          color: Colors.black.withValues(alpha: 0.2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        o.tableNumber,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order #${o.id}',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Tsh ${NumberFormat('#,###').format(o.totalAmount)}',
                            style: GoogleFonts.robotoMono(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.warning.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          o.status.toUpperCase(),
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.warning,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (o.items.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 2,
                    children: o.items
                        .take(3)
                        .map(
                          (i) => Text(
                            '${i.quantity}x ${i.name}',
                            style: GoogleFonts.poppins(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 11,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () =>
                      context.read<DashboardProvider>().claimOrder(api, o.id),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'CLAIM',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        letterSpacing: 1.5,
                        color: Colors.white,
                      ),
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

  Widget _buildMotivationSection(List<RecentFeedback> feedback) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.star_rounded, color: AppTheme.gold, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Sifa (Motivation)',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ...feedback
            .take(2)
            .map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          5,
                          (i) => Icon(
                            i < f.rating
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: AppTheme.gold,
                            size: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          f.comment ?? '',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      ],
    );
  }
}
