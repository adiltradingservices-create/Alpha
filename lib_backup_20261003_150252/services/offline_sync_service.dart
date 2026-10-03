import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SyncRecord {
  final String id;
  final String moduleType; // 'BIOMETRIC', 'INVENTORY', 'TESTING_COMMISSIONING'
  final Map<String, dynamic> payload;
  final DateTime timestamp;
  bool isSynced;

  SyncRecord({
    required this.id,
    required this.moduleType,
    required this.payload,
    required this.timestamp,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'moduleType': moduleType,
    'payload': payload,
    'timestamp': timestamp.toIso8601String(),
    'isSynced': isSynced,
  };

  factory SyncRecord.fromMap(Map<String, dynamic> map) => SyncRecord(
    id: map['id'] as String,
    moduleType: map['moduleType'] as String,
    payload: Map<String, dynamic>.from(map['payload'] as Map),
    timestamp: DateTime.parse(map['timestamp'] as String),
    isSynced: map['isSynced'] as bool? ?? false,
  );
}

class OfflineSyncService extends ChangeNotifier {
  static final OfflineSyncService _instance = OfflineSyncService._internal();
  factory OfflineSyncService() => _instance;
  OfflineSyncService._internal();

  bool _isOnline = true;
  bool _isSyncing = false;
  final List<SyncRecord> _queue = [];

  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;
  List<SyncRecord> get pendingQueue => _queue.where((r) => !r.isSynced).toList();
  int get pendingCount => pendingQueue.length;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('offline_sync_queue');
    if (raw != null) {
      final List decoded = jsonDecode(raw);
      _queue.clear();
      _queue.addAll(decoded.map((e) => SyncRecord.fromMap(Map<String, dynamic>.from(e))));
      notifyListeners();
    }
  }

  void toggleNetworkSimulation() {
    _isOnline = !_isOnline;
    notifyListeners();
    if (_isOnline) {
      triggerSync();
    }
  }

  Future<void> queueAction({
    required String moduleType,
    required Map<String, dynamic> payload,
  }) async {
    final record = SyncRecord(
      id: 'REC-${DateTime.now().millisecondsSinceEpoch}',
      moduleType: moduleType,
      payload: payload,
      timestamp: DateTime.now(),
      isSynced: _isOnline,
    );

    _queue.insert(0, record);
    await _saveQueue();
    notifyListeners();

    if (_isOnline) {
      triggerSync();
    }
  }

  Future<void> triggerSync() async {
    if (!_isOnline || _isSyncing || pendingCount == 0) return;

    _isSyncing = true;
    notifyListeners();

    // Simulate batch upload latency
    await Future.delayed(const Duration(milliseconds: 1400));

    for (var r in _queue) {
      r.isSynced = true;
    }

    await _saveQueue();
    _isSyncing = false;
    notifyListeners();
  }

  Future<void> _saveQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(_queue.map((r) => r.toMap()).toList());
    await prefs.setString('offline_sync_queue', raw);
  }
}
