class User {
  final String id;
  final String name;
  final String role;

  final String? studentId;
  final String? email;

  // Class / administrator assignment
  final String? adminId;
  final String? adminName;
  final String? classId;
  final String? classCode;
  final String? className;

  User({
    required this.id,
    required this.name,
    required this.role,
    this.studentId,
    this.email,
    this.adminId,
    this.adminName,
    this.classId,
    this.classCode,
    this.className,
  });

  bool get isAdmin =>
      role == "admin";

  bool get isStudent =>
      role == "student";

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "role": role,
      "studentId": studentId,
      "email": email,
      "adminId": adminId,
      "adminName": adminName,
      "classId": classId,
      "classCode": classCode,
      "className": className,
    };
  }

  factory User.fromJson(
    Map<String, dynamic> json,
  ) {
    return User(
      id: json["id"],
      name: json["name"],
      role: json["role"],
      studentId: json["studentId"],
      email: json["email"],
      adminId: json["adminId"],
      adminName: json["adminName"],
      classId: json["classId"],
      classCode: json["classCode"],
      className: json["className"],
    );
  }
}