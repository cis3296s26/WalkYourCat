import 'package:flutter/material.dart';
import 'steps.dart';
import 'package:walkyourcat/navbar.dart';
import 'package:walkyourcat/shop_screen.dart';

enum SampleItem { itemOne, itemTwo, itemThree }

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
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
  int _coins = 0; // your coin balance
  SampleItem? _selectedItem;

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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShopScreen(coins: _coins),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  value: SampleItem.itemOne,
                  child: Text('Settings'),
                ),
                const PopupMenuItem<SampleItem>(
                  value: SampleItem.itemTwo,
                  child: Text('Profile/Account'),
                ),
                const PopupMenuItem<SampleItem>(
                  value: SampleItem.itemThree,
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
                const Text('You have pushed the button this many times:'),
                Text(
                  '$_counter',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ],
            ),
          ),

          /* ------- STEP COUNTER WIDGET --- */
          /* ------- STEP & COIN COUNTER WIDGETS --- */
          Positioned(
            top: 16,
            left: 16,
            child: Row(
              children: [
                // 1. Your existing StepCounter
                StepCounter(
                  title: 'Steps',
                  onCoinsUpdated: (newTotal) {
                    setState(() {
                      _coins = newTotal;
                    });
                  },
                ),
                
                const SizedBox(width: 8), // Adds a little space between the cards
                
                // 2. The New Coin UI 
                Card(
                  color: Colors.amber.shade600,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
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

          /* ------- FLOATING SHOP BUTTON (bottom-left) --- */
          Positioned(
            bottom: 24,
            left: 24,
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
        ],
      ),
      bottomNavigationBar: const CustomBottomNav(),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}