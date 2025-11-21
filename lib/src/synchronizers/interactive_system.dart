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

  static List<Function> getAllSenders() {
    final thing = Zone.current[_simbolName];

    if (thing is List) {
      return thing.whereType<Function>().toList(growable: false);
    } else {
      return [];
    }
  }

  static void sendItemCertainFunctions({required List<Function> list, required dynamic item}) {
    for (final func in list) {
      try {
        func(item);
      } catch (_) {
        //log('[InteractiveSystem] An error occurred while sending an item to a function sender: $e');
      }
    }
  }

  static void sendItem<I>(I item) {
    final sender = _getItemSender<I>();
    if (sender.isEmpty) {
      log('[InteractiveSystem] A sender of type a function was expected, but the sender for this zone is $I');
      return;
    }

    sender.lambda((x) => x(item));
  }

  static Future<T> catchText<T>({required FutureOr<T> Function() function, required void Function(Oration) onText, Map<Object?, Object?> zoneValues = const {}}) =>
      catchItems<Oration, T>(function: function, onItem: onText, zoneValues: zoneValues);

  static Future<T> catchItems<I, T>({required FutureOr<T> Function() function, required void Function(I) onItem, Map<Object?, Object?> zoneValues = const {}}) {
    final previous = _getItemSender<I>();
    previous.add(onItem);

    final newZone = Zone.current.fork(zoneValues: {_simbolName: previous, ...zoneValues});
    return newZone.run<Future<T>>(() async => await function());
  }

  static Future<T> executeMultipleFunctions<T>({required List<Function> catchers, required FutureOr<T> Function() function, Map<Object?, Object?> zoneValues = const {}}) {
    final senders = getAllSenders().toList();

    for (final func in catchers) {
      final exists = senders.selectPosition((x) => func == x);
      if (exists == -1) {
        senders.add(func);
      } else {
        senders[exists] = func;
      }
    }

    final newZone = Zone.current.fork(zoneValues: {_simbolName: senders, ...zoneValues});
    return newZone.run<Future<T>>(() async => await function());
  }
}
