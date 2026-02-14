import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/glass_card.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  List<MenuCategory> _categories = [];
  List<MenuItemData> _allItems = [];
  bool _loading = false;
  String _query = '';
  int _selectedCategoryIndex = 0;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final api = context.read<AuthProvider>().api;
      final res = await api.getMenu();
      if (mounted) {
        setState(() {
          _categories = res.categories;
          _allItems = res.items;
        });
      }
    } catch (e) {
      debugPrint('Menu load error: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  List<MenuItemData> get _filteredItems {
    if (_query.isEmpty) {
      if (_categories.isEmpty) return _allItems;
      final cat = _categories[_selectedCategoryIndex];
      return cat.items;
    }
    final q = _query.toLowerCase();
    return _allItems.where((i) => (i.name).toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text(
          'Menu Card',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: TextField(
                    onChanged: (v) => setState(() => _query = v),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search food... (e.g. Savanna)',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                      filled: true,
                      fillColor: AppTheme.surfaceLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
                if (_categories.isNotEmpty && _query.isEmpty)
                  Container(
                    height: 48,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _categories.length,
                      itemBuilder: (_, i) {
                        final active = _selectedCategoryIndex == i;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () =>
                                  setState(() => _selectedCategoryIndex = i),
                              borderRadius: BorderRadius.circular(12),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  gradient: active
                                      ? AppTheme.primaryGradient
                                      : null,
                                  color: active ? null : AppTheme.surfaceLight,
                                  borderRadius: BorderRadius.circular(12),
                                  border: active
                                      ? null
                                      : Border.all(color: AppTheme.glassBorder),
                                ),
                                child: Center(
                                  child: Text(
                                    _categories[i].name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: active
                                          ? Colors.white
                                          : Colors.white70,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                Expanded(
                  child: _filteredItems.isEmpty
                      ? Center(
                          child: Text(
                            'No items found',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 16,
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          itemCount: _filteredItems.length,
                          itemBuilder: (_, i) {
                            final item = _filteredItems[i];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildMenuItem(item),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildMenuItem(MenuItemData item) {
    final available = item.isAvailable;
    final initials = item.name.length >= 2
        ? item.name.substring(0, 2).toUpperCase()
        : item.name.toUpperCase();

    return GlassCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: available ? AppTheme.primaryGradient : null,
              color: available ? null : Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: item.image != null && item.image!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      item.image!,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Text(
                        initials,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                : Text(
                    initials,
                    style: TextStyle(
                      color: available ? Colors.white : Colors.white54,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontSize: 15,
                          decoration: available
                              ? null
                              : TextDecoration.lineThrough,
                          decorationColor: AppTheme.error,
                        ),
                      ),
                    ),
                    Text(
                      'Tsh ${NumberFormat('#,###').format(item.price)}',
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                if (item.description != null && item.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      item.description!,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: available
                            ? AppTheme.success.withValues(alpha: 0.2)
                            : Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        available ? 'Available' : 'SOLD OUT',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: available ? AppTheme.success : Colors.white54,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${item.preparationTime} min',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
