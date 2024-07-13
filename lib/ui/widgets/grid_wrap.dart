import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:math' as math;

enum GridWrapAlignment {
  start,
  end,
  center,
  spaceBetween,
  spaceAround,
  spaceEvenly,
}

///最后一行的布局方式
enum GridWrapLastRunLayout {
  ///跟随设置的alignment[GridWrapAlignment]
  none,

  /// 网格对齐上面的部分
  grid,
}

class GridWrapParentData extends ContainerBoxParentData<RenderBox> {
  int _runIndex = 0;
}

class _RunMetrics {
  final double width;
  final double height;
  final int childCount;

  _RunMetrics(this.width, this.height, this.childCount);
}

class GridWrap extends MultiChildRenderObjectWidget {
  final GridWrapAlignment alignment;
  final GridWrapAlignment runAlignment;
  final GridWrapLastRunLayout lastRunLayout;
  final double spacing;
  final double runSpacing;
  final Clip clipBehavior;

  const GridWrap({
    super.key,
    this.alignment = GridWrapAlignment.start,
    this.runAlignment = GridWrapAlignment.start,
    this.lastRunLayout = GridWrapLastRunLayout.grid,
    this.spacing = 0.0,
    this.runSpacing = 0.0,
    this.clipBehavior = Clip.none,
    super.children,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderIWrap(
        alignment: alignment,
        runAlignment: runAlignment,
        lastRunLayout: lastRunLayout,
        spacing: spacing,
        runSpacing: runSpacing,
        clipBehavior: clipBehavior);
  }

  @override
  void updateRenderObject(BuildContext context, RenderIWrap renderObject) {
    renderObject
      ..alignment = alignment
      ..runAlignment = runAlignment
      ..lastRunLayout = lastRunLayout
      ..spacing = spacing
      ..runSpacing = runSpacing
      ..clipBehavior = clipBehavior;
  }
}

class RenderIWrap extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, GridWrapParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, GridWrapParentData> {
  GridWrapAlignment _alignment;
  GridWrapAlignment _runAlignment;
  GridWrapLastRunLayout _lastRunLayout;
  double _spacing;
  double _runSpacing;
  Clip _clipBehavior;

  GridWrapAlignment get runAlignment => _runAlignment;

  set runAlignment(GridWrapAlignment value) {
    if (value != _runAlignment) {
      _runAlignment = value;
      markNeedsLayout();
    }
  }

  GridWrapLastRunLayout get lastRunLayout => _lastRunLayout;

  set lastRunLayout(GridWrapLastRunLayout value) {
    if (value != _lastRunLayout) {
      _lastRunLayout = value;
      markNeedsLayout();
    }
  }

  double get spacing => _spacing;

  set spacing(double value) {
    if (value != spacing) {
      _spacing = value;
      markNeedsLayout();
    }
  }

  double get runSpacing => _runSpacing;

  set runSpacing(double value) {
    if (value != _runSpacing) {
      _runSpacing = value;
      markNeedsLayout();
    }
  }

  GridWrapAlignment get alignment => _alignment;

  set alignment(GridWrapAlignment value) {
    if (value != alignment) {
      _alignment = value;
      markNeedsLayout();
    }
  }

  Clip get clipBehavior => _clipBehavior;

  set clipBehavior(Clip value) {
    if (value != _clipBehavior) {
      _clipBehavior = value;
      markNeedsLayout();
    }
  }

  bool _hasVisualOverflow = false;

  RenderIWrap(
      {List<RenderBox>? children,
      GridWrapAlignment alignment = GridWrapAlignment.start,
      GridWrapAlignment runAlignment = GridWrapAlignment.start,
      GridWrapLastRunLayout lastRunLayout = GridWrapLastRunLayout.grid,
      double spacing = 0.0,
      double runSpacing = 0.0,
      Clip clipBehavior = Clip.none})
      : _alignment = alignment,
        _lastRunLayout = lastRunLayout,
        _spacing = spacing,
        _runAlignment = runAlignment,
        _runSpacing = runSpacing,
        _clipBehavior = clipBehavior {
    addAll(children);
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! GridWrapParentData) {
      child.parentData = GridWrapParentData();
    }
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    double width = 0.0;
    RenderBox? child = firstChild;
    while (child != null) {
      width = math.max(width, child.getMinIntrinsicWidth(double.infinity));
      child = childAfter(child);
    }
    return width;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    double width = 0.0;
    RenderBox? child = firstChild;
    while (child != null) {
      width += child.getMaxIntrinsicWidth(double.infinity);
      child = childAfter(child);
    }
    return width;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    return computeDryLayout(BoxConstraints(maxWidth: width)).height;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    return computeDryLayout(BoxConstraints(maxWidth: width)).height;
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    return defaultComputeDistanceToHighestActualBaseline(baseline);
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    BoxConstraints childConstrains =
        BoxConstraints(maxWidth: constraints.maxWidth);
    double width = 0.0;
    double height = 0.0;
    double runWidth = 0.0;
    double runHeight = 0.0;
    int childCount = 0;
    RenderBox? child = firstChild;
    while (child != null) {
      final Size childSize =
          ChildLayoutHelper.dryLayoutChild(child, childConstrains);
      final double childWidth = childSize.width;
      final double childHeight = childSize.height;
      // There must be at least one child before we move on to the next run.
      if (childCount > 0 &&
          runWidth + childWidth + spacing > constraints.maxWidth) {
        width = math.max(width, runWidth);
        height += runHeight + runSpacing;
        runWidth = 0.0;
        runHeight = 0.0;
        childCount = 0;
      }
      runWidth += childWidth;
      runHeight = math.max(runHeight, childHeight);
      if (childCount > 0) {
        runWidth += spacing;
      }
      childCount++;
      child = childAfter(child);
    }
    return constraints.constrain(Size(width, height));
  }

