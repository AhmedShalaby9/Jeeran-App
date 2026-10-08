import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeeran_flutter/core/error/failures.dart';
import 'package:jeeran_flutter/core/services/app_settings_service.dart';
import 'package:jeeran_flutter/features/auth/domain/entities/user.dart';
import 'package:jeeran_flutter/features/auth/domain/repositories/auth_repository.dart';
import 'package:jeeran_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:jeeran_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:jeeran_flutter/features/auth/presentation/bloc/auth_state.dart';

class _Repo implements AuthRepository {
  final sent = <String>[];

  @override
  Future<Either<Failure, String>> sendOtpRest(String phone, String recaptchaToken) async {
    sent.add('$phone/$recaptchaToken');
    return const Right('test:+201000000000');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError('${invocation.memberName}');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('settings carry the static-code flag', () {
    expect(AppSettings.fromJson({'otp_test_mode': true}).otpTestMode, isTrue);
    expect(AppSettings.fromJson({}).otpTestMode, isFalse);
  });

  test('production login asks for reCAPTCHA first', () async {
    AppSettingsService.instance.settings = AppSettings.fromJson({'otp_test_mode': false});
    final repo = _Repo();
    final bloc = AuthBloc(repository: repo);
    bloc.add(const AuthSendOtpEvent('+201000000000'));
    await expectLater(bloc.stream, emits(isA<AuthRecaptchaRequired>()));
    expect(repo.sent, isEmpty);
    await bloc.close();
  });

  test('staging login skips reCAPTCHA and goes straight to the code screen', () async {
    AppSettingsService.instance.settings = AppSettings.fromJson({'otp_test_mode': true});
    final repo = _Repo();
    final bloc = AuthBloc(repository: repo);
    bloc.add(const AuthSendOtpEvent('+201000000000'));
    await expectLater(bloc.stream, emitsInOrder([isA<AuthLoading>(), isA<AuthOtpSent>()]));
    expect(repo.sent, ['+201000000000/static']);
    await bloc.close();
    AppSettingsService.instance.settings = null;
  });
}
