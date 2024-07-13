import 'package:flutter/material.dart';

import '../../utils/platform_utils.dart';
import 'grid_wrap.dart';

class ChoosePanelController<T> {
  _ChoosePanelState<T>? _state;

  List<T> get selected => [...?_state?._selected];

  set selected(List<T> value) {
    if (_state != null && _state!.mounted) {
      _state!.updateSelected([...value]);
    }
  }

  void dispose() {
    _state = null;
  }
}

///选择面板
class ChoosePanel<T> extends StatefulWidget {
  ///结果保存在这里
  final ChoosePanelController<T> controller;
  final List<T> defaultSelected;
  final List<T> choices;
  final Color? selectedBackgroundColor;
  final Color? unSelectedBackgroundColor;
  final Color? textColor;
  final Widget Function(T choice, bool select)? itemBuilder;

  const ChoosePanel(
      {Key? key,
      required this.controller,
      required this.choices,
      this.defaultSelected = const [],
      this.selectedBackgroundColor,
      this.unSelectedBackgroundColor,
      this.textColor,
      this.itemBuilder})
      : super(key: key);

  @override
  State<ChoosePanel<T>> createState() => _ChoosePanelState();
}

class _ChoosePanelState<T> extends State<ChoosePanel<T>> {
  List<T> _selected = [];

  ///声明GlobalKey以在后续获取子组件位置
  final List<GlobalObjectKey> keyList = [];

  /// 点击的落点位置信息
  Offset tapPosition = Offset.zero;

  /// 最后一次经过的子组件位置信息,在同一组件内滑动不重复更新状态
  Rect? lastPassChildRect;

  @override
  void initState() {
    super.initState();
    //声明GlobalKey以在后续获取子组件位置
    keyList.addAll(List.generate(widget.choices.length,
        (index) => _GlobalValueKey(widget.choices[index]!)));
    for (var choice in widget.defaultSelected) {
      if (widget.choices.contains(choice)) {
        _selected.add(choice);
      }
    }
    widget.controller._state = this;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: () {
            //当点击事件完成后,遍历GlobalKey确定点击的位置
            for (GlobalObjectKey key in keyList) {
              // 获取当前key附属组件的renderBox
              var box = key.currentContext!.findRenderObject() as RenderBox;
              // 计算组件在全局中的位置约束信息
              var rect = box.localToGlobal(Offset.zero) & box.size;
              //判断点击的位置是否落入组件中
              if (rect.contains(tapPosition)) {
                //落点在组件中,根据key中携带的信息更新组件状态
                T value = key.value as T;
                _selected.contains(value)
                    ? _selected.remove(value)
                    : _selected.add(value);
                setState(() {});
                break;
              }
            }
          },
          onTapUp: (detail) {
            tapPosition = detail.globalPosition;
          },
          onPanUpdate: (detail) {
            var position = detail.globalPosition;
            //当第一次更新手势或者上一次经过的组件与当前组件不一致的时候
            //遍历所有子组件寻找现在的位置所在的组件
            if (lastPassChildRect == null ||
                !lastPassChildRect!.contains(position)) {
              for (var key in keyList) {
                // 获取当前key附属组件的renderBox
                var box = key.currentContext!.findRenderObject() as RenderBox;
                // 计算组件在全局中的位置以及大小信息
                var rect = box.localToGlobal(Offset.zero) & box.size;
                //判断当前手势的位置是否落入组件中
                if (rect.contains(position)) {
                  //落点在组件中,根据key中携带的信息更新组件状态
                  T value = key.value as T;
                  _selected.contains(value)
                      ? _selected.remove(value)
                      : _selected.add(value);
                  //记录当前位置所在的组件位置及大小
                  lastPassChildRect = rect;
                  setState(() {});
                  break;
                }
              }
            }
          },
          onPanEnd: (_) {
            //手势结束清除最后一次经过的子组件位置信息
            lastPassChildRect = null;
          },
          child: GridWrap(
            spacing: 5.0,
            runSpacing: 5.0,
            alignment: GridWrapAlignment.spaceBetween,
            children: List.generate(widget.choices.length, (i) {
              T choice = widget.choices[i];
              bool selected = _selected.contains(choice);
              return Builder(
                  key: keyList[i],
                  builder: (context) {
                    if (widget.itemBuilder != null) {
                      return AbsorbPointer(
                          child: widget.itemBuilder!(choice, selected));
                    } else {
                      return Container(
                        alignment: Alignment.center,
                        constraints: BoxConstraints.tight(
                            PlatformUtils.isDesktop
                                ? const Size(56, 32)
                                : const Size(64, 40)),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4.0),
                            color: selected
                                ? widget.selectedBackgroundColor ??
                                    Theme.of(context).colorScheme.primary
                                : widget.unSelectedBackgroundColor ??
                                    Theme.of(context).disabledColor),
                        child: Text(
                          '$choice',
                          style: TextStyle(
                              color: widget.textColor ??
                                  Theme.of(context).colorScheme.onPrimary,
                              fontSize: 16),
                        ),
                      );
                    }
                  });
            }).toList(),
          ),
        ),
      ],
    );
  }

  void updateSelected(List<T> selected) {
    setState(() {
      this._selected = selected;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class _GlobalValueKey extends GlobalObjectKey {
  const _GlobalValueKey(super.value);

  @override
  bool operator ==(Object other) => identical(this, other);

  @override
  int get hashCode => identityHashCode(value);
}
