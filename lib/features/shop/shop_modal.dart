import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import './shop_item.dart';
import './shop_service.dart';

void showShopModal({
  required BuildContext context,
  required Future<bool> Function(ShopItem, GlobalKey) onItemTap,
  int coins = 0,
}) {
  showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) => _ShopModal(
      coins: coins,
      onItemTap: onItemTap,
    ),
  );
}

class _ShopModal extends StatelessWidget {
  const _ShopModal({
    required this.coins,
    required this.onItemTap,
  });

  final int coins;
  final Future<bool> Function(ShopItem, GlobalKey) onItemTap;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = screenSize.width < 600 ? screenSize.width * 0.9 : 520.0;
    final dialogHeight =
        screenSize.height < 760 ? screenSize.height * 0.72 : 620.0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: FutureBuilder<List<ShopItem>>(
          future: ShopService.loadShopAssets(),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const _ShopLoadingCard();
            }

            if (snapshot.hasError) {
              return _ShopMessageCard(
                title: 'Shop unavailable',
                message: 'We could not load the shop items right now.',
              );
            }

            final items = snapshot.data ?? <ShopItem>[];
            if (items.isEmpty) {
              return _ShopMessageCard(
                title: 'Nothing in stock',
                message: 'The shelves are empty for now. Check back soon.',
              );
            }

            return _ShopModalCard(
              coins: coins,
              items: items,
              onItemTap: onItemTap,
            );
          },
        ),
      ),
    );
  }
}

