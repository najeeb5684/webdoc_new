// cancel_appointment_response.dart
class CancelAppointmentResponse {
  int statusCode;
  List<String> statusMessage;
  int count;
  CancelAppointmentPayload? payLoad;

  CancelAppointmentResponse({
    required this.statusCode,
    required this.statusMessage,
    required this.count,
    this.payLoad,
  });

  factory CancelAppointmentResponse.fromJson(Map<String, dynamic> json) {
    return CancelAppointmentResponse(
      statusCode: json['statusCode'] as int,
      statusMessage: List<String>.from(json['statusMessage'] as List),
      count: json['count'] as int,
      payLoad: json['payLoad'] == null ? null : CancelAppointmentPayload.fromJson(json['payLoad'] as Map<String, dynamic>),
    );
  }
}

class CancelAppointmentPayload {
  String refundAmount;
  String appointmentId;

  CancelAppointmentPayload({
    required this.refundAmount,
    required this.appointmentId,
  });

  factory CancelAppointmentPayload.fromJson(Map<String, dynamic> json) {
    return CancelAppointmentPayload(
      refundAmount: json['refundAmount'] as String,
      appointmentId: json['appointmentId'] as String,
    );
  }
}