import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/aurora.dart';
import '../widgets/aura_orb.dart';
import '../screens/home/aura_home_screen.dart';
import '../screens/resume/resume_flow_screen.dart';
import '../screens/jobs/jobs_flow_screen.dart';
import '../screens/interview/interview_screen.dart';
import '../screens/profile/account_screen.dart';
import '../state/navigation_state.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  static const _screens = [
    ResumeFlowScreen(),
    AuraHomeScreen(),
    JobsFlowScreen(),
    InterviewScreen(),
    AccountScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final index = context.watch<NavigationState>().tabIndex;
    final wide = MediaQuery.of(context).size.width >= 900;
    return Scaffold(
      backgroundColor: AuroraColors.void_,
      body: wide ? _wideLayout(context, index) : _narrowLayout(context, index),
    );
  }

  Widget _narrowLayout(BuildContext context, int index) {
    return Column(
      children: [
        Expanded(child: IndexedStack(index: index, children: _screens)),
        _BottomBar(index: index, onSelect: (i) => context.read<NavigationState>().goTo(i)),
      ],
    );
  }

  Widget _wideLayout(BuildContext context, int index) {
    return Row(
      children: [
        _SideRail(index: index, onSelect: (i) => context.read<NavigationState>().goTo(i)),
        Expanded(child: IndexedStack(index: index, children: _screens)),
      ],
    );
  }
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
