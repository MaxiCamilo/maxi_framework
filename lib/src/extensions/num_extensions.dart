import 'package:maxi_framework/maxi_framework.dart';

extension NumExtensions on num {
  String zeroFill({required int quantityZeros, bool cutIfExceeds = true, bool cutFromTheEnd = true}) {
    final dio = this is double ? toInt().toString() : toString();
    return dio.zeroFill(quantityZeros: quantityZeros, cutIfExceeds: cutIfExceeds, cutFromTheEnd: cutFromTheEnd);
  }
}
