

class UserCheckResponseNew {
  int? statusCode;
  List<String>? statusMessage;
  int? count;
  Payload? payLoad;

  UserCheckResponseNew({
    this.statusCode,
    this.statusMessage,
    this.count,
    this.payLoad,
  });

  factory UserCheckResponseNew.fromJson(Map<String, dynamic> json) {
    return UserCheckResponseNew(
      statusCode: json['statusCode'],
      statusMessage: json['statusMessage'] != null
          ? List<String>.from(json['statusMessage'])
          : null,
      count: json['count'],
      payLoad: json['payLoad'] != null ? Payload.fromJson(json['payLoad']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'statusCode': statusCode,
      'statusMessage': statusMessage,
      'count': count,
      'payLoad': payLoad?.toJson(),
    };
  }
}

class Payload {
  bool? user;

  Payload({this.user});

  factory Payload.fromJson(Map<String, dynamic> json) {
    return Payload(
      user: json['user'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user,
    };
  }
}
