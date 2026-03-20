import 'package:flutter/material.dart';
import 'steps.dart';
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
      title: 'WalkYourCat',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'WalkYourCat Scrum 1 Demo'),
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
                GestureDetector(
                  onTap: _incrementCounter,
                  child: Image(image: AssetImage('assets/cat.png'), width: MediaQuery.of(context).size.width * 0.75),
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
      )
    );
  }
}