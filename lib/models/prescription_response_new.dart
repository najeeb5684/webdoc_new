// prescription_response_new.dart

class PrescriptionResponseNew {
  int? statusCode;
  List<String>? statusMessage;
  int? count;
  List<PrescriptionPayload>? payLoad;

  PrescriptionResponseNew({
    this.statusCode,
    this.statusMessage,
    this.count,
    this.payLoad,
  });

  factory PrescriptionResponseNew.fromJson(Map<String, dynamic> json) =>
      PrescriptionResponseNew(
        statusCode: json["statusCode"],
        statusMessage: json["statusMessage"] == null
            ? []
            : List<String>.from(json["statusMessage"]!.map((x) => x)),
        count: json["count"],
        payLoad: json["payLoad"] == null
            ? []
            : List<PrescriptionPayload>.from(
            (json["payLoad"] as List)
                .map((x) => PrescriptionPayload.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
    "statusCode": statusCode,
    "statusMessage": statusMessage == null
        ? []
        : List<dynamic>.from(statusMessage!.map((x) => x)),
    "count": count,
    "payLoad": payLoad == null
        ? []
        : List<dynamic>.from(payLoad!.map((x) => x.toJson())),
  };
}

class PrescriptionPayload {
  int? id;
  String? consultationDate;
  String? complaint;
  String? diagnosis;
  String? prescription;
  String? tests;
  String? remarks;
  String? doctorFirstName;
  String? doctorLastName;
  String? doctorImage;
  String? doctorFullName;
  String? consultationType;
  List<ConsultationDetail>? consultationdetails;

  PrescriptionPayload({
    this.id,
    this.consultationDate,
    this.complaint,
    this.diagnosis,
    this.prescription,
    this.tests,
    this.remarks,
    this.doctorFirstName,
    this.doctorLastName,
    this.doctorImage,
    this.doctorFullName,
    this.consultationType,
    this.consultationdetails,
  });

  factory PrescriptionPayload.fromJson(Map<String, dynamic> json) =>
      PrescriptionPayload(
        id: json["Id"],
        consultationDate: json["ConsultationDate"],
        complaint: json["Complaint"],
        diagnosis: json["Diagnosis"],
        prescription: json["Prescription"],
        tests: json["Tests"],
        remarks: json["Remarks"],
        doctorFirstName: json["DoctorFirstName"],
        doctorLastName: json["DoctorLastName"],
        doctorImage: json["DoctorImage"],
        doctorFullName: json["DoctorFullName"],
        consultationType: json["ConsultationType"],
        consultationdetails: json["Consultationdetails"] == null
            ? []
            : List<ConsultationDetail>.from((json["Consultationdetails"] as List)
            .map((x) => ConsultationDetail.fromJson(x))),
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
    "DoctorImage": doctorImage,
    "DoctorFullName": doctorFullName,
    "ConsultationType": consultationType,
    "Consultationdetails": consultationdetails == null
        ? []
        : List<dynamic>.from(consultationdetails!.map((x) => x.toJson())),
  };
}

class ConsultationDetail {
  int? id;
  int? consultationId;
  String? day;
  String? night;
  String? morning;
  String? days;
  String? status;
  String? additionalNotes;
  int? medicineNameId;
  dynamic quantity;
  String? medicineName;

  ConsultationDetail({
    this.id,
    this.consultationId,
    this.day,
    this.night,
    this.morning,
    this.days,
    this.status,
    this.additionalNotes,
    this.medicineNameId,
    this.quantity,
    this.medicineName,
  });

  factory ConsultationDetail.fromJson(Map<String, dynamic> json) =>
      ConsultationDetail(
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
  };
}