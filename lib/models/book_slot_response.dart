class AppointmentDetails {
  final int? appointmentId;
  final String? appointmentNo;
  final String? appointmentDate;
  final String? appointmentTime;
  final String? paymentMethod;
  final String? financeStatus;
  final int? walletAmountUsed;
  final int? remainingAmount;

  AppointmentDetails({
    this.appointmentId,
    this.appointmentNo,
    this.appointmentDate,
    this.appointmentTime,
    this.paymentMethod,
    this.financeStatus,
    this.walletAmountUsed,
    this.remainingAmount,
  });

  factory AppointmentDetails.fromJson(Map<String, dynamic> json) {
    return AppointmentDetails(
      appointmentId: json['appointmentId'] as int?,
      appointmentNo: json['appointmentNo'] as String?,
      appointmentDate: json['appointmentDate'] as String?,
      appointmentTime: json['appointmentTime'] as String?,
      paymentMethod: json['paymentMethod'] as String?,
      financeStatus: json['financeStatus'] as String?,
      walletAmountUsed: json['walletAmountUsed'] as int?,
      remainingAmount: json['remainingAmount'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'appointmentId': appointmentId,
      'appointmentNo': appointmentNo,
      'appointmentDate': appointmentDate,
      'appointmentTime': appointmentTime,
      'paymentMethod': paymentMethod,
      'financeStatus': financeStatus,
      'walletAmountUsed': walletAmountUsed,
      'remainingAmount': remainingAmount,
    };
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
      statusCode: json['statusCode'] as int?,
      statusMessage: (json['statusMessage'] as List<dynamic>?)?.map((e) => e as String).toList(),
      count: json['count'] as int?,
      payLoad: json['payLoad'] == null ? null : AppointmentDetails.fromJson(json['payLoad'] as Map<String, dynamic>),
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


/*
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
}*/
