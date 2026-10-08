import 'dart:async';
import 'package:flutter/foundation.dart';

enum SyncStatus { synced, pending, syncing, offline }

class SyncOperation {
  final String id;
  final String entity; // 'PO', 'TRANSFER', 'WARRANTY_ASSET', 'TECH_STATUS'
  final String action; // 'CREATE', 'UPDATE', 'DELETE'
  final Map<String, dynamic> payload;
  final DateTime timestamp;
  bool isSynced;

  SyncOperation({
    required this.id,
    required this.entity,
    required this.action,
    required this.payload,
    required this.timestamp,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'entity': entity,
    'action': action,
    'payload': payload,
    'timestamp': timestamp.toIso8601String(),
    'isSynced': isSynced,
  };

  factory SyncOperation.fromMap(Map<String, dynamic> map) => SyncOperation(
    id: map['id'],
    entity: map['entity'],
    action: map['action'],
    payload: Map<String, dynamic>.from(map['payload']),
    timestamp: DateTime.parse(map['timestamp']),
    isSynced: map['isSynced'] ?? false,
  );
}

class CloudSyncEngine extends ChangeNotifier {
  static final CloudSyncEngine _instance = CloudSyncEngine._internal();
  factory CloudSyncEngine() => _instance;
  CloudSyncEngine._internal();

  final List<SyncOperation> _queue = [];
  SyncStatus _currentStatus = SyncStatus.synced;
  DateTime? _lastSyncTime;

  SyncStatus get currentStatus => _currentStatus;
  DateTime? get lastSyncTime => _lastSyncTime;
  int get pendingCount => _queue.where((o) => !o.isSynced).length;
  List<SyncOperation> get pendingOperations => _queue.where((o) => !o.isSynced).toList();

  void enqueue({
    required String entity,
    required String action,
    required Map<String, dynamic> payload,
  }) {
    final op = SyncOperation(
      id: 'OP-${DateTime.now().millisecondsSinceEpoch}',
      entity: entity,
      action: action,
      payload: payload,
      timestamp: DateTime.now(),
      isSynced: false,
    );
    _queue.add(op);
    _currentStatus = SyncStatus.pending;
    notifyListeners();
  }

  Future<bool> flushQueue() async {
    final pending = pendingOperations;
    if (pending.isEmpty) {
      _currentStatus = SyncStatus.synced;
      notifyListeners();
      return true;
    }

    _currentStatus = SyncStatus.syncing;
    notifyListeners();

    try {
      // Simulate remote network dispatch & reconciliation latency
      await Future.delayed(const Duration(milliseconds: 1400));

      for (final op in pending) {
        op.isSynced = true;
      }

      _lastSyncTime = DateTime.now();
      _currentStatus = SyncStatus.synced;
      notifyListeners();
      return true;
    } catch (e) {
      _currentStatus = SyncStatus.offline;
      notifyListeners();
      return false;
    }
  }

  void purgeSynced() {
    _queue.removeWhere((o) => o.isSynced);
    notifyListeners();
  }
}
