class SpecialistDoctorsResponse {
  final int? statusCode;
  final List<String>? statusMessage;
  final int? count;
  final List<Doctor>? payLoad;

  SpecialistDoctorsResponse({
    this.statusCode,
    this.statusMessage,
    this.count,
    this.payLoad,
  });

  factory SpecialistDoctorsResponse.fromJson(Map<String, dynamic> json) {
    return SpecialistDoctorsResponse(
      statusCode: json['statusCode'],
      statusMessage: json['statusMessage'] != null
          ? List<String>.from(json['statusMessage'])
          : null,
      count: json['count'],
      payLoad: (json['payLoad'] as List<dynamic>?)
          ?.map((e) => Doctor.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class Doctor {
  final String? docid;
  final String? email;
  final dynamic phoneNumber; //Could be Object type check null/int/string during use
  final String? userName;
  final String? role;
  final String? firstName;
  final String? lastName;
  final String? allqualifications;
  final String? detailedInformation;
  final String? applicationUserId;
  final int? onlineDoctor;
  final String? experience;
  final String? doctorDutyTime;
  final String? imgLink;
  final int? id;
  final dynamic onlineStatus; //Could be Object type check null/int/string during use
  final dynamic profileMessage; //Could be Object type check null/int/string during use
  final dynamic specialty; //Could be Object type check null/int/string during use
  final String? averageRating;
  final String? doctorSpecialties;
  final String? consultationFee;

  Doctor({
    this.docid,
    this.email,
    this.phoneNumber,
    this.userName,
    this.role,
    this.firstName,
    this.lastName,
    this.allqualifications,
    this.detailedInformation,
    this.applicationUserId,
    this.onlineDoctor,
    this.experience,
    this.doctorDutyTime,
    this.imgLink,
    this.id,
    this.onlineStatus,
    this.profileMessage,
    this.specialty,
    this.averageRating,
    this.doctorSpecialties,
    this.consultationFee,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      docid: json['id'],
      email: json['Email'],
      phoneNumber: json['PhoneNumber'],
      userName: json['UserName'],
      role: json['Role'],
      firstName: json['FirstName'],
      lastName: json['LastName'],
      allqualifications: json['Allqualifications'],
      detailedInformation: json['DetailedInformation'],
      applicationUserId: json['ApplicationUserId'],
      onlineDoctor: json['OnlineDoctor'],
      experience: json['Experience'],
      doctorDutyTime: json['DoctorDutyTime'],
      imgLink: json['ImgLink'],
      id: json['Id'],
      onlineStatus: json['OnlineStatus'],
      profileMessage: json['ProfileMessage'],
      specialty: json['Specialty'],
      averageRating: (json['AverageRating'] as num?)?.toString(),
      doctorSpecialties: json['DoctorSpecialties'],
      consultationFee: json['ConsultationFee'],
    );
  }
}