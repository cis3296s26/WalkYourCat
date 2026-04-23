import 'package:walkyourcat/services/geo_service.dart';
import 'dart:io';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
import 'package:walkyourcat/features/map/map_modal.dart';
import 'package:walkyourcat/features/leaderboard/leaderboard_modal.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:features_tour/features_tour.dart';
import 'package:flutter/services.dart';

enum SampleItem { optionOne, optionTwo, optionThree, optionFour, optionFive }

void main() async {
  // tucks away android nav bar
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  try {
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

    const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
    debugPrint('API Key loaded: ${apiKey.isNotEmpty}');

    if (Firebase.apps.isEmpty) {
      if (kIsWeb) {
        await Firebase.initializeApp(
          options: const FirebaseOptions(
            apiKey: String.fromEnvironment('FIREBASE_API_KEY'),
            appId: String.fromEnvironment('FIREBASE_APP_ID'),
            messagingSenderId: String.fromEnvironment('FIREBASE_SENDER_ID'),
            projectId: String.fromEnvironment('FIREBASE_PROJECT_ID'),
            databaseURL: String.fromEnvironment('FIREBASE_DB_URL'),
          ),
        );
      } else {
        await Firebase.initializeApp();
      }
    }
  } catch (e, stacktrace) {
    debugPrint('FATAL ERROR: $e');
    debugPrint('STACKTRACE: $stacktrace');
  }

  runApp(const MyApp());

  FeaturesTour.setGlobalConfig(
    preDialogConfig: PreDialogConfig(
      enabled: true,
      customDialogBuilder: (context, _) async {
        return await showDialog<PreDialogButtonType>(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: const Text('Welcome to Walk Your Cat!'),
                content: const Text(
                  'This tour will guide you through the main features of the app.',
                ),
                actions: [
                  TextButton(
                    onPressed: () =>
                        Navigator.pop(context, PreDialogButtonType.dismiss),
                    child: const Text('Dismiss'),
                  ),
                  TextButton(
                    onPressed: () =>
                        Navigator.pop(context, PreDialogButtonType.later),
                    child: const Text('Later'),
                  ),
                  FilledButton(
                    onPressed: () =>
                        Navigator.pop(context, PreDialogButtonType.accept),
                    child: const Text('Start Tour'),
                  ),
                ],
              ),
            ) ??
            PreDialogButtonType.later;
      },
    ),
  );
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

class _MenuOption extends StatelessWidget {
  const _MenuOption({
    required this.icon,
    required this.label,
    this.accent = Colors.deepPurple,
    this.soft = const Color(0xFFF1EBFF),
  });

