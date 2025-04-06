import 'package:codeshastraxi_overload_oblivion/features/auth/presentation/pages/landing_page.dart';
import 'package:codeshastraxi_overload_oblivion/features/space_monitor/presentation/pages/dashboard_page.dart';
import 'package:codeshastraxi_overload_oblivion/features/space_monitor/presentation/pages/scan_page.dart';
import 'package:codeshastraxi_overload_oblivion/features/space_monitor/presentation/pages/analysis_page.dart';
import 'package:codeshastraxi_overload_oblivion/features/space_monitor/presentation/pages/chatbot_page.dart';
import 'package:codeshastraxi_overload_oblivion/features/space_monitor/presentation/pages/results_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:codeshastraxi_overload_oblivion/core/theme/app_pallete.dart';
import '../cubits/scene_analysis_cubit.dart';
import 'package:codeshastraxi_overload_oblivion/init_dependencies.dart';

class LayoutPage extends StatefulWidget {
  const LayoutPage({super.key});

  @override
  State<LayoutPage> createState() => _LayoutPageState();
}

class _LayoutPageState extends State<LayoutPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const DashboardPage(),
    const ScanPage(),
    const AnalysisPage(),
    const ResultsPage(),
    const ChatbotPage(),
  ];

  // Define navigation items
  final List<NavItem> _navItems = [
    NavItem(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      label: 'Dashboard',
      color: Pallete.primaryColor,
    ),
    NavItem(
      icon: Icons.camera_alt_outlined,
      activeIcon: Icons.camera_alt,
      label: 'Scan',
      color: Pallete.primaryColor,
    ),
    NavItem(
      icon: Icons.analytics_outlined,
      activeIcon: Icons.analytics,
      label: 'Analysis',
      color: Pallete.accentColor,
    ),
    NavItem(
      icon: Icons.format_list_bulleted_outlined,
      activeIcon: Icons.format_list_bulleted,
      label: 'Results',
      color: Pallete.secondaryColor,
    ),
    NavItem(
      icon: Icons.chat_outlined,
      activeIcon: Icons.chat,
      label: 'Assistant',
      color: Pallete.secondaryColor,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SceneAnalysisCubit>(
          create: (context) => serviceLocator<SceneAnalysisCubit>(),
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Theme.of(context).colorScheme.primary,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: () {
                FirebaseAuth.instance.signOut();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LandingPage()),
                );
              },
            )
          ],
          title: const Text(
            'Trakshak',
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: _pages[_currentIndex],
        ),
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Pallete.primaryColor.withOpacity(0.1),
            blurRadius: 15,
            spreadRadius: 1,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(_navItems.length, (index) {
          return _buildNavItem(index);
        }),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final isSelected = _currentIndex == index;
    final item = _navItems[index];
    final color = isSelected ? item.color : Pallete.greyColor;

    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      customBorder: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Badge indicator above selected item
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 30,
            height: 3,
            margin: const EdgeInsets.only(bottom: 7),
            decoration: BoxDecoration(
              color: isSelected ? item.color : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          // Icon with background
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              isSelected ? item.activeIcon : item.icon,
              color: color,
              size: isSelected ? 26 : 22,
            ),
          ),
          const SizedBox(height: 4),
          // Label
          Text(
            item.label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

// Model class for navigation items
class NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Color color;

  NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.color,
  });
}
