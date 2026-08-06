class User {

  final String id;
  final String name;
  final String role;

  final String? studentId;
  final String? email;


  User({
    required this.id,
    required this.name,
    required this.role,
    this.studentId,
    this.email,
  });


  bool get isAdmin =>
      role == "admin";


  bool get isStudent =>
      role == "student";


  Map<String,dynamic> toJson(){

    return {

      "id": id,
      "name": name,
      "role": role,
      "studentId": studentId,
      "email": email,

    };

  }


  factory User.fromJson(
      Map<String,dynamic> json){

    return User(

      id: json["id"],

      name: json["name"],

      role: json["role"],

      studentId: json["studentId"],

      email: json["email"],

    );

  }

}