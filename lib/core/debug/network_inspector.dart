import 'package:alice/alice.dart';
import 'package:alice/model/alice_configuration.dart';
import 'package:alice_dio/alice_dio_adapter.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../navigation/app_navigator.dart';
import '../services/app_settings_service.dart';
import '../utils/app_colors.dart';

/// HTTP inspector (Alice), switched on remotely by `settings.network_inspector_enabled`
/// (dashboard → App & Versions) rather than the build environment — off until the
/// server settings say otherwise, on any environment, no rebuild needed either way.
class NetworkInspector {
  NetworkInspector._();

  static bool get enabled => AppSettingsService.instance.networkInspectorEnabled;

  static Alice? _alice;
  static AliceDioAdapter? _adapter;

  static Alice? get _inst {
    if (!enabled) return null;
    return _alice ??= Alice(
      configuration: AliceConfiguration(
        navigatorKey: appNavigatorKey,
        showNotification: false,
        showInspectorOnShake: false,
      ),
    );
  }

  /// Hooks the inspector into [dio]. Does nothing while the setting is off.
  static void attach(Dio dio) {
    final alice = _inst;
    if (alice == null) return;
    if (_adapter == null) {
      _adapter = AliceDioAdapter();
      alice.addAdapter(_adapter!); // once: a second ApiClient reuses the same adapter
    }
    if (!dio.interceptors.contains(_adapter)) dio.interceptors.add(_adapter!);
  }

  static void open() => _inst?.showInspector();

  /// For MaterialApp.builder: puts the floating button over every screen while enabled.
  static Widget wrap(Widget? child) {
    final page = child ?? const SizedBox.shrink();
    if (!enabled) return page;
    return Stack(children: [page, const _InspectorButton()]);
  }
}

class _InspectorButton extends StatefulWidget {
  const _InspectorButton();

  @override
  State<_InspectorButton> createState() => _InspectorButtonState();
}

class _InspectorButtonState extends State<_InspectorButton> {
  static const double _size = 48;
  Offset? _pos; // top-left; starts bottom-right, above the tab bar, and can be dragged

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final w = mq.size.width, h = mq.size.height;
    final pos = _pos ?? Offset(w - _size - 12, h - mq.padding.bottom - _size - 150);
    final clamped = Offset(
      pos.dx.clamp(0.0, w - _size),
      pos.dy.clamp(mq.padding.top, h - _size),
    );
    return Positioned(
      left: clamped.dx,
      top: clamped.dy,
      child: GestureDetector(
        onPanUpdate: (d) => setState(() => _pos = clamped + d.delta),
        child: Material(
          key: const Key('network-inspector-fab'),
          color: AppColors.primary,
          elevation: 6,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: NetworkInspector.open,
            child: const SizedBox(
              width: _size,
              height: _size,
              child: Icon(Icons.bug_report_rounded, color: Colors.white, size: 24),
            ),
          ),
        ),
      ),
    );
  }
}
