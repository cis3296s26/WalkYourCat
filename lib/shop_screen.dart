import 'package:flutter/material.dart';

// holds all the info for each tab: name, icon, and the two colors we use
class ShopCategory {
  final String name;
  final IconData icon;
  final Color accent;  // the bold main color
  final Color softBg;  // the light pastel background used on cards

  const ShopCategory({
    required this.name,
    required this.icon,
    required this.accent,
    required this.softBg,
  });
}

// the 5 categories in our shop, each with their own icon and colors
const shopTabs = [
  ShopCategory(
    name: 'Food',
    icon: Icons.restaurant_rounded,
    accent: Color(0xFFFF6B35),
    softBg: Color(0xFFFFF0EA),
  ),
  ShopCategory(
    name: 'Drink',
    icon: Icons.local_drink_rounded,
    accent: Color(0xFF2196F3),
    softBg: Color(0xFFE8F4FD),
  ),
  ShopCategory(
    name: 'Toys',
    icon: Icons.toys_rounded,
    accent: Color(0xFF9C27B0),
    softBg: Color(0xFFF3E8FA),
  ),
  ShopCategory(
    name: 'Cosmetic',
    icon: Icons.auto_awesome_rounded,
    accent: Color(0xFFE91E8C),
    softBg: Color(0xFFFDE8F3),
  ),
  ShopCategory(
    name: 'Medicine',
    icon: Icons.medical_services_rounded,
    accent: Color(0xFF00897B),
    softBg: Color(0xFFE0F4F2),
  ),
];

// the main shop screen with header, tabs, and item grid
class ShopScreen extends StatefulWidget {
  final int coins;
  const ShopScreen({super.key, this.coins = 0});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen>
    with SingleTickerProviderStateMixin {
  late TabController tabController;

  @override
  void initState() {
    super.initState();
    // set up tabs — one per category
    tabController = TabController(length: shopTabs.length, vsync: this);
    // rebuild when user taps a different tab so the header color updates
    tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // which tab is currently open
    final activeTab = shopTabs[tabController.index];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: NestedScrollView(
        // NestedScrollView lets the header collapse while the grid scrolls
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 140,   // how tall the header is when expanded
            floating: false,
            pinned: true,          // keeps the bar visible when scrolled up
            backgroundColor: activeTab.accent,
            foregroundColor: Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              // collapseMode.none so our custom header fills the space
              collapseMode: CollapseMode.none,
              background: ShopTopBanner(coins: widget.coins, tab: activeTab),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(52),
              child: CategoryTabs(controller: tabController),
            ),
          ),
        ],
        body: TabBarView(
          controller: tabController,
          children: shopTabs.map((tab) => ItemGrid(tab: tab)).toList(),
        ),
      ),
    );
  }
}

// the top banner with the shop title and coin balance, which changes color based on the active tab
class ShopTopBanner extends StatelessWidget {
  final int coins;
  final ShopCategory tab;
  const ShopTopBanner({super.key, required this.coins, required this.tab});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      // gradient shifts as you switch tabs
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [tab.accent, tab.accent.withOpacity(0.72)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      // top padding accounts for the status bar height
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 6,
        20,
        12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // left side: shop icon + title + subtitle
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.storefront_rounded,
                      color: Colors.white, size: 22),
                  const SizedBox(width: 8),
                  const Text(
                    'Shop', // will be changed later once we pick a name for it
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Treat your cat 🐾',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.78),
                  fontSize: 12,
                ),
              ),
            ],
          ),

          const Spacer(),

          // right side: balance 
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
            decoration: BoxDecoration(
              // frosted glass look
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                  color: Colors.white.withOpacity(0.4), width: 1.2),
            ),
            child: Row(
              children: [
                // gold coin circle
                Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFD700),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.monetization_on,
                      color: Color(0xFFB8860B), size: 14),
                ),
                const SizedBox(width: 7),
                // how many coins the user has
                Text(
                  '$coins',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'coins',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// scrollable category tabs below the header, with icons and active/inactive colors
class CategoryTabs extends StatelessWidget {
  final TabController controller;
  const CategoryTabs({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,  // white strip below the colorful header
      child: TabBar(
        controller: controller,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        // underline indicator uses the active tab's accent color
        indicatorColor: shopTabs[controller.index].accent,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.label,
        labelPadding: const EdgeInsets.symmetric(horizontal: 16),
        tabs: shopTabs.map((tab) {
          final isActive = controller.index == shopTabs.indexOf(tab);
          return Tab(
            height: 48,
            child: Row(
              children: [
                Icon(
                  tab.icon,
                  size: 16,
                  // active tab gets full color, others go grey
                  color: isActive ? tab.accent : Colors.grey.shade400,
                ),
                const SizedBox(width: 6),
                Text(
                  tab.name,
                  style: TextStyle(
                    color: isActive ? tab.accent : Colors.grey.shade500,
                    fontWeight:
                        isActive ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// 2 rows × 2 columns of placeholder cards for each category, all saying "coming soon" for now
class ItemGrid extends StatelessWidget {
  final ShopCategory tab;
  const ItemGrid({super.key, required this.tab});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,      // 2 cards per row
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.88, // slightly taller than wide
      ),
      itemCount: 4, // 4 placeholder cards (2 rows × 2 cols)
      itemBuilder: (context, i) => PlaceholderCard(tab: tab),
    );
  }
}

// a single card in the item grid, with a tinted image area and some skeleton-style placeholders for text, all styled based on the category's colors
class PlaceholderCard extends StatelessWidget {
  final ShopCategory tab;
  const PlaceholderCard({super.key, required this.tab});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        // subtle colored shadow so cards feel lifted off the page
        boxShadow: [
          BoxShadow(
            color: tab.accent.withOpacity(0.09),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── top tinted image area ──
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: tab.softBg,  // pastel tint matching the category
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Center(
              child: Icon(
                Icons.inventory_2_outlined,
                size: 38,
                // very faint icon so it doesn't distract
                color: tab.accent.withOpacity(0.22),
              ),
            ),
          ),

          // ── bottom text area ──
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // fake title bar (skeleton-style placeholder)
                Container(
                  height: 10,
                  width: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 6),

                // fake subtitle bar
                Container(
                  height: 8,
                  width: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 10),

                // "coming soon" badge in the category's soft color
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: tab.softBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Coming soon',
                    style: TextStyle(
                      color: tab.accent,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}