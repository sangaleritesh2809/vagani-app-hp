import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Navigation item model for [ResponsiveBottomNavBar].
class ResponsiveBottomNavItem {
  final IconData icon;
  final IconData? selectedIcon;
  final String label;
  final String? tooltip;

  const ResponsiveBottomNavItem({
    required this.icon,
    this.selectedIcon,
    required this.label,
    this.tooltip,
  });
}

/// A responsive, state-of-the-art bottom navigation bar for mobile and tablet screens.
///
/// Can operate in icon-only mode (`showLabels: false`) or with text labels (`showLabels: true`).
/// In icon-only mode, all 7 navigation items fit comfortably across any standard mobile screen width
/// with zero horizontal scrolling, clipping, or overlapping, while keeping tooltips on long-press.
class ResponsiveBottomNavBar extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final List<ResponsiveBottomNavItem> items;
  final bool showLabels;
  final Color? backgroundColor;
  final Color? indicatorColor;
  final Color? selectedItemColor;
  final Color? unselectedItemColor;
  final Color? selectedLabelColor;
  final Color? unselectedLabelColor;
  final double? height;
  final double? minItemWidth;

  const ResponsiveBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.items,
    this.showLabels = false,
    this.backgroundColor,
    this.indicatorColor,
    this.selectedItemColor,
    this.unselectedItemColor,
    this.selectedLabelColor,
    this.unselectedLabelColor,
    this.height,
    this.minItemWidth,
  });

  @override
  State<ResponsiveBottomNavBar> createState() => _ResponsiveBottomNavBarState();
}

class _ResponsiveBottomNavBarState extends State<ResponsiveBottomNavBar> {
  final ScrollController _scrollController = ScrollController();
  double _lastAvailableWidth = 0;
  bool _showLeftFade = false;
  bool _showRightFade = false;

