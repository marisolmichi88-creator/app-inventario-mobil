import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/warehouse_model.dart';
import 'package:uuid/uuid.dart';

class WarehousesProvider with ChangeNotifier {
  List<WarehouseModel> _warehouses = [];
  bool _isLoading = false;

  List<WarehouseModel> get warehouses => _warehouses;
  bool get isLoading => _isLoading;

  final _supabase = Supabase.instance.client;

  Future<void> fetchWarehouses() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase.from('warehouses').select().order('name');
      _warehouses = response.map((map) => WarehouseModel.fromMap(map)).toList();
    } catch (e) {
      print('Error fetching warehouses: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addWarehouse(WarehouseModel warehouse) async {
    try {
      final data = warehouse.toMap();
      if (data['id'] == null) data['id'] = const Uuid().v4();
      await _supabase.from('warehouses').insert(data);
      await fetchWarehouses();
    } catch (e) {
      print('Error adding warehouse: $e');
    }
  }

  Future<void> updateWarehouse(WarehouseModel warehouse) async {
    try {
      final data = warehouse.toMap();
      data.remove('id');
      await _supabase.from('warehouses').update(data).eq('id', warehouse.id!);
      await fetchWarehouses();
    } catch (e) {
      print('Error updating warehouse: $e');
    }
  }

  Future<void> toggleWarehouseStatus(String id, bool currentStatus) async {
    try {
      await _supabase.from('warehouses').update({'is_active': !currentStatus}).eq('id', id);
      await fetchWarehouses();
    } catch (e) {
      print('Error toggling warehouse status: $e');
    }
  }
}
