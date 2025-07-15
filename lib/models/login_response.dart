
class LoginResponse {
  int? statusCode;
  List<String>? statusMessage;
  int? count;
  Payload? payLoad;

  LoginResponse({
    this.statusCode,
    this.statusMessage,
    this.count,
    this.payLoad,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
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
  User? user;
  String? accessToken;

  Payload({
    this.user,
    this.accessToken,
  });

  factory Payload.fromJson(Map<String, dynamic> json) {
    return Payload(
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      accessToken: json['access_token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user?.toJson(),
      'access_token': accessToken,
    };
  }
}

class User {
  String? id;
  String? email;
  int? emailConfirmed;
  String? phoneNumber;
  int? phoneNumberConfirmed;
  int? twoFactorEnabled;
  dynamic lockoutEndDateUtc; // Can be null
  int? lockoutEnabled;
  int? accessFailedCount;
  String? userName;
  String? role;
  String? status;
  bool? isPackageActivated;
  String? packageName;
  String? activeDate;
  String? expiryDate;
  UserPackages? userPackages;

  User({
    this.id,
    this.email,
    this.emailConfirmed,
    this.phoneNumber,
    this.phoneNumberConfirmed,
    this.twoFactorEnabled,
    this.lockoutEndDateUtc,
    this.lockoutEnabled,
    this.accessFailedCount,
    this.userName,
    this.role,
    this.status,
    this.isPackageActivated,
    this.packageName,
    this.activeDate,
    this.expiryDate,
    this.userPackages,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['Id'],
      email: json['Email'],
      emailConfirmed: json['EmailConfirmed'],
      phoneNumber: json['PhoneNumber'],
      phoneNumberConfirmed: json['PhoneNumberConfirmed'],
      twoFactorEnabled: json['TwoFactorEnabled'],
      lockoutEndDateUtc: json['LockoutEndDateUtc'],
      lockoutEnabled: json['LockoutEnabled'],
      accessFailedCount: json['AccessFailedCount'],
      userName: json['UserName'],
      role: json['Role'],
      status: json['Status'],
      isPackageActivated: json['isPackageActivated'],
      packageName: json['PackageName'],
      activeDate: json['ActiveDate'],
      expiryDate: json['ExpiryDate'],
      userPackages: json['userPackages'] != null && json['userPackages'] is Map<String, dynamic> // ADDED CONDITION
          ? UserPackages.fromJson(json['userPackages'] as Map<String, dynamic>) // Explicit cast
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      'Email': email,
      'EmailConfirmed': emailConfirmed,
      'PhoneNumber': phoneNumber,
      'PhoneNumberConfirmed': phoneNumberConfirmed,
      'TwoFactorEnabled': twoFactorEnabled,
      'LockoutEndDateUtc': lockoutEndDateUtc,
      'LockoutEnabled': lockoutEnabled,
      'AccessFailedCount': accessFailedCount,
      'UserName': userName,
      'Role': role,
      'Status': status,
      'isPackageActivated': isPackageActivated,
      'PackageName': packageName,
      'ActiveDate': activeDate,
      'ExpiryDate': expiryDate,
      'userPackages': userPackages?.toJson(),
    };
  }
}

class UserPackages {
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

  UserPackages({
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

  factory UserPackages.fromJson(Map<String, dynamic> json) {
    return UserPackages(
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

  Map<String, dynamic> toJson() {
    return {
      'Id': id,
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
      'packageName': packageName?.toJson(),
    };
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

  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      'Description': description,
      'VoiceCallLimit': voiceCallLimit,
      'VideoCallLimit': videoCallLimit,
      'Packagetype': packagetype,
      'Price': price,
      'Duration': duration,
      'Addonfeatures': addonfeatures,
      'Imagelink': imagelink,
    };
  }
}


/*
class LoginData {
  String? applicationUserId;
  String? name;
  String? contactNumber;
  bool? isPackageActivated;
  String? packageName;
  String? activeDate;
  String? expiryDate;

  LoginData({
    this.applicationUserId,
    this.name,
    this.contactNumber,
    this.isPackageActivated,
    this.packageName,
    this.activeDate,
    this.expiryDate,
  });

  factory LoginData.fromJson(Map<String, dynamic> json) {
    return LoginData(
      applicationUserId: json['ApplicationUserId'],
      name: json['Name'],
      contactNumber: json['ContactNumber'],
      isPackageActivated: json['isPackageActivated'],
      packageName: json['PackageName'],
      activeDate: json['ActiveDate'],
      expiryDate: json['ExpiryDate'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ApplicationUserId': applicationUserId,
      'Name': name,
      'ContactNumber': contactNumber,
      'isPackageActivated': isPackageActivated,
      'PackageName': packageName,
      'ActiveDate': activeDate,
      'ExpiryDate': expiryDate,
    };
  }
}

class LoginResponse {
  String? responseCode;
  String? message;
  LoginData? loginData;

  LoginResponse({
    this.responseCode,
    this.message,
    this.loginData,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      responseCode: json['ResponseCode'],
      message: json['Message'],
      loginData: json['LoginData'] != null
          ? LoginData.fromJson(json['LoginData'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ResponseCode': responseCode,
      'Message': message,
      'LoginData': loginData?.toJson(),
    };
  }
}*/
