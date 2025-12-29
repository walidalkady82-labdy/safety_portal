class ModelUserData {
  final String key;
  final String nameEn;
  final String nameAr;
  final String department;
  final String photoUrl;

  ModelUserData({
    required this.key,
    required this.nameEn,
    required this.nameAr,
    required this.department,
    required this.photoUrl
  });

  factory ModelUserData.fromMap(String key, Map<dynamic, dynamic> data) {
    return ModelUserData(
      key: key,
      nameEn: (data['nameEn'] ?? data['name'] ?? "").toString(),
      nameAr: (data['nameAr'] ?? "").toString(),
      department: (data['department'] ?? "").toString(),
      photoUrl: (data['photo'] ?? data['image'] ?? "").toString(),
    );
  }
}
