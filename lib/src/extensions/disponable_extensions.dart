import 'package:maxi_framework/maxi_framework.dart';

extension DisponableExtensions on Disposable {
  TinyEvent bindChild(Disposable child) {
    final function = onDispose.whenComplete(child.dispose);
    child.onDispose.whenComplete(() => function.ignore());

    return function;
  }

  bool connectWithHeartZone() {
    final heartZone = LifeCoordinator.tryGetZoneHeart;
    if (heartZone == null) return false;

    heartZone.bindChild(this);
    return true;
  }

  void attachWithOther(Disposable other) {
    onDispose.whenComplete(other.dispose);
    other.onDispose.whenComplete(dispose);
  }
}
