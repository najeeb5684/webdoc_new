


import 'dart:convert';

SpecialistPrescriptionResponse specialistPrescriptionResponseFromJson(String str) => SpecialistPrescriptionResponse.fromJson(json.decode(str));

String specialistPrescriptionResponseToJson(SpecialistPrescriptionResponse data) => json.encode(data.toJson());

class SpecialistPrescriptionResponse {
  int statusCode;
  List<String> statusMessage;
  int count;
  Consultation payLoad;

  SpecialistPrescriptionResponse({
    required this.statusCode,
    required this.statusMessage,
    required this.count,
    required this.payLoad,
  });

  factory SpecialistPrescriptionResponse.fromJson(Map<String, dynamic> json) => SpecialistPrescriptionResponse(
    statusCode: json["statusCode"] ?? 0,
    statusMessage: json["statusMessage"] == null ? [] : List<String>.from(json["statusMessage"].map((x) => x.toString())),
    count: json["count"] ?? 0,
    payLoad: Consultation.fromJson(json["payLoad"] ?? {}),
  );

  Map<String, dynamic> toJson() => {
    "statusCode": statusCode,
    "statusMessage": List<dynamic>.from(statusMessage.map((x) => x)),
    "count": count,
    "payLoad": payLoad.toJson(),
  };
}

class Consultation {
  int id;
  String consultationDate;
  String complaint;
  String diagnosis;
  String prescription;
  String tests;
  String remarks;
  String doctorFirstName;
  String doctorLastName;
  String patientAddress;
  String patientFirstName;
  String patientLastName;
  String patientCountry;
  String doctorExperience;
  String docSpeciality;
  String patientPhone;
  String doctorSpecialties;
  String doctorFullName;
  List<Consultationdetail> consultationdetails;
  String? consultationType;

  Consultation({
    required this.id,
    required this.consultationDate,
    required this.complaint,
    required this.diagnosis,
    required this.prescription,
    required this.tests,
    required this.remarks,
    required this.doctorFirstName,
    required this.doctorLastName,
    required this.patientAddress,
    required this.patientFirstName,
    required this.patientLastName,
    required this.patientCountry,
    required this.doctorExperience,
    required this.docSpeciality,
    required this.patientPhone,
    required this.doctorSpecialties,
    required this.doctorFullName,
    required this.consultationdetails,
    this.consultationType,
  });

  factory Consultation.fromJson(Map<String, dynamic> json) => Consultation(
    id: json["Id"] ?? 0,
    consultationDate: json["ConsultationDate"] ?? 'N/A',
    complaint: json["Complaint"] ?? 'N/A',
    diagnosis: json["Diagnosis"] ?? 'N/A',
    prescription: json["Prescription"] ?? 'N/A',
    tests: json["Tests"] ?? 'N/A',
    remarks: json["Remarks"] ?? 'N/A',
    doctorFirstName: json["DoctorFirstName"] ?? 'N/A',
    doctorLastName: json["DoctorLastName"] ?? 'N/A',
    patientAddress: json["PatientAddress"] ?? 'N/A',
    patientFirstName: json["PatientFirstName"] ?? 'N/A',
    patientLastName: json["PatientLastName"] ?? 'N/A',
    patientCountry: json["PatientCountry"] ?? 'N/A',
    doctorExperience: json["DoctorExperience"] ?? 'N/A',
    docSpeciality: json["DocSpeciality"] ?? 'N/A',
    patientPhone: json["PatientPhone"] ?? 'N/A',
    doctorSpecialties: json["DoctorSpecialties"] ?? 'N/A',
    doctorFullName: json["DoctorFullName"] ?? 'N/A',
    consultationdetails: json["Consultationdetails"] == null ? [] : List<Consultationdetail>.from(json["Consultationdetails"].map((x) => Consultationdetail.fromJson(x))),
    consultationType: json["ConsultationType"] ?? 'N/A',
  );

