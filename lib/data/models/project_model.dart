class ProjectModel {
  final String? id;
  final String name;
  final String? client;
  final String? description;
  final String? startDate;
  final String? endDate;
  final String status;
  final double budget;

  ProjectModel({
    this.id,
    required this.name,
    this.client,
    this.description,
    this.startDate,
    this.endDate,
    this.status = 'active', // active, completed, cancelled
    this.budget = 0.0,
  });

  factory ProjectModel.fromMap(Map<String, dynamic> map) {
    return ProjectModel(
      id: map['id'],
      name: map['name'],
      client: map['client'],
      description: map['description'],
      startDate: map['start_date'],
      endDate: map['end_date'],
      status: map['status'] ?? 'active',
      budget: (map['budget'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'client': client,
      'description': description,
      'start_date': startDate,
      'end_date': endDate,
      'status': status,
      'budget': budget,
    };
    if (id != null) map['id'] = id;
    return map;
  }
}
