class WalletHistoryResponse {
  final int statusCode;
  final List<String> statusMessage;
  final int count;
  final WalletPayload payLoad;

  WalletHistoryResponse({
    required this.statusCode,
    required this.statusMessage,
    required this.count,
    required this.payLoad,
  });

  factory WalletHistoryResponse.fromJson(Map<String, dynamic> json) {
    return WalletHistoryResponse(
      statusCode: json['statusCode'] as int,
      statusMessage: List<String>.from(json['statusMessage'] as List),
      count: json['count'] as int,
      payLoad: WalletPayload.fromJson(json['payLoad'] as Map<String, dynamic>),
    );
  }
}

class WalletPayload {
  final String balance;
  final List<Transaction> transactions;

  WalletPayload({
    required this.balance,
    required this.transactions,
  });

  factory WalletPayload.fromJson(Map<String, dynamic> json) {
    return WalletPayload(
      balance: json['balance'] as String,
      transactions: (json['transactions'] as List)
          .map((i) => Transaction.fromJson(i as Map<String, dynamic>))
          .toList(),
    );
  }
}

class Transaction {
  final int Id;
  final int AppointmentId;
  final String Balance;
  final String Type;
  final String BankType;
  final dynamic TransectionRecordId;
  final String AppointmentDate;
  final String AppointmentTime;
  final String DoctorName;

  Transaction({
    required this.Id,
    required this.AppointmentId,
    required this.Balance,
    required this.Type,
    required this.BankType,
    required this.TransectionRecordId,
    required this.AppointmentDate,
    required this.AppointmentTime,
    required this.DoctorName,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      Id: json['Id'] as int,
      AppointmentId: json['AppointmentId'] as int,
      Balance: json['Balance'] as String,
      Type: json['Type'] as String,
      BankType: json['BankType'] as String,
      TransectionRecordId: json['TransectionRecordId'],
      AppointmentDate: json['AppointmentDate'] as String,
      AppointmentTime: json['AppointmentTime'] as String,
      DoctorName: json['DoctorName'] as String,
    );
  }
}