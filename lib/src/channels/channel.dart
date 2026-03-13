import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';

abstract interface class Channel<R, S> implements Disposable {
  Result<Stream<R>> getReceiver();

  Result<void> sendItem(S item);
}

extension ChannelExtension<R, S> on Channel<R, S> {
  Type get receiverType => R;
  Type get senderType => S;

  Future<Result<void>> sendItemAsync(S item) {
    return sendItem(item).onCorrectFuture((x) async {
      await Future.delayed(Duration.zero);
      return voidResult;
    });
  }

  Result<void> reflectChannel(Channel<S, R> other) {
    final thisReceiver = getReceiver();
    if (thisReceiver.itsFailure) {
      return thisReceiver.cast();
    }

    final otherReceiver = other.getReceiver();
    if (otherReceiver.itsFailure) {
      return otherReceiver.cast();
    }

    late final StreamSubscription thisSubscription;
    late final StreamSubscription otherSubscription;

    thisSubscription = thisReceiver.content.listen((item) => other.sendItem(item).logIfFails(errorName: 'reflectChannel: this -> other '), onDone: () => otherSubscription.cancel());
    otherSubscription = otherReceiver.content.listen((item) => sendItem(item).logIfFails(errorName: 'reflectChannel: other -> this '), onDone: () => thisSubscription.cancel());
    return voidResult;
  }
}
