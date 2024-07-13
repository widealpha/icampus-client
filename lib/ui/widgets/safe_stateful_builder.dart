import 'package:flutter/material.dart';

///封装修改StatefulBuilder,使用setState的时候自动判断mounted
class SafeStatefulBuilder extends StatefulWidget {
  final VoidCallback? initState;
  final StatefulWidgetBuilder builder;
  final VoidCallback? dispose;

  const SafeStatefulBuilder({
    Key? key,
    required this.builder,
    this.initState,
    this.dispose,
  }) : super(key: key);

  @override
  State<SafeStatefulBuilder> createState() => _SafeStatefulBuilderState();
}

class _SafeStatefulBuilderState extends State<SafeStatefulBuilder> {
  @override
  void initState() {
    super.initState();
    widget.initState?.call();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, (callback) {
        if (mounted) {
          setState(callback);
        }
      });

  @override
  void dispose() {
    super.dispose();
    widget.dispose?.call();
  }
}
