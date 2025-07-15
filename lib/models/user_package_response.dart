class UserPackageResponse {
  int? statusCode;
  List<String>? statusMessage;
  int? count;
  UserPackagePayload? payLoad;

  UserPackageResponse({
    this.statusCode,
    this.statusMessage,
    this.count,
    this.payLoad,
  });

  factory UserPackageResponse.fromJson(Map<String, dynamic> json) {
    return UserPackageResponse(
      statusCode: json['statusCode'],
      statusMessage: json['statusMessage'] != null
          ? List<String>.from(json['statusMessage'])
          : null,
      count: json['count'],
      payLoad: json['payLoad'] != null
          ? UserPackagePayload.fromJson(json['payLoad'])
          : null,
    );
  }
}

class UserPackagePayload {
  int? id;
  int? insuranceProductId;
  String? patientProfileId;
  String? activeDate;
  String? expiryDate;
  String? lastPaidDate;
  String? totalWeeks;
  String? paidWeeks;
  String? status;
  int? voiceCalls;
  int? videoCalls;
  String? corporate;
  dynamic externalUniqueId; // Can be null
  PackageName? packageName;

  UserPackagePayload({
    this.id,
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
    this.packageName,
  });

  factory UserPackagePayload.fromJson(Map<String, dynamic> json) {
    return UserPackagePayload(
      id: json['Id'],
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
      packageName: json['packageName'] != null
          ? PackageName.fromJson(json['packageName'])
          : null,
    );
  }
}

class PackageName {
  int? id;
  String? description;
  int? voiceCallLimit;
  int? videoCallLimit;
  String? packagetype;
  String? price;
  String? duration;
  String? addonfeatures;
  String? imagelink;

  PackageName({
    this.id,
    this.description,
    this.voiceCallLimit,
    this.videoCallLimit,
    this.packagetype,
    this.price,
    this.duration,
    this.addonfeatures,
    this.imagelink,
  });

  factory PackageName.fromJson(Map<String, dynamic> json) {
    return PackageName(
      id: json['Id'],
      description: json['Description'],
      voiceCallLimit: json['VoiceCallLimit'],
      videoCallLimit: json['VideoCallLimit'],
      packagetype: json['Packagetype'],
      price: json['Price'],
      duration: json['Duration'],
      addonfeatures: json['Addonfeatures'],
      imagelink: json['Imagelink'],
    );
  }
}