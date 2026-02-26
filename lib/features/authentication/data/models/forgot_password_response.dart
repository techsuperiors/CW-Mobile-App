/// Response model for forgot password API
class ForgotPasswordResponse {
  final bool success;
  final ForgotPasswordData? data;

  ForgotPasswordResponse({
    required this.success,
    this.data,
  });

  factory ForgotPasswordResponse.fromJson(Map<String, dynamic> json) {
    return ForgotPasswordResponse(
      success: json['success'] as bool? ?? false,
      data: json['data'] != null
          ? ForgotPasswordData.fromJson(
              json['data'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class ForgotPasswordData {
  final String? otp;
  final String? email;

  ForgotPasswordData({
    this.otp,
    this.email,
  });

  factory ForgotPasswordData.fromJson(Map<String, dynamic> json) {
    return ForgotPasswordData(
      otp: json['otp'] as String?,
      email: json['email'] as String?,
    );
  }
}