  @override
  void performLayout() {
    final BoxConstraints constraints = this.constraints;
    _hasVisualOverflow = false;
    RenderBox? child = firstChild;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    final BoxConstraints childConstraints;
    double mainAxisLimit = 0.0;
    childConstraints = BoxConstraints(maxWidth: constraints.maxWidth);
    mainAxisLimit = constraints.maxWidth;
    final double spacing = this.spacing;
    final double runSpacing = this.runSpacing;
    final List<_RunMetrics> runMetrics = <_RunMetrics>[];
    double width = 0.0;
    double height = 0.0;
    double runWidth = 0.0;
    double runHeight = 0.0;
    int childCount = 0;
    while (child != null) {
      child.layout(childConstraints, parentUsesSize: true);
      final double childWidth = child.size.width;
      final double childHeight = child.size.height;
      if (childCount > 0 && runWidth + spacing + childWidth > mainAxisLimit) {
        width = math.max(width, runWidth);
        height += runHeight;
        if (runMetrics.isNotEmpty) {
          height += runSpacing;
        }
        runMetrics.add(_RunMetrics(runWidth, runHeight, childCount));
        runWidth = 0.0;
        runHeight = 0.0;
        childCount = 0;
      }
      runWidth += childWidth;
      if (childCount > 0) {
        runWidth += spacing;
      }
      runHeight = math.max(runHeight, childHeight);
      childCount += 1;
      final GridWrapParentData childParentData =
          child.parentData! as GridWrapParentData;
      childParentData._runIndex = runMetrics.length;
      child = childParentData.nextSibling;
    }
    if (childCount > 0) {
      width = math.max(width, runWidth);
      height += runHeight;
      if (runMetrics.isNotEmpty) {
        height += runSpacing;
      }
      runMetrics.add(_RunMetrics(runWidth, runHeight, childCount));
    }

    final int runCount = runMetrics.length;
    assert(runCount > 0);

    double containerWidth = 0.0;
    double containerHeight = 0.0;

    size = constraints.constrain(Size(width, height));
    containerWidth = size.width;
    containerHeight = size.height;

    _hasVisualOverflow = containerWidth < width || containerHeight < height;

    final double crossAxisFreeSpace = math.max(0.0, containerHeight - height);
    double runLeadingSpace = 0.0;
    double runBetweenSpace = 0.0;
    switch (runAlignment) {
      case GridWrapAlignment.start:
        break;
      case GridWrapAlignment.end:
        runLeadingSpace = crossAxisFreeSpace;
        break;
      case GridWrapAlignment.center:
        runLeadingSpace = crossAxisFreeSpace / 2.0;
        break;
      case GridWrapAlignment.spaceBetween:
        runBetweenSpace =
            runCount > 1 ? crossAxisFreeSpace / (runCount - 1) : 0.0;
        break;
      case GridWrapAlignment.spaceAround:
        runBetweenSpace = crossAxisFreeSpace / runCount;
        runLeadingSpace = runBetweenSpace / 2.0;
        break;
      case GridWrapAlignment.spaceEvenly:
        runBetweenSpace = crossAxisFreeSpace / (runCount + 1);
        runLeadingSpace = runBetweenSpace;
        break;
    }

    runBetweenSpace += runSpacing;
    double crossAxisOffset = runLeadingSpace;

    child = firstChild;
    //当lastRunLayout设置为grid,或者只有一行的时候全部按alignment绘制
    if (lastRunLayout == GridWrapLastRunLayout.none || runCount == 1) {
      for (int i = 0; i < runCount; ++i) {
        final _RunMetrics metrics = runMetrics[i];
        final double runWidth = metrics.width;
        final double runHeight = metrics.height;
        final int childCount = metrics.childCount;

        final double lineFreeSpace = math.max(0.0, containerWidth - runWidth);
        double childLeadingSpace = 0.0;
        double childBetweenSpace = 0.0;

        switch (alignment) {
          case GridWrapAlignment.start:
            break;
          case GridWrapAlignment.end:
            childLeadingSpace = lineFreeSpace;
            break;
          case GridWrapAlignment.center:
            childLeadingSpace = lineFreeSpace / 2.0;
            break;
          case GridWrapAlignment.spaceBetween:
            childBetweenSpace =
                childCount > 1 ? lineFreeSpace / (childCount - 1) : 0.0;
            break;
          case GridWrapAlignment.spaceAround:
            childBetweenSpace = lineFreeSpace / childCount;
            childLeadingSpace = childBetweenSpace / 2.0;
            break;
          case GridWrapAlignment.spaceEvenly:
            childBetweenSpace = lineFreeSpace / (childCount + 1);
            childLeadingSpace = childBetweenSpace;
            break;
        }

        childBetweenSpace += spacing;
        double childMainPosition = childLeadingSpace;
        while (child != null) {
          final GridWrapParentData childParentData =
              child.parentData! as GridWrapParentData;
          if (childParentData._runIndex != i) {
            break;
          }
          const double childCrossAxisOffset = 0;
          childParentData.offset =
              Offset(childMainPosition, crossAxisOffset + childCrossAxisOffset);
          childMainPosition += child.size.width + childBetweenSpace;
          child = childParentData.nextSibling;
        }
        crossAxisOffset += runHeight + runBetweenSpace;
      }
    } else if (lastRunLayout == GridWrapLastRunLayout.grid) {
      double leadingSpace = 0.0;
      double betweenSpace = 0.0;
      int i = 0;
      //绘制除末尾行外的行
      for (i = 0; i < runCount - 1; ++i) {
        final _RunMetrics metrics = runMetrics[i];
        final double runWidth = metrics.width;
        final double runHeight = metrics.height;
        final int childCount = metrics.childCount;

        final double lineFreeSpace = math.max(0.0, containerWidth - runWidth);
        double childLeadingSpace = 0.0;
        double childBetweenSpace = 0.0;

        switch (alignment) {
          case GridWrapAlignment.start:
            break;
          case GridWrapAlignment.end:
            childLeadingSpace = lineFreeSpace;
            break;
          case GridWrapAlignment.center:
            childLeadingSpace = lineFreeSpace / 2.0;
            break;
          case GridWrapAlignment.spaceBetween:
            childBetweenSpace =
                childCount > 1 ? lineFreeSpace / (childCount - 1) : 0.0;
            break;
          case GridWrapAlignment.spaceAround:
            childBetweenSpace = lineFreeSpace / childCount;
            childLeadingSpace = childBetweenSpace / 2.0;
            break;
          case GridWrapAlignment.spaceEvenly:
            childBetweenSpace = lineFreeSpace / (childCount + 1);
            childLeadingSpace = childBetweenSpace;
            break;
        }

        childBetweenSpace += spacing;
        leadingSpace = childLeadingSpace;
        betweenSpace = childBetweenSpace;
        double childMainPosition = childLeadingSpace;
        while (child != null) {
          final GridWrapParentData childParentData =
              child.parentData! as GridWrapParentData;
          if (childParentData._runIndex != i) {
            break;
          }
          const double childCrossAxisOffset = 0;
          childParentData.offset =
              Offset(childMainPosition, crossAxisOffset + childCrossAxisOffset);
          childMainPosition += child.size.width + childBetweenSpace;
          child = childParentData.nextSibling;
        }
        crossAxisOffset += runHeight + runBetweenSpace;
      }
      double childBetweenSpace = betweenSpace;
      double childMainPosition = leadingSpace;
      while (child != null) {
        final GridWrapParentData childParentData =
            child.parentData! as GridWrapParentData;
        if (childParentData._runIndex != i) {
          break;
        }
        const double childCrossAxisOffset = 0;
        childParentData.offset =
            Offset(childMainPosition, crossAxisOffset + childCrossAxisOffset);
        childMainPosition += child.size.width + childBetweenSpace;
        child = childParentData.nextSibling;
      }
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_hasVisualOverflow && clipBehavior != Clip.none) {
      _clipRectLayer.layer = context.pushClipRect(
        needsCompositing,
        offset,
        Offset.zero & size,
        defaultPaint,
        clipBehavior: clipBehavior,
        oldLayer: _clipRectLayer.layer,
      );
    } else {
      _clipRectLayer.layer = null;
      defaultPaint(context, offset);
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }

  final LayerHandle<ClipRectLayer> _clipRectLayer =
      LayerHandle<ClipRectLayer>();

  @override
  void dispose() {
    _clipRectLayer.layer = null;
    super.dispose();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<GridWrapAlignment>('alignment', alignment));
    properties.add(DoubleProperty('spacing', spacing));
    properties.add(EnumProperty<GridWrapAlignment>('runAlignment', runAlignment));
    properties.add(DoubleProperty('runSpacing', runSpacing));
    properties.add(DoubleProperty('crossAxisAlignment', runSpacing));
  }
}
