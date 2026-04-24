import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';

//typedef TextableExecutor<T> = InteractiveSystem<Oration, T>;

class InteractiveSystemValue<T> {
  final T value;
  final dynamic payload;

  const InteractiveSystemValue({required this.value, this.payload});
}

mixin InteractiveSystem {
  static const kInteractiveSymbolName = #maxiInteractive;

  static Result<MasterChannel<InteractiveSystemValue, InteractiveSystemValue>> obtainChannel() {
    final channelResult = tryCast<MasterChannel<InteractiveSystemValue, InteractiveSystemValue>>(FixedOration(message: 'No interactive channel found'), Zone.current[kInteractiveSymbolName]);
    if (channelResult.itsFailure) {
      return channelResult.cast();
    }

    if (channelResult.content.itWasDiscarded) {
      return NegativeResult.controller(
        code: ErrorCode.discontinuedFunctionality,
        message: FixedOration(message: 'The interactive channel was discarded'),
      );
    }

    return ResultValue(content: channelResult.content);
  }

  static Result<Channel<InteractiveSystemValue, InteractiveSystemValue>> forkChannel() {
    return obtainChannel().onCorrect((x) => x.buildConnector());
  }

  static Result<void> sendValue({required dynamic value, dynamic payload}) {
    return obtainChannel().onCorrect((x) => x.sendItem(InteractiveSystemValue(value: value, payload: payload)));
  }

  static Future<Result<void>> sendValueAsync({required dynamic value, dynamic payload}) async {
    final sendingResult = sendValue(value: value, payload: payload);
    if (sendingResult.itsFailure) {
      return sendingResult.cast();
    }

    await Future.delayed(Duration.zero);

    return voidResult;
  }

  static Result<Stream<T>> receiveValues<T>({bool Function(T item, dynamic payload)? filter}) {
    final forkChannelResult = forkChannel();
    if (forkChannelResult.itsFailure) return forkChannelResult.cast();

    final channel = forkChannelResult.content;

    if (filter == null) {
      return channel.getReceiver().onCorrectSelect((x) => x.where((x) => x.value is T).map((e) => e.value as T));
    } else {
      return channel.getReceiver().onCorrectSelect((x) => x.where((x) => x.value is T).where((x) => filter(x.value as T, x.payload)).map((e) => e.value as T));
    }
  }
}
