import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

class StatusTabDefinition<TStatus> {
  final String label;
  final TStatus? status;

  const StatusTabDefinition({required this.label, required this.status});
}

class StatusTabbedSection<TStatus, TItem> extends StatelessWidget {
  final TabController controller;
  final List<StatusTabDefinition<TStatus>> tabs;
  final List<TItem> items;
  final String searchQuery;
  final TStatus? Function(TItem item) statusSelector;
  final bool Function(TItem item, String query) matchesSearch;
  final Color Function(int index) tabColorBuilder;
  final Widget Function(BuildContext context, List<TItem> filteredItems)
  listBuilder;
  final Widget Function(BuildContext context)? emptyBuilder;
  final EdgeInsetsGeometry? margin;

  const StatusTabbedSection({
    super.key,
    required this.controller,
    required this.tabs,
    required this.items,
    required this.searchQuery,
    required this.statusSelector,
    required this.matchesSearch,
    required this.tabColorBuilder,
    required this.listBuilder,
    this.emptyBuilder,
    this.margin,
  });

  Color _getAnimatedColor() {
    final animation = controller.animation!;
    final value = animation.value;
    final fromIndex = value.floor();
    final toIndex = value.ceil();

    if (fromIndex == toIndex) return tabColorBuilder(fromIndex);

    final t = value - fromIndex;
    return Color.lerp(
      tabColorBuilder(fromIndex),
      tabColorBuilder(toIndex),
      t,
    )!;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final counts = <TStatus?, int>{};
    counts[null] = items.length;
    for (final tab in tabs) {
      if (tab.status != null) {
        counts[tab.status] = items
            .where((item) => statusSelector(item) == tab.status)
            .length;
      }
    }

    return Column(
      children: [
        Container(
          margin:
              margin ??
              EdgeInsets.symmetric(vertical: screenHeight * 0.008),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: AnimatedBuilder(
            animation: controller.animation!,
            builder: (context, _) {
              final animationValue = controller.animation!.value;
              return TabBar(
                controller: controller,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorSize: TabBarIndicatorSize.label,
                labelPadding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.024,
                ),
                indicator: UnderlineTabIndicator(
                  borderSide: BorderSide(
                    width: 2.5,
                    color: _getAnimatedColor(),
                  ),
                ),
                dividerColor: Colors.transparent,
                labelStyle: AppTextStyles.bodySmall(
                  context,
                ).copyWith(fontWeight: FontWeight.w600),
                unselectedLabelStyle: AppTextStyles.bodySmall(
                  context,
                ).copyWith(fontWeight: FontWeight.w400),
                tabs: List.generate(tabs.length, (index) {
                  final count = counts[tabs[index].status] ?? 0;
                  final isSelected = (animationValue - index).abs() < 0.5;
                  return Tab(
                    height: screenHeight * 0.052,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(tabs[index].label),
                        SizedBox(width: screenWidth * 0.008),
                        _StatusCountBadge(
                          count: count,
                          isSelected: isSelected,
                          color: tabColorBuilder(index),
                        ),
                      ],
                    ),
                  );
                }),
              );
            },
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: controller,
            children: tabs.map((tab) {
              final filteredItems = items.where((item) {
                final searchMatches = matchesSearch(item, searchQuery);
                final tabMatches =
                    tab.status == null || statusSelector(item) == tab.status;
                return searchMatches && tabMatches;
              }).toList();

              if (filteredItems.isEmpty) {
                return emptyBuilder?.call(context) ??
                    const SizedBox.shrink();
              }

              return listBuilder(context, filteredItems);
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _StatusCountBadge extends StatelessWidget {
  final int count;
  final bool isSelected;
  final Color color;

  const _StatusCountBadge({
    required this.count,
    required this.isSelected,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? color : const Color(0xFFEEEEEE),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isSelected ? Colors.white : AppColors.textSecondary,
        ),
      ),
    );
  }
}
