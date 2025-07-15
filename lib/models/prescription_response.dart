class PrescriptionResponse {
  String? responseCode;
  String? message;
  List<Consultation>? consultationList;
  int? totalRecords;
  int? currentPage;
  int? pageSize;

  PrescriptionResponse({
    this.responseCode,
    this.message,
    this.consultationList,
    this.totalRecords,
    this.currentPage,
    this.pageSize,
  });

  PrescriptionResponse.fromJson(Map<String, dynamic> json) {
    responseCode = json['responseCode'];
    message = json['message'];
    if (json['consultationList'] != null) {
      consultationList = <Consultation>[];
      json['consultationList'].forEach((v) {
        consultationList!.add(Consultation.fromJson(v));
      });
    }
    totalRecords = json['totalRecords'];
    currentPage = json['currentPage'];
    pageSize = json['pageSize'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['responseCode'] = responseCode;
    data['message'] = message;
    if (consultationList != null) {
      data['consultationList'] =
          consultationList!.map((v) => v.toJson()).toList();
    }
    data['totalRecords'] = totalRecords;
    data['currentPage'] = currentPage;
    data['pageSize'] = pageSize;
    return data;
  }
}

class Consultation {
  String? compliant;
  String? consultationDate;
  String? consultationType;
  List<Consultationdetail>? consultationdetails;
  String? diagnosis;
  String? doctorName;
  String? prescription;
  String? remarks;
  String? tests;
  String? id;

  Consultation({
    this.compliant,
    this.consultationDate,
    this.consultationType,
    this.consultationdetails,
    this.diagnosis,
    this.doctorName,
    this.prescription,
    this.remarks,
    this.tests,
    this.id,
  });

  Consultation.fromJson(Map<String, dynamic> json) {
    compliant = json['compliant'];
    consultationDate = json['consultationDate'];
    consultationType = json['consultationType'];
    if (json['consultationdetails'] != null) {
      consultationdetails = <Consultationdetail>[];
      json['consultationdetails'].forEach((v) {
        consultationdetails!.add(Consultationdetail.fromJson(v));
      });
    }
    diagnosis = json['diagnosis'];
    doctorName = json['doctorName'];
    prescription = json['prescription'];
    remarks = json['remarks'];
    tests = json['tests'];
    id = json['id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['compliant'] = compliant;
    data['consultationDate'] = consultationDate;
    data['consultationType'] = consultationType;
    if (consultationdetails != null) {
      data['consultationdetails'] =
          consultationdetails!.map((v) => v.toJson()).toList();
    }
    data['diagnosis'] = diagnosis;
    data['doctorName'] = doctorName;
    data['prescription'] = prescription;
    data['remarks'] = remarks;
    data['tests'] = tests;
    data['id'] = id;
    return data;
  }
}

class Consultationdetail {
  String? additionalNotes;
  String? day;
  String? id;
  String? medicineName;
  String? morning;
  String? night;
  String? noOfDays;

  Consultationdetail({
    this.additionalNotes,
    this.day,
    this.id,
    this.medicineName,
    this.morning,
    this.night,
    this.noOfDays,
  });

  Consultationdetail.fromJson(Map<String, dynamic> json) {
    additionalNotes = json['additionalNotes'];
    day = json['day'];
    id = json['id'];
    medicineName = json['medicineName'];
    morning = json['morning'];
    night = json['night'];
    noOfDays = json['noOfDays'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['additionalNotes'] = additionalNotes;
    data['day'] = day;
    data['id'] = id;
    data['medicineName'] = medicineName;
    data['morning'] = morning;
    data['night'] = night;
    data['noOfDays'] = noOfDays;
    return data;
  }
}