import 'package:appkioskcoex/helper/global_var.dart';
import 'package:flutter/widgets.dart';

/// onResume() / onPause() per halaman seperti Activity Android:
///  - resume saat halaman pertama tampil, saat halaman di atasnya di-pop, dan saat app kembali ke foreground
///  - pause saat halaman lain di-push di atasnya, saat app ke background, dan saat halaman di-dispose
mixin ActivityLifecycle<W extends StatefulWidget> on State<W> implements RouteAware {
  bool _visible = false;
  bool _subscribed = false;
  late final _AppLifecycleObserver _appObserver = _AppLifecycleObserver(_onAppLifecycle);

  void onResume() {}
  void onPause() {}

  void _resume() {
    if (_visible) return;
    _visible = true;
    onResume();
  }

  void _pause() {
    if (!_visible) return;
    _visible = false;
    onPause();
  }

  void _onAppLifecycle(AppLifecycleState state) {
    if (!mounted) return;
    final isTop = ModalRoute.of(context)?.isCurrent ?? false;
    if (state == AppLifecycleState.resumed) {
      if (isTop) _resume();
    } else if (state == AppLifecycleState.paused) {
      _pause();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(_appObserver);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _resume();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (!_subscribed && route is PageRoute) {
      activityRouteObserver.subscribe(this, route);
      _subscribed = true;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_appObserver);
    activityRouteObserver.unsubscribe(this);
    _pause();
    super.dispose();
  }

  @override
  void didPushNext() => _pause();
  @override
  void didPopNext() => _resume();
  @override
  void didPush() {}
  @override
  void didPop() {}
}

class _AppLifecycleObserver with WidgetsBindingObserver {
  final void Function(AppLifecycleState state) onChange;
  _AppLifecycleObserver(this.onChange);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) => onChange(state);
}
