import 'package:maxi_framework/maxi_framework.dart';

mixin NativeFileSingleton {
  static String? _localRoute;
  static Semaphore? _semaphore;

  static Result<String> get localRoute {
    if (_localRoute == null) {
      return NegativeResult.controller(
        code: ErrorCode.implementationFailure,
        message: FixedOration(message: 'The local directory path has not been defined yet'),
      );
    } else {
      return ResultValue(content: _localRoute!);
    }
  }

  static Future<String> defineRoute({required String route, bool omittedIfDefined = true}) async {
    _semaphore ??= Semaphore();
    return _semaphore!.execute(() async {
      if (omittedIfDefined && _localRoute != null) {
        return route;
      }

      _localRoute = route;

      return route;
    });
  }

  static Future<Result<String>> defineRouteByFunctionality({required Functionality<String> getterRoute, bool omittedIfDefined = true}) {
    _semaphore ??= Semaphore();
    return _semaphore!.execute(() async {
      if (omittedIfDefined && _localRoute != null) {
        return ResultValue(content: _localRoute!);
      }

      final result = await getterRoute.execute();

      if (result.itsCorrect) {
        _localRoute = result.content;
      }

      _semaphore = null;
      return result;
    });
  }
}
