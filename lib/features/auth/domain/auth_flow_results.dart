import 'entities/user_entity.dart';

/// Данные для экрана ввода OTP после ответа бэка `requires_otp`.
final class OtpChallenge {
  const OtpChallenge({
    required this.message,
    this.emailMasked,
    required this.resendAfterSeconds,
  });

  final String message;
  final String? emailMasked;
  final int resendAfterSeconds;
}

sealed class AuthLoginResult {}

final class AuthLoginSuccess extends AuthLoginResult {
  AuthLoginSuccess(this.user);
  final UserEntity user;
}

final class AuthLoginNeedsOtp extends AuthLoginResult {
  AuthLoginNeedsOtp(this.challenge);
  final OtpChallenge challenge;
}

sealed class AuthRegisterResult {}

final class AuthRegisterSuccess extends AuthRegisterResult {
  AuthRegisterSuccess(this.user);
  final UserEntity user;
}

final class AuthRegisterNeedsOtp extends AuthRegisterResult {
  AuthRegisterNeedsOtp(this.challenge);
  final OtpChallenge challenge;
}
