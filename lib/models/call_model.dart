class CallModel {
  String? appointmentID;
  String? callType;
  String? callingPlatform;
  String? isCalling;
  String? senderEmail;

  CallModel({
    this.appointmentID,
    this.callType,
    this.callingPlatform,
    this.isCalling,
    this.senderEmail,
  });

  CallModel.fromJson(Map<String, dynamic> json) {
    appointmentID = json['AppointmentID'];
    callType = json['CallType'];
    callingPlatform = json['CallingPlatform'];
    isCalling = json['IsCalling'];
    senderEmail = json['SenderEmail'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['AppointmentID'] = appointmentID;
    data['CallType'] = callType;
    data['CallingPlatform'] = callingPlatform;
    data['IsCalling'] = isCalling;
    data['SenderEmail'] = senderEmail;
    return data;
  }
}