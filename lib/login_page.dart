import 'package:flutter/material.dart';
import 'instructions_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  
  // Student Form Controllers
  final _studentIdController = TextEditingController();
  final _studentEmailController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _studentPasswordController = TextEditingController();

  // Admin Form Controllers
  final _adminUsernameController = TextEditingController();
  final _adminPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

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

  void _navigateToInstructions() {
    // Navigate to instructions and remove login page from the backstack
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const InstructionsPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("HRV App Portal"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.school), text: "Student"),
            Tab(icon: Icon(Icons.admin_panel_settings), text: "Admin"),
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

  Widget _buildStudentForm() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: ListView(
        children: [
          const Text("Student Registration / Sign In", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(controller: _firstNameController, decoration: const InputDecoration(labelText: "First Name", border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _lastNameController, decoration: const InputDecoration(labelText: "Last Name", border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _studentIdController, decoration: const InputDecoration(labelText: "Student ID", border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _studentEmailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: "Student Email", border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _studentPasswordController, obscureText: true, decoration: const InputDecoration(labelText: "Password", border: OutlineInputBorder())),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _navigateToInstructions,
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: Colors.blue),
            child: const Text("Proceed to Instructions", style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminForm() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text("Admin Portal Login", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(controller: _adminUsernameController, decoration: const InputDecoration(labelText: "Specialized Username", border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _adminPasswordController, obscureText: true, decoration: const InputDecoration(labelText: "Admin Password", border: OutlineInputBorder())),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _navigateToInstructions,
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: Colors.purple),
            child: const Text("Admin Sign In", style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}