import 'package:flutter/material.dart';

extension ContextExtension on BuildContext {
  ThemeData get theme => Theme.of(this);

  Size get size => MediaQuery.of(this).size;

  double get width => MediaQuery.of(this).size.width;

  double get height => MediaQuery.of(this).size.height;

  Future<T?> to<T>(WidgetBuilder builder, {Object? arguments}) {
    return Navigator.of(this).push(MaterialPageRoute(
        builder: (ctx) => builder(ctx),
        settings: RouteSettings(arguments: arguments)));
  }
}
