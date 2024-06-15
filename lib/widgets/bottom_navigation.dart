import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:projectx/screens/home/home.dart';
import 'package:projectx/screens/settings/settings.dart';

class BottomNavigationContainer extends StatefulWidget {
  const BottomNavigationContainer({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _BottomNavigationContainerState createState() =>
      _BottomNavigationContainerState();
}

class _BottomNavigationContainerState extends State<BottomNavigationContainer> {
  int currentIndex = 0;

  final List<Widget> screens = const [
    HomeScreen(),
    SettingsScreen(),
  ];

  // Metodo da button nav
  void onTabTapped(int index) {
    if (currentIndex == index) return;

    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: OrientationBuilder(
        builder: (context, orientation) {
          if (orientation == Orientation.landscape) {
            return Row(
              children: [
                NavigationRail(
                  groupAlignment: 0.0,
                  selectedIndex: currentIndex,
                  onDestinationSelected: onTabTapped,
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    NavigationRailDestination(
                      icon: const Icon(Icons.home),
                      selectedIcon: const Icon(Icons.home_outlined),
                      label: Text(AppLocalizations.of(context)!.home),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.settings),
                      selectedIcon: const Icon(Icons.settings_outlined),
                      label: Text(AppLocalizations.of(context)!.settings),
                    ),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(child: screens[currentIndex]),
              ],
            );
          } else {
            return Scaffold(
              body: screens[currentIndex],
              // Bottom Nav
              bottomNavigationBar: NavigationBarTheme(
                data: NavigationBarThemeData(
                  labelTextStyle: WidgetStateProperty.all(
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
                  ),
                ),
                child: NavigationBar(
                  onDestinationSelected: onTabTapped,
                  selectedIndex: currentIndex,
                  labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                  destinations: [
                    NavigationDestination(
                      icon: const Icon(Icons.home),
                      selectedIcon: const Icon(Icons.home_outlined),
                      label: AppLocalizations.of(context)!.home,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.settings),
                      selectedIcon: const Icon(Icons.settings_outlined),
                      label: AppLocalizations.of(context)!.settings,
                    ),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
