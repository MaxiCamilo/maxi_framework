import 'package:maxi_framework/maxi_framework.dart';

class InvocationParameters {
  static const InvocationParameters emptry = InvocationParameters();

  final List fixedParameters;
  final Map<String, dynamic> namedParameters;

  const InvocationParameters({this.fixedParameters = const [], this.namedParameters = const {}});

  factory InvocationParameters.clone(InvocationParameters original, {bool avoidConstants = true}) {
    return InvocationParameters(
      fixedParameters: avoidConstants ? original.fixedParameters.toList() : original.fixedParameters,
      namedParameters: avoidConstants ? Map<String, dynamic>.from(original.namedParameters) : original.namedParameters,
    );
  }

  factory InvocationParameters.addParameters({required InvocationParameters original, bool addToEnd = true, List fixedParameters = const [], Map<String, dynamic> namedParameters = const {}}) {
    if (addToEnd) {
      return InvocationParameters(fixedParameters: [...original.fixedParameters, ...fixedParameters], namedParameters: {...original.namedParameters, ...namedParameters});
    } else {
      return InvocationParameters(fixedParameters: [...fixedParameters, ...original.fixedParameters], namedParameters: {...namedParameters, ...original.namedParameters});
    }
  }

  factory InvocationParameters.only(dynamic value) => InvocationParameters(fixedParameters: [value]);

  factory InvocationParameters.list(List values) => InvocationParameters(fixedParameters: values);

  T named<T>(String name) {
    if (namedParameters.isEmpty) {
      throw NegativeResult.controller(
        code: ErrorCode.implementationFailure,
        message: FixedOration(message: 'The list is empty'),
      );
    }

    final item = namedParameters[name];

    if (item is T) {
      return item;
    } else {
      if (item == null) {
        throw NegativeResult.controller(
          code: ErrorCode.implementationFailure,
          message: FlexibleOration(message: 'The list of arguments doesn\'t contain property %1', textParts: [name]),
        );
      } else {
        throw NegativeResult.controller(
          code: ErrorCode.implementationFailure,
          message: FlexibleOration(message: 'The parameter list contains parameter %1 of type %2, but type %3 was expected', textParts: [name, item.runtimeType, T]),
        );
      }
    }
  }

  T optionalNamed<T>({required String name, required T predetermined}) {
    if (namedParameters.isEmpty) {
      return predetermined;
    }

    final item = namedParameters[name];
    if (item == null) {
      return predetermined;
    }

    if (item is T) {
      return item;
    } else {
      throw NegativeResult.controller(
        code: ErrorCode.implementationFailure,
        message: FlexibleOration(message: 'The parameter list contains parameter %1 of type %2, but type %3 was expected', textParts: [name, item.runtimeType, T]),
      );
    }
  }

  T fixed<T>([int location = 0]) {
    if (location < 0) {
      throw NegativeResult.controller(
        code: ErrorCode.implementationFailure,
        message: FixedOration(message: 'The context does not allow negative parameters'),
      );
    }

    if (location >= fixedParameters.length) {
      throw NegativeResult.controller(
        code: ErrorCode.implementationFailure,
        message: FlexibleOration(message: 'The context has %1 parameters, but parameter %2 (+1) was expected', textParts: [fixedParameters.length, location]),
      );
    }

    final item = fixedParameters[location];
    if (item is T) {
      return item;
    } else {
      throw NegativeResult.controller(
        code: ErrorCode.implementationFailure,
        message: FlexibleOration(message: 'The fixed parameter number %1 was expected to be of type %2, but is of type %3', textParts: [location, T, item.runtimeType]),
      );
    }
  }

  T optionalFixed<T>({required int location, required T predetermined}) {
    if (location < 0) {
      throw NegativeResult.controller(
        code: ErrorCode.implementationFailure,
        message: FixedOration(message: 'The context does not allow negative parameters'),
      );
    }

    if (location >= fixedParameters.length) {
      return predetermined;
    }

    final item = fixedParameters[location];
    if (item is T) {
      return item;
    } else {
      throw NegativeResult.controller(
        code: ErrorCode.implementationFailure,
        message: FlexibleOration(message: 'The fixed parameter number %1 was expected to be of type %2, but is of type %3', textParts: [location, T, item.runtimeType]),
      );
    }
  }

  T firts<T>() => fixed<T>(0);

  T second<T>() => fixed<T>(1);

  T third<T>() => fixed<T>(2);

  T fourth<T>() => fixed<T>(3);

  T fifth<T>() => fixed<T>(4);

  T sixth<T>() => fixed<T>(5);

  T seventh<T>() => fixed<T>(6);

  T octave<T>() => fixed<T>(7);

  T ninth<T>() => fixed<T>(8);

  T last<T>() => fixed<T>(fixedParameters.length - 1);
  T penultimate<T>() => fixed<T>(fixedParameters.length - 2);
  T antepenultimate<T>() => fixed<T>(fixedParameters.length - 3);

  T reverseIndex<T>(int i) => fixed<T>(fixedParameters.length - (i + 1));
}
