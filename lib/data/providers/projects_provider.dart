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
      debugPrint('Error fetching projects: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addProject(ProjectModel project) async {
    final data = project.toMap();
    if (data['id'] == null) data['id'] = const Uuid().v4();
    try {
      await _supabase.from('projects').insert(data);
    } catch (e) {
      // Si la columna 'client' aún no existe en la BD, reintenta sin ella
      // para no romper la creación del proyecto.
      debugPrint('Insert proyecto: reintentando sin client. Detalle: $e');
      data.remove('client');
      try {
        await _supabase.from('projects').insert(data);
      } catch (e2) {
        debugPrint('Error adding project: $e2');
      }
    }
    await fetchProjects();
  }

  Future<void> updateProject(ProjectModel project) async {
    final data = project.toMap();
    data.remove('id');
    try {
      await _supabase.from('projects').update(data).eq('id', project.id!);
    } catch (e) {
      debugPrint('Update proyecto: reintentando sin client. Detalle: $e');
      data.remove('client');
      try {
        await _supabase.from('projects').update(data).eq('id', project.id!);
      } catch (e2) {
        debugPrint('Error updating project: $e2');
      }
    }
    await fetchProjects();
  }

  Future<void> deleteProject(String id) async {
    try {
      await _supabase.from('projects').delete().eq('id', id);
      await fetchProjects();
    } catch (e) {
      debugPrint('Error deleting project: $e');
    }
  }
}
