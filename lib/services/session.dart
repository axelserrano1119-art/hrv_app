import '../models/user.dart';


class Session {

  static User? currentUser;


  static bool get loggedIn =>
      currentUser != null;


  static bool get isAdmin =>
      currentUser?.isAdmin ?? false;


  static bool get isStudent =>
      currentUser?.isStudent ?? false;

}