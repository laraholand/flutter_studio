import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

class TabData {
  final int index;
  final Tab title;
  final Widget content;

  TabData({required this.index, required this.title, required this.content});
}

enum MoveToTab { idol, next, previous, first, last }

class DynamicTabBarWidget extends StatefulWidget {
  final List<TabData> dynamicTabs;
  final Function(TabController) onTabControllerUpdated;
  final Function(int?)? onTabChanged;

  final MoveToTab? onAddTabMoveTo;
  final int? onAddTabMoveToIndex;

  final bool isScrollable;
  final ScrollPhysics? physicsTabBarView;

  const DynamicTabBarWidget({
    super.key,
    required this.dynamicTabs,
    required this.onTabControllerUpdated,
    this.onTabChanged,
    this.onAddTabMoveTo,
    this.onAddTabMoveToIndex,
    this.isScrollable = true,
    this.physicsTabBarView,
  });

  @override
  State<DynamicTabBarWidget> createState() => _DynamicTabBarWidgetState();
}

class _DynamicTabBarWidgetState extends State<DynamicTabBarWidget>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int activeTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = _createController(
      length: widget.dynamicTabs.length,
      initialIndex: 0,
    );
  }

  TabController _createController({
    required int length,
    required int initialIndex,
  }) {
    final controller = TabController(
      length: length,
      vsync: this,
      initialIndex: initialIndex >= length ? length - 1 : initialIndex,
    );

    controller.addListener(() {
      if (!controller.indexIsChanging) return;

      setState(() {
        activeTab = controller.index;
      });

      widget.onTabChanged?.call(controller.index);
    });

    widget.onTabControllerUpdated(controller);

    return controller;
  }

  @override
  void didUpdateWidget(covariant DynamicTabBarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Only recreate controller if length changed
    if (widget.dynamicTabs.length != oldWidget.dynamicTabs.length) {
      final currentIndex = _tabController.index;

      _tabController.dispose();

      _tabController = _createController(
        length: widget.dynamicTabs.length,
        initialIndex: currentIndex,
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.dynamicTabs.isEmpty) {
      return const SizedBox();
    }

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
      ),
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            isScrollable: widget.isScrollable,
            tabs: widget.dynamicTabs.map((tab) => tab.title).toList(),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: widget.physicsTabBarView,
              children: widget.dynamicTabs
                  .map(
                    (tab) => KeepAliveWrapper(
                      child: KeyedSubtree(
                        key: ValueKey(tab.index),
                        child: tab.content,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class KeepAliveWrapper extends StatefulWidget {
  final Widget child;

  const KeepAliveWrapper({super.key, required this.child});

  @override
  State<KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // VERY IMPORTANT
    return widget.child;
  }
}
