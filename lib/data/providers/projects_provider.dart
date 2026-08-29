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
      // Si la columna 'client' o 'budget' aún no existe en la BD, reintenta sin ellas
      // para no romper la creación del proyecto.
      debugPrint('Insert proyecto: reintentando sin budget/client. Detalle: $e');
      data.remove('client');
      data.remove('budget');
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
      debugPrint('Update proyecto: reintentando sin budget/client. Detalle: $e');
      data.remove('client');
      data.remove('budget');
      try {
        await _supabase.from('projects').update(data).eq('id', project.id!);
      } catch (e2) {
        debugPrint('Error updating project: $e2');
      }
    }
    await fetchProjects();
  }

  /// Elimina un proyecto solo si no tiene movimientos asociados.
  ///
  /// Devuelve `false` sin borrar nada cuando ya se le cargó material: esos
  /// movimientos son el sustento del reporte de consumo y de los costos, y
  /// perderían su referencia. En ese caso conviene marcarlo como terminado.
  Future<bool> deleteProject(String id) async {
    try {
      final conMovimientos = await _supabase
          .from('movements')
          .select('id')
          .eq('project_id', id)
          .limit(1);
      if (conMovimientos.isNotEmpty) return false;

      await _supabase.from('projects').delete().eq('id', id);
      await fetchProjects();
      return true;
    } catch (e) {
      debugPrint('Error deleting project: $e');
      rethrow;
    }
  }
}
