@Timeout(Duration(minutes: 30))
library;

import 'dart:async';

import 'package:test/test.dart';
import 'package:maxi_framework/maxi_framework.dart';

class SyncFunctionality with FunctionalityMixin<String> {
  final String name;
  final int age;

  const SyncFunctionality({required this.name, required this.age});

  @override
  Future<Result<String>> runInternalFuncionality() async {
    print('Hi $name!');

    await heart.lifecycleScope.delay(duration: const Duration(seconds: 30));

    if (isCanceled) {
      return CancelationResult();
    }

    print('You are $age years old!');

    await heart.lifecycleScope.delay(duration: const Duration(seconds: 30));

    return ResultValue(content: 'jejeje');
    /*
    return context.error(
      code: ErrorCode.invalidProperty,
      message: FixedOration(message: 'Oh no!'),
    );*/
  }

  @override
  void onCancel() {
    print('>:(');
  }
}

class AsyncFunctionality with FunctionalityMixin<String> {
  final String name;
  final int age;

  const AsyncFunctionality({required this.name, required this.age});

  @override
  void onCancel() {
    print('tot');
  }

  @override
  Future<Result<String>> runInternalFuncionality() async {
    print('chanchan');
    sendText(FlexibleOration(message: 'Hi %1!', textParts: [name]));

    await heart.lifecycleScope.delay(duration: const Duration(seconds: 7));

    if (isCanceled) {
      return CancelationResult();
    }

    sendText(FlexibleOration(message: 'You are %1 years old!', textParts: [age]));

    if (isCanceled) {
      return CancelationResult();
    }

    await heart.lifecycleScope.delay(duration: const Duration(seconds: 5));

    return ResultValue(content: 'byebye');
  }
}

void main() {
  group('A group of tests', () {
    setUp(() {
      // Additional setup goes here.
    });

    test('Test functionalities', () async {
      final func = const SyncFunctionality(name: 'Maxitito', age: 30);
      /*
      Future.delayed(const Duration(seconds: 5)).whenComplete(() {
        waiter.dispose();
      });*/

      final result = await func.separateExecution();

      if (result.itsCorrect) {
        print('Result: ${result.content}');
      } else {
        print('Error!: ${result.error.message}');
      }
    });

    

    test('Mutex', () async {
      Future<void> first() async {
        await Future.delayed(const Duration(seconds: 2));
        print('wait');
        await Future.delayed(const Duration(seconds: 2));
        print('Bye');
      }

      Future<String> second(String name) async {
        return 'Byeeee $name';
      }

      final futures = <Future>[];
      final mutex = Mutex();

      futures.add(mutex.execute(first));
      futures.add(mutex.execute(() => second('Maxi'))); /*
      futures.add(
        mutex
            .executeInteractiveFunctionality(
              functionality: AsyncFunctionality(name: 'Seba', age: 27),
              onItem: (x) => print('Event: $x'),
            )
            .waitResult(),
      );*/
      futures.add(mutex.execute(() => second('Seba')));
      /*
      futures.add(
        Mutex.executeWithLifeCoordinator(
          function: (heart) async {
            await heart.lifecycleScope.delay(duration: const Duration(seconds: 2));
            return ResultValue(content: 'yey!');
          },
        ),
      );*/

      final result = await Future.wait(futures);
      print(result);
    });
  });
}