  Map<String, dynamic> toJson() => {
    "Id": id,
    "ConsultationDate": consultationDate,
    "Complaint": complaint,
    "Diagnosis": diagnosis,
    "Prescription": prescription,
    "Tests": tests,
    "Remarks": remarks,
    "DoctorFirstName": doctorFirstName,
    "DoctorLastName": doctorLastName,
    "PatientAddress": patientAddress,
    "PatientFirstName": patientFirstName,
    "PatientLastName": patientLastName,
    "PatientCountry": patientCountry,
    "DoctorExperience": doctorExperience,
    "DocSpeciality": docSpeciality,
    "PatientPhone": patientPhone,
    "DoctorSpecialties": doctorSpecialties,
    "DoctorFullName": doctorFullName,
    "Consultationdetails": List<dynamic>.from(consultationdetails.map((x) => x.toJson())),
    "ConsultationType": consultationType,
  };

  String get doctorName => '$doctorFirstName $doctorLastName';
}

class Consultationdetail {
  int id;
  int consultationId;
  String day;
  String night;
  String morning;
  String days;
  String status;
  String additionalNotes;
  int medicineNameId;
  dynamic quantity;
  String medicineName;
  String? noOfDays;

  Consultationdetail({
    required this.id,
    required this.consultationId,
    required this.day,
    required this.night,
    required this.morning,
    required this.days,
    required this.status,
    required this.additionalNotes,
    required this.medicineNameId,
    required this.quantity,
    required this.medicineName,
    this.noOfDays,
  });

  factory Consultationdetail.fromJson(Map<String, dynamic> json) => Consultationdetail(
    id: json["Id"] ?? 0,
    consultationId: json["ConsultationId"] ?? 0,
    day: json["Day"] ?? 'N/A',
    night: json["Night"] ?? 'N/A',
    morning: json["Morning"] ?? 'N/A',
    days: json["Days"] ?? 'N/A',
    status: json["status"] ?? 'N/A',
    additionalNotes: json["AdditionalNotes"] ?? 'N/A',
    medicineNameId: json["MedicineNameId"] ?? 0,
    quantity: json["quantity"] ?? 'N/A',
    medicineName: json["MedicineName"] ?? 'N/A',
    noOfDays: json["Days"] ?? 'N/A',
  );

  Map<String, dynamic> toJson() => {
    "Id": id,
    "ConsultationId": consultationId,
    "Day": day,
    "Night": night,
    "Morning": morning,
    "Days": days,
    "status": status,
    "AdditionalNotes": additionalNotes,
    "MedicineNameId": medicineNameId,
    "quantity": quantity,
    "MedicineName": medicineName,
    "Days": noOfDays,
  };
}



