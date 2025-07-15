class Profile {
  final int statusCode;
  final List<String> statusMessage;
  final int count;
  final PayLoad payLoad;

  Profile({
    required this.statusCode,
    required this.statusMessage,
    required this.count,
    required this.payLoad,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      statusCode: json['statusCode'],
      statusMessage: List<String>.from(json['statusMessage']),
      count: json['count'],
      payLoad: PayLoad.fromJson(json['payLoad']),
    );
  }
}

class PayLoad {
  final String applicationUserId;
  final String firstName;
  final String lastName;
  final String cnic;
  final String dateOfBirth;
  final String gender;
  final String address;
  final String country;
  final String city;
  final String mobileNumber;
  final String? martialStatus;
  final String age;
  final dynamic weight; // Could be int, double, or null
  final dynamic height; // Could be int, double, or null

  PayLoad({
    required this.applicationUserId,
    required this.firstName,
    required this.lastName,
    required this.cnic,
    required this.dateOfBirth,
    required this.gender,
    required this.address,
    required this.country,
    required this.city,
    required this.mobileNumber,
    this.martialStatus,
    required this.age,
    this.weight,
    this.height,
  });

  factory PayLoad.fromJson(Map<String, dynamic> json) {
    return PayLoad(
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
      martialStatus: json['MartialStatus'],
      age: json['Age'],
      weight: json['Weight'],
      height: json['Height'],
    );
  }
}