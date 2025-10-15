import 'dart:async';
import 'dart:developer';

import 'package:maxi_framework/maxi_framework.dart';

//typedef TextableExecutor<T> = InteractiveSystem<Oration, T>;

mixin InteractiveSystem {
  static const _simbolName = #maxiInteractive;

  static List<void Function(I)> _getItemSender<I>() {
    final thing = Zone.current[_simbolName];
    final result = <void Function(I)>[];

    if (thing is List) {
      for (final func in thing) {
        if (func is void Function(I)) {
          result.add(func);
        }
      }
    }

    return result;
  }

  static void sendItem<I>(I item) {
    final sender = _getItemSender<I>();
    if (sender.isEmpty) {
      log('[InteractiveSystem] A sender of type a function was expected, but the sender for this zone is $I');
      return;
    }

    sender.lambda((x) => x(item));
  }

  static Future<T> execute<I, T>({required FutureOr<T> Function() function, required void Function(I) onItem, Map<Object?, Object?> zoneValues = const {}}) {
    final previous = _getItemSender<I>();
    previous.add(onItem);

    final newZone = Zone.current.fork(zoneValues: {_simbolName: previous, ...zoneValues});
    return newZone.run<Future<T>>(() async => await function());
  }
}
