/// Response model for validate password reset OTP API
class ValidateOtpResponse {
  final bool success;
  final String? token;

  ValidateOtpResponse({
    required this.success,
    this.token,
  });

  factory ValidateOtpResponse.fromJson(Map<String, dynamic> json) {
    return ValidateOtpResponse(
      success: json['success'] as bool? ?? false,
      token: json['token'] as String?,
    );
  }
}
