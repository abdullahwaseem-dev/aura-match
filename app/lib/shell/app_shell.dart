import 'package:flutter/material.dart';
import '../theme/aurora.dart';
import '../widgets/aura_orb.dart';
import '../screens/home/aura_home_screen.dart';
import '../screens/resume/resume_flow_screen.dart';
import '../screens/jobs/jobs_flow_screen.dart';
import '../screens/interview/interview_placeholder_screen.dart';
import '../screens/profile/profile_placeholder_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _NavItem {
  const _NavItem(this.label, this.icon);
  final String label;
  final IconData icon;
}

const _items = [
  _NavItem('Resume', Icons.description_outlined),
  _NavItem('Home', Icons.auto_awesome_outlined),
  _NavItem('Jobs', Icons.work_outline),
  _NavItem('Prep', Icons.mic_none_outlined),
  _NavItem('Profile', Icons.person_outline),
];

const _screens = [
  ResumeFlowScreen(),
  AuraHomeScreen(),
  JobsFlowScreen(),
  InterviewPlaceholderScreen(),
  ProfilePlaceholderScreen(),
];

class _AppShellState extends State<AppShell> {
  int _index = 1; // Home is the default landing tab

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 900;
    return Scaffold(
      backgroundColor: AuroraColors.void_,
      body: wide ? _wideLayout() : _narrowLayout(),
    );
  }

  Widget _narrowLayout() {
    return Column(
      children: [
        Expanded(child: IndexedStack(index: _index, children: _screens)),
        _BottomBar(index: _index, onSelect: (i) => setState(() => _index = i)),
      ],
    );
  }

  Widget _wideLayout() {
    return Row(
      children: [
        _SideRail(index: _index, onSelect: (i) => setState(() => _index = i)),
        Expanded(child: IndexedStack(index: _index, children: _screens)),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.index, required this.onSelect});
  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 10, top: 22),
      decoration: BoxDecoration(
        color: AuroraColors.void2.withValues(alpha: 0.9),
        border: const Border(top: BorderSide(color: AuroraColors.lineSoft)),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: -30,
            child: GestureDetector(
              onTap: () => onSelect(1),
              child: const AuraOrb(size: 54),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_items.length, (i) {
              final active = i == index;
              return GestureDetector(
                onTap: () => onSelect(i),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_items[i].icon, size: 22, color: active ? AuroraColors.cyan : AuroraColors.mistDim),
                      const SizedBox(height: 4),
                      Text(
                        _items[i].label,
                        style: AuroraText.caption.copyWith(
                          fontSize: 9,
                          color: active ? AuroraColors.cyan : AuroraColors.mistDim,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _SideRail extends StatelessWidget {
  const _SideRail({required this.index, required this.onSelect});
  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: const BoxDecoration(
        color: Color(0xFF0B0C13),
        border: Border(right: BorderSide(color: AuroraColors.lineSoft)),
      ),
      child: Column(
        children: [
          const AuraOrb(size: 40),
          const SizedBox(height: 40),
          ...List.generate(_items.length, (i) {
            final active = i == index;
            return Padding(
              padding: const EdgeInsets.only(bottom: 22),
              child: GestureDetector(
                onTap: () => onSelect(i),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: active ? AuroraColors.cyan.withValues(alpha: 0.1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(_items[i].icon, size: 20, color: active ? AuroraColors.cyan : AuroraColors.mistDim),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _items[i].label,
                      style: AuroraText.caption.copyWith(
                        fontSize: 8.5,
                        color: active ? AuroraColors.cyan : AuroraColors.mistDim,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
