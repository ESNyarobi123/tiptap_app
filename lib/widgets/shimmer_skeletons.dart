import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Base colors for dark-themed shimmer
const _baseColor = Color(0xFF1E1A2E);
const _highlightColor = Color(0xFF2A2540);

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  CORE BUILDING BLOCKS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Wraps children in a shimmer animation
Widget shimmerWrap({required Widget child}) {
  return Shimmer.fromColors(
    baseColor: _baseColor,
    highlightColor: _highlightColor,
    child: child,
  );
}

/// Rounded rectangle placeholder
Widget _bone({double? width, double height = 14, double radius = 8}) {
  return Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}

/// Circle placeholder (avatars, icons)
Widget _circle(double size) {
  return Container(
    width: size,
    height: size,
    decoration: const BoxDecoration(
      color: Colors.white,
      shape: BoxShape.circle,
    ),
  );
}

/// Rounded square placeholder (icon boxes)
Widget _roundedSquare(double size, {double radius = 14}) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  DASHBOARD SKELETON
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Full dashboard skeleton: stats card + urgent section + marketplace cards
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return shimmerWrap(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats hero card
            _statsCardSkeleton(),
            const SizedBox(height: 24),
            // Section title
            _bone(width: 140, height: 16),
            const SizedBox(height: 14),
            // 3 order cards
            ...List.generate(
              3,
              (i) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _orderCardSkeleton(),
              ),
            ),
            const SizedBox(height: 24),
            // Another section title
            _bone(width: 180, height: 16),
            const SizedBox(height: 14),
            // 2 more cards
            ...List.generate(
              2,
              (i) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _orderCardSkeleton(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statsCardSkeleton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Stats row: 4 items
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              4,
              (_) => Column(
                children: [
                  _bone(width: 40, height: 24, radius: 6),
                  const SizedBox(height: 6),
                  _bone(width: 55, height: 10),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Today's orders bar
          Row(
            children: [
              _roundedSquare(40, radius: 10),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _bone(width: 100, height: 12),
                    const SizedBox(height: 6),
                    _bone(width: 60, height: 10),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _orderCardSkeleton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _roundedSquare(48, radius: 14),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bone(width: 120, height: 14),
                const SizedBox(height: 8),
                _bone(width: 80, height: 10),
              ],
            ),
          ),
          _bone(width: 60, height: 24, radius: 8),
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  SALARY SLIPS SKELETON
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class SalarySlipsSkeleton extends StatelessWidget {
  const SalarySlipsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return shimmerWrap(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        physics: const NeverScrollableScrollPhysics(),
        children: [
          // Summary card
          _summaryCardSkeleton(),
          const SizedBox(height: 16),
          // 4 slip cards
          ...List.generate(
            4,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _slipCardSkeleton(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCardSkeleton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _roundedSquare(48, radius: 14),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bone(width: 90, height: 10),
                const SizedBox(height: 8),
                _bone(width: 150, height: 22, radius: 6),
              ],
            ),
          ),
          _bone(width: 50, height: 20, radius: 8),
        ],
      ),
    );
  }

  Widget _slipCardSkeleton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Month badge
          _roundedSquare(48, radius: 14),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bone(width: 100, height: 14),
                const SizedBox(height: 6),
                _bone(width: 50, height: 10),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _bone(width: 90, height: 14),
              const SizedBox(height: 6),
              _bone(width: 40, height: 10),
            ],
          ),
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  WORK HISTORY SKELETON
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class WorkHistorySkeleton extends StatelessWidget {
  const WorkHistorySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return shimmerWrap(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        physics: const NeverScrollableScrollPhysics(),
        children: List.generate(
          3,
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _historyCardSkeleton(),
          ),
        ),
      ),
    );
  }

  Widget _historyCardSkeleton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _roundedSquare(42, radius: 12),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _bone(width: 140, height: 14),
                    const SizedBox(height: 6),
                    _bone(width: 100, height: 10),
                  ],
                ),
              ),
              _bone(width: 55, height: 22, radius: 8),
            ],
          ),
          const SizedBox(height: 14),
          // Info pills
          Row(
            children: [
              _bone(width: 80, height: 22, radius: 8),
              const SizedBox(width: 8),
              _bone(width: 130, height: 22, radius: 8),
            ],
          ),
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  UNLINKED DASHBOARD SKELETON
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class UnlinkedDashboardSkeleton extends StatelessWidget {
  const UnlinkedDashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return shimmerWrap(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero code card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  _circle(72),
                  const SizedBox(height: 16),
                  _bone(width: 120, height: 12),
                  const SizedBox(height: 12),
                  _bone(width: 200, height: 32, radius: 14),
                  const SizedBox(height: 20),
                  _bone(height: 60, radius: 12),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Mini stats
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  4,
                  (_) => Column(
                    children: [
                      _bone(width: 40, height: 24, radius: 6),
                      const SizedBox(height: 6),
                      _bone(width: 55, height: 10),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  ORDERS SKELETON (My Orders tab)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class OrdersSkeleton extends StatelessWidget {
  const OrdersSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return shimmerWrap(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        physics: const NeverScrollableScrollPhysics(),
        children: List.generate(
          5,
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _orderCardSkeleton(),
          ),
        ),
      ),
    );
  }

  Widget _orderCardSkeleton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _roundedSquare(44, radius: 12),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _bone(width: 110, height: 14),
                    const SizedBox(height: 6),
                    _bone(width: 70, height: 10),
                  ],
                ),
              ),
              _bone(width: 65, height: 24, radius: 8),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _bone(width: 80, height: 18, radius: 6),
              const SizedBox(width: 8),
              _bone(width: 60, height: 18, radius: 6),
              const Spacer(),
              _bone(width: 50, height: 18, radius: 6),
            ],
          ),
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  REQUESTS / CALLS SKELETON
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class RequestsSkeleton extends StatelessWidget {
  const RequestsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => shimmerWrap(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, index == 0 ? 16 : 0, 16, 12),
            child: _requestCardSkeleton(),
          ),
        ),
        childCount: 4,
      ),
    );
  }

  Widget _requestCardSkeleton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _circle(44),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bone(width: 100, height: 14),
                const SizedBox(height: 6),
                _bone(width: 140, height: 10),
                const SizedBox(height: 8),
                _bone(width: 80, height: 10),
              ],
            ),
          ),
          _bone(width: 70, height: 32, radius: 10),
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  TIPS SKELETON
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class TipsSkeleton extends StatelessWidget {
  const TipsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return shimmerWrap(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Total tips card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _bone(width: 110, height: 12),
                  const SizedBox(height: 10),
                  _bone(width: 160, height: 28, radius: 6),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Recent tips label
            _bone(width: 100, height: 14),
            const SizedBox(height: 14),
            // Tip cards
            ...List.generate(
              5,
              (i) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _tipCardSkeleton(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tipCardSkeleton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _circle(36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bone(width: 100, height: 12),
                const SizedBox(height: 6),
                _bone(width: 70, height: 10),
              ],
            ),
          ),
          _bone(width: 70, height: 18, radius: 6),
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  RATINGS SKELETON
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class RatingsSkeleton extends StatelessWidget {
  const RatingsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return shimmerWrap(
      child: ListView(
        padding: const EdgeInsets.all(16),
        physics: const NeverScrollableScrollPhysics(),
        children: List.generate(
          5,
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ratingCardSkeleton(),
          ),
        ),
      ),
    );
  }

  Widget _ratingCardSkeleton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _circle(36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _bone(width: 90, height: 12),
                    const SizedBox(height: 6),
                    _bone(width: 60, height: 10),
                  ],
                ),
              ),
              // Stars
              Row(
                children: List.generate(
                  5,
                  (_) => Padding(
                    padding: const EdgeInsets.only(right: 2),
                    child: _circle(14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _bone(height: 10),
          const SizedBox(height: 4),
          _bone(width: 200, height: 10),
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  MENU SKELETON
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class MenuSkeleton extends StatelessWidget {
  const MenuSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return shimmerWrap(
      child: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: _bone(height: 48, radius: 14),
          ),
          // Category chips
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: List.generate(
                5,
                (i) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _bone(
                    width: 70 + (i % 3) * 15,
                    height: 32,
                    radius: 16,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Menu items
          Expanded(
            child: ListView(
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              children: List.generate(
                6,
                (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _menuItemSkeleton(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuItemSkeleton() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _roundedSquare(56, radius: 12),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bone(width: 130, height: 14),
                const SizedBox(height: 6),
                _bone(width: 80, height: 10),
              ],
            ),
          ),
          _bone(width: 60, height: 20, radius: 6),
        ],
      ),
    );
  }
}
