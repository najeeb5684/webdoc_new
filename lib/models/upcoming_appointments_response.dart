
class UpcomingAppointmentsResponse {
  int? statusCode;
  List<String>? statusMessage;
  int? count;
  List<UpcomingAppointment>? payLoad;

  UpcomingAppointmentsResponse({
    this.statusCode,
    this.statusMessage,
    this.count,
    this.payLoad,
  });

  factory UpcomingAppointmentsResponse.fromJson(Map<String, dynamic> json) {
    return UpcomingAppointmentsResponse(
      statusCode: json['statusCode'],
      statusMessage: json['statusMessage'] != null ? List<String>.from(json['statusMessage']) : null,
      count: json['count'],
      payLoad: json['payLoad'] != null
          ? (json['payLoad'] as List).map((i) => UpcomingAppointment.fromJson(i)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'statusCode': statusCode,
      'statusMessage': statusMessage,
      'count': count,
      'payLoad': payLoad?.map((i) => i.toJson()).toList(),
    };
  }
}

class UpcomingAppointment {
  String? id;
  String? email;
  int? appointmentId;
  String? appointmentDate;
  String? appointmentTime;
  String? appointmentNo;
  String? status;
  int? consultationId; // Added property
  String? firstName;
  String? lastName;
  dynamic allqualifications;
  String? experience;
  String? imgLink;
  String? applicationUserId;
  String? specialty;
  String? followUpCode; // Added property

  UpcomingAppointment({
    this.id,
    this.email,
    this.appointmentId,
    this.appointmentDate,
    this.appointmentTime,
    this.appointmentNo,
    this.status,
    this.consultationId,  // Added to constructor
    this.firstName,
    this.lastName,
    this.allqualifications,
    this.experience,
    this.imgLink,
    this.applicationUserId,
    this.specialty,
    this.followUpCode, // Added to constructor
  });

  factory UpcomingAppointment.fromJson(Map<String, dynamic> json) {
    return UpcomingAppointment(
      id: json['id'],
      email: json['Email'],
      appointmentId: json['Id'],
      appointmentDate: json['AppointmentDate'],
      appointmentTime: json['AppointmentTime'],
      appointmentNo: json['AppointmentNo'],
      status: json['Status'],
      consultationId: json['ConsultationId'], // Assigned from JSON
      firstName: json['FirstName'],
      lastName: json['LastName'],
      allqualifications: json['Allqualifications'],
      experience: json['Experience'],
      imgLink: json['ImgLink'],
      applicationUserId: json['ApplicationUserId'],
      specialty: json['Specialty'],
      followUpCode: json['FollowUpCode'], // Assigned from JSON
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'Email': email,
      'Id': appointmentId,
      'AppointmentDate': appointmentDate,
      'AppointmentTime': appointmentTime,
      'AppointmentNo': appointmentNo,
      'Status': status,
      'ConsultationId': consultationId, // Added to toJson
      'FirstName': firstName,
      'LastName': lastName,
      'Allqualifications': allqualifications,
      'Experience': experience,
      'ImgLink': imgLink,
      'ApplicationUserId': applicationUserId,
      'Specialty': specialty,
      'FollowUpCode': followUpCode, // Added to toJson
    };
  }
}


/*
class UpcomingAppointmentsResponse {
  int? statusCode;
  List<String>? statusMessage;
  int? count;
  List<UpcomingAppointment>? payLoad;

  UpcomingAppointmentsResponse({
    this.statusCode,
    this.statusMessage,
    this.count,
    this.payLoad,
  });

  factory UpcomingAppointmentsResponse.fromJson(Map<String, dynamic> json) {
    return UpcomingAppointmentsResponse(
      statusCode: json['statusCode'],
      statusMessage: json['statusMessage'] != null ? List<String>.from(json['statusMessage']) : null,
      count: json['count'],
      payLoad: json['payLoad'] != null
          ? (json['payLoad'] as List).map((i) => UpcomingAppointment.fromJson(i)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'statusCode': statusCode,
      'statusMessage': statusMessage,
      'count': count,
      'payLoad': payLoad?.map((i) => i.toJson()).toList(),
    };
  }
}

class UpcomingAppointment {
  String? id;
  String? email;
  int? appointmentId;
  String? appointmentDate;
  String? appointmentTime;
  String? appointmentNo;
  String? status;
  String? firstName;
  String? lastName;
  dynamic allqualifications;
  String? experience;
  String? imgLink;
  String? applicationUserId;
  String? specialty;

  UpcomingAppointment({
    this.id,
    this.email,
    this.appointmentId,
    this.appointmentDate,
    this.appointmentTime,
    this.appointmentNo,
    this.status,
    this.firstName,
    this.lastName,
    this.allqualifications,
    this.experience,
    this.imgLink,
    this.applicationUserId,
    this.specialty,
  });

  factory UpcomingAppointment.fromJson(Map<String, dynamic> json) {
    return UpcomingAppointment(
      id: json['id'],
      email: json['Email'],
      appointmentId: json['Id'],
      appointmentDate: json['AppointmentDate'],
      appointmentTime: json['AppointmentTime'],
      appointmentNo: json['AppointmentNo'],
      status: json['Status'],
      firstName: json['FirstName'],
      lastName: json['LastName'],
      allqualifications: json['Allqualifications'],
      experience: json['Experience'],
      imgLink: json['ImgLink'],
      applicationUserId: json['ApplicationUserId'],
      specialty: json['Specialty'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'Email': email,
      'Id': appointmentId,
      'AppointmentDate': appointmentDate,
      'AppointmentTime': appointmentTime,
      'AppointmentNo': appointmentNo,
      'Status': status,
      'FirstName': firstName,
      'LastName': lastName,
      'Allqualifications': allqualifications,
      'Experience': experience,
      'ImgLink': imgLink,
      'ApplicationUserId': applicationUserId,
    };
  }
}*/
