// lib/models/package_models.dart

// Model for a single package
class Package {
  final int id;
  final String name;
  final String? img; // Nullable
  final String price; // Stored as String as per API
  final String company;
  final String duration;

  Package({
    required this.id,
    required this.name,
    this.img,
    required this.price,
    required this.company,
    required this.duration,
  });

  factory Package.fromJson(Map<String, dynamic> json) {
    return Package(
      id: json['id'] as int,
      name: json['name'] as String,
      img: json['img'] as String?, // Handle null
      price: json['price'] as String, // Keep as String
      company: json['company'] as String,
      duration: json['duration'] as String,
    );
  }
}

// Model for the overall API response containing packages
class PackageResponse {
  final String responseCode;
  final String message;
  final List<Package> getPackageDetails; // List of Package objects

  PackageResponse({
    required this.responseCode,
    required this.message,
    required this.getPackageDetails,
  });

  factory PackageResponse.fromJson(Map<String, dynamic> json) {
    // Check if getPackageDetails is not null and is a List
    var list = json['getPackageDetails'];
    List<Package> packageList = [];
    if (list != null && list is List) {
      packageList = list.map((i) => Package.fromJson(i)).toList();
    }


    return PackageResponse(
      responseCode: json['responseCode'] as String,
      message: json['message'] as String,
      getPackageDetails: packageList,
    );
  }
}