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
}