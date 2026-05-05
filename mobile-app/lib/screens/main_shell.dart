import 'package:flutter/material.dart';
import '../utils/theme.dart';
import 'home_screen.dart';
import 'proyectos_screen.dart';
import 'tramites_screen.dart';
import 'perfil_screen.dart';

class MainShell extends StatefulWidget {
  final int initialIndex;
  const MainShell({super.key, this.initialIndex = 0});

  static void goToTab(BuildContext context, int index) {
    final state = context.findAncestorStateOfType<MainShellState>();
    state?.setTab(index);
  }

  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void setTab(int index) => setState(() => _currentIndex = index);

  static const _screens = [
    HomeScreen(),
    ProyectosScreen(),
    TramitesScreen(),
    PerfilScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.darkBorder, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Inicio'),
            BottomNavigationBarItem(icon: Icon(Icons.list_alt_rounded), label: 'Proyectos'),
            BottomNavigationBarItem(icon: Icon(Icons.description_rounded), label: 'Trámites'),
            BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Perfil'),
          ],
        ),
      ),
    );
  }
}