
class UserCheckResponse {
  String? responseCode;
  String? message;

  UserCheckResponse({this.responseCode, this.message});

  UserCheckResponse.fromJson(Map<String, dynamic> json) {
    responseCode = json['responseCode'];
    message = json['message'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['responseCode'] = responseCode;
    data['message'] = message;
    return data;
  }
}