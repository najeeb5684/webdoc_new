// activate_response.dart

class ActivateResponse {
  int? statusCode;
  List<String>? statusMessage;
  int? count;
  Payload? payLoad;

  ActivateResponse({
    this.statusCode,
    this.statusMessage,
    this.count,
    this.payLoad,
  });

  factory ActivateResponse.fromJson(Map<String, dynamic> json) {
    return ActivateResponse(
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
  int? insuranceProductId;
  String? patientProfileId;
  String? activeDate;
  String? expiryDate;
  String? lastPaidDate;
  int? totalWeeks;
  int? paidWeeks;
  String? status;
  int? voiceCalls;
  int? videoCalls;
  String? corporate;
  dynamic externalUniqueId; // Can be null

  Payload({
    this.insuranceProductId,
    this.patientProfileId,
    this.activeDate,
    this.expiryDate,
    this.lastPaidDate,
    this.totalWeeks,
    this.paidWeeks,
    this.status,
    this.voiceCalls,
    this.videoCalls,
    this.corporate,
    this.externalUniqueId,
  });

  factory Payload.fromJson(Map<String, dynamic> json) {
    return Payload(
      insuranceProductId: json['InsuranceProductId'],
      patientProfileId: json['PatientProfileId'],
      activeDate: json['ActiveDate'],
      expiryDate: json['ExpiryDate'],
      lastPaidDate: json['LastPaidDate'],
      totalWeeks: json['TotalWeeks'],
      paidWeeks: json['PaidWeeks'],
      status: json['Status'],
      voiceCalls: json['VoiceCalls'],
      videoCalls: json['VideoCalls'],
      corporate: json['Corporate'],
      externalUniqueId: json['ExternalUniqueId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'InsuranceProductId': insuranceProductId,
      'PatientProfileId': patientProfileId,
      'ActiveDate': activeDate,
      'ExpiryDate': expiryDate,
      'LastPaidDate': lastPaidDate,
      'TotalWeeks': totalWeeks,
      'PaidWeeks': paidWeeks,
      'Status': status,
      'VoiceCalls': voiceCalls,
      'VideoCalls': videoCalls,
      'Corporate': corporate,
      'ExternalUniqueId': externalUniqueId,
    };
  }
}