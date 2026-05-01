import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import 'project_detail_screen.dart';
import 'models/project_model.dart';

class DashboardScreen extends StatefulWidget {
  final String role;
  const DashboardScreen({super.key, required this.role});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final projectController = TextEditingController();
  final currentUser = FirebaseAuth.instance.currentUser;

  // ── Create Project (Admin only) ─────────────────────────────
  Future createProject() async {
    if (projectController.text.isEmpty) return;

    await FirebaseFirestore.instance.collection('projects').add({
      "name": projectController.text.trim(),
      "createdBy": currentUser!.uid,
      "members": [],
      "createdAt": FieldValue.serverTimestamp(),
    });

    projectController.clear();
  }

  // ── Delete Project (Admin only) ─────────────────────────────
  Future deleteProject(String projectId) async {
    await FirebaseFirestore.instance
        .collection('projects')
        .doc(projectId)
        .delete();
  }

  // ── Fetch Stats for Admin Header ────────────────────────────
  Future<List<int>> _fetchStats() async {
    final projects =
        await FirebaseFirestore.instance.collection('projects').get();
    final members = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'member')
        .get();

    int taskCount = 0;
    for (var p in projects.docs) {
      final tasks = await FirebaseFirestore.instance
          .collection('projects')
          .doc(p.id)
          .collection('tasks')
          .get();
      taskCount += tasks.size;
    }
    return [projects.size, members.size, taskCount];
  }

  // ── Project Stream based on role ────────────────────────────
  Stream<QuerySnapshot> get projectStream {
    if (widget.role == 'admin') {
      return FirebaseFirestore.instance
          .collection('projects')
          .orderBy('createdAt', descending: true)
          .snapshots();
    } else {
      return FirebaseFirestore.instance
          .collection('projects')
          .where('members', arrayContains: currentUser!.uid)
          .snapshots();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.role == 'admin' ? 'Admin Dashboard' : 'My Projects',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              currentUser?.email ?? '',
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: widget.role == 'admin' ? _buildAdminView() : _buildMemberView(),
    );
  }

  // ── Admin Stats Header ──────────────────────────────────────
  Widget _buildAdminStats() {
    return FutureBuilder<List<int>>(
      future: _fetchStats(),
      builder: (context, snap) {
        final stats = snap.data ?? [0, 0, 0];
        return Container(
          margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[700]!, Colors.blue[500]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statCard('Projects', stats[0], Icons.folder_open),
              _dividerLine(),
              _statCard('Members', stats[1], Icons.people_alt_outlined),
              _dividerLine(),
              _statCard('Tasks', stats[2], Icons.task_alt),
            ],
          ),
        );
      },
    );
  }

  Widget _statCard(String label, int count, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 22),
        const SizedBox(height: 6),
        Text(
          '$count',
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _dividerLine() {
    return Container(
      width: 1,
      height: 48,
      color: Colors.white24,
    );
  }

  // ── Admin View ──────────────────────────────────────────────
  Widget _buildAdminView() {
    return Column(
      children: [
        // Stats header
        _buildAdminStats(),

        // Create project input
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: projectController,
                  decoration: InputDecoration(
                    labelText: "New Project Name",
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon:
                        const Icon(Icons.add_box_outlined, color: Colors.blue),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: createProject,
                icon: const Icon(Icons.add),
                label: const Text("Create"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              const Icon(Icons.folder, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                'All Projects',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 6),
        Expanded(child: _buildProjectList()),
      ],
    );
  }

  // ── Member View ─────────────────────────────────────────────
  Widget _buildMemberView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade100),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.blue[50],
                child: Text(
                  (currentUser?.email ?? 'U')[0].toUpperCase(),
                  style: TextStyle(
                      color: Colors.blue[700], fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentUser?.email ?? '',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  Text(
                    'Member',
                    style:
                        TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'ASSIGNED PROJECTS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.grey[500],
              letterSpacing: 1.0,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Expanded(child: _buildProjectList()),
      ],
    );
  }

  // ── Shared Project List ─────────────────────────────────────
  Widget _buildProjectList() {
    return StreamBuilder<QuerySnapshot>(
      stream: projectStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder_open, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 14),
                Text(
                  widget.role == 'admin'
                      ? "No projects yet.\nCreate one above!"
                      : "You have no assigned projects yet.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[500], fontSize: 15),
                ),
              ],
            ),
          );
        }

        var docs = snapshot.data!.docs;

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
          itemCount: docs.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            var data = docs[index].data() as Map<String, dynamic>;
            var project = ProjectModel.fromFirestore(docs[index].id, data);

            // Pick a color per project based on index
            final colors = [
              Colors.blue,
              Colors.purple,
              Colors.teal,
              Colors.orange,
              Colors.pink,
              Colors.indigo,
            ];
            final color = colors[index % colors.length];

            return Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 6),
                leading: CircleAvatar(
                  backgroundColor: color.shade50,
                  child: Text(
                    project.name[0].toUpperCase(),
                    style: TextStyle(
                        color: color.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                ),
                title: Text(
                  project.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 15),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      Icon(Icons.people_outline,
                          size: 13, color: Colors.grey[500]),
                      const SizedBox(width: 3),
                      Text(
                        "${project.members.length} member${project.members.length == 1 ? '' : 's'}",
                        style: TextStyle(
                            color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                trailing: widget.role == 'admin'
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.arrow_forward_ios,
                              size: 13, color: Colors.grey),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red, size: 20),
                            onPressed: () => _confirmDelete(project.id),
                          ),
                        ],
                      )
                    : const Icon(Icons.arrow_forward_ios,
                        size: 13, color: Colors.grey),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProjectDetailScreen(
                        project: project,
                        role: widget.role,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  // ── Delete Confirmation Dialog ──────────────────────────────
  void _confirmDelete(String projectId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text("Delete Project"),
        content: const Text(
            "Are you sure? This will also delete all tasks inside."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await deleteProject(projectId);
            },
            child: const Text("Delete",
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}