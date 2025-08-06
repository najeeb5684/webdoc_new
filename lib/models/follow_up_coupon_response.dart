class FollowUpCouponResponse {
  int statusCode;
  List<String> statusMessage;
  int count;
  FollowUpCouponPayload? payLoad;

  FollowUpCouponResponse({
    required this.statusCode,
    required this.statusMessage,
    required this.count,
    this.payLoad,
  });

  factory FollowUpCouponResponse.fromJson(Map<String, dynamic> json) {
    return FollowUpCouponResponse(
      statusCode: json['statusCode'] as int,
      statusMessage: List<String>.from(json['statusMessage']),
      count: json['count'] as int,
      payLoad: json['payLoad'] != null
          ? FollowUpCouponPayload.fromJson(json['payLoad'])
          : null,
    );
  }
}

class FollowUpCouponPayload {
  int id;
  String patientID;
  String doctorID;
  String couponCode;

  FollowUpCouponPayload({
    required this.id,
    required this.patientID,
    required this.doctorID,
    required this.couponCode,
  });

  factory FollowUpCouponPayload.fromJson(Map<String, dynamic> json) {
    return FollowUpCouponPayload(
      id: json['Id'] as int,
      patientID: json['PatientID'] as String,
      doctorID: json['DoctorID'] as String,
      couponCode: json['CouponCode'] as String,
    );
  }
}