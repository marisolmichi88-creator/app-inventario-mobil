class ProjectModel {
  final String? id;
  final String name;
  final String? description;
  final String? startDate;
  final String? endDate;
  final String status;

  ProjectModel({
    this.id,
    required this.name,
    this.description,
    this.startDate,
    this.endDate,
    this.status = 'active', // active, completed, cancelled
  });

  factory ProjectModel.fromMap(Map<String, dynamic> map) {
    return ProjectModel(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      startDate: map['start_date'],
      endDate: map['end_date'],
      status: map['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'description': description,
      'start_date': startDate,
      'end_date': endDate,
      'status': status,
    };
    if (id != null) map['id'] = id;
    return map;
  }
}
