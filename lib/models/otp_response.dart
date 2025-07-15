
// otp_response.dart

class OtpResponse {
  int? statusCode;
  List<String>? statusMessage;
  int? count;
  Payload? payLoad;

  OtpResponse({
    this.statusCode,
    this.statusMessage,
    this.count,
    this.payLoad,
  });

  factory OtpResponse.fromJson(Map<String, dynamic> json) {
    return OtpResponse(
      statusCode: json['statusCode'],
      statusMessage: json['statusMessage'] != null
          ? List<String>.from(json['statusMessage'])
          : null,
      count: json['count'],
      payLoad: json['payLoad'] != null ? Payload.fromJson(json['payLoad']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'statusCode': statusCode,
      'statusMessage': statusMessage,
      'count': count,
      'payLoad': payLoad?.toJson(),
    };
  }
}

class Payload {
  String? phone;
  String? expiresIn;
  String? providerUsed;
  bool? isLocalNumber;

  Payload({
    this.phone,
    this.expiresIn,
    this.providerUsed,
    this.isLocalNumber,
  });

  factory Payload.fromJson(Map<String, dynamic> json) {
    return Payload(
      phone: json['phone'],
      expiresIn: json['expires_in'],
      providerUsed: json['provider_used'],
      isLocalNumber: json['is_local_number'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phone': phone,
      'expires_in': expiresIn,
      'provider_used': providerUsed,
      'is_local_number': isLocalNumber,
    };
  }
}