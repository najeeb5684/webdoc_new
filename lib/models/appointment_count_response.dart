
class AppointmentCountResponse {
  final int statusCode;
  final List<String> statusMessage;
  final int count;
  final Payload? payLoad;

  AppointmentCountResponse({
    required this.statusCode,
    required this.statusMessage,
    required this.count,
    this.payLoad,
  });

  factory AppointmentCountResponse.fromJson(Map<String, dynamic> json) {
    return AppointmentCountResponse(
      statusCode: json['statusCode'],
      statusMessage: List<String>.from(json['statusMessage']),
      count: json['count'],
      payLoad: json['payLoad'] != null ? Payload.fromJson(json['payLoad']) : null,
    );
  }
}

class Payload {
  final int upcomingAppointmentCount;

  Payload({required this.upcomingAppointmentCount});

  factory Payload.fromJson(Map<String, dynamic> json) {
    return Payload(upcomingAppointmentCount: json['upcomingAppointmentCount']);
  }
}