  double get _effectiveHeight =>
      widget.height ?? (widget.showLabels ? 66.0 : 58.0);
  double get _effectiveMinItemWidth =>
      widget.minItemWidth ?? (widget.showLabels ? 76.0 : 46.0);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateScrollFades);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToIndex(widget.selectedIndex, animate: false);
      _updateScrollFades();
    });
  }

  @override
  void didUpdateWidget(covariant ResponsiveBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex ||
        oldWidget.items.length != widget.items.length ||
        oldWidget.showLabels != widget.showLabels) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToIndex(widget.selectedIndex, animate: true);
        _updateScrollFades();
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateScrollFades);
    _scrollController.dispose();
    super.dispose();
  }

  void _updateScrollFades() {
    if (!mounted || !_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    final canScroll = maxScroll > 0;

    final showLeft = canScroll && currentScroll > 4;
    final showRight = canScroll && currentScroll < maxScroll - 4;

    if (showLeft != _showLeftFade || showRight != _showRightFade) {
      setState(() {
        _showLeftFade = showLeft;
        _showRightFade = showRight;
      });
    }
  }

  double _calculateItemWidth(double availableWidth) {
    if (widget.items.isEmpty) return _effectiveMinItemWidth;
    final totalNeeded = widget.items.length * _effectiveMinItemWidth;
    if (availableWidth >= totalNeeded) {
      return availableWidth / widget.items.length;
    }
    // For scrollable mode when width is extremely small
    final divisor = widget.showLabels ? 4.4 : 6.0;
    final proportionalWidth = availableWidth / divisor;
    return proportionalWidth.clamp(_effectiveMinItemWidth, 96.0);
  }

  void _scrollToIndex(int index, {bool animate = true}) {
    if (!_scrollController.hasClients || widget.items.isEmpty) return;
    if (index < 0 || index >= widget.items.length) return;

    final itemWidth = _calculateItemWidth(_lastAvailableWidth);
    final targetOffset =
        (index * itemWidth) - (_lastAvailableWidth / 2) + (itemWidth / 2);
    final maxScroll = _scrollController.position.maxScrollExtent;
    final minScroll = _scrollController.position.minScrollExtent;
    final clampedOffset = targetOffset.clamp(minScroll, maxScroll);

    if (animate) {
      _scrollController.animateTo(
        clampedOffset,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    } else {
      _scrollController.jumpTo(clampedOffset);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final effectiveBgColor = widget.backgroundColor ??
        (isDark ? AppColors.darkSurface : Colors.white);
    final effectiveIndicatorColor = widget.indicatorColor ??
        (isDark
            ? AppColors.secondaryLight.withValues(alpha: 0.3)
            : AppColors.secondary);
    final effectiveSelectedIconColor =
        widget.selectedItemColor ?? (isDark ? Colors.white : Colors.white);
    final effectiveUnselectedIconColor = widget.unselectedItemColor ??
        (isDark ? AppColors.darkTextSecondary : const Color(0xFF475569));
    final effectiveSelectedLabelColor = widget.selectedLabelColor ??
        (isDark ? Colors.white : AppColors.secondaryDark);
    final effectiveUnselectedLabelColor = widget.unselectedLabelColor ??
        (isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B));

    return Material(
      color: effectiveBgColor,
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
      child: SafeArea(
        top: false,
        bottom: true,
        child: Container(
          height: _effectiveHeight,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 1,
              ),
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              _lastAvailableWidth = constraints.maxWidth;
              final itemWidth = _calculateItemWidth(constraints.maxWidth);
              final totalItemsWidth =
                  widget.items.length * _effectiveMinItemWidth;
              final fitsWithoutScroll = constraints.maxWidth >= totalItemsWidth;

              if (fitsWithoutScroll) {
                // If items fit cleanly across the available width, distribute evenly
                return Row(
                  children: List.generate(
                    widget.items.length,
                    (index) => Expanded(
                      child: _buildItem(
                        context: context,
                        index: index,
                        item: widget.items[index],
                        isSelected: index == widget.selectedIndex,
                        indicatorColor: effectiveIndicatorColor,
                        selectedIconColor: effectiveSelectedIconColor,
                        unselectedIconColor: effectiveUnselectedIconColor,
                        selectedLabelColor: effectiveSelectedLabelColor,
                        unselectedLabelColor: effectiveUnselectedLabelColor,
                        isDark: isDark,
                      ),
                    ),
                  ),
                );
              }

              // Otherwise render horizontally scrollable bar
              return Stack(
                children: [
                  ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context).copyWith(
                      dragDevices: {
                        PointerDeviceKind.touch,
                        PointerDeviceKind.mouse,
                        PointerDeviceKind.trackpad,
                      },
                    ),
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          widget.items.length,
                          (index) => SizedBox(
                            width: itemWidth,
                            child: _buildItem(
                              context: context,
                              index: index,
                              item: widget.items[index],
                              isSelected: index == widget.selectedIndex,
                              indicatorColor: effectiveIndicatorColor,
                              selectedIconColor: effectiveSelectedIconColor,
                              unselectedIconColor: effectiveUnselectedIconColor,
                              selectedLabelColor: effectiveSelectedLabelColor,
                              unselectedLabelColor:
                                  effectiveUnselectedLabelColor,
                              isDark: isDark,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Left fade gradient cue
                  if (_showLeftFade)
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: 18,
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                effectiveBgColor,
                                effectiveBgColor.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Right fade gradient cue
                  if (_showRightFade)
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      width: 18,
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerRight,
                              end: Alignment.centerLeft,
                              colors: [
                                effectiveBgColor,
                                effectiveBgColor.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildItem({
    required BuildContext context,
    required int index,
    required ResponsiveBottomNavItem item,
    required bool isSelected,
    required Color indicatorColor,
    required Color selectedIconColor,
    required Color unselectedIconColor,
    required Color selectedLabelColor,
    required Color unselectedLabelColor,
    required bool isDark,
  }) {
    return Semantics(
      selected: isSelected,
      button: true,
      label: item.label,
      child: Tooltip(
        message: item.tooltip ?? item.label,
        waitDuration: const Duration(milliseconds: 500),
        child: InkWell(
          onTap: () {
            widget.onItemSelected(index);
            _scrollToIndex(index, animate: true);
          },
          borderRadius: BorderRadius.circular(16),
          splashColor: indicatorColor.withValues(alpha: 0.15),
          highlightColor: Colors.transparent,
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: widget.showLabels ? 5 : 6,
              horizontal: 2,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon pill container (fixed 52x30 preserves identical vertical alignment)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  width: 52,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isSelected ? indicatorColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Icon(
                      isSelected ? (item.selectedIcon ?? item.icon) : item.icon,
                      size: 22,
                      color:
                          isSelected ? selectedIconColor : unselectedIconColor,
                    ),
                  ),
                ),
                if (widget.showLabels) ...[
                  const SizedBox(height: 3),
                  // Text label: exactly single line, with ellipsis protection, centered
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        letterSpacing: -0.15,
                        color: isSelected
                            ? selectedLabelColor
                            : unselectedLabelColor,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
