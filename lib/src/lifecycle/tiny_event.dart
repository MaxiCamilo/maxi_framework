import 'dart:async';
import 'dart:developer';

import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';

class TinyEvent<T> {
  final bool itsTemporal;

  bool _isIgnored = false;
  Function(TinyEvent<T>) onIgnore;

  List<Function>? _onCompleteListen;
  List<Function>? _onErrorListen;

  TinyEvent._({required this.itsTemporal, required this.onIgnore});

  TinyEvent<T> whenComplete(Function() onComplete) {
    if (_isIgnored) {
      log('Trying to add a complete listener to a TinyEvent that was already ignored. Function: $onComplete', name: 'TinyEvent');
      return this;
    }

    _onCompleteListen ??= [];
    _onCompleteListen?.add(onComplete);
    return this;
  }

  TinyEvent<T> then(Function onDone) {
    if (_isIgnored) {
      log('Trying to add a complete listener to a TinyEvent that was already ignored. Function: $onDone', name: 'TinyEvent');
      return this;
    }

    _onCompleteListen ??= [];
    _onCompleteListen?.add(onDone);
    return this;
  }

  TinyEvent<T> onError(Function onError) {
    if (_isIgnored) {
      log('Trying to add an error listener to a TinyEvent that was already ignored. Function: $onError', name: 'TinyEvent');
      return this;
    }

    _onErrorListen ??= [];
    _onErrorListen?.add(onError);
    return this;
  }

  @protected
  void complete(T value) {
    if (_onCompleteListen != null) {
      for (final func in _onCompleteListen!) {
        if (func is Function()) {
          func();
        } else if (func is Function(T)) {
          func(value);
        } else {
          log('Trying to complete a TinyEvent with a function that has an invalid signature. Function: $func', name: 'TinyEvent');
        }
      }
    }

    if (itsTemporal) {
      _onCompleteListen?.clear();
      _onErrorListen?.clear();
      _onCompleteListen = null;
      _onErrorListen = null;
    }
  }

  @protected
  void error(dynamic error, StackTrace stackTrace) {
    if (_onErrorListen != null) {
      for (final func in _onErrorListen!) {
        if (func is Function()) {
          func();
        } else if (func is Function(dynamic)) {
          func(error);
        } else if (func is Function(dynamic, StackTrace)) {
          func(error, stackTrace);
        } else if (func is Function(StackTrace)) {
          func(stackTrace);
        } else {
          log('Trying to complete a TinyEvent with a function that has an invalid signature. Function: $func', name: 'TinyEvent');
        }
      }
    }

    if (_onCompleteListen != null) {
      for (final func in _onCompleteListen!.whereType<Function()>()) {
        func();
      }
    }

    if (itsTemporal) {
      _onCompleteListen?.clear();
      _onErrorListen?.clear();
      _onCompleteListen = null;
      _onErrorListen = null;
    }
  }

  TinyEvent<T> listen(void Function(T)? onData, {Function? onError, void Function()? onDone}) {
    if (onData != null) {
      then(onData);
    }
    if (onError != null) {
      this.onError(onError);
    }
    if (onDone != null) {
      whenComplete(onDone);
    }

    return this;
  }

  void close() => ignore();
  void dispose() => ignore();

  void ignore() {
    if (_isIgnored) return;
    _isIgnored = true;
    onIgnore(this);
    _onCompleteListen?.clear();
    _onErrorListen?.clear();
    _onCompleteListen = null;
    _onErrorListen = null;
  }
}

class TinyEventManager<T> {
  final List<TinyEvent<T>> _permanentEvents = [];
  final List<TinyEvent<T>> _temporalyEvents = [];

  TinyEvent<T> createEvent({required bool temporal, Function(TinyEvent<T>)? onIgnore}) {
    final newEvent = TinyEvent<T>._(
      itsTemporal: temporal,
      onIgnore: (event) {
        if (temporal) {
          _temporalyEvents.remove(event);
        } else {
          _permanentEvents.remove(event);
        }

        if (onIgnore != null) {
          onIgnore(event);
        }
      },
    );

    if (temporal) {
      _temporalyEvents.add(newEvent);
    } else {
      _permanentEvents.add(newEvent);
    }

    return newEvent;
  }

  TinyEvent<T> listen(void Function(T)? onData, {Function(dynamic, StackTrace)? onError, void Function()? onDone, bool? cancelOnError}) {
    final event = createEvent(temporal: false);
    event.listen(
      onData,
      onError: (ex, st) {
        if (onError != null) {
          onError(ex, st);
        }
        if (cancelOnError == true) {
          event.close();
        }
      },
      onDone: onDone,
    );
    return event;
  }

  Stream<T> get stream {
    final controller = StreamController<T>();
    final event = createEvent(
      temporal: false,
      onIgnore: (ignoredEvent) {
        if (!controller.isClosed) {
          controller.close();
        }
      },
    );

    event.then((value) {
      if (!controller.isClosed) {
        controller.add(value);
      }
    });

    event.onError((error, st) {
      if (!controller.isClosed) {
        controller.addError(error, st);
      }
    });

    return controller.stream.doOnCancel(() {
      event.ignore();
    });
  }

  void triggerEvent(T value) {
    for (final event in _permanentEvents.toList(growable: false)) {
      event.complete(value);
    }

    for (final event in _temporalyEvents.toList(growable: false)) {
      event.complete(value);
    }

    _temporalyEvents.clear();
  }

  void triggerError(dynamic error, StackTrace stackTrace) {
    for (final event in _permanentEvents) {
      event.error(error, stackTrace);
    }

    for (final event in _temporalyEvents) {
      event.error(error, stackTrace);
    }
    _temporalyEvents.clear();
  }

  void dispose() {
    _permanentEvents.clear();
    _temporalyEvents.clear();
  }
}
