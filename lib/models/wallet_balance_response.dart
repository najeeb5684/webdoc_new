class WalletBalanceResponse {
  final int statusCode;
  final List<String> statusMessage;
  final int count;
  final WalletBalancePayload payLoad;

  WalletBalanceResponse({
    required this.statusCode,
    required this.statusMessage,
    required this.count,
    required this.payLoad,
  });

  factory WalletBalanceResponse.fromJson(Map<String, dynamic> json) {
    return WalletBalanceResponse(
      statusCode: json['statusCode'] as int,
      statusMessage: List<String>.from(json['statusMessage'] as List),
      count: json['count'] as int,
      payLoad: WalletBalancePayload.fromJson(json['payLoad'] as Map<String, dynamic>),
    );
  }
}

class WalletBalancePayload {
  final String balance;

  WalletBalancePayload({
    required this.balance,
  });

  factory WalletBalancePayload.fromJson(Map<String, dynamic> json) {
    return WalletBalancePayload(
      balance: json['balance'] as String,
    );
  }
}