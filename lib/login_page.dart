import 'package:flutter/material.dart';

import 'models/user.dart';
import 'services/session.dart';
import 'services/firebase_service.dart';

import 'student_dashboard.dart';
import 'screens/admin_dashboard_screen.dart';
import 'pages/join_class_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() =>
      _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;

  // ==========================================
  // STUDENT FORM
  // ==========================================

  final _studentIdController =
      TextEditingController();

  final _studentEmailController =
      TextEditingController();

  final _firstNameController =
      TextEditingController();

  final _lastNameController =
      TextEditingController();

  final _studentPasswordController =
      TextEditingController();

  // ==========================================
  // ADMIN FORM
  // ==========================================

  final _adminUsernameController =
      TextEditingController();

  final _adminPasswordController =
      TextEditingController();

  bool _isLoading = false;

  final FirebaseService _firebaseService =
      FirebaseService();

  // ==========================================
  // INIT
  // ==========================================

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: 2,
      vsync: this,
    );
  }

  // ==========================================
  // DISPOSE
  // ==========================================

  @override
  void dispose() {
    _tabController?.dispose();

    _studentIdController.dispose();
    _studentEmailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _studentPasswordController.dispose();

    _adminUsernameController.dispose();
    _adminPasswordController.dispose();

    super.dispose();
  }

  // ==========================================
  // STUDENT LOGIN
  // ==========================================

  Future<void> _studentLogin() async {
    final studentId =
        _studentIdController.text.trim();

    final firstName =
        _firstNameController.text.trim();

    final lastName =
        _lastNameController.text.trim();

    final email =
        _studentEmailController.text.trim();

    if (studentId.isEmpty ||
        firstName.isEmpty ||
        lastName.isEmpty) {
      _showMessage(
        'Please enter your name and Student ID.',
      );

      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // ==========================================
      // CREATE STUDENT USER
      // ==========================================

      final user = User(
        id: studentId,
        name: '$firstName $lastName',
        role: 'student',
        studentId: studentId,
        email: email,
      );

      // ==========================================
      // SAVE STUDENT TO FIREBASE
      // ==========================================

      await _firebaseService.saveStudent(user);

      // ==========================================
      // SET CURRENT SESSION
      // ==========================================

      Session.currentUser = user;

      // ==========================================
      // CHECK FOR EXISTING CLASS
      // ==========================================

      final classGroup =
          await _firebaseService.getClassForStudent(
        studentId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      // ==========================================
      // STUDENT DOES NOT HAVE A CLASS
      // ==========================================

      if (classGroup == null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => JoinClassPage(
              studentId: studentId,
            ),
          ),
        );

        return;
      }

      // ==========================================
      // STUDENT ALREADY HAS A CLASS
      // ==========================================

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const StudentDashboard(),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      _showMessage(
        'Unable to connect to Firebase.\n$e',
      );
    }
  }

  // ==========================================
  // ADMIN LOGIN
  // ==========================================

  Future<void> _adminLogin() async {
    final username =
        _adminUsernameController.text.trim();

    if (username.isEmpty) {
      _showMessage(
        'Please enter your admin username.',
      );

      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // ==========================================
      // ADMIN ID
      // ==========================================

      final adminId = username;

      final user = User(
        id: adminId,
        name: username,
        role: 'admin',
        email: null,
      );

      // ==========================================
      // SAVE ADMIN TO FIREBASE
      // ==========================================

      await _firebaseService.saveAdmin(
        adminId: adminId,
        adminName: username,
      );

      // ==========================================
      // SET SESSION
      // ==========================================

      Session.currentUser = user;

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      // ==========================================
      // OPEN ADMIN DASHBOARD
      // ==========================================

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const AdminDashboardScreen(),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      _showMessage(
        'Unable to connect to Firebase.\n$e',
      );
    }
  }

  // ==========================================
  // MESSAGE
  // ==========================================

  void _showMessage(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // ==========================================
  // BUILD
  // ==========================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'HRV App Portal',
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(
                Icons.school,
              ),
              text: 'Student',
            ),
            Tab(
              icon: Icon(
                Icons.admin_panel_settings,
              ),
              text: 'Admin',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStudentForm(),
          _buildAdminForm(),
        ],
      ),
    );
  }

  // ==========================================
  // STUDENT FORM
  // ==========================================

  Widget _buildStudentForm() {
    return Padding(
      padding:
          const EdgeInsets.all(24.0),
      child: ListView(
        children: [
          const Text(
            'Student Registration / Sign In',
            style: TextStyle(
              fontSize: 20,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          TextField(
            controller:
                _firstNameController,
            decoration:
                const InputDecoration(
              labelText: 'First Name',
              border:
                  OutlineInputBorder(),
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          TextField(
            controller:
                _lastNameController,
            decoration:
                const InputDecoration(
              labelText: 'Last Name',
              border:
                  OutlineInputBorder(),
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          TextField(
            controller:
                _studentIdController,
            decoration:
                const InputDecoration(
              labelText: 'Student ID',
              border:
                  OutlineInputBorder(),
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          TextField(
            controller:
                _studentEmailController,
            keyboardType:
                TextInputType.emailAddress,
            decoration:
                const InputDecoration(
              labelText: 'Student Email',
              border:
                  OutlineInputBorder(),
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          TextField(
            controller:
                _studentPasswordController,
            obscureText: true,
            decoration:
                const InputDecoration(
              labelText: 'Password',
              border:
                  OutlineInputBorder(),
            ),
          ),

          const SizedBox(
            height: 24,
          ),

          ElevatedButton(
            onPressed:
                _isLoading
                    ? null
                    : _studentLogin,
            style:
                ElevatedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(
                vertical: 16,
              ),
              backgroundColor:
                  Colors.blue,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Continue',
                    style:
                        TextStyle(
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ADMIN FORM
  // ==========================================

  Widget _buildAdminForm() {
    return Padding(
      padding:
          const EdgeInsets.all(24.0),
      child: ListView(
        children: [
          const Text(
            'Admin Portal Login',
            style: TextStyle(
              fontSize: 20,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          TextField(
            controller:
                _adminUsernameController,
            decoration:
                const InputDecoration(
              labelText:
                  'Specialized Username',
              border:
                  OutlineInputBorder(),
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          TextField(
            controller:
                _adminPasswordController,
            obscureText: true,
            decoration:
                const InputDecoration(
              labelText:
                  'Admin Password',
              border:
                  OutlineInputBorder(),
            ),
          ),

          const SizedBox(
            height: 24,
          ),

          ElevatedButton(
            onPressed:
                _isLoading
                    ? null
                    : _adminLogin,
            style:
                ElevatedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(
                vertical: 16,
              ),
              backgroundColor:
                  Colors.purple,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Admin Sign In',
                    style:
                        TextStyle(
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}