import 'package:flutter/widgets.dart';
import 'package:saman_sports/controllers/notificaciones_controller.dart';

class NotificacionesScope extends InheritedNotifier<NotificacionesController> {
  const NotificacionesScope({
    super.key,
    required NotificacionesController controller,
    required super.child,
  }) : super(notifier: controller);

  static NotificacionesController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<NotificacionesScope>()
        ?.notifier;
  }
}
