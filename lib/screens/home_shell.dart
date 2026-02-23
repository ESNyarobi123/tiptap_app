import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../main.dart' show navigatorKey;
import '../models/dashboard_model.dart';
import '../providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../services/call_service.dart';
import 'dashboard_screen.dart';
import 'incoming_call_screen.dart';
import 'me_screen.dart';
import 'orders_screen.dart';
import 'payslip_screen.dart';
import 'requests_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  int _index = 0;
  bool _callServiceStarted = false;
  bool _isShowingCallScreen = false;

  static const _screens = [
    DashboardScreen(),
    OrdersScreen(),
    RequestsScreen(),
    PayslipScreen(),
    MeScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initCallService();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Stop the call service when HomeShell is disposed
    try {
      final callService = context.read<CallService>();
      callService.stop();
    } catch (_) {}
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final callService = context.read<CallService>();
    if (state == AppLifecycleState.resumed) {
      // App came to foreground — restart polling
      final api = context.read<AuthProvider>().api;
      callService.start(api);
    } else if (state == AppLifecycleState.paused) {
      // App went to background — we keep polling (service continues)
      // In a future version, we could use flutter_background_service here
    }
  }

  void _initCallService() {
    if (_callServiceStarted) return;
    _callServiceStarted = true;

    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) return;

    final callService = context.read<CallService>();

    // Set up the callback for when a new call is detected
    callService.onIncomingCall = (call) {
      _showIncomingCallScreen(call);
    };

    // Start polling
    callService.start(auth.api);
  }

  /// Show the full-screen incoming call screen
  void _showIncomingCallScreen(PendingRequest call) {
    if (_isShowingCallScreen) return; // Don't stack
    _isShowingCallScreen = true;

    // Use the global navigator key to push over everything
    navigatorKey.currentState
        ?.push<String>(
          PageRouteBuilder(
            opaque: false,
            barrierDismissible: false,
            pageBuilder: (context, animation, secondaryAnimation) {
              return IncomingCallScreen(call: call);
            },
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        )
        .then((result) {
          _isShowingCallScreen = false;
          if (result == 'accepted') {
            // Navigate to the Calls/Requests tab
            if (mounted) {
              setState(() => _index = 2);
            }
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A0614), Color(0xFF120D1F), Color(0xFF0F172A)],
          ),
        ),
        child: IndexedStack(index: _index, children: _screens),
      ),
      bottomNavigationBar: _buildGlassNavBar(),
    );
  }

  Widget _buildGlassNavBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.12),
                  Colors.white.withValues(alpha: 0.06),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _navItem(0, Icons.home_rounded, 'Home'),
                  _navItem(1, Icons.receipt_long_rounded, 'Orders'),
                  _navItemWithBadge(
                    2,
                    Icons.notifications_active_rounded,
                    'Calls',
                  ),
                  _navItem(3, Icons.account_balance_wallet_rounded, 'Payroll'),
                  _navItem(4, Icons.person_rounded, 'Me'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItemWithBadge(int i, IconData icon, String label) {
    final active = _index == i;
    final pendingCount =
        context.watch<DashboardProvider>().data?.pendingRequests.length ?? 0;
    final hasBadge = pendingCount > 0;
    return _NavItemWidget(
      active: active,
      icon: icon,
      label: label,
      hasBadge: hasBadge,
      onTap: () => setState(() => _index = i),
    );
  }

  Widget _navItem(int i, IconData icon, String label) {
    final active = _index == i;
    return _NavItemWidget(
      active: active,
      icon: icon,
      label: label,
      hasBadge: false,
      onTap: () => setState(() => _index = i),
    );
  }
}

class _NavItemWidget extends StatelessWidget {
  final bool active;
  final IconData icon;
  final String label;
  final bool hasBadge;
  final VoidCallback onTap;

  const _NavItemWidget({
    required this.active,
    required this.icon,
    required this.label,
    required this.hasBadge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              gradient: active
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primary.withValues(alpha: 0.3),
                        AppTheme.secondary.withValues(alpha: 0.2),
                      ],
                    )
                  : null,
              borderRadius: BorderRadius.circular(20),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      icon,
                      size: 18,
                      color: active
                          ? AppTheme.primary
                          : Colors.white.withValues(alpha: 0.5),
                    ),
                    if (hasBadge)
                      Positioned(
                        top: -4,
                        right: -8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppTheme.alert,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.surface,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.alert.withValues(alpha: 0.8),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: active
                        ? AppTheme.primary
                        : Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
