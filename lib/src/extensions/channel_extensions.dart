import 'package:maxi_framework/maxi_framework.dart';

extension ChannelExtensions<R, S> on Channel<R, S> {
  FutureResult<R> sendAndReceive({required Mutex mutex, required S data, required Duration timeout}) async {
    if (this is SyncFunctionality) {
      final syncInitResult = (this as SyncFunctionality).execute();
      if (syncInitResult.itsFailure) {
        return syncInitResult.cast();
      }
    }

    return mutex.execute(() async {
      if (this is AsynchronouslyInitialized) {
        final asyncInitResult = await (this as AsynchronouslyInitialized).initialize();
        if (asyncInitResult.itsFailure) {
          return asyncInitResult.cast();
        }
      }

      await Future.delayed(Duration.zero);

      final sendResult = sendItem(data);
      if (sendResult.itsFailure) {
        return sendResult.cast();
      }

      await Future.delayed(Duration.zero);
      final receiveResult = getReceiver();
      if (receiveResult.itsFailure) {
        return receiveResult.cast();
      }
      return receiveResult.content.waitItem(timeout: timeout);
    });
  }
}
