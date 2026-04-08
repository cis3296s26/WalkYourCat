import 'dart:io';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:walkyourcat/features/achievements/achievments_modal.dart';
import 'package:walkyourcat/features/challenges/challenges_service.dart';
import 'package:walkyourcat/features/shop/shop_item.dart';
import 'package:walkyourcat/steps.dart';
import 'package:walkyourcat/features/shop/shop_modal.dart';
import 'package:add_to_cart_animation/add_to_cart_animation.dart';
import 'package:walkyourcat/stepcurrency_manager.dart';
import 'package:walkyourcat/features/inventory/inventory_modal.dart';
import 'package:walkyourcat/features/inventory/inventory_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:walkyourcat/cat_stats_bar.dart';
import 'package:walkyourcat/features/challenges/challenges_ui.dart';
// import 'package:walkyourcat/features/challenges/challenges_history_modal.dart';

enum SampleItem { optionOne, optionTwo, optionThree, optionFour }

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    // Web implementation of sqlite
    databaseFactory = databaseFactoryFfiWeb;
  } else {
    if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    // Mobile "should" just work
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WalkYourCat',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  SampleItem? _selectedItem;
  final player = AudioPlayer();
  GlobalKey<CartIconKey> inventoryKey = GlobalKey<CartIconKey>();
  late Future<void> Function(GlobalKey) runAddToCartAnimation;
  int _coins = 0;
  final StepCurrencyManager _currencyManager = StepCurrencyManager();
  String _currentCatImage = 'assets/animations/idle_cat.gif';
  late Timer _backgroundUpdateTimer;
  /*Uncomment 3 methods below to test with a starting balance of 100 coins */

  @override
  void initState() {
    super.initState();
    _initializeCoins();
    // Update background every minute to check if hour changed
    _backgroundUpdateTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _backgroundUpdateTimer.cancel();
    super.dispose();
  }

  Future<void> _initializeCoins() async {
    // Temporary test seed so the shop starts with 100 coins.
    await _currencyManager.setCoinBalance(300);
    await _loadCoins();
  }

  Future<void> _loadCoins() async {
    final coins = await _currencyManager.getCoinBalance();
    if (!mounted) return;
    setState(() {
      _coins = coins;
    });
  }

  Future<void> _incrementCounter() async {
    setState(() {
      _counter++;
      _currentCatImage = 'assets/animations/petted_cat.gif';
      CatStatsBar.updateStats(food: 0, health: 0);  // TO TEST STAT CHANGES ON PET INTERACTION
      ChallengesService.instance.addProgress('petting', 1);
    });

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _currentCatImage = 'assets/animations/idle_cat.gif';
      });
    }
  }

  void _openInventory() {
    showInventoryModal(
      context: context,
      onItemTap: (invItem, key) async {
        // Apply item effects and remove from inventory
        await InventoryService.instance.useItem(invItem);
        // Start animation
        _playItemAnimation(invItem.item.tag);

        return true;
      },
    );
  }

  void _openChallenges() {
    showChallengesModal(context);
  }
  //   void _openChallengesHistory() {
  //   showChallengesHistoryModal(context);
  // }
  void _playItemAnimation(String tag) async {
    /* --- CHANGE CAT ANIMATION BASED ON ITEM EFFECTS --- */
    // --------- FOOD --------
    if (tag == 'food') {
      setState(() {
        _currentCatImage = 'assets/animations/eating_cat.gif';
      });
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() {
          _currentCatImage = 'assets/animations/idle_cat.gif';
        });
      }
      // --------- TOYS --------
    } else if (tag == 'fun') {
      setState(() {
        _currentCatImage = 'assets/animations/happy_cat.gif';
      });
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() {
          _currentCatImage = 'assets/animations/idle_cat.gif';
        });
      }
    }
  }

  String _getBackgroundImageForCurrentTime() {
    // get current hour
    final int hour = DateTime.now().hour;

    // set background based on time of day
    if (hour >= 20 || hour < 5) {
      // 8pm - 4:59am
      return 'assets/images/bg_evening.png';
    } else if (hour >= 5 && hour < 7) {
      // 5am - 6:59am
      return 'assets/images/bg_sunset.png';
    } else if (hour >= 7 && hour < 17) {
      // 7am - 4:59pm
      return 'assets/images/bg_morning.png';
    } else {
      // 5pm - 7:59pm
      return 'assets/images/bg_morning.png';
    }
  }

  void _openShop() {
    showShopModal(
      context: context,
      coins: _coins,
      // This is the callback function, technically this logic can also live
      // in the modal itself but tbh I was unsure what made more sense
      onItemTap: (item, itemKey) {
        print("User clicked on ${item.name} which costs ${item.price}!");
        return purchaseItem(item, itemKey);
      },
    );
  }

  Future<bool> purchaseItem(ShopItem item, GlobalKey itemKey) async {
    if (_coins < item.price) {
      showMessage(context, "Not enough coins available for purchase");
      player.play(AssetSource('sounds/declined.mp3'));
      return false;
    }

    try {
      await InventoryService.instance.addItem(item);

      setState(() {
        _coins -= item.price;
      });

      await _currencyManager.setCoinBalance(_coins);
      runAddToCartAnimation(itemKey);
      player.play(AssetSource('sounds/purchase.wav'));

      print("Purchased ${item.name}! New balance: $_coins");
      return true;
    } catch (e) {
      print("Purchase Error: $e");
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AddToCartAnimation(
      cartKey: inventoryKey,
      createAddToCartAnimation: (runAddToCartAnimation) {
        this.runAddToCartAnimation = runAddToCartAnimation;
      },
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                _getBackgroundImageForCurrentTime(),
                fit: BoxFit.cover,
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  SizedBox(height: MediaQuery.of(context).size.height * 0.5),
                  GestureDetector(
                    onTap: _incrementCounter,
                    child: Image(
                        image: AssetImage(_currentCatImage),
                        width: MediaQuery.of(context).size.width * 0.65),
                  ),
                ],
              ),
            ),

            /* ------- STEP & COIN COUNTER WIDGETS --- */
            Positioned(
              top: 36,
              left: 16,
              child: Row(
                children: [
                  StepCounter(
                    title: 'Steps',
                    onCoinsUpdated: (newTotal) {
                      setState(() {
                        _coins = newTotal;
                      });
                    },
                  ),

                  const SizedBox(
                      width: 8), // Adds a little space between the cards
                  Card(
                    color: Colors.amber.shade600,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12.0, vertical: 8.0),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.monetization_on_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$_coins',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            //stats bar
            Positioned(
              top: 80, // sits just below the steps + coins row
              left: 16,
              child: CatStatsBar(),
            ),

            Positioned(
              top: 36,
              right: 16,
              child: PopupMenuButton<SampleItem>(
                initialValue: _selectedItem,
                icon: const Icon(Icons.more_vert),
                itemBuilder: (BuildContext context) =>
                    <PopupMenuEntry<SampleItem>>[
                  const PopupMenuItem<SampleItem>(
                    value: SampleItem.optionOne,
                    child: Text('Settings'),
                  ),
                  const PopupMenuItem<SampleItem>(
                    value: SampleItem.optionTwo,
                    child: Text('Profile/Account'),
                  ),
                  const PopupMenuItem<SampleItem>(
                    value: SampleItem.optionThree,
                    child: Text('Social'),
                  ),
                  // PopupMenuItem<SampleItem>(
                  //   value: SampleItem.optionFour,
                  //   onTap: _openChallengesHistory,
                  //   child: const Text('Challenges History'),
                  // ),
                ],
              ),
            ),

            /* ------- FLOATING CHALLENGE BUTTON (bottom-right) --- */
            Positioned(
              bottom: 24,
              left: 90,
              child: GestureDetector(
                onTap: _openChallenges,
                child: Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.deepPurple,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurple.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.emoji_events,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
            ),

            /* ------- FLOATING SHOP BUTTON (bottom-right) --- */
            Positioned(
              bottom: 24,
              right: 24,
              child: GestureDetector(
                onTap: _openShop,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.deepPurple,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurple.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
            ),

            /* ------- FLOATING Inventory BUTTON (bottom-left) --- */
            Positioned(
              bottom: 24,
              left: 24,
              child: GestureDetector(
                onTap: _openInventory,
                child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.deepPurple,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepPurple.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: AddToCartIcon(
                      key: inventoryKey,
                      icon: const Icon(Icons.inventory, color: Colors.white),
                      badgeOptions: const BadgeOptions(
                        active: false,
                      ),
                    )),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showMessage(BuildContext context, String message) {
    final snackBar = SnackBar(
      content: Center(
        // Wrap the Text widget with Center
        child: Text(
          message,
          textAlign: TextAlign
              .center, // Optional: ensure text itself aligns center within the Center widget's bounds
        ),
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}