import 'package:flutter/material.dart';

import '../models/class_group.dart';
import '../services/firebase_service.dart';
import '../student_dashboard.dart';

class JoinClassPage extends StatefulWidget {
  final String studentId;

  const JoinClassPage({
    super.key,
    required this.studentId,
  });

  @override
  State<JoinClassPage> createState() =>
      _JoinClassPageState();
}

class _JoinClassPageState
    extends State<JoinClassPage> {
  final FirebaseService _firebaseService =
      FirebaseService();

  final TextEditingController _codeController =
      TextEditingController();

  bool _isJoining = false;

  ClassGroup? _joinedClass;

  @override
  void initState() {
    super.initState();
    _loadCurrentClass();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD CURRENT CLASS
  // ============================================================

  Future<void> _loadCurrentClass() async {
    try {
      final classGroup =
          await _firebaseService.getClassForStudent(
        widget.studentId,
      );

      if (!mounted) return;

      // If the student is already enrolled,
      // send them directly to the normal student dashboard.
      if (classGroup != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const StudentDashboard(),
          ),
        );

        return;
      }

      setState(() {
        _joinedClass = null;
      });
    } catch (_) {
      // Having no class is completely okay.
    }
  }

  // ============================================================
  // JOIN CLASS
  // ============================================================

  Future<void> _joinClass() async {
    final code =
        _codeController.text.trim().toUpperCase();

    if (code.isEmpty) {
      _showMessage(
        'Please enter a class code.',
      );
      return;
    }

    if (_isJoining) {
      return;
    }

    setState(() {
      _isJoining = true;
    });

    try {
      // --------------------------------------------------------
      // FIND CLASS
      // --------------------------------------------------------

      final classGroup =
          await _firebaseService.getClassByCode(
        code,
      );

      if (classGroup == null) {
        throw Exception(
          'Class code not found.',
        );
      }

      // --------------------------------------------------------
      // JOIN CLASS
      // --------------------------------------------------------

      await _firebaseService.joinClass(
        studentId: widget.studentId,
        classCode: code,
      );

      if (!mounted) return;

      setState(() {
        _joinedClass = classGroup;
        _isJoining = false;
        _codeController.clear();
      });

      // --------------------------------------------------------
      // SUCCESS MESSAGE
      // --------------------------------------------------------

      _showMessage(
        'Successfully joined ${classGroup.name}.',
      );

      // Give the SnackBar a moment to appear before
      // transitioning to the student dashboard.
      await Future.delayed(
        const Duration(milliseconds: 500),
      );

      if (!mounted) return;

      // --------------------------------------------------------
      // CONTINUE TO STUDENT DASHBOARD
      // --------------------------------------------------------

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const StudentDashboard(),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isJoining = false;
      });

      _showMessage(
        e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
      );
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Class',
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),

        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(
              maxWidth: 700,
            ),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                // ==================================================
                // HEADER
                // ==================================================

                const Text(
                  'Join Class',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                Text(
                  'Enter the class code provided by your instructor.',
                  style: TextStyle(
                    color:
                        Colors.grey[500],
                  ),
                ),

                const SizedBox(
                  height: 28,
                ),

                // ==================================================
                // JOIN CARD
                // ==================================================

                _buildJoinCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // JOIN CARD
  // ============================================================

  Widget _buildJoinCard() {
    return Card(
      color: Colors.grey[900],

      child: Padding(
        padding:
            const EdgeInsets.all(24),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            // ----------------------------------------------------
            // TITLE
            // ----------------------------------------------------

            const Text(
              'Join a Class',
              style: TextStyle(
                fontSize: 21,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              'Enter the class code provided by your instructor.',
              style: TextStyle(
                color:
                    Colors.grey[500],
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            // ----------------------------------------------------
            // CLASS CODE
            // ----------------------------------------------------

            TextField(
              controller:
                  _codeController,

              enabled:
                  !_isJoining,

              textCapitalization:
                  TextCapitalization.characters,

              textInputAction:
                  TextInputAction.done,

              onSubmitted: (_) {
                if (!_isJoining) {
                  _joinClass();
                }
              },

              decoration:
                  const InputDecoration(
                labelText:
                    'Class Code',

                hintText:
                    'e.g. BIO101',

                prefixIcon:
                    Icon(
                  Icons.key,
                ),

                border:
                    OutlineInputBorder(),
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            // ----------------------------------------------------
            // JOIN BUTTON
            // ----------------------------------------------------

            SizedBox(
              width:
                  double.infinity,

              child:
                  ElevatedButton.icon(
                onPressed:
                    _isJoining
                        ? null
                        : _joinClass,

                icon: _isJoining
                    ? const SizedBox(
                        width: 18,
                        height: 18,

                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.group_add,
                      ),

                label:
                    Text(
                  _isJoining
                      ? 'Joining...'
                      : 'Join Class',
                ),
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            // ----------------------------------------------------
            // STUDENT ID
            // ----------------------------------------------------

            Center(
              child: Text(
                'Student ID: ${widget.studentId}',
                style: TextStyle(
                  color:
                      Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CURRENT CLASS
  //
  // This is kept as a fallback widget, although successful
  // enrollment now immediately sends the student to the
  // StudentDashboard.
  // ============================================================

  Widget _buildCurrentClass() {
    final classGroup =
        _joinedClass!;

    return Card(
      color:
          Colors.grey[900],

      child: Padding(
        padding:
            const EdgeInsets.all(24),

        child: Column(
          mainAxisSize:
              MainAxisSize.min,

          children: [
            Container(
              width: 70,
              height: 70,

              decoration:
                  BoxDecoration(
                color:
                    Colors.greenAccent
                        .withOpacity(
                  0.12,
                ),

                shape:
                    BoxShape.circle,
              ),

              child:
                  const Icon(
                Icons.check_circle,

                color:
                    Colors.greenAccent,

                size: 42,
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            const Text(
              'You are enrolled',

              style:
                  TextStyle(
                color:
                    Colors.greenAccent,

                fontSize: 20,

                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            Text(
              classGroup.name,

              textAlign:
                  TextAlign.center,

              style:
                  const TextStyle(
                fontSize: 26,

                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              'Instructor: ${classGroup.adminName}',

              textAlign:
                  TextAlign.center,

              style:
                  TextStyle(
                color:
                    Colors.grey[400],
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            Container(
              width:
                  double.infinity,

              padding:
                  const EdgeInsets.all(
                16,
              ),

              decoration:
                  BoxDecoration(
                color:
                    Colors.grey[850],

                borderRadius:
                    BorderRadius.circular(
                  10,
                ),
              ),

              child: Column(
                children: [
                  Text(
                    'Class Code',

                    style:
                        TextStyle(
                      color:
                          Colors.grey[500],

                      fontSize:
                          12,
                    ),
                  ),

                  const SizedBox(
                    height: 6,
                  ),

                  Text(
                    classGroup.classCode,

                    style:
                        const TextStyle(
                      fontSize: 24,

                      fontWeight:
                          FontWeight.bold,

                      letterSpacing: 3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}