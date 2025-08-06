
class PastAppointmentsResponse {
  int? statusCode;
  List<String>? statusMessage;
  int? count;
  List<Appointment>? payLoad;

  PastAppointmentsResponse({this.statusCode, this.statusMessage, this.count, this.payLoad});

  PastAppointmentsResponse.fromJson(Map<String, dynamic> json) {
    statusCode = json['statusCode'];
    statusMessage = (json['statusMessage'] as List<dynamic>).cast<String>();
    count = json['count'];
    if (json['payLoad'] != null) {
      payLoad = <Appointment>[];
      json['payLoad'].forEach((v) {
        payLoad!.add(Appointment.fromJson(v as Map<String, dynamic>));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['statusCode'] = this.statusCode;
    data['statusMessage'] = this.statusMessage;
    data['count'] = this.count;
    if (this.payLoad != null) {
      data['payLoad'] = this.payLoad!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Appointment {
  String? id;
  String? email;
  int? appointmentId;
  String? appointmentDate;
  String? appointmentTime;
  String? appointmentNo;
  String? status;
  int? consultationId;
  String? firstName;
  String? lastName;
  String? allqualifications;
  String? experience;
  String? imgLink;
  String? applicationUserId;
  String? specialty;
  String? followUpCode;

  Appointment({
    this.id,
    this.email,
    this.appointmentId,
    this.appointmentDate,
    this.appointmentTime,
    this.appointmentNo,
    this.status,
    this.consultationId,
    this.firstName,
    this.lastName,
    this.allqualifications,
    this.experience,
    this.imgLink,
    this.applicationUserId,
    this.specialty,
    this.followUpCode,
  });

  Appointment.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    email = json['Email'];
    appointmentId = json['Id'];
    appointmentDate = json['AppointmentDate'];
    appointmentTime = json['AppointmentTime'];
    appointmentNo = json['AppointmentNo'];
    status = json['Status'];
    consultationId = json['ConsultationId'];
    firstName = json['FirstName'];
    lastName = json['LastName'];
    allqualifications = json['Allqualifications'];
    experience = json['Experience'];
    imgLink = json['ImgLink'];
    applicationUserId = json['ApplicationUserId'];
    specialty = json['Specialty'];
    followUpCode = json['FollowUpCode'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = this.id;
    data['Email'] = this.email;
    data['Id'] = this.appointmentId;
    data['AppointmentDate'] = this.appointmentDate;
    data['AppointmentTime'] = this.appointmentTime;
    data['AppointmentNo'] = this.appointmentNo;
    data['Status'] = this.status;
    data['ConsultationId'] = this.consultationId;
    data['FirstName'] = this.firstName;
    data['LastName'] = this.lastName;
    data['Allqualifications'] = this.allqualifications;
    data['Experience'] = this.experience;
    data['ImgLink'] = this.imgLink;
    data['ApplicationUserId'] = this.applicationUserId;
    data['Specialty'] = this.specialty;
    data['FollowUpCode'] = this.followUpCode;
    return data;
  }
}


/*class PastAppointmentsResponse {
  int? statusCode;
  List<String>? statusMessage;
  int? count;
  List<Appointment>? payLoad;

  PastAppointmentsResponse({this.statusCode, this.statusMessage, this.count, this.payLoad});

  PastAppointmentsResponse.fromJson(Map<String, dynamic> json) {
    statusCode = json['statusCode'];
    statusMessage = json['statusMessage'].cast<String>();
    count = json['count'];
    if (json['payLoad'] != null) {
      payLoad = <Appointment>[];
      json['payLoad'].forEach((v) {
        payLoad!.add(new Appointment.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['statusCode'] = this.statusCode;
    data['statusMessage'] = this.statusMessage;
    data['count'] = this.count;
    if (this.payLoad != null) {
      data['payLoad'] = this.payLoad!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}
class Appointment {
  String? id;
  String? email;
  int? appointmentId;
  String? appointmentDate;
  String? appointmentTime;
  String? appointmentNo;
  String? status;
  String? firstName;
  String? lastName;
  String? allqualifications;
  String? experience;
  String? imgLink;
  String? applicationUserId;
  String? specialty;
  int? consultationId; // Add this line

  Appointment(
      {this.id,
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
        this.consultationId // Add this to the constructor
      });

  Appointment.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    email = json['Email'];
    appointmentId = json['Id'];
    appointmentDate = json['AppointmentDate'];
    appointmentTime = json['AppointmentTime'];
    appointmentNo = json['AppointmentNo'];
    status = json['Status'];
    firstName = json['FirstName'];
    lastName = json['LastName'];
    allqualifications = json['Allqualifications'];
    experience = json['Experience'];
    imgLink = json['ImgLink'];
    applicationUserId = json['ApplicationUserId'];
    specialty = json['Specialty'];
    consultationId = json['ConsultationId']; // Add this line
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['Email'] = this.email;
    data['Id'] = this.appointmentId;
    data['AppointmentDate'] = this.appointmentDate;
    data['AppointmentTime'] = this.appointmentTime;
    data['AppointmentNo'] = this.appointmentNo;
    data['Status'] = this.status;
    data['FirstName'] = this.firstName;
    data['LastName'] = this.lastName;
    data['Allqualifications'] = this.allqualifications;
    data['Experience'] = this.experience;
    data['ImgLink'] = this.imgLink;
    data['ApplicationUserId'] = this.applicationUserId;
    data['Specialty'] = this.specialty;
    data['ConsultationId'] = this.consultationId; // Add this line
    return data;
  }
}*/





/*
class PastAppointmentsResponse {
  int? statusCode;
  List<String>? statusMessage;
  int? count;
  List<Appointment>? payLoad;

  PastAppointmentsResponse({this.statusCode, this.statusMessage, this.count, this.payLoad});

  PastAppointmentsResponse.fromJson(Map<String, dynamic> json) {
    statusCode = json['statusCode'];
    statusMessage = json['statusMessage'].cast<String>();
    count = json['count'];
    if (json['payLoad'] != null) {
      payLoad = <Appointment>[];
      json['payLoad'].forEach((v) {
        payLoad!.add(new Appointment.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['statusCode'] = this.statusCode;
    data['statusMessage'] = this.statusMessage;
    data['count'] = this.count;
    if (this.payLoad != null) {
      data['payLoad'] = this.payLoad!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Appointment {
  String? id;
  String? email;
  int? appointmentId;
  String? appointmentDate;
  String? appointmentTime;
  String? appointmentNo;
  String? status;
  String? firstName;
  String? lastName;
  String? allqualifications;
  String? experience;
  String? imgLink;
  String? applicationUserId;
  String? specialty;

  Appointment(
      {this.id,
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
        this.specialty
      });

  Appointment.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    email = json['Email'];
    appointmentId = json['Id'];
    appointmentDate = json['AppointmentDate'];
    appointmentTime = json['AppointmentTime'];
    appointmentNo = json['AppointmentNo'];
    status = json['Status'];
    firstName = json['FirstName'];
    lastName = json['LastName'];
    allqualifications = json['Allqualifications'];
    experience = json['Experience'];
    imgLink = json['ImgLink'];
    applicationUserId = json['ApplicationUserId'];
    specialty = json['Specialty'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['Email'] = this.email;
    data['Id'] = this.appointmentId;
    data['AppointmentDate'] = this.appointmentDate;
    data['AppointmentTime'] = this.appointmentTime;
    data['AppointmentNo'] = this.appointmentNo;
    data['Status'] = this.status;
    data['FirstName'] = this.firstName;
    data['LastName'] = this.lastName;
    data['Allqualifications'] = this.allqualifications;
    data['Experience'] = this.experience;
    data['ImgLink'] = this.imgLink;
    data['ApplicationUserId'] = this.applicationUserId;
    data['Specialty'] = this.specialty;
    return data;
  }
}*/
