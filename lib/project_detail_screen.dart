import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'models/project_model.dart';

class ProjectDetailScreen extends StatefulWidget {
  final ProjectModel project;
  final String role;

  const ProjectDetailScreen({
    super.key,
    required this.project,
    required this.role,
  });

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.role == 'admin' ? 2 : 1,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Toggle Task Status ──────────────────────────────────────
  Future toggleTaskStatus(String taskId, String currentStatus) async {
    final newStatus = currentStatus == 'complete' ? 'pending' : 'complete';
    await FirebaseFirestore.instance
        .collection('projects')
        .doc(widget.project.id)
        .collection('tasks')
        .doc(taskId)
        .update({"status": newStatus});
  }

  // ── Delete Task ─────────────────────────────────────────────
  Future deleteTask(String taskId) async {
    await FirebaseFirestore.instance
        .collection('projects')
        .doc(widget.project.id)
        .collection('tasks')
        .doc(taskId)
        .delete();
  }

  // ── Assign Member ───────────────────────────────────────────
  Future assignMember(String uid) async {
    await FirebaseFirestore.instance
        .collection('projects')
        .doc(widget.project.id)
        .update({
      "members": FieldValue.arrayUnion([uid]),
    });
  }

  // ── Remove Member ───────────────────────────────────────────
  Future removeMember(String uid) async {
    await FirebaseFirestore.instance
        .collection('projects')
        .doc(widget.project.id)
        .update({
      "members": FieldValue.arrayRemove([uid]),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.project.name),
        bottom: widget.role == 'admin'
            ? TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(icon: Icon(Icons.task_alt), text: "Tasks"),
                  Tab(icon: Icon(Icons.people), text: "Members"),
                ],
              )
            : null,
        actions: [
          if (widget.role == 'admin')
            IconButton(
              icon: const Icon(Icons.add_task),
              tooltip: "Add Task",
              onPressed: () => _showAddTaskDialog(),
            ),
        ],
      ),
      body: widget.role == 'admin'
          ? TabBarView(
              controller: _tabController,
              children: [
                _buildTasksTab(),
                _buildMembersTab(),
              ],
            )
          : _buildTasksTab(),
    );
  }

  // ── ADD TASK DIALOG ─────────────────────────────────────────
  void _showAddTaskDialog() async {
    final titleController = TextEditingController();
    String? selectedMemberId;
    DateTime? selectedDueDate;

    // Fetch members of this project
    final projectDoc = await FirebaseFirestore.instance
        .collection('projects')
        .doc(widget.project.id)
        .get();

    final memberIds =
        List<String>.from(projectDoc.data()?['members'] ?? []);

    // Fetch member emails
    List<Map<String, String>> membersList = [];
    for (String uid in memberIds) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (userDoc.exists) {
        membersList.add({
          "uid": uid,
          "email": userDoc.data()?['email'] ?? uid,
        });
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text("Add New Task"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Task title
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: "Task Title",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                // Assign to member
                membersList.isEmpty
                    ? const Text(
                        "No members in this project yet.\nAdd members first from the Members tab.",
                        style: TextStyle(color: Colors.orange, fontSize: 13),
                        textAlign: TextAlign.center,
                      )
                    : DropdownButtonFormField<String>(
                        value: selectedMemberId,
                        decoration: const InputDecoration(
                          labelText: "Assign To",
                          border: OutlineInputBorder(),
                        ),
                        hint: const Text("Select member"),
                        items: membersList
                            .map((m) => DropdownMenuItem(
                                  value: m['uid'],
                                  child: Text(m['email']!),
                                ))
                            .toList(),
                        onChanged: (val) =>
                            setDialogState(() => selectedMemberId = val),
                      ),
                const SizedBox(height: 12),

                // Due date picker
                OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(
                    selectedDueDate == null
                        ? "Set Due Date (optional)"
                        : "Due: ${selectedDueDate!.day}/${selectedDueDate!.month}/${selectedDueDate!.year}",
                  ),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate:
                          DateTime.now().add(const Duration(days: 1)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now()
                          .add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedDueDate = picked);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty) return;

                final taskData = {
                  "title": titleController.text.trim(),
                  "status": "pending",
                  "assignedTo": selectedMemberId,
                  "createdAt": FieldValue.serverTimestamp(),
                  "createdBy": currentUser!.uid,
                  if (selectedDueDate != null)
                    "dueDate": Timestamp.fromDate(selectedDueDate!),
                };

                await FirebaseFirestore.instance
                    .collection('projects')
                    .doc(widget.project.id)
                    .collection('tasks')
                    .add(taskData);

                Navigator.pop(ctx);
              },
              child: const Text("Add Task"),
            ),
          ],
        ),
      ),
    );
  }

  // ── TASKS TAB ───────────────────────────────────────────────
  Widget _buildTasksTab() {
    // Members only see their own tasks
    final taskStream = widget.role == 'admin'
        ? FirebaseFirestore.instance
            .collection('projects')
            .doc(widget.project.id)
            .collection('tasks')
            .orderBy('createdAt', descending: false)
            .snapshots()
        : FirebaseFirestore.instance
            .collection('projects')
            .doc(widget.project.id)
            .collection('tasks')
            .where('assignedTo', isEqualTo: currentUser!.uid)
            .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: taskStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.checklist, size: 60, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text(
                  widget.role == 'admin'
                      ? "No tasks yet. Tap + to add."
                      : "No tasks assigned to you yet.",
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        final tasks = snapshot.data!.docs;
        final now = DateTime.now();

        // Count stats
        int done = tasks
            .where((t) =>
                (t.data() as Map)['status'] == 'complete')
            .length;

        return Column(
          children: [
            // Progress bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: tasks.isEmpty ? 0 : done / tasks.length,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(4),
                      color: Colors.green,
                      backgroundColor: Colors.grey[200],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "$done/${tasks.length} done",
                    style:
                        TextStyle(color: Colors.grey[700], fontSize: 12),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: tasks.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final data =
                      tasks[index].data() as Map<String, dynamic>;
                  final status = data['status'] ?? 'pending';
                  final isComplete = status == 'complete';
                  final taskId = tasks[index].id;

                  // Check overdue
                  bool isOverdue = false;
                  String dueDateText = '';
                  if (data['dueDate'] != null) {
                    final due =
                        (data['dueDate'] as Timestamp).toDate();
                    isOverdue = due.isBefore(now) && !isComplete;
                    dueDateText =
                        "Due: ${due.day}/${due.month}/${due.year}";
                  }

                  return Card(
                    elevation: 1,
                    color: isOverdue ? Colors.red[50] : Colors.white,
                    child: ListTile(
                      leading: GestureDetector(
                        onTap: () => toggleTaskStatus(taskId, status),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isComplete
                                ? Colors.green
                                : Colors.grey[300],
                          ),
                          child: isComplete
                              ? const Icon(Icons.check,
                                  color: Colors.white, size: 16)
                              : null,
                        ),
                      ),
                      title: Text(
                        data['title'] ?? '',
                        style: TextStyle(
                          decoration: isComplete
                              ? TextDecoration.lineThrough
                              : null,
                          color: isComplete
                              ? Colors.grey
                              : Colors.black87,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Status badge
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isComplete
                                  ? Colors.green[100]
                                  : isOverdue
                                      ? Colors.red[100]
                                      : Colors.orange[100],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              isComplete
                                  ? "Complete"
                                  : isOverdue
                                      ? "Overdue"
                                      : "Pending",
                              style: TextStyle(
                                fontSize: 11,
                                color: isComplete
                                    ? Colors.green[800]
                                    : isOverdue
                                        ? Colors.red[800]
                                        : Colors.orange[800],
                              ),
                            ),
                          ),
                          if (dueDateText.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                dueDateText,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isOverdue
                                      ? Colors.red
                                      : Colors.grey[600],
                                ),
                              ),
                            ),
                        ],
                      ),
                      trailing: widget.role == 'admin'
                          ? IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.red),
                              onPressed: () => deleteTask(taskId),
                            )
                          : null,
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // ── MEMBERS TAB ─────────────────────────────────────────────
  Widget _buildMembersTab() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('projects')
          .doc(widget.project.id)
          .snapshots(),
      builder: (context, projectSnap) {
        if (!projectSnap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        List<dynamic> assignedMembers =
            (projectSnap.data!.data() as Map<String, dynamic>)['members'] ??
                [];

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'member')
              .snapshots(),
          builder: (context, usersSnap) {
            if (!usersSnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            var allMembers = usersSnap.data!.docs;

            if (allMembers.isEmpty) {
              return const Center(
                  child: Text("No members registered yet."));
            }

            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: allMembers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final userData =
                    allMembers[index].data() as Map<String, dynamic>;
                final uid = allMembers[index].id;
                final email = userData['email'] ?? 'Unknown';
                final isAssigned = assignedMembers.contains(uid);

                return Card(
                  elevation: 1,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          isAssigned ? Colors.green[50] : Colors.grey[200],
                      child: Text(
                        email[0].toUpperCase(),
                        style: TextStyle(
                          color: isAssigned
                              ? Colors.green
                              : Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(email),
                    subtitle: Text(
                      isAssigned ? "Assigned to project" : "Not assigned",
                      style: TextStyle(
                        color:
                            isAssigned ? Colors.green : Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    trailing: isAssigned
                        ? OutlinedButton.icon(
                            onPressed: () => removeMember(uid),
                            icon: const Icon(Icons.remove_circle_outline,
                                size: 16),
                            label: const Text("Remove"),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                            ),
                          )
                        : ElevatedButton.icon(
                            onPressed: () => assignMember(uid),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text("Assign"),
                          ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}