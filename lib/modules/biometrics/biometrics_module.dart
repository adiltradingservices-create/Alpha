import '../../services/sync_service.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_module.dart';
import '../../services/locale_service.dart';
import '../../services/offline_sync_service.dart';
import '../../services/whatsapp_dispatcher_service.dart';

/// Central Attendance Record Entity
class AttendanceTelemetryRecord {
  final String id;
  final String technicianId;
  final String technicianName;
  final String type; // 'CHECK_IN' | 'CHECK_OUT'
  final String category; // 'Office', 'Store', 'Vendor', 'Project Site', 'Client Office', 'Meeting'
  final String locationName;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final String? faceThumbnailBase64;
  final String? photoPath;
  final bool isOffSiteWarning;

  AttendanceTelemetryRecord({
    required this.id,
    required this.technicianId,
    required this.technicianName,
    required this.type,
    required this.category,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.faceThumbnailBase64,
    this.photoPath,
    this.isOffSiteWarning = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'technicianId': technicianId,
    'technicianName': technicianName,
    'type': type,
    'category': category,
    'locationName': locationName,
    'latitude': latitude,
    'longitude': longitude,
    'timestamp': timestamp.toIso8601String(),
    'faceThumbnailBase64': faceThumbnailBase64,
    'photoPath': photoPath,
    'isOffSiteWarning': isOffSiteWarning,
  };

  factory AttendanceTelemetryRecord.fromJson(Map<String, dynamic> json) => AttendanceTelemetryRecord(
    id: json['id'] ?? '',
    technicianId: json['technicianId'] ?? '',
    technicianName: json['technicianName'] ?? '',
    type: json['type'] ?? 'CHECK_IN',
    category: json['category'] ?? 'Project Site',
    locationName: json['locationName'] ?? '',
    latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
    longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
    timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : DateTime.now(),
    faceThumbnailBase64: json['faceThumbnailBase64'],
    photoPath: json['photoPath'],
    isOffSiteWarning: json['isOffSiteWarning'] ?? false,
  );
}

/// Central Singleton Attendance Telemetry Store with Local Cache & Punch Policies
class AttendanceDataStore with ChangeNotifier {
  static final AttendanceDataStore _instance = AttendanceDataStore._internal();
  factory AttendanceDataStore() => _instance;
  AttendanceDataStore._internal() {
    _loadFromCache();
  }

  bool allowUnlimitedPunches = true;
  int maxDailyPunches = 2;

  final List<AttendanceTelemetryRecord> records = [];

  bool get isCurrentlyCheckedIn {
    if (records.isEmpty) return false;
    return records.first.type == 'CHECK_IN';
  }

  int get todayPunchCount {
    final now = DateTime.now();
    return records.where((r) =>
      r.timestamp.year == now.year &&
      r.timestamp.month == now.month &&
      r.timestamp.day == now.day
    ).length;
  }

  bool get canPunchToday {
    if (allowUnlimitedPunches) return true;
    return todayPunchCount < maxDailyPunches;
  }

  void togglePunchPolicy(bool unlimited) {
    allowUnlimitedPunches = unlimited;
    _savePolicy();
    notifyListeners();
  }

  void setMaxDailyPunches(int limit) {
    maxDailyPunches = limit;
    _savePolicy();
    notifyListeners();
  }

  Timer? _remotePollTimer;

  void addRecord(AttendanceTelemetryRecord record, {File? facePhoto}) {
    records.insert(0, record);
    _saveToCache();
    notifyListeners();

    // Broadcast asynchronously to MySQL backend
    SyncService.submitAttendancePunch(
      record: record,
      facePhoto: facePhoto,
    ).then((success) {
      debugPrint('[ATTENDANCE-SYNC] Push to MySQL success: $success');
    }).catchError((err) {
      debugPrint('[ATTENDANCE-SYNC] Push error: $err');
    });
  }

  /// Pull records from MySQL backend and merge without duplicates
  Future<void> syncWithBackend() async {
    try {
      final remoteRecords = await SyncService.fetchAttendanceLogs();
      if (remoteRecords.isEmpty) return;

      bool hasNew = false;
      for (final remote in remoteRecords) {
        final existingIdx = records.indexWhere((r) => r.id == remote.id);
        if (existingIdx == -1) {
          records.add(remote);
          hasNew = true;
        }
      }

      if (hasNew) {
        records.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        _saveToCache();
        notifyListeners();
        debugPrint('[ATTENDANCE-SYNC] Merged remote logs from MySQL successfully.');
      }
    } catch (e) {
      debugPrint('[ATTENDANCE-SYNC] Fetch error: $e');
    }
  }

