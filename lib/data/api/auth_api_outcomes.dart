import '../models/user_model.dart';

sealed class AuthApiLoginOutcome {}

final class AuthApiLoginSuccess extends AuthApiLoginOutcome {
  AuthApiLoginSuccess(this.user);
  final UserModel user;
}

final class AuthApiLoginOtpRequired extends AuthApiLoginOutcome {
  AuthApiLoginOtpRequired({
    required this.message,
    this.emailMasked,
    required this.resendAfterSeconds,
  });

  final String message;
  final String? emailMasked;
  final int resendAfterSeconds;
}

sealed class AuthApiRegisterOutcome {}

final class AuthApiRegisterSuccess extends AuthApiRegisterOutcome {
  AuthApiRegisterSuccess(this.user);
  final UserModel user;
}

final class AuthApiRegisterOtpRequired extends AuthApiRegisterOutcome {
  AuthApiRegisterOtpRequired({
    required this.message,
    this.emailMasked,
    required this.resendAfterSeconds,
  });

  final String message;
  final String? emailMasked;
  final int resendAfterSeconds;
}
