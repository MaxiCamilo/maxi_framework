import 'package:maxi_framework/maxi_framework.dart';

abstract interface class Channel<R, S> implements Disposable {
  Result<Stream<R>> getReceiver();

  Result<void> sendItem(S item);
}
