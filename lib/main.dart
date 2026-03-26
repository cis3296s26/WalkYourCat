import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:walkyourcat/features/shop/shop_item.dart';
import 'package:walkyourcat/steps.dart';
import 'package:walkyourcat/navbar.dart';
import 'package:walkyourcat/features/shop/shop_modal.dart';
import 'package:add_to_cart_animation/add_to_cart_animation.dart';

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
  int _coins = 100; // your coin balance
  SampleItem? _selectedItem;
  final player = AudioPlayer();
  GlobalKey<CartIconKey> inventoryKey = GlobalKey<CartIconKey>();
  late Function(GlobalKey) runAddToCartAnimation;

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
      onItemTap: (item) {
        print("User clicked on ${item.name} which costs ${item.price}!");
        purchaseItem(item);
      },
    );
  }

  void purchaseItem(ShopItem item) {
    if (_coins >= item.price) {
      setState(() {
        _coins = _coins - item.price;
        print(
            "Purchased ${item.name} for ${item.price} coins! Remaining balance: $_coins coins.");
      });
      try {
        player.play(AssetSource('sounds/purchase.wav'));
      } catch (e) {
        print("Error playing sound: $e");
      }
    } else {
      String message = "Not enough coins available for purchase";
      showMessage(context, message);
      try {
        player.play(AssetSource('sounds/declined.mp3'));
      } catch (e) {
        print("Error playing sound: $e");
      }
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

            /* ------- STEP COUNTER WIDGET --- */
            const Positioned(
              top: 16,
              left: 16,
              child: StepCounter(title: 'Steps'),
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
