import 'package:maxi_framework/maxi_framework.dart';

class LifecycleScope with DisposableMixin, LifecycleHub {
  LifecycleScope({Disposable? parent}) {
    if (parent != null) {
      if (parent is LifecycleHub) {
        parent.joinDisposableObject(this);
      } else {
        parent.bindChild(this);
      }
    }
  }
}
