class FeedbackResponse {
  final int statusCode;
  final List<String> statusMessage;
  final int count;
  final FeedbackPayload? payLoad; // Make payLoad nullable

  FeedbackResponse({
    required this.statusCode,
    required this.statusMessage,
    required this.count,
    this.payLoad, // No longer required
  });

  factory FeedbackResponse.fromJson(Map<String, dynamic> json) {
    return FeedbackResponse(
      statusCode: json['statusCode'] as int,
      statusMessage: (json['statusMessage'] as List<dynamic>).map((e) => e as String).toList(),
      count: json['count'] as int,
      payLoad: json['payLoad'] != null
          ? FeedbackPayload.fromJson(json['payLoad'] as Map<String, dynamic>)
          : null, // Handle null payload
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'statusCode': statusCode,
      'statusMessage': statusMessage,
      'count': count,
      'payLoad': payLoad?.toJson(), // Use the null-aware operator
    };
  }
}

class FeedbackPayload {
  final String? doctorId; // Make fields nullable
  final String? patientId;
  final String? ratingPoints;
  final String? feedbackText;

  FeedbackPayload({
    this.doctorId, // No longer required
    this.patientId,
    this.ratingPoints,
    this.feedbackText,
  });

  factory FeedbackPayload.fromJson(Map<String, dynamic> json) {
    return FeedbackPayload(
      doctorId: json['DoctorId'] as String?, // Cast to nullable String?
      patientId: json['PatientId'] as String?,
      ratingPoints: json['RatingPoints'] as String?,
      feedbackText: json['FeedbackText'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'DoctorId': doctorId,
      'PatientId': patientId,
      'RatingPoints': ratingPoints,
      'FeedbackText': feedbackText,
    };
  }
}