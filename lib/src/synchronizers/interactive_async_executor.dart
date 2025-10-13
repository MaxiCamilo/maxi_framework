import 'dart:async';
import 'dart:developer';

import 'package:maxi_framework/maxi_framework.dart';

//typedef TextableExecutor<T> = InteractiveExecutor<Oration, T>;

mixin InteractiveExecutor {
  static Symbol _simbolName<I>() => Symbol('MaxiInteractive$I');

  static List<void Function(I)>? _getItemSender<I>() {
    final thing = Zone.current[_simbolName<I>()];
    if (thing is List<void Function(I)>) {
      return thing;
    } else {
      return null;
    }
  }

  static void sendItem<I>(I item) {
    final sender = Zone.current[_simbolName<I>()];
    if (sender == null) {
      log('[InteractiveExecutor] This zone has no item sender');
      return;
    }

    if (sender is List<void Function(I)>) {
      sender.lambda((x) => x(item));
    } else {
      log('[InteractiveExecutor] A sender of type a function was expected, but the sender for this zone is %${sender.runtimeType}');
    }
  }

  static Future<T> execute<I, T>({required FutureOr<T> Function() function, required void Function(I) onItem, Map<Object?, Object?> zoneValues = const {}}) {
    final previous = _getItemSender<I>() ?? <void Function(I)>[];
    previous.add(onItem);

    final newZone = Zone.current.fork(zoneValues: {_simbolName<I>(): previous, ...zoneValues});
    return newZone.run<Future<T>>(() async => await function());
  }
}
