class ProjectModel {
  final String id;
  final String name;
  final List<dynamic> members;

  ProjectModel({
    required this.id,
    required this.name,
    required this.members,
  });

  factory ProjectModel.fromFirestore(String id, Map<String, dynamic> data) {
    return ProjectModel(
      id: id,
      name: data['name'] ?? '',
      members: data['members'] ?? [],
    );
  }
}