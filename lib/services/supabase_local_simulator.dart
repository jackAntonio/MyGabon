import 'package:flutter/foundation.dart';
import 'demo_data.dart';

/// 🎬 LOCAL SUPABASE SIMULATOR
/// Queries real data exactly like Supabase would
/// Can be swapped to real Supabase later without code changes

class SupabaseLocalSimulator {
  static final SupabaseLocalSimulator _instance = SupabaseLocalSimulator._internal();

  factory SupabaseLocalSimulator() {
    return _instance;
  }

  SupabaseLocalSimulator._internal();

  late Map<String, dynamic> _data;

  void initialize() {
    _data = gabonDemoData;
  }

  /// Query a table with optional select, filter, limit
  Future<List<Map<String, dynamic>>> query(
    String table, {
    List<String>? select,
    Map<String, dynamic>? filters,
    int? limit,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 100));

    if (!_data.containsKey(table)) {
      throw Exception('Table $table not found');
    }

    List<Map<String, dynamic>> rows =
        List<Map<String, dynamic>>.from(_data[table] as List);

    // Apply filters
    if (filters != null) {
      for (final entry in filters.entries) {
        rows = rows
            .where((row) => row.containsKey(entry.key) && row[entry.key] == entry.value)
            .toList();
      }
    }

    // Apply select (column projection)
    if (select != null) {
      rows = rows.map((row) {
        final filtered = <String, dynamic>{};
        for (final col in select) {
          if (row.containsKey(col)) {
            filtered[col] = row[col];
          }
        }
        return filtered;
      }).toList();
    }

    // Apply limit
    if (limit != null) {
      rows = rows.take(limit).toList();
    }

    return rows;
  }

  /// Get a single row by ID
  Future<Map<String, dynamic>?> getById(
    String table,
    String id,
  ) async {
    final results = await query(
      table,
      filters: {'id': id},
      limit: 1,
    );
    return results.isNotEmpty ? results[0] : null;
  }

  /// Check connection (always succeeds in simulator)
  Future<bool> checkConnection() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return true;
  }

  /// Count rows in table
  Future<int> count(String table, {Map<String, dynamic>? filters}) async {
    final rows = await query(table, filters: filters);
    return rows.length;
  }

  /// Insert new row (not used in demo but available)
  Future<Map<String, dynamic>> insert(
    String table,
    Map<String, dynamic> row,
  ) async {
    await Future.delayed(const Duration(milliseconds: 100));
    row['id'] = 'local_${DateTime.now().millisecondsSinceEpoch}';
    (_data[table] as List).add(row);
    return row;
  }

  /// Update row
  Future<bool> update(
    String table,
    Map<String, dynamic> row,
    String id,
  ) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final data = _data[table] as List;
    final index = data.indexWhere((r) => r['id'] == id);
    if (index >= 0) {
      data[index] = {...data[index], ...row};
      return true;
    }
    return false;
  }

  /// Delete row
  Future<bool> delete(String table, String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final data = _data[table] as List;
    data.removeWhere((r) => r['id'] == id);
    return true;
  }
}
