import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:walkyourcat/features/shop/shop_item.dart';
import 'package:walkyourcat/steps.dart';
import 'package:walkyourcat/navbar.dart';
import 'package:walkyourcat/features/shop/shop_modal.dart';
import 'package:add_to_cart_animation/add_to_cart_animation.dart';
import 'package:walkyourcat/stepcurrency_manager.dart';

enum SampleItem { optionOne, optionTwo, optionThree }

void main() {
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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'WalkYourCat Scrum 2 Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

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
  /*Uncomment 3 methods below to test with a starting balance of 100 coins */
  // @override
  // void initState() {
  //   super.initState();
  //   _initializeCoins();
  // }

  // Future<void> _initializeCoins() async {
  //   // Temporary test seed so the shop starts with 100 coins.
  //   await _currencyManager.setCoinBalance(100);
  //   await _loadCoins();
  // }

  // Future<void> _loadCoins() async {
  //   final coins = await _currencyManager.getCoinBalance();
  //   if (!mounted) return;
  //   setState(() {
  //     _coins = coins;
  //   });
  // }

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  void _handleMenuSelection(SampleItem item) {
    setState(() {
      _selectedItem = item;
    });
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
    if (_coins >= item.price) {
      setState(() {
        _coins -= item.price;
        print(
            "Purchased ${item.name} for ${item.price} coins! Remaining balance: $_coins coins.");
      });
      _currencyManager.setCoinBalance(_coins);

      runAddToCartAnimation(itemKey);

      try {
        player.play(AssetSource('sounds/purchase.wav'));
      } catch (e) {
        print("Error playing sound: $e");
      }
      return true;
    } else {
      String message = "Not enough coins available for purchase";
      showMessage(context, message);
      try {
        player.play(AssetSource('sounds/declined.mp3'));
      } catch (e) {
        print("Error playing sound: $e");
      }
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
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(widget.title),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: PopupMenuButton<SampleItem>(
                initialValue: _selectedItem,
                onSelected: _handleMenuSelection,
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
                ],
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  GestureDetector(
                    onTap: _incrementCounter,
                    child: Image(
                        image: AssetImage('assets/cat.png'),
                        width: MediaQuery.of(context).size.width * 0.75),
                  ),
                  const Text('You have pet the cat this many times:'),
                  Text(
                    '$_counter',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              ),
            ),

            /* ------- STEP & COIN COUNTER WIDGETS --- */
            Positioned(
              top: 16,
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
                // onTap: _openShop,
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
                      icon: const Icon(Icons.inventory),
                      badgeOptions: const BadgeOptions(
                        active: false,
                      ),
                    )),
              ),
            ),
          ],
        ),
        bottomNavigationBar: const CustomBottomNav(),
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
