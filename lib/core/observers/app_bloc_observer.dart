import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';

class AppBlocObserver extends BlocObserver {
  @override
  void onCreate(BlocBase bloc) {
    super.onCreate(bloc);
    if (kDebugMode) {
      debugPrint('🟢 BLoC created: ${bloc.runtimeType} #${bloc.hashCode}');
    }
  }

  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    if (kDebugMode) {
      debugPrint(
        '📤 Event: ${event.runtimeType} → ${bloc.runtimeType} #${bloc.hashCode}',
      );
    }
  }

  @override
  void onClose(BlocBase bloc) {
    super.onClose(bloc);
    if (kDebugMode) {
      debugPrint('🔴 BLoC closed: ${bloc.runtimeType} #${bloc.hashCode}');
    }
  }
}
