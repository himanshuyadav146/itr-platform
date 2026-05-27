import 'package:flutter/material.dart';

/// Breakpoints and helpers for width-aware grids across phone, tablet, and wide layouts.
class ResponsiveLayout {
  ResponsiveLayout._();

  static const double tabletBreakpoint = 600;
  static const double desktopBreakpoint = 900;

  /// Column count from available width (defaults: 2 / 3 / 4).
  static int columnCount(
    double maxWidth, {
    int phoneColumns = 2,
    int tabletColumns = 3,
    int wideColumns = 4,
  }) {
    if (maxWidth >= desktopBreakpoint) return wideColumns;
    if (maxWidth >= tabletBreakpoint) return tabletColumns;
    return phoneColumns;
  }

  /// Equal tile width for [columns] items with [spacing] between them.
  static double itemWidth(
    double maxWidth, {
    required int columns,
    required double spacing,
  }) {
    final safeColumns = columns.clamp(1, 12);
    final totalSpacing = spacing * (safeColumns - 1);
    return (maxWidth - totalSpacing) / safeColumns;
  }

  /// Width for a horizontal carousel card (~78% of parent, clamped).
  static double horizontalCardWidth(double maxWidth) {
    return (maxWidth * 0.78).clamp(260.0, 420.0);
  }
}

/// Fills available width with a responsive column count; each child gets equal width.
class ResponsiveWrapGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final int phoneColumns;
  final int tabletColumns;
  final int wideColumns;

  const ResponsiveWrapGrid({
    super.key,
    required this.children,
    this.spacing = 16,
    this.runSpacing = 16,
    this.phoneColumns = 2,
    this.tabletColumns = 3,
    this.wideColumns = 4,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = ResponsiveLayout.columnCount(
          constraints.maxWidth,
          phoneColumns: phoneColumns,
          tabletColumns: tabletColumns,
          wideColumns: wideColumns,
        );
        final itemWidth = ResponsiveLayout.itemWidth(
          constraints.maxWidth,
          columns: columns,
          spacing: spacing,
        );

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: children
              .map(
                (child) => SizedBox(
                  width: itemWidth,
                  child: child,
                ),
              )
              .toList(),
        );
      },
    );
  }
}
