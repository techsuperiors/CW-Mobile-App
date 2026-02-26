/// Response model for reset password and change password APIs
class ResetPasswordResponse {
  final bool success;
  final String? message;

  ResetPasswordResponse({
    required this.success,
    this.message,
  });

  factory ResetPasswordResponse.fromJson(Map<String, dynamic> json) {
    return ResetPasswordResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
    );
  }
}