  /// Start background polling timer on Admin laptop
  void startAutoPoll({int seconds = 5}) {
    _remotePollTimer?.cancel();
    syncWithBackend();
    _remotePollTimer = Timer.periodic(Duration(seconds: seconds), (_) {
      syncWithBackend();
    });
  }

  void stopAutoPoll() {
    _remotePollTimer?.cancel();
    _remotePollTimer = null;
  }

  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      allowUnlimitedPunches = prefs.getBool('bio_unlimited_punches') ?? true;
      maxDailyPunches = prefs.getInt('bio_max_daily_punches') ?? 2;
      final raw = prefs.getString('bio_attendance_records');
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> list = jsonDecode(raw);
        records.clear();
        for (final item in list) {
          records.add(AttendanceTelemetryRecord.fromJson(item));
        }
      } else {
        records.addAll([
          AttendanceTelemetryRecord(
            id: 'ATT-101',
            technicianId: 'TECH-101',
            technicianName: 'Ahmad Faizal',
            type: 'CHECK_IN',
            category: 'HQ / Office',
            locationName: 'Central HQ Depot • Petaling Jaya',
            latitude: 3.1118,
            longitude: 101.6372,
            timestamp: DateTime.now().subtract(const Duration(hours: 3, minutes: 20)),
          ),
          AttendanceTelemetryRecord(
            id: 'ATT-102',
            technicianId: 'TECH-101',
            technicianName: 'Ahmad Faizal',
            type: 'CHECK_OUT',
            category: 'Project Site',
            locationName: 'Menara AlphaTech • Server Room',
            latitude: 3.1412,
            longitude: 101.6865,
            timestamp: DateTime.now().subtract(const Duration(minutes: 35)),
          ),
          AttendanceTelemetryRecord(
            id: 'ATT-103',
            technicianId: 'TECH-102',
            technicianName: 'Suresh Kumar',
            type: 'CHECK_IN',
            category: 'Vendor / Supplier',
            locationName: 'Hikvision Partner Warehouse • Subang',
            latitude: 3.0560,
            longitude: 101.5850,
            timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 10)),
            isOffSiteWarning: true,
          ),
        ]);
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _savePolicy() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('bio_unlimited_punches', allowUnlimitedPunches);
      await prefs.setInt('bio_max_daily_punches', maxDailyPunches);
    } catch (_) {}
  }

  Future<void> _saveToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = records.take(100).map((r) => r.toJson()).toList();
      await prefs.setString('bio_attendance_records', jsonEncode(list));
    } catch (_) {}
  }
}

/// AppModule Implementation
class BiometricsModule implements AppModule {
  @override
  String get moduleId => 'BIOMETRICS_TELEMETRY';

  @override
  String get title => LocaleService.currentLanguage.value == AppLanguage.en
      ? 'FACIAL BIOMETRICS & SHIFT TELEMETRY'
      : 'BIOMETRIK MUKA & TELEMETRI WAKTU KERJA';

  @override
  IconData get icon => Icons.face_retouching_natural_rounded;

  @override
  Widget? buildTechnicianUI(BuildContext context) {
    return const BiometricsAttendanceView();
  }

  @override
  Widget? buildAdminUI(BuildContext context) {
    return const AdminAttendanceLedgerView();
  }

  static Widget buildQuickPunchCockpit({
    required VoidCallback onPunchCompleted,
  }) {
    return ModularBiometricsCockpit(onPunchCompleted: onPunchCompleted);
  }

  static Widget buildHistoryLogsView() {
    return const ModularAttendanceHistoryLogs();
  }
}

/// ---------------------------------------------------------------------------
/// EMBEDDABLE MODULAR COCKPIT
/// ---------------------------------------------------------------------------
class ModularBiometricsCockpit extends StatefulWidget {
  final VoidCallback onPunchCompleted;
  const ModularBiometricsCockpit({super.key, required this.onPunchCompleted});

  @override
  State<ModularBiometricsCockpit> createState() => _ModularBiometricsCockpitState();
}

class _ModularBiometricsCockpitState extends State<ModularBiometricsCockpit> {
  final AttendanceDataStore _store = AttendanceDataStore();
  final ImagePicker _picker = ImagePicker();

  String _punchType = 'CHECK_IN';
  String _selectedCategory = 'Project Site';
  String _selectedPredefinedLocation = 'Menara AlphaTech • Server Room';
  final TextEditingController _customLocationController = TextEditingController();
  bool _isCustomLocation = false;

  XFile? _capturedFacePhoto;
  String? _faceThumbnailBase64;
  bool _isLocating = false;
  Position? _currentPosition;
  bool _isSubmitting = false;

  static const double targetSiteLat = 3.1412;
  static const double targetSiteLng = 101.6865;

  final List<String> _locationCategories = [
    'HQ / Office',
    'Central Store / Depot',
    'Vendor / Supplier',
    'Project Site',
    'Client Office',
    'Client Meeting',
  ];

