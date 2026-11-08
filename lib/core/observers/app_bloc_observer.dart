import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

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
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    Sentry.captureException(
      error,
      stackTrace: stackTrace,
      hint: Hint.withMap({'bloc': '${bloc.runtimeType}'}),
    );
  }

  @override
  void onClose(BlocBase bloc) {
    super.onClose(bloc);
    if (kDebugMode) {
      debugPrint('🔴 BLoC closed: ${bloc.runtimeType} #${bloc.hashCode}');
    }
  }
}
