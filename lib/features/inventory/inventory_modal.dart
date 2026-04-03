import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import './inventory_item.dart';
import './inventory_service.dart';

void showInventoryModal({
  required BuildContext context,
}) {
  showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) => const _InventoryModal(),
  );
}

class _InventoryModal extends StatelessWidget {
  const _InventoryModal();

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = screenSize.width < 600 ? screenSize.width * 0.9 : 520.0;
    final dialogHeight =
        screenSize.height < 760 ? screenSize.height * 0.82 : 660.0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: FutureBuilder<List<InventoryItem>>(
          future: InventoryService.instance.fetchInventory(),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const _InventoryLoadingCard();
            }

            final items = snapshot.data ?? <InventoryItem>[];
            if (items.isEmpty) {
              return const _InventoryEmptyCard();
            }

            return _InventoryModalCard(items: items);
          },
        ),
      ),
    );
  }
}

class _InventoryLoadingCard extends StatelessWidget {
  const _InventoryLoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Material(
      color: Colors.white,
      borderRadius: BorderRadius.all(Radius.circular(28)),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

// if your cat has, nothing this shows
class _InventoryEmptyCard extends StatelessWidget {
  const _InventoryEmptyCard();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.all(Radius.circular(28)),
      child: Column(
        children: [
          const _InventoryHeader(),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined,
                      size: 56, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'Your Pawket is empty!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Visit the Meowket to stock up 🛍️',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// every icon here is copied directly from _ShopItemCard._iconForTag(), so the inventory card will always show the SAME icon
// the accent + background colors also match the shop's _categories list, so switching between shop and inventory feels the same

class _TagStyle {
  final IconData icon;
  final Color accent;
  final Color soft;
  const _TagStyle(
      {required this.icon, required this.accent, required this.soft});
}

// const map so flutter never rebuilds this unnecessarily
const Map<String, _TagStyle> _tagStyles = {
  // food — Icons.lunch_dining_rounded, matches _iconForTag in shop_modal.dart
  'food': _TagStyle(
    icon: Icons.lunch_dining_rounded,
    accent: Color(0xFFFF7043),
    soft: Color(0xFFFFF0EA),
  ),
  // drinks — Icons.local_drink_rounded, matches _iconForTag in shop_modal.dart
  'drinks': _TagStyle(
    icon: Icons.local_drink_rounded,
    accent: Color(0xFF2196F3),
    soft: Color(0xFFE3F2FD),
  ),
  // fun — Icons.sports_esports_rounded, matches _iconForTag in shop_modal.dart
  'fun': _TagStyle(
    icon: Icons.sports_esports_rounded,
    accent: Color(0xFF7E57C2),
    soft: Color(0xFFF1EBFF),
  ),
  // medicine — Icons.medication_rounded, matches _iconForTag in shop_modal.dart
  'medicine': _TagStyle(
    icon: Icons.medication_rounded,
    accent: Color(0xFF26A69A),
    soft: Color(0xFFE6F7F5),
  ),
  //  cosmetic — FontAwesomeIcons.glasses, matches _iconForTag in shop_modal.dart
  'cosmetic': _TagStyle(
    icon: FontAwesomeIcons.glasses,
    accent: Color(0xFFE91E8C),
    soft: Color(0xFFFDE8F3),
  ),
};

// fallback for any unknown tags — grey + generic box icon, won't crash
_TagStyle _styleFor(String tag) =>
    _tagStyles[tag] ??
    const _TagStyle(
      icon: Icons.inventory_2_rounded,
      accent: Color(0xFF78909C),
      soft: Color(0xFFECEFF1),
    );

// we sort everything by quantity high → low so your most stocked items
// show up first — feels more useful than random order

class _InventoryModalCard extends StatelessWidget {
  const _InventoryModalCard({required this.items});
  final List<InventoryItem> items;

  @override
  Widget build(BuildContext context) {
    final groupedItems = _groupItemsByCategory(items);

    return Material(
      color: const Color(0xFFFAF8F5),
      borderRadius: const BorderRadius.all(Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          const _InventoryHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < groupedItems.length; i++) ...[
                    if (i > 0) const SizedBox(height: 20),
                    _CategoryDivider(tag: groupedItems[i].$1),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.8,
                      ),
                      itemCount: groupedItems[i].$2.length,
                      itemBuilder: (context, index) =>
                          _InventoryCard(inv: groupedItems[i].$2[index]),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

List<(String, List<InventoryItem>)> _groupItemsByCategory(
    List<InventoryItem> items) {
  const categoryOrder = ['food', 'drinks', 'fun', 'medicine', 'cosmetic'];
  final grouped = <String, List<InventoryItem>>{};

  for (final item in items) {
    grouped.putIfAbsent(item.item.tag, () => []).add(item);
  }

  for (final entry in grouped.values) {
    entry.sort((a, b) => b.quantity.compareTo(a.quantity));
  }

  final orderedTags = [
    ...categoryOrder.where(grouped.containsKey),
    ...grouped.keys.where((tag) => !categoryOrder.contains(tag)).toList()
      ..sort(),
  ];

  return orderedTags.map((tag) => (tag, grouped[tag]!)).toList();
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: color,
        letterSpacing: 1.1,
      ),
    );
  }
}

class _CategoryDivider extends StatelessWidget {
  const _CategoryDivider({required this.tag});

  final String tag;

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(tag);
    final label =
        tag.isEmpty ? 'Other' : '${tag[0].toUpperCase()}${tag.substring(1)}';

    return Row(
      children: [
        _SectionLabel(label: label, color: style.accent),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 1.5,
            decoration: BoxDecoration(
              color: style.accent.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ],
    );
  }
}

// two-part layout like the shop:
class _InventoryCard extends StatelessWidget {
  const _InventoryCard({required this.inv});
  final InventoryItem inv;

  @override
  Widget build(BuildContext context) {
    final ts = _styleFor(inv.item.tag);

    // resolve the color set based on warm vs cool style
    final Color iconBg = ts.soft;
    final Color iconColor = ts.accent;
    final Color textColor = const Color(0xFF3E2723);
    final Color qtyBg = ts.accent.withValues(alpha: 0.12);
    final Color qtyColor = ts.accent;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        // soft shadow so the cards feel lifted off the background, not flat
        boxShadow: [
          BoxShadow(
            color: ts.accent.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // takes up the majority of the card, image or icon centered inside and if the item has an image path (like assets/images/apple.png) we show
          // if the image fails to load or there's no path, falls back to the icon
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: Center(
                child: (inv.item.image != null && inv.item.image!.isNotEmpty)
                    ? Padding(
                        padding: const EdgeInsets.all(10),
                        child: Image.asset(
                          inv.item.image!,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) =>
                              Icon(ts.icon, size: 30, color: iconColor),
                        ),
                      )
                    : Icon(ts.icon, size: 30, color: iconColor),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 7, 8, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        inv.item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: qtyBg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'x${inv.quantity}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: qtyColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (inv.item.stats.hunger > 0)
                      _StatChip(
                        label: 'Food ${_signed(inv.item.stats.hunger)}',
                        background: Colors.white.withValues(alpha: 0.75),
                        foreground: const Color(0xFF8D5A2B),
                      ),
                    if (inv.item.stats.health > 0)
                      _StatChip(
                        label: 'Health ${_signed(inv.item.stats.health)}',
                        background: Colors.white.withValues(alpha: 0.75),
                        foreground: const Color(0xFF2E7D32)
                      ),
                    if (inv.item.stats.happiness > 0)
                      _StatChip(
                        label: 'Happiness ${_signed(inv.item.stats.happiness)}',
                        background: Colors.white.withValues(alpha: 0.75),
                        foreground:const Color(0xFF7E57C2)
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
    static String _signed(int value) {
    if (value > 0) return '+$value';
    return '$value';
  }
}

//inventory header
class _InventoryHeader extends StatelessWidget {
  const _InventoryHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 14, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.fromARGB(255, 73, 20, 220),
            Color.fromARGB(255, 215, 69, 24)
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
                  'Pawket',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  "your cat's belongings 🐾",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

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
          ],
        ));
  }
}
