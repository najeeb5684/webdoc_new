class SpecialistCategoryResponse {
  final int? statusCode;
  final List<String>? statusMessage;
  final int? count;
  final List<SpecialistCategory>? payLoad;

  SpecialistCategoryResponse({
    this.statusCode,
    this.statusMessage,
    this.count,
    this.payLoad,
  });

  factory SpecialistCategoryResponse.fromJson(Map<String, dynamic> json) {
    return SpecialistCategoryResponse(
      statusCode: json['statusCode'],
      statusMessage: json['statusMessage'] != null
          ? List<String>.from(json['statusMessage'])
          : null,
      count: json['count'],
      payLoad: (json['payLoad'] as List<dynamic>?)
          ?.map((e) => SpecialistCategory.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SpecialistCategory {
  final int? id;
  final String? description;
  final String? imageLink;
  final String? type;
  final String? status;

  SpecialistCategory({
    this.id,
    this.description,
    this.imageLink,
    this.type,
    this.status,
  });

  factory SpecialistCategory.fromJson(Map<String, dynamic> json) {
    return SpecialistCategory(
      id: json['Id'],
      description: json['Description'],
      imageLink: json['ImageLink'],
      type: json['Type'],
      status: json['Status'],
    );
  }
}