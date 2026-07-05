import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/project_model.dart';
import 'package:uuid/uuid.dart';

class ProjectsProvider with ChangeNotifier {
  List<ProjectModel> _projects = [];
  bool _isLoading = false;

  List<ProjectModel> get projects => _projects;
  bool get isLoading => _isLoading;

  final _supabase = Supabase.instance.client;

  Future<void> fetchProjects() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase.from('projects').select().order('name');
      _projects = response.map((map) => ProjectModel.fromMap(map)).toList();
    } catch (e) {
      print('Error fetching projects: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addProject(ProjectModel project) async {
    try {
      final data = project.toMap();
      if (data['id'] == null) data['id'] = const Uuid().v4();
      await _supabase.from('projects').insert(data);
      await fetchProjects();
    } catch (e) {
      print('Error adding project: $e');
    }
  }

  Future<void> updateProject(ProjectModel project) async {
    try {
      final data = project.toMap();
      data.remove('id');
      await _supabase.from('projects').update(data).eq('id', project.id!);
      await fetchProjects();
    } catch (e) {
      print('Error updating project: $e');
    }
  }

  Future<void> deleteProject(String id) async {
    try {
      await _supabase.from('projects').delete().eq('id', id);
      await fetchProjects();
    } catch (e) {
      print('Error deleting project: $e');
    }
  }
}
