
class ApiResponse {
  final int statusCode;
  final List<String> statusMessage;
  final int count;
  final dynamic payLoad;

  ApiResponse({
    required this.statusCode,
    required this.statusMessage,
    required this.count,
    required this.payLoad,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      statusCode: json['statusCode'] as int,
      statusMessage: List<String>.from(json['statusMessage'] as List),
      count: json['count'] as int,
      payLoad: json['payLoad'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'statusCode': statusCode,
      'statusMessage': statusMessage,
      'count': count,
      'payLoad': payLoad,
    };
  }
}

//------------------------------------------------------------------------------
// Models specific to Send OTP API
//------------------------------------------------------------------------------

class SendOtpResponse extends ApiResponse {
  final SendOtpPayload? payLoad;

  SendOtpResponse({
    required int statusCode,
    required List<String> statusMessage,
    required int count,
    this.payLoad,
  }) : super(statusCode: statusCode, statusMessage: statusMessage, count: count, payLoad: payLoad);

  factory SendOtpResponse.fromJson(Map<String, dynamic> json) {
    return SendOtpResponse(
      statusCode: json['statusCode'] as int,
      statusMessage: List<String>.from(json['statusMessage'] as List),
      count: json['count'] as int,
      payLoad: json['payLoad'] != null ? SendOtpPayload.fromJson(json['payLoad']) : null,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'statusCode': statusCode,
      'statusMessage': statusMessage,
      'count': count,
      'payLoad': payLoad?.toJson(),
    };
  }
}

class SendOtpPayload {
  final String phone;
  final String type;
  final String expiresIn;
  final String providerUsed;
  final bool isLocalNumber;
  final bool otpId;

  SendOtpPayload({
    required this.phone,
    required this.type,
    required this.expiresIn,
    required this.providerUsed,
    required this.isLocalNumber,
    required this.otpId,
  });

  factory SendOtpPayload.fromJson(Map<String, dynamic> json) {
    return SendOtpPayload(
      phone: json['phone'] as String,
      type: json['type'] as String,
      expiresIn: json['expires_in'] as String,
      providerUsed: json['provider_used'] as String,
      isLocalNumber: json['is_local_number'] as bool,
      otpId: json['otp_id'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phone': phone,
      'type': type,
      'expires_in': expiresIn,
      'provider_used': providerUsed,
      'is_local_number': isLocalNumber,
      'otp_id': otpId,
    };
  }
}

//------------------------------------------------------------------------------
// Models specific to Verify OTP API
//------------------------------------------------------------------------------

class VerifyOtpResponse extends ApiResponse {
  final VerifyOtpPayload? payLoad;

  VerifyOtpResponse({
    required int statusCode,
    required List<String> statusMessage,
    required int count,
    this.payLoad,
  }) : super(statusCode: statusCode, statusMessage: statusMessage, count: count, payLoad: payLoad);

  factory VerifyOtpResponse.fromJson(Map<String, dynamic> json) {
    return VerifyOtpResponse(
      statusCode: json['statusCode'] as int,
      statusMessage: List<String>.from(json['statusMessage'] as List),
      count: json['count'] as int,
      payLoad: json['payLoad'] != null ? VerifyOtpPayload.fromJson(json['payLoad']) : null,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'statusCode': statusCode,
      'statusMessage': statusMessage,
      'count': count,
      'payLoad': payLoad?.toJson(),
    };
  }
}

class VerifyOtpPayload {
  final String phone;
  final String verifiedAt;
  final String providerUsed;

  VerifyOtpPayload({
    required this.phone,
    required this.verifiedAt,
    required this.providerUsed,
  });

  factory VerifyOtpPayload.fromJson(Map<String, dynamic> json) {
    return VerifyOtpPayload(
      phone: json['phone'] as String,
      verifiedAt: json['verified_at'] as String,
      providerUsed: json['provider_used'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phone': phone,
      'verified_at': verifiedAt,
      'provider_used': providerUsed,
    };
  }
}
