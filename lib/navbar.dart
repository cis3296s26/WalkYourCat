import 'package:flutter/material.dart';

class CustomBottomNav extends StatefulWidget {
  const CustomBottomNav({super.key});

  @override
  State<CustomBottomNav> createState() => _CustomBottomNavState();
}

class _CustomBottomNavState extends State<CustomBottomNav> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    print('Button $index clicked!');
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: '1',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: '2',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: '3',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: '4',
        ),
      ],
      currentIndex: _selectedIndex,
      type: BottomNavigationBarType.fixed, 
      selectedItemColor: Theme.of(context).colorScheme.primary,
      unselectedItemColor: Colors.grey,
      onTap: _onItemTapped,
    );
  }
}