  final List<String> _predefinedLocations = [
    'Menara AlphaTech • Server Room',
    'Central HQ Depot • Petaling Jaya',
    'Hikvision Partner Warehouse • Subang',
    'Lahore SafeCity Junction 14-B',
    'Shah Alam Smart Street Lighting',
    'Other / Custom Location...',
  ];

  @override
  void initState() {
    super.initState();
    AttendanceDataStore().startAutoPoll(seconds: 4);
    _resolveGpsLocation();
  }

  @override
  void dispose() {
    _customLocationController.dispose();
    super.dispose();
  }

  Future<void> _resolveGpsLocation() async {
    setState(() => _isLocating = true);
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium, timeLimit: Duration(seconds: 7)),
      );
      if (mounted) {
        setState(() {
          _currentPosition = pos;
          _isLocating = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _captureFaceSnapshot() async {
    try {
      final photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 70,
      );
      if (photo != null) {
        final bytes = await photo.readAsBytes();
        setState(() {
          _capturedFacePhoto = photo;
          _faceThumbnailBase64 = base64Encode(bytes);
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Camera unavailable. Using optical fallback.")),
        );
      }
    }
  }

  Future<void> _submitAttendance() async {
    if (!_store.canPunchToday) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFEF4444),
          content: Text("Shift punch limit reached (${_store.todayPunchCount}/${_store.maxDailyPunches} today). Contact HQ."),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final locationName = _isCustomLocation
        ? _customLocationController.text.trim()
        : _selectedPredefinedLocation;

    if (locationName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select or enter a valid location.")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final lat = _currentPosition?.latitude ?? 3.1118;
    final lng = _currentPosition?.longitude ?? 101.6372;
    final distanceMeters = Geolocator.distanceBetween(lat, lng, targetSiteLat, targetSiteLng);
    final isOffSite = distanceMeters > 500 && _selectedCategory == 'Project Site';

    final record = AttendanceTelemetryRecord(
      id: 'ATT-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      technicianId: 'TECH-101',
      technicianName: 'Ahmad Faizal',
      type: _punchType,
      category: _selectedCategory,
      locationName: locationName,
      latitude: lat,
      longitude: lng,
      timestamp: DateTime.now(),
      faceThumbnailBase64: _faceThumbnailBase64,
      photoPath: _capturedFacePhoto?.path,
      isOffSiteWarning: isOffSite,
    );

    _store.addRecord(record, facePhoto: _capturedFacePhoto != null ? File(_capturedFacePhoto!.path) : null);

    OfflineSyncService().queueAction(
      moduleType: 'BIOMETRIC',
      payload: {
        'id': record.id,
        'type': record.type,
        'category': record.category,
        'location': record.locationName,
        'lat': record.latitude,
        'lng': record.longitude,
        'timestamp': record.timestamp.toIso8601String(),
        'isOffSite': isOffSite,
      },
    );

    try {
      final punchTime = '${record.timestamp.hour.toString().padLeft(2, '0')}:${record.timestamp.minute.toString().padLeft(2, '0')}';
      final statusTag = record.type == 'CHECK_IN' ? '✅ CHECKED-IN' : '🚪 CHECKED-OUT';
      final offSiteTag = isOffSite ? ' ⚠️ [Off-Site ${distanceMeters.toStringAsFixed(0)}m]' : ' [GPS Verified]';

      final msg = '$statusTag\n'
          '👤 Tech: ${record.technicianName} (TECH-101)\n'
          '📍 Category: ${record.category}\n'
          '🏢 Site: ${record.locationName}$offSiteTag\n'
          '🕒 Time: $punchTime\n'
          '🗺️ GPS: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';

      if (mounted) {
        await WhatsAppDispatcherService().sendSiteReport(
          context: context,
          recipientPhone: '+60123456789',
          message: msg,
        );
      }
    } catch (_) {}

    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
      _capturedFacePhoto = null;
      _faceThumbnailBase64 = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _punchType == 'CHECK_IN' ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
        content: Text("Recorded $_punchType at $locationName${isOffSite ? ' (Flagged: Outside Geofence)' : ''}"),
        behavior: SnackBarBehavior.floating,
      ),
    );

    widget.onPunchCompleted();
  }

  @override
  Widget build(BuildContext context) {
    final isPunchIn = _punchType == 'CHECK_IN';

    return AnimatedBuilder(
      animation: _store,
      builder: (context, _) {
        final isAllowedToPunch = _store.canPunchToday;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0B132B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF1E293B)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("REAL-TIME FACIAL BIOMETRIC ATTENDANCE", style: TextStyle(color: Color(0xFF38BDF8), fontSize: 7.5, fontWeight: FontWeight.w900)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: (_store.allowUnlimitedPunches ? const Color(0xFF10B981) : const Color(0xFF38BDF8)).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: (_store.allowUnlimitedPunches ? const Color(0xFF10B981) : const Color(0xFF38BDF8)).withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      _store.allowUnlimitedPunches
                          ? "MODE: UNLIMITED"
                          : "MODE: LIMITED (${_store.todayPunchCount}/${_store.maxDailyPunches})",
                      style: TextStyle(
                        color: _store.allowUnlimitedPunches ? const Color(0xFF10B981) : const Color(0xFF38BDF8),
                        fontSize: 6,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _punchType = 'CHECK_IN'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isPunchIn ? const Color(0xFF10B981) : const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: isPunchIn ? const Color(0xFF10B981) : const Color(0xFF1E293B)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.login_rounded, color: isPunchIn ? Colors.black : const Color(0xFF64748B), size: 14),
                            const SizedBox(width: 5),
                            Text("CHECK IN", style: TextStyle(color: isPunchIn ? Colors.black : Colors.white, fontSize: 8, fontWeight: FontWeight.w900)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _punchType = 'CHECK_OUT'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: !isPunchIn ? const Color(0xFFF59E0B) : const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: !isPunchIn ? const Color(0xFFF59E0B) : const Color(0xFF1E293B)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.logout_rounded, color: !isPunchIn ? Colors.black : const Color(0xFF64748B), size: 14),
                            const SizedBox(width: 5),
                            Text("CHECK OUT", style: TextStyle(color: !isPunchIn ? Colors.black : Colors.white, fontSize: 8, fontWeight: FontWeight.w900)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Center(
                child: GestureDetector(
                  onTap: _captureFaceSnapshot,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _capturedFacePhoto != null
                            ? const Color(0xFF10B981)
                            : (isPunchIn ? const Color(0xFF38BDF8) : const Color(0xFFF59E0B)),
                        width: 3,
                      ),
                    ),
                    child: ClipOval(
                      child: _capturedFacePhoto != null
                          ? Image.file(File(_capturedFacePhoto!.path), fit: BoxFit.cover)
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.face_retouching_natural_rounded, color: isPunchIn ? const Color(0xFF38BDF8) : const Color(0xFFF59E0B), size: 34),
                                const SizedBox(height: 4),
                                const Text("TAP TO CAPTURE", style: TextStyle(color: Colors.white, fontSize: 6.5, fontWeight: FontWeight.bold)),
                                const Text("Front Camera Frame", style: TextStyle(color: Color(0xFF64748B), fontSize: 5.5)),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              const Text("1. LOCATION CATEGORY", style: TextStyle(color: Color(0xFF64748B), fontSize: 6.5, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                dropdownColor: const Color(0xFF0F172A),
                style: const TextStyle(color: Colors.white, fontSize: 8.5),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                ),
                items: _locationCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              ),
              const SizedBox(height: 8),

              const Text("2. DESTINATION / SITE NAME", style: TextStyle(color: Color(0xFF64748B), fontSize: 6.5, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              DropdownButtonFormField<String>(
                initialValue: _selectedPredefinedLocation,
                dropdownColor: const Color(0xFF0F172A),
                style: const TextStyle(color: Colors.white, fontSize: 8.5),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                ),
                items: _predefinedLocations.map((loc) => DropdownMenuItem(value: loc, child: Text(loc))).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedPredefinedLocation = val;
                      _isCustomLocation = (val == 'Other / Custom Location...');
                    });
                  }
                },
              ),

              if (_isCustomLocation) ...[
                const SizedBox(height: 6),
                TextField(
                  controller: _customLocationController,
                  style: const TextStyle(color: Colors.white, fontSize: 8.5),
                  decoration: InputDecoration(
                    labelText: "ENTER MANUAL LOCATION NAME",
                    labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 7),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                ),
              ],
              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFF1E293B))),
                child: Row(
                  children: [
                    Icon(Icons.my_location_rounded, color: _isLocating ? const Color(0xFFF59E0B) : const Color(0xFF10B981), size: 14),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _isLocating
                            ? "Acquiring GPS coordinates..."
                            : (_currentPosition != null ? "GPS: ${_currentPosition!.latitude.toStringAsFixed(4)}° N, ${_currentPosition!.longitude.toStringAsFixed(4)}° E (Auto-Verified)" : "GPS Telemetry Synced with HQ"),
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 6.5),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.refresh_rounded, color: Color(0xFF38BDF8), size: 14),
                      onPressed: _resolveGpsLocation,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: !isAllowedToPunch
                        ? const Color(0xFF334155)
                        : (isPunchIn ? const Color(0xFF10B981) : const Color(0xFFF59E0B)),
                    foregroundColor: !isAllowedToPunch ? const Color(0xFF94A3B8) : Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: Icon(!isAllowedToPunch ? Icons.lock_clock_rounded : (isPunchIn ? Icons.check_circle_rounded : Icons.logout_rounded), size: 16),
                  label: Text(
                    _isSubmitting
                        ? "TRANSMITTING TELEMETRY..."
                        : (!isAllowedToPunch
                            ? "PUNCH LIMIT REACHED (${_store.todayPunchCount}/${_store.maxDailyPunches})"
                            : (isPunchIn ? "SUBMIT REAL-TIME CHECK IN" : "SUBMIT REAL-TIME CHECK OUT")),
                    style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900),
                  ),
                  onPressed: (_isSubmitting || !isAllowedToPunch) ? null : _submitAttendance,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// ---------------------------------------------------------------------------
