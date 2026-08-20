import 'package:flutter/material.dart';

import '../models/class_group.dart';
import '../models/user.dart';
import '../services/firebase_service.dart';

class AdminClassesPage extends StatefulWidget {
  final String adminId;
  final String adminName;

  const AdminClassesPage({
    super.key,
    required this.adminId,
    required this.adminName,
  });

  @override
  State<AdminClassesPage> createState() =>
      _AdminClassesPageState();
}

class _AdminClassesPageState
    extends State<AdminClassesPage> {
  final FirebaseService _firebaseService =
      FirebaseService();

  final TextEditingController _classNameController =
      TextEditingController();

  final TextEditingController _classCodeController =
      TextEditingController();

  List<ClassGroup> _classes = [];

  final Map<String, int> _studentCounts = {};

  bool _isLoading = true;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  @override
  void dispose() {
    _classNameController.dispose();
    _classCodeController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD CLASSES
  // ============================================================

  Future<void> _loadClasses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final classes =
          await _firebaseService.getClassesForAdmin(
        widget.adminId,
      );

      final counts = <String, int>{};

      for (final classGroup in classes) {
        final students =
            await _firebaseService.getStudentsForClass(
          classGroup.id,
        );

        counts[classGroup.id] =
            students.length;
      }

      if (!mounted) return;

      setState(() {
        _classes = classes;
        _studentCounts.clear();
        _studentCounts.addAll(counts);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showMessage(
        'Unable to load classes: $e',
      );
    }
  }

  // ============================================================
  // CREATE CLASS
  // ============================================================

  Future<void> _createClass() async {
    final className =
        _classNameController.text.trim();

    final classCode =
        _classCodeController.text
            .trim()
            .toUpperCase();

    if (className.isEmpty) {
      _showMessage(
        'Please enter a class name.',
      );
      return;
    }

    if (classCode.isEmpty) {
      _showMessage(
        'Please enter a class code.',
      );
      return;
    }

    if (classCode.length < 4) {
      _showMessage(
        'Class code must contain at least 4 characters.',
      );
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      await _firebaseService.createClass(
        adminId: widget.adminId,
        adminName: widget.adminName,
        className: className,
        classCode: classCode,
      );

      if (!mounted) return;

      Navigator.pop(context);

      _showMessage(
        'Class "$className" created successfully.',
      );

      _loadClasses();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isCreating = false;
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
  // CREATE CLASS DIALOG
  // ============================================================

  void _showCreateClassDialog() {
    _classNameController.clear();
    _classCodeController.clear();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            return AlertDialog(
              title: const Text(
                'Create Class',
              ),
              content: SizedBox(
                width: 450,
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    TextField(
                      controller:
                          _classNameController,
                      textCapitalization:
                          TextCapitalization.words,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Class Name',
                        hintText:
                            'e.g. Biochemistry 101',
                        border:
                            OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    TextField(
                      controller:
                          _classCodeController,
                      textCapitalization:
                          TextCapitalization.characters,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Class Code',
                        hintText:
                            'e.g. BIO101',
                        border:
                            OutlineInputBorder(),
                        helperText:
                            'Students will use this code to join.',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _isCreating
                      ? null
                      : () {
                          Navigator.pop(
                            dialogContext,
                          );
                        },
                  child:
                      const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  onPressed: _isCreating
                      ? null
                      : () async {
                          setDialogState(() {});

                          await _createClass();
                        },
                  icon: _isCreating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.add,
                        ),
                  label: const Text(
                    'Create Class',
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // VIEW CLASS STUDENTS
  // ============================================================

  Future<void> _showStudents(
    ClassGroup classGroup,
  ) async {
    showDialog(
      context: context,
      builder: (context) {
        return _ClassStudentsDialog(
          firebaseService:
              _firebaseService,
          classGroup: classGroup,
        );
      },
    );
  }

  // ============================================================
  // COPY CLASS CODE
  // ============================================================

  void _copyClassCode(
    ClassGroup classGroup,
  ) {
    // Clipboard support can be added later.
    // For now, show the code clearly.
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Class Join Code',
          ),
          content: SelectableText(
            classGroup.classCode,
            textAlign:
                TextAlign.center,
            style: const TextStyle(
              fontSize: 32,
              fontWeight:
                  FontWeight.bold,
              letterSpacing: 3,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child:
                  const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
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
        title:
            const Text('My Classes'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadClasses,
        child: SingleChildScrollView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          padding:
              const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(
                maxWidth: 1000,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'My Classes',
                              style:
                                  TextStyle(
                                fontSize: 28,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                            const SizedBox(
                              height: 6,
                            ),
                            Text(
                              'Create and manage classes for your students.',
                              style:
                                  TextStyle(
                                color:
                                    Colors.grey[500],
                                fontSize:
                                    15,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        width: 16,
                      ),

                      ElevatedButton.icon(
                        onPressed:
                            _showCreateClassDialog,
                        icon:
                            const Icon(
                          Icons.add,
                        ),
                        label:
                            const Text(
                          'Create Class',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 28,
                  ),

                  if (_isLoading)
                    const Center(
                      child:
                          Padding(
                        padding:
                            EdgeInsets.all(
                          40,
                        ),
                        child:
                            CircularProgressIndicator(),
                      ),
                    )
                  else if (_classes.isEmpty)
                    _buildEmptyState()
                  else
                    ..._classes.map(
                      _buildClassCard,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding:
            const EdgeInsets.all(40),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.class_outlined,
                size: 60,
                color:
                    Colors.grey[600],
              ),

              const SizedBox(
                height: 16,
              ),

              const Text(
                'No Classes Yet',
                style:
                    TextStyle(
                  fontSize: 21,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              Text(
                'Create your first class so students can join using a class code.',
                textAlign:
                    TextAlign.center,
                style:
                    TextStyle(
                  color:
                      Colors.grey[500],
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              ElevatedButton.icon(
                onPressed:
                    _showCreateClassDialog,
                icon:
                    const Icon(
                  Icons.add,
                ),
                label:
                    const Text(
                  'Create Your First Class',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CLASS CARD
  // ============================================================

  Widget _buildClassCard(
    ClassGroup classGroup,
  ) {
    final studentCount =
        _studentCounts[
                classGroup.id] ??
            0;

    return Card(
      color: Colors.grey[900],
      margin:
          const EdgeInsets.only(
        bottom: 16,
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration:
                      BoxDecoration(
                    color:
                        Colors.tealAccent.withOpacity(
                      0.12,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),
                  ),
                  child:
                      const Icon(
                    Icons.school,
                    color:
                        Colors.tealAccent,
                    size: 28,
                  ),
                ),

                const SizedBox(
                  width: 16,
                ),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        classGroup.name,
                        style:
                            const TextStyle(
                          fontSize: 21,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        height: 5,
                      ),

                      Text(
                        'Instructor: ${classGroup.adminName}',
                        style:
                            TextStyle(
                          color:
                              Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
              child: Row(
                children: [
                  const Icon(
                    Icons.key,
                    color:
                        Colors.tealAccent,
                  ),

                  const SizedBox(
                    width: 12,
                  ),

                  const Text(
                    'Join Code:',
                    style:
                        TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    width: 12,
                  ),

                  SelectableText(
                    classGroup.classCode,
                    style:
                        const TextStyle(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),

                  const Spacer(),

                  IconButton(
                    tooltip:
                        'Show Join Code',
                    onPressed: () =>
                        _copyClassCode(
                      classGroup,
                    ),
                    icon:
                        const Icon(
                      Icons.visibility,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            Row(
              children: [
                Icon(
                  Icons.people,
                  color:
                      Colors.grey[500],
                  size: 20,
                ),

                const SizedBox(
                  width: 8,
                ),

                Text(
                  '$studentCount ${studentCount == 1 ? 'Student' : 'Students'}',
                  style:
                      TextStyle(
                    color:
                        Colors.grey[400],
                  ),
                ),

                const Spacer(),

                OutlinedButton.icon(
                  onPressed: () =>
                      _showStudents(
                    classGroup,
                  ),
                  icon:
                      const Icon(
                    Icons.people_outline,
                  ),
                  label:
                      const Text(
                    'View Students',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// CLASS STUDENTS DIALOG
// ================================================================

class _ClassStudentsDialog
    extends StatefulWidget {
  final FirebaseService firebaseService;
  final ClassGroup classGroup;

  const _ClassStudentsDialog({
    required this.firebaseService,
    required this.classGroup,
  });

  @override
  State<_ClassStudentsDialog>
      createState() =>
          _ClassStudentsDialogState();
}

class _ClassStudentsDialogState
    extends State<_ClassStudentsDialog> {
  late Future<List<User>> _studentsFuture;

  @override
  void initState() {
    super.initState();

    _studentsFuture =
        widget.firebaseService
            .getStudentsForClass(
      widget.classGroup.id,
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return AlertDialog(
      title: Text(
        widget.classGroup.name,
      ),
      content: SizedBox(
        width: 500,
        height: 400,
        child: FutureBuilder<
            List<User>>(
          future: _studentsFuture,
          builder:
              (context, snapshot) {
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child:
                    CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Unable to load students:\n${snapshot.error}',
                  textAlign:
                      TextAlign.center,
                ),
              );
            }

            final students =
                snapshot.data ??
                    [];

            if (students.isEmpty) {
              return const Center(
                child: Text(
                  'No students have joined this class yet.',
                  textAlign:
                      TextAlign.center,
                ),
              );
            }

            return ListView.builder(
              itemCount:
                  students.length,
              itemBuilder:
                  (context, index) {
                final student =
                    students[index];

                return ListTile(
                  leading:
                      CircleAvatar(
                    child: Text(
                      student.name.isNotEmpty
                          ? student.name[0]
                              .toUpperCase()
                          : '?',
                    ),
                  ),
                  title:
                      Text(
                    student.name,
                  ),
                  subtitle:
                      Text(
                    student.studentId ??
                        student.email ??
                        '',
                  ),
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(
              context,
            );
          },
          child:
              const Text('Close'),
        ),
      ],
    );
  }
}