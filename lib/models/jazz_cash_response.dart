// lib/models/jazzcash_response.dart

class JazzCashResponse {
  String? ppAmount;
  String? ppAuthCode;
  String? ppBillReference;
  String? ppLanguage;
  String? ppMerchantID;
  String? ppResponseCode;
  String? ppResponseMessage;
  String? ppRetreivalReferenceNo;
  String? ppSubMerchantID;
  String? ppTxnCurrency;
  String? ppTxnDateTime;
  String? ppTxnRefNo;
  String? ppMobileNumber;
  String? ppCNIC;
  String? ppDiscountedAmount;
  String? ppmpf1;
  String? ppmpf2;
  String? ppmpf3;
  String? ppmpf4;
  String? ppmpf5;
  String? ppSecureHash;

  JazzCashResponse({
    this.ppAmount,
    this.ppAuthCode,
    this.ppBillReference,
    this.ppLanguage,
    this.ppMerchantID,
    this.ppResponseCode,
    this.ppResponseMessage,
    this.ppRetreivalReferenceNo,
    this.ppSubMerchantID,
    this.ppTxnCurrency,
    this.ppTxnDateTime,
    this.ppTxnRefNo,
    this.ppMobileNumber,
    this.ppCNIC,
    this.ppDiscountedAmount,
    this.ppmpf1,
    this.ppmpf2,
    this.ppmpf3,
    this.ppmpf4,
    this.ppmpf5,
    this.ppSecureHash,
  });

  factory JazzCashResponse.fromJson(Map<String, dynamic> json) {
    return JazzCashResponse(
      ppAmount: json['pp_Amount'],
      ppAuthCode: json['pp_AuthCode'],
      ppBillReference: json['pp_BillReference'],
      ppLanguage: json['pp_Language'],
      ppMerchantID: json['pp_MerchantID'],
      ppResponseCode: json['pp_ResponseCode'],
      ppResponseMessage: json['pp_ResponseMessage'],
      ppRetreivalReferenceNo: json['pp_RetreivalReferenceNo'],
      ppSubMerchantID: json['pp_SubMerchantID'],
      ppTxnCurrency: json['pp_TxnCurrency'],
      ppTxnDateTime: json['pp_TxnDateTime'],
      ppTxnRefNo: json['pp_TxnRefNo'],
      ppMobileNumber: json['pp_MobileNumber'],
      ppCNIC: json['pp_CNIC'],
      ppDiscountedAmount: json['pp_DiscountedAmount'],
      ppmpf1: json['ppmpf_1'],
      ppmpf2: json['ppmpf_2'],
      ppmpf3: json['ppmpf_3'],
      ppmpf4: json['ppmpf_4'],
      ppmpf5: json['ppmpf_5'],
      ppSecureHash: json['pp_SecureHash'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pp_Amount': ppAmount,
      'pp_AuthCode': ppAuthCode,
      'pp_BillReference': ppBillReference,
      'pp_Language': ppLanguage,
      'pp_MerchantID': ppMerchantID,
      'pp_ResponseCode': ppResponseCode,
      'pp_ResponseMessage': ppResponseMessage,
      'pp_RetreivalReferenceNo': ppRetreivalReferenceNo,
      'pp_SubMerchantID': ppSubMerchantID,
      'pp_TxnCurrency': ppTxnCurrency,
      'pp_TxnDateTime': ppTxnDateTime,
      'pp_TxnRefNo': ppTxnRefNo,
      'pp_MobileNumber': ppMobileNumber,
      'pp_CNIC': ppCNIC,
      'pp_DiscountedAmount': ppDiscountedAmount,
      'ppmpf_1': ppmpf1,
      'ppmpf_2': ppmpf2,
      'ppmpf_3': ppmpf3,
      'ppmpf_4': ppmpf4,
      'ppmpf_5': ppmpf5,
      'pp_SecureHash': ppSecureHash,
    };
  }
}