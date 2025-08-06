

// registration_response.dart

class RegistrationResponse {
  int? statusCode;
  List<String>? statusMessage;
  int? count;
  Payload? payLoad;

  RegistrationResponse({
    this.statusCode,
    this.statusMessage,
    this.count,
    this.payLoad,
  });

  factory RegistrationResponse.fromJson(Map<String, dynamic> json) {
    return RegistrationResponse(
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
  String? applicationUserId;
  String? firstName;
  String? lastName;
  String? cnic;
  String? dateOfBirth;
  String? gender;
  String? age;
  String? address;
  String? country;
  String? city;
  String? mobileNumber;
  int? freecall;
  bool? freePackageSubscribed;
  FreePackageDetails? freePackageDetails;
  bool? isPackageActivated;
  String? packageName;
  String? activeDate;
  String? expiryDate;

  Payload({
    this.applicationUserId,
    this.firstName,
    this.lastName,
    this.cnic,
    this.dateOfBirth,
    this.gender,
    this.age,
    this.address,
    this.country,
    this.city,
    this.mobileNumber,
    this.freecall,
    this.freePackageSubscribed,
    this.freePackageDetails,
    this.isPackageActivated,
    this.packageName,
    this.activeDate,
    this.expiryDate,
  });

  factory Payload.fromJson(Map<String, dynamic> json) {
    return Payload(
      applicationUserId: json['ApplicationUserId'],
      firstName: json['FirstName'],
      lastName: json['LastName'],
      cnic: json['CNIC'],
      dateOfBirth: json['DateOfBirth'],
      gender: json['Gender'],
      age: json['Age'],
      address: json['Address'],
      country: json['Country'],
      city: json['City'],
      mobileNumber: json['MobileNumber'],
      freecall: json['freecall'],
      freePackageSubscribed: json['free_package_subscribed'],
      freePackageDetails: json['free_package_details'] != null ? FreePackageDetails.fromJson(json['free_package_details']) : null,
      isPackageActivated: json['isPackageActivated'],
      packageName: json['PackageName'],
      activeDate: json['ActiveDate'],
      expiryDate: json['ExpiryDate'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ApplicationUserId': applicationUserId,
      'FirstName': firstName,
      'LastName': lastName,
      'CNIC': cnic,
      'DateOfBirth': dateOfBirth,
      'Gender': gender,
      'Age': age,
      'Address': address,
      'Country': country,
      'City': city,
      'MobileNumber': mobileNumber,
      'freecall': freecall,
      'free_package_subscribed': freePackageSubscribed,
      'free_package_details': freePackageDetails?.toJson(),
      'isPackageActivated': isPackageActivated,
      'PackageName': packageName,
      'ActiveDate': activeDate,
      'ExpiryDate': expiryDate,
    };
  }
}

class FreePackageDetails {
  String? insuranceProductId;
  String? patientProfileId;
  String? activeDate;
  String? expiryDate;
  String? lastPaidDate;
  String? totalWeeks;
  String? paidWeeks;
  String? status;
  String? voiceCalls;
  String? videoCalls;
  String? corporate;
  dynamic externalUniqueId; // Can be null, so using dynamic
  String? platform;

  FreePackageDetails({
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
    this.platform,
  });

  factory FreePackageDetails.fromJson(Map<String, dynamic> json) {
    return FreePackageDetails(
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
      platform: json['Platform'],
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
      'Platform': platform,
    };
  }
}

/*
// registration_response.dart

class RegistrationResponse {
  int? statusCode;
  List<String>? statusMessage;
  int? count;
  Payload? payLoad;

  RegistrationResponse({
    this.statusCode,
    this.statusMessage,
    this.count,
    this.payLoad,
  });

  factory RegistrationResponse.fromJson(Map<String, dynamic> json) {
    return RegistrationResponse(
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
  String? applicationUserId;
  String? firstName;
  String? lastName;
  String? cnic;
  String? dateOfBirth;
  String? gender;
  String? address;
  String? country;
  String? city;
  String? mobileNumber;
  int? freecall;

  Payload({
    this.applicationUserId,
    this.firstName,
    this.lastName,
    this.cnic,
    this.dateOfBirth,
    this.gender,
    this.address,
    this.country,
    this.city,
    this.mobileNumber,
    this.freecall,
  });

  factory Payload.fromJson(Map<String, dynamic> json) {
    return Payload(
      applicationUserId: json['ApplicationUserId'],
      firstName: json['FirstName'],
      lastName: json['LastName'],
      cnic: json['CNIC'],
      dateOfBirth: json['DateOfBirth'],
      gender: json['Gender'],
      address: json['Address'],
      country: json['Country'],
      city: json['City'],
      mobileNumber: json['MobileNumber'],
      freecall: json['freecall'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ApplicationUserId': applicationUserId,
      'FirstName': firstName,
      'LastName': lastName,
      'CNIC': cnic,
      'DateOfBirth': dateOfBirth,
      'Gender': gender,
      'Address': address,
      'Country': country,
      'City': city,
      'MobileNumber': mobileNumber,
      'freecall': freecall,
    };
  }
}*/