class _ShopLoadingCard extends StatelessWidget {
  const _ShopLoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Material(
      color: Colors.white,
      borderRadius: BorderRadius.all(Radius.circular(28)),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _ShopMessageCard extends StatelessWidget {
  const _ShopMessageCard({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.all(Radius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShopModalCard extends StatelessWidget {
  const _ShopModalCard({
    required this.coins,
    required this.items,
    required this.onItemTap,
  });

  final int coins;
  final List<ShopItem> items;
  final Future<bool> Function(ShopItem, GlobalKey) onItemTap;

  static const List<_ShopCategory> _categories = [
    _ShopCategory(
      tag: 'food',
      label: 'Food',
      icon: Icons.restaurant_rounded,
      accent: Color(0xFFFF7043),
      soft: Color(0xFFFFF0EA),
    ),
    _ShopCategory(
      tag: 'drinks',
      label: 'Drinks',
      icon: Icons.local_drink_rounded,
      accent: Color(0xFF2196F3),
      soft: Color(0xFFE3F2FD),
    ),
    _ShopCategory(
      tag: 'fun',
      label: 'Fun',
      icon: Icons.toys_rounded,
      accent: Color(0xFF7E57C2),
      soft: Color(0xFFF1EBFF),
    ),
    _ShopCategory(
      tag: 'medicine',
      label: 'Medicine',
      icon: Icons.medical_services_rounded,
      accent: Color(0xFF26A69A),
      soft: Color(0xFFE6F7F5),
    ),
    _ShopCategory(
      tag: 'cosmetic',
      label: 'Cosmetic',
      icon: FontAwesomeIcons.glasses,
      accent: Color(0xFFE91E8C),
      soft: Color(0xFFFDE8F3),
    ),
  ];

  Widget _buildTab(
      _ShopCategory category, int index, TabController controller) {
    final isActive = controller.index == index;

    return Tab(
      icon: Icon(
        category.icon,
        size: isActive ? 24 : 18,
        color: isActive ? category.accent : Colors.grey.shade500,
      ),
      text: isActive ? category.label : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeCategories = _categories
        .where((category) => items.any((item) => item.tag == category.tag))
        .toList();

    return DefaultTabController(
      length: activeCategories.length,
      child: Material(
        color: Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(28)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            _ShopHeader(coins: coins),
            Container(
              color: const Color(0xFFFFFBF7),
              child: Builder(
                builder: (context) {
                  final controller = DefaultTabController.of(context);
                  return AnimatedBuilder(
                    animation: controller,
                    builder: (context, child) {
                      return TabBar(
                        isScrollable: true,
                        labelStyle: TextStyle(color: Color(0xFF2C1F17)),
                        unselectedLabelStyle:
                            TextStyle(color: Color(0xFFFFFBF7)),
                        indicatorColor: const Color.fromARGB(255, 255, 215, 64),
                        tabs: activeCategories.asMap().entries.map((entry) {
                          final index = entry.key;
                          final category = entry.value;
                          return _buildTab(category, index, controller);
                        }).toList(),
                      );
                    },
                  );
                },
              ),
            ),
            Expanded(
              child: TabBarView(
                children: activeCategories.map((category) {
                  final categoryItems =
                      items.where((item) => item.tag == category.tag).toList();
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: categoryItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = categoryItems[index];
                      return _ShopItemCard(
                        item: item,
                        accent: category.accent,
                        soft: category.soft,
                        onTap: (itemKey) async {
                          await onItemTap(item, itemKey);
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                      );
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShopHeader extends StatelessWidget {
  const _ShopHeader({required this.coins});

  final int coins;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 14, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.fromARGB(255, 220, 20, 60),
            Color.fromARGB(255, 136, 8, 8)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Meowket',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Pick something nice for your cat.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.monetization_on_rounded,
                  color: Colors.amberAccent,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  '$coins',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            tooltip: 'Close shop',
          ),
        ],
      ),
    );
  }
}

class _ShopItemCard extends StatelessWidget {
  const _ShopItemCard({
    required this.item,
    required this.accent,
    required this.soft,
    required this.onTap,
  });

  final ShopItem item;
  final Color accent;
  final Color soft;
  final Future<void> Function(GlobalKey) onTap;

  @override
  Widget build(BuildContext context) {
    final itemKey = GlobalKey();

    return Material(
      color: soft,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: () => onTap(itemKey),
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                key: itemKey,
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: _buildItemVisual(item, accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2C1F17),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (item.stats.hunger > 0)
                          _StatChip(
                            label: 'Food ${_signed(item.stats.hunger)}',
                            background: Colors.white.withValues(alpha: 0.75),
                            foreground: const Color(0xFF8D5A2B),
                          ),
                        if (item.stats.health > 0)
                          _StatChip(
                              label: 'Health ${_signed(item.stats.health)}',
                              background: Colors.white.withValues(alpha: 0.75),
                              foreground: const Color(0xFF2E7D32)),
                        if (item.stats.happiness > 0)
                          _StatChip(
                              label:
                                  'Happiness ${_signed(item.stats.happiness)}',
                              background: Colors.white.withValues(alpha: 0.75),
                              foreground: const Color(0xFF7E57C2)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _StatChip(
                label: '${item.price}',
                background: Colors.white,
                foreground: accent,
                coin: const Icon(
                  Icons.monetization_on_rounded,
                  color: Colors.amberAccent,
                  size: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildItemVisual(ShopItem item, Color accent) {
    if (item.image != null && item.image!.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: Image.asset(
          item.image!,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Icon(
            _iconForTag(item.tag),
            color: accent,
            size: 28,
          ),
        ),
      );
    }

    return Icon(
      _iconForTag(item.tag),
      color: accent,
      size: 28,
    );
  }

  static IconData _iconForTag(String tag) {
    switch (tag) {
      case 'food':
        return Icons.lunch_dining_rounded;
      case 'drinks':
        return Icons.local_drink_rounded;
      case 'medicine':
        return Icons.medication_rounded;
      case 'fun':
        return Icons.sports_esports_rounded;
      case 'cosmetic':
        return Icons.checkroom_rounded;
      default:
        return Icons.inventory_2_rounded;
    }
  }

  static String _signed(int value) {
    if (value > 0) return '+$value';
    return '$value';
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.background,
    required this.foreground,
    this.coin,
  });

  final String label;
  final Color background;
  final Color foreground;
  final Icon? coin;

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: foreground,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (coin != null) ...[
              const SizedBox(width: 4),
              coin!,
            ],
          ],
        ));
  }
}

class _ShopCategory {
  const _ShopCategory({
    required this.tag,
    required this.label,
    required this.icon,
    required this.accent,
    required this.soft,
  });

  final String tag;
  final String label;
  final IconData icon;
  final Color accent;
  final Color soft;
}
