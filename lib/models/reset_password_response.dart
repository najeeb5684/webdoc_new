class ChangePasswordResponse {
  int? statusCode;
  List<String>? statusMessage;
  int? count;
  dynamic payLoad; // Use dynamic because the payload is null in the example

  ChangePasswordResponse({
    this.statusCode,
    this.statusMessage,
    this.count,
    this.payLoad,
  });

  factory ChangePasswordResponse.fromJson(Map<String, dynamic> json) {
    return ChangePasswordResponse(
      statusCode: json['statusCode'],
      statusMessage: json['statusMessage'] != null ? List<String>.from(json['statusMessage']) : null,
      count: json['count'],
      payLoad: json['payLoad'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'statusCode': statusCode,
      'statusMessage': statusMessage,
      'count': count,
      'payLoad': payLoad,
    };
  }
}