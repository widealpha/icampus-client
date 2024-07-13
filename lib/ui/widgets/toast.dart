import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/cupertino.dart';

class Toast {
  static VoidCallback show(String text) {
    return BotToast.showText(text: text);
  }

  static void cancelAll() {
    BotToast.cleanAll();
  }

  static VoidCallback showLoading({
    bool crossPage = true,
    bool clickClose = false,
    bool allowClick = false,
    bool enableKeyboardSafeArea = true,
    VoidCallback? onClose,
  }) {
    return BotToast.showLoading(
        crossPage: crossPage,
        clickClose: clickClose,
        allowClick: allowClick,
        enableKeyboardSafeArea: enableKeyboardSafeArea,
        onClose: onClose);
  }
}
