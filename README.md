# maxi_framework

`maxi_framework` is the base library for my Dart and Flutter projects.

It provides shared architecture primitives to keep code consistent across platforms, reduce exception-driven flows using `Result<T>`, manage object lifecycles, and abstract communication patterns such as channels.

## What this package is for

Use this package as a foundation layer when you want:

- A unified way to target multiple platforms.
- Functional-style error handling with `Result<T>` instead of relying on exceptions.
- Disposable and recoverable lifecycle management for objects, streams, timers, and async tasks.
- Reusable abstractions for communication and app-level services.

## Main capabilities

### 1) Cross-platform application manager

The package exposes an `ApplicationManager` contract with runtime/platform flags and I/O builders, plus conditional factories for:

- Dart VM/native
- Flutter
- Web

Key API:

- `appManager` singleton accessor
- `defineAppManager(...)` for custom injection
- platform flags: `isWeb`, `isLinux`, `isWindows`, `isAndroid`, `isIOS`, etc.

### 2) Result-first error handling

Core type: `Result<T>`

- `ResultValue<T>` for success
- `NegativeResult<T>` for controlled failures
- `ExceptionResult<T>` for captured exceptions
- `CancelationResult<T>` for cancellations

This model helps avoid uncontrolled exception flows and makes failures explicit in return types.

### 3) Lifecycle and disposal coordination

Lifecycle primitives include:

- `Disposable` / `DisposableMixin`
- `LifeCoordinator`
- `LifecycleHub`
- initialization helpers (`InitializableMixin`, async initialization utilities)

These utilities allow you to connect and clean up streams, controllers, timers, and dependencies safely.

### 4) Channel abstraction

`Channel<R, S>` abstracts bidirectional communication via typed sender/receiver contracts:

- `Result<Stream<R>> getReceiver()`
- `Result<void> sendItem(S item)`

`MasterChannel<R, S>` provides a concrete implementation with connector channels and stream fan-out behavior.

## Installation

```yaml
dependencies:
	maxi_framework: ^1.0.0
```

Then run:

```bash
dart pub get
```

## Quick usage examples

### Returning `Result<T>` instead of throwing

```dart
import 'package:maxi_framework/maxi_framework.dart';

Result<int> parsePositive(String input) {
	final parsed = int.tryParse(input);

	if (parsed == null) {
		return NegativeResult.controller(
			code: ErrorCode.wrongType,
			message: const FixedOration(message: 'Invalid integer value'),
		);
	}

	if (parsed < 0) {
		return NegativeResult.controller(
			code: ErrorCode.invalidProperty,
			message: const FixedOration(message: 'Only positive values are allowed'),
		);
	}

	return ResultValue(content: parsed);
}
```

### Creating and using a channel

```dart
import 'package:maxi_framework/maxi_framework.dart';

final master = MasterChannel<String, int>();
final connectorResult = master.buildConnector();

if (connectorResult.itsCorrect) {
	final connector = connectorResult.content;

	connector.getReceiver().onCorrectLambda((stream) {
		stream.listen((text) {
			// Receive text messages
		});
	});

	master.sendItem(42); // Sends `int` to connector receivers
}
```

### Coordinating disposables with lifecycle helpers

```dart
import 'dart:async';
import 'package:maxi_framework/maxi_framework.dart';

class MyController with DisposableMixin, LifecycleHub {
	late final StreamController<int> controller;

	MyController() {
		controller = joinStreamController(StreamController<int>.broadcast());
	}

	@override
	void performObjectDiscard() {
		super.performObjectDiscard();
	}
}
```

## Package exports

Main library:

```dart
import 'package:maxi_framework/maxi_framework.dart';
```

This gives access to modules such as:

- lifecycle
- error handling
- channels
- app management
- synchronizers
- validators
- conditions
- file abstractions

## Notes

- This package is intended as a core foundation layer.
- Companion libraries in the same ecosystem can build on these contracts.
- Public APIs prioritize explicit flows and composable primitives for large projects.
