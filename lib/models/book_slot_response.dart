class AppointmentDetails {
  final String? appointmentNo;
  final String? appointmentDate;
  final String? appointmentTime;

  AppointmentDetails({
    this.appointmentNo,
    this.appointmentDate,
    this.appointmentTime,
  });

  factory AppointmentDetails.fromJson(Map<String, dynamic> json) {
    return AppointmentDetails(
      appointmentNo: json['appointmentNo'],
      appointmentDate: json['appointmentDate'],
      appointmentTime: json['appointmentTime'],
    );
  }
}

class BookSlotResponse {
  final int? statusCode;
  final List<String>? statusMessage;
  final int? count;
  final AppointmentDetails? payLoad;

  BookSlotResponse({
    this.statusCode,
    this.statusMessage,
    this.count,
    this.payLoad,
  });

  factory BookSlotResponse.fromJson(Map<String, dynamic> json) {
    return BookSlotResponse(
      statusCode: json['statusCode'],
      statusMessage: json['statusMessage'] != null
          ? List<String>.from(json['statusMessage'])
          : null,
      count: json['count'],
      payLoad: json['payLoad'] != null
          ? AppointmentDetails.fromJson(json['payLoad'])
          : null,
    );
  }
}