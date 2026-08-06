import '../models/user.dart';


class UserStorage {


static final List<User> users = [

  User(
    id: "admin001",
    name: "Admin",
    role: "admin",
  ),


];


static void addUser(User user){

  users.add(user);

}


static User? login(
    String name,
    String role,
){

  for(User user in users){

    if(
      user.name == name &&
      user.role == role
    ){

      return user;

    }

  }


  return null;

}


static List<User> getStudents(){

 return users
     .where(
       (u)=>u.isStudent
     )
     .toList();

}


}