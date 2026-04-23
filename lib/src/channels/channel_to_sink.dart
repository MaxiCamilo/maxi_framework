import 'dart:async';
import 'dart:developer';

import 'package:maxi_framework/maxi_framework.dart';

extension ChannelToSinkExtension<T> on Channel<dynamic, T> {
  StreamSink<T> toSink() => _ChannelToSink(channel: this);
}

class _ChannelToSink<T> implements StreamSink<T> {
  final Channel<dynamic, T> channel;

  const _ChannelToSink({required this.channel});

  @override
  void add(T event) {
    channel.sendItem(event);
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    log('Error in channel sink: $error', error: error, stackTrace: stackTrace);
  }

  @override
  Future<dynamic> addStream(Stream<T> stream) {
    final completer = Completer();
    final subscription = stream.listen(
      (event) {
        channel.sendItem(event);
      },
      onError: (error, st) {
        log('Error in channel sink stream: $error', error: error, stackTrace: st);
      },
      onDone: () {
        completer.complete();
      },
    );

    channel.onDispose.whenComplete(() => subscription.cancel());

    return completer.future;
  }

  @override
  Future<dynamic> close() async {
    channel.dispose();
  }

  @override
  Future<dynamic> get done => channel.onDispose.toFuture();
}
