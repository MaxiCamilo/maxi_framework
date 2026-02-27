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
}
