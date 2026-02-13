import 'package:maxi_framework/maxi_framework.dart';

extension DisponableExtensions on Disposable {
  Future bindChild(Disposable child) {

    final function = onDispose.whenComplete(child.dispose);
    child.onDispose.whenComplete(() => function.ignore());

    return function;
  }

  Future bindToParent(Disposable parent) {
    return parent.onDispose.whenComplete(dispose);
  }

  bool connectWithHeartZone() {
    final heartZone = LifeCoordinator.tryGetZoneHeart;
    if (heartZone == null) return false;

    heartZone.bindChild(this);
    return true;
  }
}
