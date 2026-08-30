import 'package:flutter/material.dart';
import 'package:ev_charge_navigator/theme/app_theme.dart';
import 'package:ev_charge_navigator/screens/home_page.dart';
import 'package:ev_charge_navigator/screens/safety_guide_page.dart';
import 'package:ev_charge_navigator/screens/charging_map_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 1; // Home is default (center tab)

  final List<Widget> _pages = [
    const SafetyGuidePage(),
    const HomePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            if (index == 2) {
              // Map tab — open as full-screen page via Navigator.push
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ChargingMapPage(),
                ),
              );
            } else {
              setState(() => _currentIndex = index);
            }
          },
          selectedItemColor: AppColors.primaryBlue,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.shield),
              label: 'Safety',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map),
              label: 'Map',
            ),
          ],
        ),
      ),
    );
  }
}
