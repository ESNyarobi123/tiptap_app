import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../core/theme.dart';
import '../models/dashboard_model.dart';
import '../providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/shimmer_skeletons.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen>
    with SingleTickerProviderStateMixin {
  List<PendingRequest> _list = [];
  bool _loading = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final api = context.read<AuthProvider>().api;
      _list = await api.getPendingRequests();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _complete(int id) async {
    if (!mounted) return;
    try {
      final api = context.read<AuthProvider>().api;
      await context.read<DashboardProvider>().completeRequest(api, id);
      if (mounted) await _load();
    } catch (_) {}
  }

  List<PendingRequest> get _sortedList {
    final copy = List<PendingRequest>.from(_list);
    copy.sort((a, b) {
      if (a.type == 'request_bill' && b.type != 'request_bill') return -1;
      if (a.type != 'request_bill' && b.type == 'request_bill') return 1;
      DateTime? aTime;
      DateTime? bTime;
      try {
        aTime = DateTime.parse(a.createdAt);
        bTime = DateTime.parse(b.createdAt);
      } catch (_) {}
      if (aTime != null && bTime != null) return aTime.compareTo(bTime);
      return 0;
    });
    return copy;
  }

  // Count by type
  int get _billCount => _list.where((r) => r.type == 'request_bill').length;
  int get _callCount => _list.where((r) => r.type != 'request_bill').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          // ─── Header ───
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: AppTheme.surface.withValues(alpha: 0.95),
            surfaceTintColor: Colors.transparent,
            expandedHeight: 70,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF1A1035),
                      AppTheme.surface.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            title: Row(
              children: [
                Text(
                  'Customer Calls',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                if (_list.isNotEmpty) ...[
                  const SizedBox(width: 10),
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) =>
                        Opacity(opacity: _pulseAnimation.value, child: child),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF43F5E), Color(0xFFE11D48)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.alert.withValues(alpha: 0.4),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Text(
                        '${_list.length}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  onPressed: _load,
                ),
              ),
            ],
          ),

          // ─── Summary Cards ───
          if (!_loading && _list.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    if (_billCount > 0) ...[
                      Expanded(
                        child: _summaryChip(
                          icon: Icons.receipt_long_rounded,
                          label: 'Bills',
                          count: _billCount,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF43F5E), Color(0xFFE11D48)],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    if (_callCount > 0)
                      Expanded(
                        child: _summaryChip(
                          icon: Icons.notifications_active_rounded,
                          label: 'Calls',
                          count: _callCount,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

          // ─── Content ───
          if (_loading)
            const RequestsSkeleton()
          else if (_list.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.notifications_off_rounded,
                        size: 44,
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'All caught up!',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Hakuna maombi ya wateja kwa sasa',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((context, i) {
                final r = _sortedList[i];
                return Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    i == 0 ? 8 : 0,
                    16,
                    i == _sortedList.length - 1 ? 100 : 10,
                  ),
                  child: _AlertCard(
                    request: r,
                    index: i,
                    onDone: () async => await _complete(r.id),
                  ),
                );
              }, childCount: _sortedList.length),
            ),
        ],
      ),
    );
  }

  Widget _summaryChip({
    required IconData icon,
    required String label,
    required int count,
    required Gradient gradient,
  }) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          Text(
            '$count',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  ALERT CARD — Individual request card
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _AlertCard extends StatefulWidget {
  final PendingRequest request;
  final int index;
  final Future<void> Function() onDone;

  const _AlertCard({
    required this.request,
    required this.index,
    required this.onDone,
  });

  @override
  State<_AlertCard> createState() => _AlertCardState();
}

class _AlertCardState extends State<_AlertCard> {
  bool _isCompleting = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.request;
    final isBill = r.type == 'request_bill';

    DateTime? created;
    try {
      created = DateTime.parse(r.createdAt);
    } catch (_) {}
    final minutesAgo = created != null
        ? DateTime.now().difference(created).inMinutes
        : 0;
    final isUrgent = minutesAgo >= 10;
    final hasTable = r.tableNumber != null && r.tableNumber!.isNotEmpty;

    final accentColor = isBill ? AppTheme.rose : AppTheme.primary;
    final accentGradient = isBill
        ? const LinearGradient(colors: [Color(0xFFF43F5E), Color(0xFFE11D48)])
        : const LinearGradient(colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)]);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (widget.index * 80)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Transform.translate(
        offset: Offset(0, 20 * (1 - value)),
        child: Opacity(opacity: value, child: child),
      ),
      child: Dismissible(
        key: ValueKey(r.id),
        direction: DismissDirection.endToStart,
        confirmDismiss: (dir) async {
          setState(() => _isCompleting = true);
          await widget.onDone();
          return true;
        },
        background: Container(
          decoration: BoxDecoration(
            gradient: AppTheme.successGradient,
            borderRadius: BorderRadius.circular(18),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(height: 4),
              Text(
                'Done',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        child: GlassCard(
          padding: EdgeInsets.zero,
          tint: isBill
              ? AppTheme.rose.withValues(alpha: 0.05)
              : AppTheme.primary.withValues(alpha: 0.03),
          child: Column(
            children: [
              // Colored top accent
              Container(
                height: 3,
                decoration: BoxDecoration(
                  gradient: accentGradient,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    // Type icon
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: accentGradient,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        isBill
                            ? Icons.receipt_long_rounded
                            : Icons.notifications_active_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Type label
                          Text(
                            r.displayType,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          // Table
                          Row(
                            children: [
                              Icon(
                                hasTable
                                    ? Icons.table_restaurant_rounded
                                    : Icons.location_on_rounded,
                                size: 13,
                                color: hasTable
                                    ? accentColor
                                    : Colors.white.withValues(alpha: 0.4),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  r.tableDisplay,
                                  style: GoogleFonts.poppins(
                                    fontSize: hasTable ? 13 : 12,
                                    fontWeight: hasTable
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: hasTable
                                        ? accentColor
                                        : Colors.white.withValues(alpha: 0.5),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          // Time
                          if (created != null) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                if (isUrgent)
                                  Container(
                                    width: 7,
                                    height: 7,
                                    margin: const EdgeInsets.only(right: 5),
                                    decoration: BoxDecoration(
                                      color: AppTheme.alert,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.alert.withValues(
                                            alpha: 0.6,
                                          ),
                                          blurRadius: 6,
                                        ),
                                      ],
                                    ),
                                  ),
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 12,
                                  color: isUrgent
                                      ? AppTheme.alert
                                      : Colors.white.withValues(alpha: 0.4),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  timeago.format(created),
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: isUrgent
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isUrgent
                                        ? AppTheme.alert
                                        : Colors.white.withValues(alpha: 0.4),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Action button
                    _isCompleting
                        ? Container(
                            width: 44,
                            height: 44,
                            alignment: Alignment.center,
                            child: const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.primary,
                              ),
                            ),
                          )
                        : Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () async {
                                setState(() => _isCompleting = true);
                                await widget.onDone();
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppTheme.success.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppTheme.success.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.check_rounded,
                                  color: AppTheme.success,
                                  size: 22,
                                ),
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
    );
  }
}