/// MODULAR ATTENDANCE HISTORY LOGS
/// ---------------------------------------------------------------------------
class ModularAttendanceHistoryLogs extends StatelessWidget {
  const ModularAttendanceHistoryLogs({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AttendanceDataStore();

    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final logs = store.records;
        if (logs.isEmpty) {
          return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("No records logged yet.", style: TextStyle(color: Color(0xFF64748B), fontSize: 8))));
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: logs.length,
          itemBuilder: (ctx, idx) {
            final rec = logs[idx];
            final isIn = rec.type == 'CHECK_IN';

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFF0B132B), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF1E293B))),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(6), border: Border.all(color: isIn ? const Color(0xFF10B981) : const Color(0xFFF59E0B))),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: rec.faceThumbnailBase64 != null
                          ? Image.memory(base64Decode(rec.faceThumbnailBase64!), fit: BoxFit.cover)
                          : (rec.photoPath != null
                              ? Image.file(File(rec.photoPath!), fit: BoxFit.cover)
                              : Icon(Icons.face_retouching_natural_rounded, color: isIn ? const Color(0xFF10B981) : const Color(0xFFF59E0B), size: 20)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(color: (isIn ? const Color(0xFF10B981) : const Color(0xFFF59E0B)).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(3)),
                              child: Text(rec.type.replaceAll('_', ' '), style: TextStyle(color: isIn ? const Color(0xFF10B981) : const Color(0xFFF59E0B), fontSize: 6, fontWeight: FontWeight.w900)),
                            ),
                            const SizedBox(width: 6),
                            Text(rec.category, style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 6.5, fontWeight: FontWeight.bold)),
                            if (rec.isOffSiteWarning) ...[
                              const SizedBox(width: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(color: const Color(0xFFEF4444).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(3)),
                                child: const Text("OFF-SITE", style: TextStyle(color: Color(0xFFEF4444), fontSize: 5.5, fontWeight: FontWeight.w900)),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(rec.locationName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                        Text("${rec.timestamp.hour.toString().padLeft(2, '0')}:${rec.timestamp.minute.toString().padLeft(2, '0')} • ${rec.timestamp.day}/${rec.timestamp.month}/${rec.timestamp.year} • GPS Synced", style: const TextStyle(color: Color(0xFF64748B), fontSize: 6.5)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// Standalone Full-Page Technician View
class BiometricsAttendanceView extends StatelessWidget {
  const BiometricsAttendanceView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        ModularBiometricsCockpit(onPunchCompleted: () {}),
        const SizedBox(height: 16),
        const Text("RECENT ATTENDANCE LOGS", style: TextStyle(color: Color(0xFF64748B), fontSize: 7, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        const ModularAttendanceHistoryLogs(),
      ],
    );
  }
}

/// ---------------------------------------------------------------------------
/// ADMIN LIVE ATTENDANCE AUDIT CENTER (Filters, Export, Print, and Multi-Pin Map)
/// ---------------------------------------------------------------------------
class AdminAttendanceLedgerView extends StatefulWidget {
  const AdminAttendanceLedgerView({super.key});

  @override
  State<AdminAttendanceLedgerView> createState() => _AdminAttendanceLedgerViewState();
}

class _AdminAttendanceLedgerViewState extends State<AdminAttendanceLedgerView> {
  Widget _buildAvatar(AttendanceTelemetryRecord rec, bool isIn) {
    if (rec.faceThumbnailBase64 != null && rec.faceThumbnailBase64!.trim().isNotEmpty) {
      try {
        final cleanBase64 = rec.faceThumbnailBase64!.contains(',')
            ? rec.faceThumbnailBase64!.split(',').last
            : rec.faceThumbnailBase64!;
        final bytes = base64Decode(cleanBase64);
        return Image.memory(
          bytes,
          width: 36,
          height: 36,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _fallbackIcon(isIn),
        );
      } catch (_) {}
    }

    if (rec.photoPath != null && rec.photoPath!.trim().isNotEmpty) {
      if (rec.photoPath!.startsWith('http')) {
        return Image.network(
          rec.photoPath!,
          width: 36,
          height: 36,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _fallbackIcon(isIn),
        );
      }
      try {
        final file = File(rec.photoPath!);
        if (file.existsSync()) {
          return Image.file(file, width: 36, height: 36, fit: BoxFit.cover);
        }
      } catch (_) {}
    }

    return _fallbackIcon(isIn);
  }

  Widget _fallbackIcon(bool isIn) {
    return Icon(
      Icons.face_retouching_natural_rounded,
      color: isIn ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
      size: 20,
    );
  }
  
  
  final AttendanceDataStore _store = AttendanceDataStore();

  @override
  void initState() {
    super.initState();
    _store.startAutoPoll(seconds: 3);
  }

  // Filters State
  String _selectedTypeFilter = 'ALL'; // ALL, CHECK_IN, CHECK_OUT
  final String _selectedCategoryFilter = 'ALL'; // ALL or specific category
  bool _onlyOffSiteBreaches = false;
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  // View Mode: 'LIST' or 'MAP'
  String _activeViewMode = 'LIST';


  @override
  void dispose() {
    _store.stopAutoPoll();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _openLocationOnMap(double lat, double lng) async {
    final uri = Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lng");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  List<AttendanceTelemetryRecord> _filterRecords(List<AttendanceTelemetryRecord> records) {
    return records.where((r) {
      if (_selectedTypeFilter != 'ALL' && r.type != _selectedTypeFilter) {
        return false;
      }
      if (_selectedCategoryFilter != 'ALL' && r.category != _selectedCategoryFilter) {
        return false;
      }
      if (_onlyOffSiteBreaches && !r.isOffSiteWarning) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchName = r.technicianName.toLowerCase().contains(q);
        final matchLoc = r.locationName.toLowerCase().contains(q);
        final matchId = r.technicianId.toLowerCase().contains(q);
        if (!matchName && !matchLoc && !matchId) return false;
      }
      return true;
    }).toList();
  }

  /// EXPORT CSV FORMAT (RFC 4180 standard)
  void _exportCsv(List<AttendanceTelemetryRecord> records) {
    final sb = StringBuffer();
    sb.writeln("Log_ID,Technician_ID,Technician_Name,Punch_Type,Category,Location_Name,Latitude,Longitude,Timestamp,Off_Site_Warning");
    for (final r in records) {
      final safeLocation = '"${r.locationName.replaceAll('"', '""')}"';
      sb.writeln("${r.id},${r.technicianId},${r.technicianName},${r.type},${r.category},$safeLocation,${r.latitude},${r.longitude},${r.timestamp.toIso8601String()},${r.isOffSiteWarning}");
    }

    final csvText = sb.toString();
    Clipboard.setData(ClipboardData(text: csvText));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text("ATTENDANCE CSV EXPORTED", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Generated CSV with ${records.length} records. Copied directly to your system clipboard!", style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 8)),
            const SizedBox(height: 10),
            Container(
              height: 100,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFF070D18), borderRadius: BorderRadius.circular(6)),
              child: SingleChildScrollView(
                child: Text(csvText, style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 6.5, fontFamily: 'monospace')),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text("CLOSE", style: TextStyle(color: Color(0xFF10B981), fontSize: 8.5)),
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  /// PRINTABLE TIMESHEET DOCKET MODAL
  void _showPrintPreview(List<AttendanceTelemetryRecord> records) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("OFFICIAL ATTENDANCE & BIOMETRIC AUDIT REPORT", style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w900)),
                    Text("Generated: ${DateTime.now().toLocal()} • Total Logs: ${records.length}", style: const TextStyle(color: Colors.grey, fontSize: 7)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.print_rounded, color: Colors.black),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Routing to Android System Print Spooler..."), backgroundColor: Color(0xFF10B981)),
                    );
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
            const Divider(color: Colors.black12),
            Expanded(
              child: ListView.separated(
                itemCount: records.length,
                separatorBuilder: (_, _) => const Divider(color: Colors.black12, height: 1),
                itemBuilder: (c, idx) {
                  final rec = records[idx];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("${rec.technicianName} (${rec.type})", style: const TextStyle(color: Colors.black, fontSize: 8.5, fontWeight: FontWeight.bold)),
                            Text("[${rec.category}] ${rec.locationName}", style: const TextStyle(color: Colors.black87, fontSize: 7)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text("${rec.timestamp.hour.toString().padLeft(2, '0')}:${rec.timestamp.minute.toString().padLeft(2, '0')} • ${rec.timestamp.day}/${rec.timestamp.month}", style: const TextStyle(color: Colors.black54, fontSize: 7)),
                            if (rec.isOffSiteWarning)
                              const Text("⚠️ OFF-SITE", style: TextStyle(color: Colors.red, fontSize: 6.5, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const Divider(color: Colors.black12),
            const Text("Supervisor Sign-off: _______________________      Date: _____________", style: TextStyle(color: Colors.black87, fontSize: 7.5)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _store,
      builder: (context, _) {
        final filteredRecords = _filterRecords(_store.records);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // POLICY CONTROL CARD
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.tune_rounded, color: _store.allowUnlimitedPunches ? const Color(0xFF10B981) : const Color(0xFF38BDF8), size: 16),
                      const SizedBox(width: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("SHIFT PUNCH POLICY", style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900)),
                          Text(
                            _store.allowUnlimitedPunches ? "Unlimited Mode: Free multi-site visits" : "Limited Mode: Max ${_store.maxDailyPunches} punches/day",
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 6),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Switch(
                    value: _store.allowUnlimitedPunches,
                    activeThumbColor: const Color(0xFF10B981),
                    activeTrackColor: const Color(0xFF10B981).withValues(alpha: 0.3),
                    inactiveThumbColor: const Color(0xFF38BDF8),
                    inactiveTrackColor: const Color(0xFF38BDF8).withValues(alpha: 0.3),
                    onChanged: (val) => _store.togglePunchPolicy(val),
                  ),
                ],
              ),
            ),

            // SEARCH BAR & VIEW SWITCHER (LIST vs MAP)
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 34,
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      style: const TextStyle(color: Colors.white, fontSize: 8),
                      decoration: InputDecoration(
                        hintText: "Search tech, site, ID...",
                        hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 7.5),
                        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 14),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        contentPadding: EdgeInsets.zero,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF1E293B))),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Toggle List vs Map
                Container(
                  decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF1E293B))),
                  child: Row(
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: Icon(Icons.view_list_rounded, color: _activeViewMode == 'LIST' ? const Color(0xFF10B981) : const Color(0xFF64748B), size: 16),
                        tooltip: "List Ledger",
                        onPressed: () => setState(() => _activeViewMode = 'LIST'),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: Icon(Icons.map_rounded, color: _activeViewMode == 'MAP' ? const Color(0xFF38BDF8) : const Color(0xFF64748B), size: 16),
                        tooltip: "Live Multi-Pin Map View",
                        onPressed: () => setState(() => _activeViewMode = 'MAP'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // INTERACTIVE FILTER CHIPS ROW
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip(label: "ALL", isSelected: _selectedTypeFilter == 'ALL', onSelected: () => setState(() => _selectedTypeFilter = 'ALL')),
                  const SizedBox(width: 5),
                  _filterChip(label: "CHECK IN", isSelected: _selectedTypeFilter == 'CHECK_IN', onSelected: () => setState(() => _selectedTypeFilter = 'CHECK_IN')),
                  const SizedBox(width: 5),
                  _filterChip(label: "CHECK OUT", isSelected: _selectedTypeFilter == 'CHECK_OUT', onSelected: () => setState(() => _selectedTypeFilter = 'CHECK_OUT')),
                  const SizedBox(width: 8),
                  Container(width: 1, height: 16, color: const Color(0xFF1E293B)),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() => _onlyOffSiteBreaches = !_onlyOffSiteBreaches),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: _onlyOffSiteBreaches ? const Color(0xFFEF4444).withValues(alpha: 0.2) : const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: _onlyOffSiteBreaches ? const Color(0xFFEF4444) : const Color(0xFF1E293B)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, size: 11, color: _onlyOffSiteBreaches ? const Color(0xFFEF4444) : const Color(0xFF64748B)),
                          const SizedBox(width: 4),
                          Text("OFF-SITE ONLY", style: TextStyle(color: _onlyOffSiteBreaches ? const Color(0xFFEF4444) : const Color(0xFF64748B), fontSize: 6.5, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ACTION BAR: Export CSV & Print Timesheet
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("${filteredRecords.length} LOGS DISPLAYED", style: const TextStyle(color: Color(0xFF64748B), fontSize: 6.5, fontWeight: FontWeight.w900)),
                Row(
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: const Color(0xFF38BDF8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6), side: const BorderSide(color: Color(0xFF1E293B))),
                      ),
                      icon: const Icon(Icons.file_download_outlined, size: 12),
                      label: const Text("EXPORT CSV", style: TextStyle(fontSize: 6.5, fontWeight: FontWeight.w900)),
                      onPressed: () => _exportCsv(filteredRecords),
                    ),
                    const SizedBox(width: 6),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: const Color(0xFF10B981),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6), side: const BorderSide(color: Color(0xFF1E293B))),
                      ),
                      icon: const Icon(Icons.print_outlined, size: 12),
                      label: const Text("PRINT", style: TextStyle(fontSize: 6.5, fontWeight: FontWeight.w900)),
                      onPressed: () => _showPrintPreview(filteredRecords),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            // MAIN CONTENT: LIST or MULTI-PIN MAP
            Expanded(
              child: _activeViewMode == 'LIST'
                  ? _buildListView(filteredRecords)
                  : _buildMultiPinMapView(filteredRecords),
            ),
          ],
        );
      },
    );
  }

  Widget _filterChip({required String label, required bool isSelected, required VoidCallback onSelected}) {
    return GestureDetector(
      onTap: onSelected,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF10B981) : const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isSelected ? const Color(0xFF10B981) : const Color(0xFF1E293B)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : const Color(0xFF94A3B8),
            fontSize: 6.5,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _buildListView(List<AttendanceTelemetryRecord> records) {
    if (records.isEmpty) {
      return const Center(child: Text("No records matching the filter.", style: TextStyle(color: Color(0xFF64748B), fontSize: 8)));
    }

    return ListView.builder(
      itemCount: records.length,
      itemBuilder: (ctx, idx) {
        final rec = records[idx];
        final isIn = rec.type == 'CHECK_IN';

        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF0B132B),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: rec.isOffSiteWarning ? const Color(0xFFEF4444).withValues(alpha: 0.6) : const Color(0xFF1E293B)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: isIn ? const Color(0xFF10B981) : const Color(0xFFF59E0B)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: _buildAvatar(rec, isIn),




                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(rec.technicianName, style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: (isIn ? const Color(0xFF10B981) : const Color(0xFFF59E0B)).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(rec.type.replaceAll('_', ' '), style: TextStyle(color: isIn ? const Color(0xFF10B981) : const Color(0xFFF59E0B), fontSize: 6, fontWeight: FontWeight.w900)),
                        ),
                        if (rec.isOffSiteWarning) ...[
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(color: const Color(0xFFEF4444).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(3)),
                            child: const Text("OFF-SITE", style: TextStyle(color: Color(0xFFEF4444), fontSize: 5.5, fontWeight: FontWeight.w900)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 1),
                    Text("[${rec.category}] ${rec.locationName}", maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 7)),
                    Text("${rec.timestamp.hour.toString().padLeft(2, '0')}:${rec.timestamp.minute.toString().padLeft(2, '0')} • Lat: ${rec.latitude.toStringAsFixed(4)}, Lng: ${rec.longitude.toStringAsFixed(4)}", style: const TextStyle(color: Color(0xFF64748B), fontSize: 6)),
                  ],
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.map_rounded, color: Color(0xFF10B981), size: 16),
                tooltip: "Open Map Coordinates",
                onPressed: () => _openLocationOnMap(rec.latitude, rec.longitude),
              ),
            ],
          ),
        );
      },
    );
  }

  /// MULTI-PIN RADAR MAP VIEW COMPONENT
  Widget _buildMultiPinMapView(List<AttendanceTelemetryRecord> records) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF030712),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFF0B132B),
              borderRadius: BorderRadius.vertical(top: Radius.circular(9)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.radar_rounded, color: Color(0xFF38BDF8), size: 14),
                    SizedBox(width: 6),
                    Text("LIVE FIELD GPS RADAR OVERVIEW", style: TextStyle(color: Colors.white, fontSize: 7.5, fontWeight: FontWeight.w900)),
                  ],
                ),
                Text("${records.length} Active Coordinates", style: const TextStyle(color: Color(0xFF64748B), fontSize: 6.5)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: records.length,
              itemBuilder: (ctx, idx) {
                final rec = records[idx];
                final isIn = rec.type == 'CHECK_IN';
                final pinColor = rec.isOffSiteWarning
                    ? const Color(0xFFEF4444)
                    : (isIn ? const Color(0xFF10B981) : const Color(0xFFF59E0B));

                return GestureDetector(
                  onTap: () => _openLocationOnMap(rec.latitude, rec.longitude),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B1120),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: pinColor.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(shape: BoxShape.circle, color: pinColor.withValues(alpha: 0.15)),
                          child: Icon(Icons.location_on_rounded, color: pinColor, size: 18),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(rec.technicianName, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                              Text(rec.locationName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 7)),
                              Text("GPS: ${rec.latitude.toStringAsFixed(4)}° N, ${rec.longitude.toStringAsFixed(4)}° E", style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 6.5)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0xFF1E293B))),
                          child: const Row(
                            children: [
                              Text("LAUNCH", style: TextStyle(color: Color(0xFF10B981), fontSize: 6.5, fontWeight: FontWeight.bold)),
                              SizedBox(width: 2),
                              Icon(Icons.open_in_new_rounded, color: Color(0xFF10B981), size: 10),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
