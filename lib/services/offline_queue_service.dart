import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

enum QueueAction {
  postService,
  postProduct,
  sendMessage,
  updateProfile,
  addReview,
}

class QueuedAction {
  final String id;
  final QueueAction action;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  int retryCount;
  
  QueuedAction({
    required this.id,
    required this.action,
    required this.data,
    DateTime? createdAt,
    this.retryCount = 0,
  }) : createdAt = createdAt ?? DateTime.now();
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'action': action.toString(),
    'data': data,
    'createdAt': createdAt.toIso8601String(),
    'retryCount': retryCount,
  };
  
  static QueuedAction fromJson(Map<String, dynamic> json) {
    return QueuedAction(
      id: json['id'] as String,
      action: QueueAction.values.firstWhere(
        (e) => e.toString() == json['action'],
      ),
      data: json['data'] as Map<String, dynamic>,
      createdAt: DateTime.parse(json['createdAt'] as String),
      retryCount: json['retryCount'] as int? ?? 0,
    );
  }
}

/// Service for managing offline actions and auto-syncing
/// Queues user actions when offline and syncs when connection returns
class OfflineQueueService extends ChangeNotifier {
  static const String queueBoxName = 'offline_queue';
  static late Box<Map<dynamic, dynamic>> _queueBox;
  
  static bool _initialized = false;
  final List<QueuedAction> _pendingActions = [];
  final Map<String, Future<bool> Function(Map<String, dynamic>)> _actionHandlers = {};
  
  bool _isSyncing = false;
  int _syncProgress = 0;
  
  bool get isSyncing => _isSyncing;
  int get syncProgress => _syncProgress;
  List<QueuedAction> get pendingActions => List.unmodifiable(_pendingActions);
  
  Future<void> init() async {
    if (_initialized) return;
    
    try {
      _queueBox = await Hive.openBox<Map<dynamic, dynamic>>(queueBoxName);
      
      // Load pending actions from storage
      await _loadPendingActions();
      
      _initialized = true;
      debugPrint('✅ Service file d\'attente hors ligne initialisé');
    } catch (e) {
      debugPrint('❌ Erreur initialisation file d\'attente: $e');
    }
  }
  
  /// Register action handler for sync
  void registerActionHandler(
    QueueAction action,
    Future<bool> Function(Map<String, dynamic>) handler,
  ) {
    _actionHandlers[action.toString()] = handler;
    debugPrint('📝 Gestionnaire enregistré pour: ${action.toString()}');
  }
  
  /// Queue an action when offline
  Future<void> queueAction(
    QueueAction action,
    Map<String, dynamic> data,
  ) async {
    try {
      final queuedAction = QueuedAction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        action: action,
        data: data,
      );
      
      _pendingActions.add(queuedAction);
      
      // Persist to storage
      final jsonData = queuedAction.toJson();
      await _queueBox.put(queuedAction.id, jsonData);
      
      debugPrint(
        '📤 Action en queue: ${action.toString()} (Total: ${_pendingActions.length})',
      );
      
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Erreur mise en queue: $e');
    }
  }
  
  /// Sync all pending actions (call when connection returns)
  Future<void> syncAllPendingActions() async {
    if (_pendingActions.isEmpty || _isSyncing) return;
    
    _isSyncing = true;
    _syncProgress = 0;
    notifyListeners();
    
    try {
      final total = _pendingActions.length;
      int synced = 0;
      final failedIds = <String>[];
      
      for (final action in _pendingActions) {
        try {
          final handler = _actionHandlers[action.action.toString()];
          
          if (handler == null) {
            debugPrint('⚠️ Aucun gestionnaire pour: ${action.action}');
            failedIds.add(action.id);
            continue;
          }
          
          // Try to sync with exponential backoff
          bool success = false;
          for (int attempt = 0; attempt < 3; attempt++) {
            try {
              success = await handler(action.data);
              if (success) break;
            } catch (e) {
              debugPrint(
                '⏳ Tentative ${attempt + 1}/3 pour ${action.id}: $e',
              );
              await Future.delayed(
                Duration(milliseconds: 500 * (1 << attempt)),
              );
            }
          }
          
          if (success) {
            _queueBox.delete(action.id);
            synced++;
            debugPrint('✅ Action synchronisée: ${action.id}');
          } else {
            action.retryCount++;
            if (action.retryCount >= 5) {
              // After 5 failed attempts, mark as failed
              _queueBox.delete(action.id);
              debugPrint('❌ Action supprimée après 5 tentatives: ${action.id}');
            } else {
              // Update retry count
              final jsonData = action.toJson();
              _queueBox.put(action.id, jsonData);
            }
            failedIds.add(action.id);
          }
        } catch (e) {
          debugPrint('❌ Erreur synchronisation action: $e');
          failedIds.add(action.id);
        }
        
        _syncProgress = ((synced + failedIds.length) / total * 100).toInt();
        notifyListeners();
      }
      
      // Remove synced actions from memory
      _pendingActions.removeWhere(
        (action) => !failedIds.contains(action.id),
      );
      
      debugPrint(
        '✅ Synchronisation terminée: $synced/$total réussies',
      );
    } catch (e) {
      debugPrint('❌ Erreur synchronisation globale: $e');
    } finally {
      _isSyncing = false;
      _syncProgress = 0;
      notifyListeners();
    }
  }
  
  /// Load pending actions from storage
  Future<void> _loadPendingActions() async {
    try {
      _pendingActions.clear();
      
      for (int i = 0; i < _queueBox.length; i++) {
        try {
          final value = _queueBox.getAt(i);
          if (value != null) {
            final queuedAction = QueuedAction.fromJson(
              Map<String, dynamic>.from(value),
            );
            _pendingActions.add(queuedAction);
          }
        } catch (e) {
          debugPrint('⚠️ Erreur parsing action: $e');
        }
      }
      
      debugPrint(
        '📂 ${_pendingActions.length} actions en attente chargées',
      );
    } catch (e) {
      debugPrint('❌ Erreur chargement actions: $e');
    }
  }
  
  /// Clear all pending actions
  Future<void> clearAllActions() async {
    try {
      _queueBox.clear();
      _pendingActions.clear();
      debugPrint('🗑️ File d\'attente vidée');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Erreur vidage file d\'attente: $e');
    }
  }
  
  /// Get pending actions count
  int getPendingActionCount() => _pendingActions.length;
  
  @override
  void dispose() {
    super.dispose();
  }
}