  final IconData icon;
  final String label;
  final Color accent;
  final Color soft;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: soft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accent, size: 18),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF2F1F17),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final tourController = FeaturesTourController('HomePage');
  int _counter = 0;
  SampleItem? _selectedItem;
  final player = AudioPlayer();
  GlobalKey<CartIconKey> inventoryKey = GlobalKey<CartIconKey>();
  late Future<void> Function(GlobalKey) runAddToCartAnimation;
  int _coins = 0;
  final StepCurrencyManager _currencyManager = StepCurrencyManager();
  String _currentCatImage = 'assets/animations/idle_cat.gif';
  late Timer _backgroundUpdateTimer;

  @override
  void initState() {
    super.initState();
    _initializeCoins();
    tourController.start(context);
    GeoService.instance.initTracking();
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

  void _update() {
    setState(() {});
  }

  void _runTutorial() {
    tourController.start(context, force: true);
  }

  Future<void> _initializeCoins() async {
    // Temporary test seed so the shop starts with 2500 coins.
    // await _currencyManager.setCoinBalance(5000);
    // await _loadCoins();
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
      CatStatsBar.updateStats(
          food: 0, health: 0); // TO TEST STAT CHANGES ON PET INTERACTION
    });

    await ChallengesService.instance.addProgress('petting', 1);
    await StepCurrencyManager().simulateSteps(5);
    await _loadCoins(); // Refresh coins if a challenge was completed

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

        await _loadCoins();

        return true;
      },
    );
  }

  void _openMap() {
    showMapModal(
      context,
      inventoryTargetKey: inventoryKey,          // the GlobalKey on the inventory button
      runAddToCartAnimation: runAddToCartAnimation, // fallback cart animation
    );
  }

  void _openChallenges() {
    showChallengesModal(
      context,
      onCoinsAdded: () async {
        await _loadCoins();
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  void _openAchievements() {
    showChallengesModal(context, initialTab: 1);
  }

  void _openLeaderboard() {
    showLeaderboardModal(context);
  }

  void _playItemAnimation(String tag) async {
    /* --- VARIABLES --- */
    String animation;
    // keywords
    String eating = 'assets/animations/eating_cat.gif';
    String drinking = 'assets/animations/drinking_cat.gif';
    String groomed = 'assets/animations/happy_cat.gif';
    String idle = 'assets/animations/idle_cat.gif';
    String playing = 'assets/animations/playing_cat.gif';

    /* ------ DECIDING ANIMATION BASED ON TAG ------ */
    switch (tag) {
      case 'food':
        debugPrint('[MAIN - ANI]: Playing food animation');
        animation = eating;
      case 'drinks':
        debugPrint('[MAIN - ANI]: Playing drink animation');
        animation = drinking;
      case 'fun':
        debugPrint('[MAIN - ANI]: Playing fun animation');
        animation = playing;
      case 'medicine':
        debugPrint('[MAIN - ANI]: Playing medicine animation');
        animation = drinking;
      case 'cosmetic':
        debugPrint('[MAIN - ANI]: Playing cosmetic animation');
        animation = groomed;
      default:
        debugPrint('[MAIN - ANI]: No animation for tag: $tag');
        animation = idle;
    }
    /* --- END OF DECIDING ANIMATION BASED ON TAG --- */

    // update cat image for 2 seconds, then revert back to idle
    setState(() {
      _currentCatImage = animation;
    });
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _currentCatImage = 'assets/animations/idle_cat.gif';
      });
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
      return 'assets/images/bg_sunset.png';
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

  /// user action taken when reviving the cat.
  Future<void> _payVetBill() async {
    debugPrint("[MAIN]: Attempting to pay vet bill...");

    // check for enough coins
    if (_coins >= 2500) {
      // Deduct 2,500 coins for vet bill
      setState(() {
        _coins -= 2500;
      });

      // revive cat
      CatStatsController.instance.revive();

      // update coin balance
      await _currencyManager.setCoinBalance(_coins);
      player.play(AssetSource('sounds/purchase.wav'));
      debugPrint("[MAIN]: Paid vet bill!");
    }
    // else, it cannot revive
    else {
      showMessage(context, "Not enough coins available for purchase");
      player.play(AssetSource('sounds/declined.mp3'));
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
                  // listen to changes in CatStatsController
                  ListenableBuilder(
                    listenable: CatStatsController.instance,
                    builder: (context, child) {
                      // situations
                      final isDead = CatStatsController.instance.health <= 0;
                      final isSick = CatStatsController.instance.health <= 30 && CatStatsController.instance.health > 0;
                      final isNight = DateTime.now().hour >= 20 || DateTime.now().hour < 5; 

                      /* -- IF CAT IS DEAD, SHOW VET -- */
                      if (isDead) {
                        return Container(
                          width: MediaQuery.of(context).size.width * 0.75,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.redAccent.shade100, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withValues(alpha: 0.1),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.local_hospital_rounded,
                                  color: Colors.redAccent, size: 56),
                              const SizedBox(height: 12),
                              const Text(
                                'AT THE VET',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF2C1F17),
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: _payVetBill,
                                icon:
                                    const Icon(Icons.payment_rounded, size: 18),
                                label: const Text('Pay Bill (2,500)'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      /* -- IF CAT IS SICK, CHANGE ANI -- */
                      else if (isSick) {
                        return Image.asset(
                          'assets/animations/sick_cat.gif',
                          width: MediaQuery.of(context).size.width * 0.65,
                        );
                      }

                      /* -- IF IT'S NIGHT, SHOW SLEEPING ANI -- */
                      else if (isNight) {
                        return Image.asset(
                          'assets/animations/sleeping_cat.gif',
                          width: MediaQuery.of(context).size.width * 0.65,
                        );
                      }

                      /* -- ELSE, SHOW CAT AS NORMAL -- */
                      return GestureDetector(
                        onTap: _incrementCounter,
                        child: Image(
                            image: AssetImage(_currentCatImage),
                            width: MediaQuery.of(context).size.width * 0.65),
                      );
                    },
                  ),
                ],
              ),
            ),

            /* ------- STEP & COIN COUNTER WIDGETS --- */
            FeaturesTour(
              controller: tourController,
              index: 0,
              introduce: Text(
                  "This is the step counter and coin balance! Earn coins by walking with your cat, completing challenges, and picking up coins on the map!"),
              child: Positioned(
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
            ),

            //stats bar
            FeaturesTour(
                controller: tourController,
                index: 1,
                introduce: Text(
                    "This is your cat's stats bar! Hunger, Health, and Happiness. Keep an eye on these to make sure your cat is doing well!"),
                child: Positioned(
                  top: 80, // sits just below the steps + coins row
                  left: 16,
                  child: CatStatsBar(),
                )),

            FeaturesTour(
              controller: tourController,
              index: 2,
              introduce: Text(
                  "This is the menu button! Here you can access your profile, settings, achievements, social features, and tutorial!"),
              child: Positioned(
                top: 30,
                right: 16,
                child: PopupMenuButton<SampleItem>(
                  initialValue: _selectedItem,
                  color: const Color(0xFFFFFBF7),
                  elevation: 10,
                  offset: const Offset(0, 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  icon: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.deepPurple,
                    ),
                    child: const Icon(
                      Icons.more_vert,
                      color: Colors.white,
                    ),
                  ),
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<SampleItem>>[
                    const PopupMenuItem<SampleItem>(
                      value: SampleItem.optionOne,
                      child: _MenuOption(
                        icon: Icons.settings_rounded,
                        label: 'Settings',
                      ),
                    ),
                    const PopupMenuItem<SampleItem>(
                      value: SampleItem.optionTwo,
                      child: _MenuOption(
                        icon: Icons.person_rounded,
                        label: 'Profile',
                      ),
                    ),
                    PopupMenuItem<SampleItem>(
                      value: SampleItem.optionThree,
                      onTap: _openLeaderboard,
                      child: const _MenuOption(
                        icon: Icons.leaderboard_rounded,
                        label: 'Leaderboard',
                      ),
                    ),
                    PopupMenuItem<SampleItem>(
                      value: SampleItem.optionFour,
                      onTap: _openAchievements,
                      child: const _MenuOption(
                        icon: Icons.emoji_events_rounded,
                        label: 'Achievements',
                        accent: Color(0xFFE7A100),
                        soft: Color(0xFFFFF1D6),
                      ),
                    ),
                    PopupMenuItem<SampleItem>(
                      value: SampleItem.optionFive,
                      onTap: _runTutorial,
                      child: const _MenuOption(
                        icon: Icons.school_rounded,
                        label: 'Tutorial',
                      ),
                    )
                  ],
                ),
              ),
            ),

            /* ------- FLOATING SHOP BUTTON (bottom-right) --- */
            FeaturesTour(
              controller: tourController,
              index: 3,
              introduce: Text(
                  "This is the shop button! Here you can spend your hard-earned coins on food, toys, and other items to care for your cat!"),
              child: Positioned(
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
                          color: Colors.deepPurple.withValues(alpha: 0.4),
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
            ),

            /* ------- FLOATING Map BUTTON (bottom-right) --- */
            FeaturesTour(
              controller: tourController,
              index: 4,
              introduce: Text(
                  "This is the map button! Here you can view the map of your neighborhood and find places to walk your cat!"),
              child: Positioned(
                bottom: 24,
                right: 90,
                child: GestureDetector(
                  onTap: _openMap,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.deepPurple,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepPurple.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.map,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
              ),
            ),

            /* ------- FLOATING CHALLENGE BUTTON (bottom-left) --- */
            FeaturesTour(
              controller: tourController,
              index: 5,
              introduce: Text(
                  "This is the challenges button! Here you can view and complete daily challenges to earn rewards!"),
              child: Positioned(
                bottom: 24,
                left: 90,
                child: GestureDetector(
                  onTap: _openChallenges,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.deepPurple,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepPurple.withValues(alpha: 0.4),
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
            ),

            /* ------- FLOATING Inventory BUTTON (bottom-left) --- */
            FeaturesTour(
              controller: tourController,
              index: 6,
              introduce: Text(
                  "This is the inventory button! Here you can view and use the items you've purchased from the shop!"),
              onAfterIntroduce: (_) => _update(),
              child: Positioned(
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
                            color: Colors.deepPurple.withValues(alpha: 0.4),
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
