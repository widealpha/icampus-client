import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'package:rfw/rfw.dart';

LocalWidgetLibrary createCustomWidgets() =>
    LocalWidgetLibrary(_customWidgetsDefinitions);

Map<String, LocalWidgetBuilder> get _customWidgetsDefinitions =>
    <String, LocalWidgetBuilder>{
      'HtmlWidget': (context, source) => SelectionArea(
            child: HtmlWidget(
              source.v<String>(['html']) ?? '<html lang="ZH_CN"></html>',
              buildAsync: true,
              enableCaching: false,
              renderMode: const ListViewMode(padding: EdgeInsets.all(12)),
              customStylesBuilder: (element) {
                Map<String, String> styles = {};
                //给table加入边框
                switch (element.localName) {
                  case 'table':
                    styles['border'] = '1px solid';
                    styles['border-collapse'] = 'collapse';
                    break;
                  case 'td':
                    styles['border'] = '1px solid';
                    break;
                }
                return styles;
              },
              onLoadingBuilder: (context, element, loadingProgress) =>
                  const Center(child: CircularProgressIndicator()),
              onTapUrl: (url) async {
                source.handler(
                    <Object>['onTapUrl'],
                    (HandlerTrigger trigger) => (String value) {
                          return trigger(<String, String>{'value': value});
                        })?.call(url);
                return true;
              },
            ),
          ),
      'Input': (context, source) {
        return StatefulTextField(
          text: source.v<String>(['value']) ?? '',
          enabled: source.v<bool>(['enabled']),
          isDense: source.v<bool>(['isDense']),
          hintText: source.v<String>(['hintText']) ?? '',
          labelText: source.v<String>(['labelText']) ?? '',
          errorText: source.v<String>(['errorText']) ?? '',
          inputBorder: source.v<String>(['inputBorder']),
          maxLength: source.v<int>(['maxLength']),
          maxLines: source.v<int>(['maxLines']),
          style: ArgumentDecoders.textStyle(source, ['style']),
          onChanged: source.handler(
              <Object>['onChanged'],
              (HandlerTrigger trigger) => (String value) {
                    return trigger(<String, String>{'value': value});
                  }),
          onSubmitted: source.handler(
              <Object>['onSubmitted'],
              (HandlerTrigger trigger) => (String value) {
                    return trigger(<String, String>{'value': value});
                  }),
        );
      },
      'IndexPage': (context, source) {
        return IndexedStack(
          index: source.v<int>(['index']),
          alignment: ArgumentDecoders.alignment(source, ['alignment']) ??
              AlignmentDirectional.topStart,
          children: source.childList(['children']),
        );
      },
      'SmartRefresher': (context, source) {
        return SmartRefresher(
          controller: RefreshController(),
        );
      }
    };

class StatefulTextField extends StatefulWidget {
  final String text;
  final bool? enabled;
  final bool? isDense;
  final String hintText;
  final String labelText;
  final String errorText;
  final String? inputBorder;
  final int? maxLength;
  final int? maxLines;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextStyle? style;

  const StatefulTextField({
    super.key,
    this.text = '',
    this.hintText = '',
    this.labelText = '',
    this.errorText = '',
    this.inputBorder,
    this.onChanged,
    this.enabled,
    this.isDense,
    this.maxLength,
    this.maxLines,
    this.onSubmitted,
    this.style,
  });

  @override
  State<StatefulTextField> createState() => _StatefulTextFieldState();
}

class _StatefulTextFieldState extends State<StatefulTextField> {
  late final _controller = TextEditingController(text: widget.text);

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      enabled: widget.enabled,
      maxLength: widget.maxLength,
      maxLines: widget.maxLines,
      decoration: _decodeInputDecoration(),
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      style: widget.style,
    );
  }

  InputDecoration _decodeInputDecoration() {
    InputBorder border = const UnderlineInputBorder();
    if (widget.inputBorder == 'underline') {
      border = const UnderlineInputBorder();
    } else if (widget.inputBorder == 'outline') {
      border = const OutlineInputBorder();
    } else if (widget.inputBorder == 'none') {
      border = InputBorder.none;
    }
    return InputDecoration(
      border: border,
      hintText: widget.hintText.isEmpty ? null : widget.hintText,
      labelText: widget.labelText.isEmpty ? null : widget.labelText,
      errorText: widget.errorText.isEmpty ? null : widget.errorText,
      isDense: widget.isDense,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
