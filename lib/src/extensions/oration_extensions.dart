import 'package:maxi_framework/maxi_framework.dart';

extension OrationExtensions on Oration {
  Oration translate() {
    if (translated) {
      return this;
    }
    return appTranslator.translateOration(oration: this);
  }

  String translateText() {
    if (translated) {
      return toString();
    }
    return appTranslator.translateOration(oration: this).toString();
  }
}
