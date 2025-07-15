class EasyPaisaResponse {
  final String? statusCode;
  final List<String>? statusMessage;
  final int? count;
  final EasyPaisaPayload? payLoad;

  EasyPaisaResponse({
    this.statusCode,
    this.statusMessage,
    this.count,
    this.payLoad,
  });

  factory EasyPaisaResponse.fromJson(Map<String, dynamic> json) {
    return EasyPaisaResponse(
      statusCode: json['statusCode']?.toString(), // convert to String safely
      statusMessage: (json['statusMessage'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(), // safely convert all list elements to String
      count: json['count'] is int
          ? json['count']
          : int.tryParse(json['count']?.toString() ?? ''), // safe int conversion
      payLoad: json['payLoad'] != null && json['payLoad'] is Map<String, dynamic>
          ? EasyPaisaPayload.fromJson(json['payLoad'])
          : null,
    );
  }
}

class EasyPaisaPayload {
  final String? orderId;
  final String? storeId;
  final String? transactionId;
  final String? transactionDateTime;
  final String? responseCode;
  final String? responseDesc;

  EasyPaisaPayload({
    this.orderId,
    this.storeId,
    this.transactionId,
    this.transactionDateTime,
    this.responseCode,
    this.responseDesc,
  });

  factory EasyPaisaPayload.fromJson(Map<String, dynamic> json) {
    return EasyPaisaPayload(
      orderId: json['orderId']?.toString(),
      storeId: json['storeId']?.toString(),
      transactionId: json['transactionId']?.toString(),
      transactionDateTime: json['transactionDateTime']?.toString(),
      responseCode: json['responseCode']?.toString(),
      responseDesc: json['responseDesc']?.toString(),
    );
  }
}
