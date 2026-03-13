import 'package:maxi_framework/maxi_framework.dart';

extension MapExtensions<K, V> on Map<K, V> {
  Result<V> getRequiredValue({required K key, V? defaultValue}) {
    final item = this[key];
    if (item == null) {
      if (defaultValue != null) {
        return ResultValue(content: defaultValue);
      } else {
        return NegativeResult.controller(
          code: ErrorCode.nonExistent,
          message: FlexibleOration(message: 'The property called %1 is required', textParts: [key]),
        );
      }
    }

    return ResultValue(content: item);
  }

  Result<T> getRequiredValueWithSpecificType<T>({required K key, T? defaultValue}) {
    final item = this[key];
    if (item == null) {
      if (defaultValue != null) {
        return ResultValue(content: defaultValue);
      }
      return NegativeResult.controller(
        code: ErrorCode.nonExistent,
        message: FlexibleOration(message: 'The property called %1 is required', textParts: [key]),
      );
    }

    if (item is T) {
      return ResultValue(content: item as T);
    } else {
      return NegativeResult.controller(
        code: ErrorCode.wrongType,
        message: FlexibleOration(message: 'The property %1 was expected to be of type %2, but a value of type %3 was received', textParts: [key, T, item.runtimeType]),
      );
    }
  }

  Map<K, V> where(bool Function(K key, V value) condition) {
    final result = <K, V>{};
    for (final entry in entries) {
      if (condition(entry.key, entry.value)) {
        result[entry.key] = entry.value;
      }
    }
    return result;
  }
}
