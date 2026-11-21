import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:saman_sports/core/theme/app_sizes.dart';

class TablaDesplazable extends StatefulWidget {
  const TablaDesplazable({super.key, required this.child});

  final Widget child;

  @override
  State<TablaDesplazable> createState() => _TablaDesplazableState();
}

class _TablaDesplazableState extends State<TablaDesplazable> {
  final ScrollController _control = ScrollController();

  @override
  void didUpdateWidget(TablaDesplazable oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_control.hasClients || _control.offset == 0) return;
      _control.jumpTo(0);
    });
  }

  @override
  void dispose() {
    _control.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: const {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.trackpad,
        },
      ),
      child: Scrollbar(
        controller: _control,
        thumbVisibility: true,
        trackVisibility: true,
        child: SingleChildScrollView(
          controller: _control,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(bottom: AppSizes.space12),
          child: widget.child,
        ),
      ),
    );
  }
}
