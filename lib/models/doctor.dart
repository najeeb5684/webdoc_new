class Doctor {
  String? doctorId;
  String? firstName;
  String? lastName;
  String? imgLink;
  String? doctorSpecialty;
  String? country;
  String? isOnline;
  String? profileMessage;
  String? rate; // Rating
  String? emailDoctor; // Add the doctorEmail property
  String? qualifications;
  String? experience;

  Doctor({
    this.doctorId,
    this.firstName,
    this.lastName,
    this.imgLink,
    this.doctorSpecialty,
    this.country,
    this.isOnline,
    this.profileMessage,
    this.rate,
    this.emailDoctor,
    this.qualifications,
    this.experience,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      doctorId: json['doctorId']?.toString(),
      firstName: json['firstName'],
      lastName: json['lastName'],
      imgLink: json['imgLink'],
      doctorSpecialty: json['doctorSpecialty'],
      country: json['country'],
      isOnline: json['isOnline'],
      profileMessage: json['profileMessage'],
      rate: json['rate']?.toString(),
      emailDoctor: json['emailDoctor'], // Parse emailDoctor from JSON
      qualifications: json['qualifications'],
      experience: json['experience'],
    );
  }
}

class DoctorListResponse {
  String? responseCode;
  List<Doctor>? doctorList;

  DoctorListResponse({this.responseCode, this.doctorList});

  factory DoctorListResponse.fromJson(Map<String, dynamic> json) {
    return DoctorListResponse(
      responseCode: json['responseCode'],
      doctorList: (json['doctorList'] as List<dynamic>?)
          ?.map((e) => Doctor.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
/*
class Doctor {
  String? doctorId;
  String? firstName;
  String? lastName;
  String? imgLink;
  String? doctorSpecialty;
  String? country;
  String? isOnline;
  double? rate; // Rating
  String? emailDoctor; // Add the doctorEmail property

  Doctor({
    this.doctorId,
    this.firstName,
    this.lastName,
    this.imgLink,
    this.doctorSpecialty,
    this.country,
    this.isOnline,
    this.rate,
    this.emailDoctor,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      doctorId: json['doctorId']?.toString(),
      firstName: json['firstName'],
      lastName: json['lastName'],
      imgLink: json['imgLink'],
      doctorSpecialty: json['doctorSpecialty'],
      country: json['country'],
      isOnline: json['isOnline'],
      rate: double.tryParse(json['rate']?.toString() ?? '0.0'),
      emailDoctor: json['emailDoctor'], // Parse emailDoctor from JSON
    );
  }
}
class DoctorListResponse {
  String? responseCode;
  List<Doctor>? doctorList;

  DoctorListResponse({this.responseCode, this.doctorList});

  factory DoctorListResponse.fromJson(Map<String, dynamic> json) {
    return DoctorListResponse(
      responseCode: json['responseCode'],
      doctorList: (json['doctorList'] as List<dynamic>?)
          ?.map((e) => Doctor.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}*/
