class ClassGroup {
  final String id;
  final String name;
  final String classCode;
  final String adminId;
  final String adminName;

  ClassGroup({
    required this.id,
    required this.name,
    required this.classCode,
    required this.adminId,
    required this.adminName,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'classCode': classCode,
      'adminId': adminId,
      'adminName': adminName,
    };
  }

  factory ClassGroup.fromJson(
    Map<String, dynamic> json,
  ) {
    return ClassGroup(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      classCode: json['classCode'] ?? '',
      adminId: json['adminId'] ?? '',
      adminName: json['adminName'] ?? '',
    );
  }
}