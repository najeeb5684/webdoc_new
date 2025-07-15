class GetSlotsResponse {
  int? statusCode;
  List<String>? statusMessage;
  int? count;
  List<Slot>? payLoad;

  GetSlotsResponse({this.statusCode, this.statusMessage, this.count, this.payLoad});

  GetSlotsResponse.fromJson(Map<String, dynamic> json) {
    statusCode = json['statusCode'];
    statusMessage = json['statusMessage'] != null ? List<String>.from(json['statusMessage']) : null;
    count = json['count'];
    if (json['payLoad'] != null) {
      payLoad = <Slot>[];
      json['payLoad'].forEach((v) {
        payLoad!.add(Slot.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['statusCode'] = statusCode;
    data['statusMessage'] = statusMessage;
    data['count'] = count;
    if (payLoad != null) {
      data['payLoad'] = payLoad!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Slot {
  int? slotNo;
  String? time;

  Slot({this.slotNo, this.time});

  Slot.fromJson(Map<String, dynamic> json) {
    slotNo = json['slot_no'];
    time = json['time'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['slot_no'] = slotNo;
    data['time'] = time;
    return data;
  }
}