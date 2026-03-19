import 'package:flutter/material.dart';
import 'steps.dart';                      // step counter stuff
import 'package:walkyourcat/navbar.dart';

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

  String get _selectedMenuLabel {
    switch (_selectedItem) {
      case SampleItem.itemOne:
        return 'Settings selected';
      case SampleItem.itemTwo:
        return 'Profile/Account selected';
      case SampleItem.itemThree:
        return 'Social selected';
      case null:
        return 'No menu item selected';
    }
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
                const Text(
                  'You have pushed the button this many times:',
                ),
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
