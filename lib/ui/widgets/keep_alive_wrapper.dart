import 'package:flutter/material.dart';

class AutomaticKeepAliveWrapper extends StatefulWidget {
  final Widget child;
  final bool keepAlive;

  const AutomaticKeepAliveWrapper(
      {super.key, required this.child, required this.keepAlive});

  @override
  State<AutomaticKeepAliveWrapper> createState() =>
      _AutomaticKeepAliveWrapperState();
}

class _AutomaticKeepAliveWrapperState extends State<AutomaticKeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }

  @override
  bool get wantKeepAlive => widget.keepAlive;
}
