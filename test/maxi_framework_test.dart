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
  Future<Result<String>> runFuncionality(FutureControllerContext<String> context) async {
    print('Hi $name!');
    await context.heart.delay(duration: const Duration(seconds: 30));

    print('You are $age years old!');

    if (context.checkCancelarion()) {
      return context.returnCancelation();
    }

    await context.heart.delay(duration: const Duration(seconds: 30));

    return context.ok('Byebye');
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

class AsyncFunctionality with TextableFunctionalityMixin<String> {
  final String name;
  final int age;

  const AsyncFunctionality({required this.name, required this.age});

  @override
  void onCancel() {
    print('tot');
  }

  @override
  Future<Result<String>> runFuncionality({required void Function(Oration x) sendItem, required FutureControllerContext<String> context, required ParentController heart}) async {
    print('chanchan');
    sendItem(FlexibleOration(message: 'Hi %1!', textParts: [name]));

    await heart.delay(duration: const Duration(seconds: 5));

    if (context.checkCancelarion()) {
      return context.returnCancelation();
    }

    sendItem(FlexibleOration(message: 'You are %1 years old!', textParts: [name]));

    if (context.checkCancelarion()) {
      return context.returnCancelation();
    }

    await heart.delay(duration: const Duration(seconds: 5));

    return context.ok('Byebye');
  }
}

void main() {
  group('A group of tests', () {
    setUp(() {
      // Additional setup goes here.
    });

    test('Test functionalities', () async {
      final func = const SyncFunctionality(name: 'Maxitito', age: 30);
      final waiter = func.execute();

      Future.delayed(const Duration(seconds: 5)).whenComplete(() {
        waiter.dispose();
      });

      final result = await waiter.waitResult();

      if (result.itsCorrect) {
        print('Result: ${result.content}');
      } else {
        print('Error!: ${result.error.message}');
      }
    });

    test('Test Textables', () async {
      final func = const AsyncFunctionality(name: 'Maxitito', age: 30);
      final executor = func.buildExecutor();

      Future.delayed(const Duration(seconds: 5)).whenComplete(() {
        executor.dispose();
      });

      final result = await executor.executeAsFuture(onItem: (x) => print('Event: $x'));

      if (result.itsCorrect) {
        print('Result: ${result.content}');
      } else {
        print('Error!: ${result.error.message}');
      }

      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);
      print('chau!');
    });

    test('Semaphore', () async {
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
      final semaphore = Semaphore();

      futures.add(semaphore.execute(first));
      futures.add(semaphore.execute(() => second('Maxi')));
      futures.add(
        semaphore
            .executeInteractiveFunctionality(
              functionality: AsyncFunctionality(name: 'Seba', age: 27),
              onItem: (x) => print('Event: $x'),
            )
            .waitResult(),
      );
      futures.add(semaphore.execute(() => second('Seba')));
      futures.add(
        semaphore.executeWithParentController(
          function: (heart) async {
            await heart.delay(duration: const Duration(seconds: 2));
            return PositiveResult(content: 'yey!');
          },
        ),
      );

      final result = await Future.wait(futures);
      print(result);
    });
  });
}
