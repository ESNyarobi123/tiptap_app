import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/shimmer_skeletons.dart';

class RatingsScreen extends StatefulWidget {
  const RatingsScreen({super.key});

  @override
  State<RatingsScreen> createState() => _RatingsScreenState();
}

class _RatingsScreenState extends State<RatingsScreen> {
  // ... (state vars and methods remain unchanged, just updating build method styles)
  List<dynamic> _list = [];
  bool _loading = false;

  Future<void> _load() async {
    // ... (logic remains)
    if (!mounted) return; // Add mount check
    setState(() => _loading = true);
    try {
      final api = context.read<AuthProvider>().api;
      final res = await api.getRatings(
        page: 1,
      ); // Assuming this returns populated model
      if (mounted) setState(() => _list = res.data);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text(
          'My Ratings',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const RatingsSkeleton()
          : _list.isEmpty
          ? Center(
              child: Text(
                'No ratings yet',
                style: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              color: AppTheme.primary,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _list.length,
                itemBuilder: (_, i) {
                  final r = _list[i];
                  // Assuming r is a RatingItem model with these fields
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              ...List.generate(
                                5,
                                (j) => Icon(
                                  j < (r.rating ?? 0)
                                      ? Icons.star_rounded
                                      : Icons.star_outline_rounded,
                                  color: Colors.amber,
                                  size: 20,
                                ),
                              ),
                              const Spacer(),
                              if (r.tableNumber != null)
                                Text(
                                  'Table ${r.tableNumber}',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                          if (r.comment != null &&
                              r.comment.toString().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                '"${r.comment}"',
                                style: GoogleFonts.poppins(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontStyle: FontStyle.italic,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          if (r.createdAt != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              r.createdAt
                                  .toString(), // Formatting date would be better but keeping simple
                              style: GoogleFonts.poppins(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