/*
// specialist_prescription_response.dart
import 'dart:convert';

SpecialistPrescriptionResponse specialistPrescriptionResponseFromJson(String str) => SpecialistPrescriptionResponse.fromJson(json.decode(str));

String specialistPrescriptionResponseToJson(SpecialistPrescriptionResponse data) => json.encode(data.toJson());

class SpecialistPrescriptionResponse {
  int statusCode;
  List<String> statusMessage;
  int count;
  Consultation payLoad;

  SpecialistPrescriptionResponse({
    required this.statusCode,
    required this.statusMessage,
    required this.count,
    required this.payLoad,
  });

  factory SpecialistPrescriptionResponse.fromJson(Map<String, dynamic> json) => SpecialistPrescriptionResponse(
    statusCode: json["statusCode"],
    statusMessage: List<String>.from(json["statusMessage"].map((x) => x)),
    count: json["count"],
    payLoad: Consultation.fromJson(json["payLoad"]),
  );

  Map<String, dynamic> toJson() => {
    "statusCode": statusCode,
    "statusMessage": List<dynamic>.from(statusMessage.map((x) => x)),
    "count": count,
    "payLoad": payLoad.toJson(),
  };
}

class Consultation {
  int id;
  String consultationDate;
  String complaint;
  String diagnosis;
  String prescription;
  String tests;
  String remarks;
  String doctorFirstName;
  String doctorLastName;
  String patientAddress;
  String patientFirstName;
  String patientLastName;
  String patientCountry;
  String doctorExperience;
  String docSpeciality;
  String patientPhone;
  String doctorSpecialties;
  String doctorFullName;
  List<Consultationdetail> consultationdetails;
  String? consultationType;

  Consultation({
    required this.id,
    required this.consultationDate,
    required this.complaint,
    required this.diagnosis,
    required this.prescription,
    required this.tests,
    required this.remarks,
    required this.doctorFirstName,
    required this.doctorLastName,
    required this.patientAddress,
    required this.patientFirstName,
    required this.patientLastName,
    required this.patientCountry,
    required this.doctorExperience,
    required this.docSpeciality,
    required this.patientPhone,
    required this.doctorSpecialties,
    required this.doctorFullName,
    required this.consultationdetails,
    this.consultationType,
  });

  factory Consultation.fromJson(Map<String, dynamic> json) => Consultation(
    id: json["Id"],
    consultationDate: json["ConsultationDate"],
    complaint: json["Complaint"],
    diagnosis: json["Diagnosis"],
    prescription: json["Prescription"],
    tests: json["Tests"],
    remarks: json["Remarks"],
    doctorFirstName: json["DoctorFirstName"],
    doctorLastName: json["DoctorLastName"],
    patientAddress: json["PatientAddress"],
    patientFirstName: json["PatientFirstName"],
    patientLastName: json["PatientLastName"],
    patientCountry: json["PatientCountry"],
    doctorExperience: json["DoctorExperience"],
    docSpeciality: json["DocSpeciality"],
    patientPhone: json["PatientPhone"],
    doctorSpecialties: json["DoctorSpecialties"],
    doctorFullName: json["DoctorFullName"],
    consultationdetails: List<Consultationdetail>.from(json["Consultationdetails"].map((x) => Consultationdetail.fromJson(x))),
    consultationType: json["ConsultationType"],
  );

  Map<String, dynamic> toJson() => {
    "Id": id,
    "ConsultationDate": consultationDate,
    "Complaint": complaint,
    "Diagnosis": diagnosis,
    "Prescription": prescription,
    "Tests": tests,
    "Remarks": remarks,
    "DoctorFirstName": doctorFirstName,
    "DoctorLastName": doctorLastName,
    "PatientAddress": patientAddress,
    "PatientFirstName": patientFirstName,
    "PatientLastName": patientLastName,
    "PatientCountry": patientCountry,
    "DoctorExperience": doctorExperience,
    "DocSpeciality": docSpeciality,
    "PatientPhone": patientPhone,
    "DoctorSpecialties": doctorSpecialties,
    "DoctorFullName": doctorFullName,
    "Consultationdetails": List<dynamic>.from(consultationdetails.map((x) => x.toJson())),
    "ConsultationType": consultationType,
  };

  String? get doctorName => '$doctorFirstName $doctorLastName';
}

class Consultationdetail {
  int id;
  int consultationId;
  String day;
  String night;
  String morning;
  String days;
  String status;
  String additionalNotes;
  int medicineNameId;
  dynamic quantity;
  String medicineName;
  String? noOfDays;

  Consultationdetail({
    required this.id,
    required this.consultationId,
    required this.day,
    required this.night,
    required this.morning,
    required this.days,
    required this.status,
    required this.additionalNotes,
    required this.medicineNameId,
    required this.quantity,
    required this.medicineName,
    this.noOfDays,
  });

  factory Consultationdetail.fromJson(Map<String, dynamic> json) => Consultationdetail(
    id: json["Id"],
    consultationId: json["ConsultationId"],
    day: json["Day"],
    night: json["Night"],
    morning: json["Morning"],
    days: json["Days"],
    status: json["status"],
    additionalNotes: json["AdditionalNotes"],
    medicineNameId: json["MedicineNameId"],
    quantity: json["quantity"],
    medicineName: json["MedicineName"],
    noOfDays: json["Days"],
  );

  Map<String, dynamic> toJson() => {
    "Id": id,
    "ConsultationId": consultationId,
    "Day": day,
    "Night": night,
    "Morning": morning,
    "Days": days,
    "status": status,
    "AdditionalNotes": additionalNotes,
    "MedicineNameId": medicineNameId,
    "quantity": quantity,
    "MedicineName": medicineName,
    "Days": noOfDays,
  };
}*/
