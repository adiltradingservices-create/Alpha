import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../modules/biometrics/biometrics_module.dart';

class SyncService {
  static const String baseUrl = "https://api.alphatechnetworks.com";
  static const String endpoint = "$baseUrl/api/work-orders/submit";
  static const String attendanceEndpoint = "$baseUrl/api/attendance";

  static Future<bool> isOffline() async {
    final conn = await Connectivity().checkConnectivity();
    return conn.contains(ConnectivityResult.none);
  }

  // ---------------------------------------------------------------------------
  // ATTENDANCE: MOBILE PUSH (TECHNICIAN)
  // ---------------------------------------------------------------------------
  static Future<bool> submitAttendancePunch({
    required AttendanceTelemetryRecord record,
    File? facePhoto,
  }) async {
    if (await isOffline()) {
      await _queueOfflineAttendance(record);
      return false;
    }

    try {
      final uri = Uri.parse('$attendanceEndpoint/check-in');
      final req = http.MultipartRequest('POST', uri);

      req.fields['id'] = record.id;
      req.fields['technicianId'] = record.technicianId;
      req.fields['technicianName'] = record.technicianName;
      req.fields['type'] = record.type;
      req.fields['category'] = record.category;
      req.fields['locationName'] = record.locationName;
      req.fields['latitude'] = record.latitude.toString();
      req.fields['longitude'] = record.longitude.toString();
      req.fields['timestamp'] = record.timestamp.toIso8601String();
      req.fields['isOffSiteWarning'] = record.isOffSiteWarning.toString();

      if (record.faceThumbnailBase64 != null && record.faceThumbnailBase64!.isNotEmpty) {
        req.fields['faceThumbnailBase64'] = record.faceThumbnailBase64!;
      }

      File? fileToUpload = facePhoto;
      if (fileToUpload == null && record.photoPath != null && record.photoPath!.isNotEmpty) {
        final candidate = File(record.photoPath!);
        if (candidate.existsSync()) fileToUpload = candidate;
      }

      if (fileToUpload != null && fileToUpload.existsSync()) {
        req.files.add(await http.MultipartFile.fromPath('faceImage', fileToUpload.path));
      }

      final streamed = await req.send().timeout(const Duration(seconds: 15));
      final res = await http.Response.fromStream(streamed);

      return res.statusCode == 200 || res.statusCode == 201;
    } catch (_) {
      await _queueOfflineAttendance(record);
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // ATTENDANCE: LAPTOP PULL (ADMIN PORTAL & RADAR)
  // ---------------------------------------------------------------------------
  static Future<List<AttendanceTelemetryRecord>> fetchAttendanceLogs() async {
    try {
      final res = await http
          .get(Uri.parse(attendanceEndpoint))
          .timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final List<dynamic> list = (decoded is List) ? decoded : (decoded['data'] ?? []);

        return list.map((item) {
          final photo = item['photoPath']?.toString();
          final base64 = item['faceThumbnailBase64']?.toString();
          return AttendanceTelemetryRecord(
            id: item['id']?.toString() ?? 'LOG-${DateTime.now().millisecondsSinceEpoch}',
            technicianId: item['technicianId']?.toString() ?? 'TECH-001',
            technicianName: item['technicianName']?.toString() ?? item['name'] ?? 'Technician',
            type: item['type']?.toString() ?? 'CHECK_IN',
            category: item['category']?.toString() ?? 'Project Site',
            locationName: item['locationName']?.toString() ?? item['site'] ?? 'Field Site',
            latitude: (item['latitude'] as num?)?.toDouble() ?? 3.1390,
            longitude: (item['longitude'] as num?)?.toDouble() ?? 101.6869,
            timestamp: DateTime.tryParse(item['timestamp']?.toString() ?? '') ?? DateTime.now(),
            faceThumbnailBase64: (base64 != null && base64.isNotEmpty) ? base64 : null,
            photoPath: (photo != null && photo.isNotEmpty) ? photo : null,
            isOffSiteWarning: item['isOffSiteWarning'] == true || item['isOffSiteWarning'] == 1 || item['isOffSiteWarning'] == 'true',
          );
        }).toList();
      }
    } catch (_) {}
    return [];
  }

  // ---------------------------------------------------------------------------
  // ATTENDANCE: OFFLINE QUEUE
  // ---------------------------------------------------------------------------
  static Future<void> _queueOfflineAttendance(AttendanceTelemetryRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final queue = prefs.getStringList('fieldops_attendance_queue') ?? [];
    queue.add(jsonEncode(record.toJson()));
    await prefs.setStringList('fieldops_attendance_queue', queue);
  }

  static Future<int> flushAttendanceQueue() async {
    if (await isOffline()) return 0;
    final prefs = await SharedPreferences.getInstance();
    final queue = prefs.getStringList('fieldops_attendance_queue') ?? [];
    if (queue.isEmpty) return 0;

    final List<String> failed = [];
    int successCount = 0;

    for (final item in queue) {
      try {
        final res = await http.post(
          Uri.parse('$attendanceEndpoint/check-in'),
          headers: {'Content-Type': 'application/json'},
          body: item,
        ).timeout(const Duration(seconds: 10));

        if (res.statusCode == 200 || res.statusCode == 201) {
          successCount++;
        } else {
          failed.add(item);
        }
      } catch (_) {
        failed.add(item);
      }
    }

    await prefs.setStringList('fieldops_attendance_queue', failed);
    return successCount;
  }

  // ---------------------------------------------------------------------------
  // WORK ORDER SUBMISSIONS
  // ---------------------------------------------------------------------------
  static Future<int> getQueueCount() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList('fieldops_offline_queue') ?? []).length;
  }

  static Future<void> queueOfflineOrder(Map<String, dynamic> payload, Uint8List? signature) async {
    final prefs = await SharedPreferences.getInstance();
    final queue = prefs.getStringList('fieldops_offline_queue') ?? [];

    if (signature != null) {
      final tempDir = Directory.systemTemp;
      final sigFile = File('${tempDir.path}/sig_${DateTime.now().millisecondsSinceEpoch}.png');
      await sigFile.writeAsBytes(signature);
      payload['sigPath'] = sigFile.path;
    }

    queue.add(jsonEncode(payload));
    await prefs.setStringList('fieldops_offline_queue', queue);
  }

  static Future<Map<String, dynamic>> submitDirect({
    required Map<String, String> fields,
    File? checkInFace,
    File? checkOutFace,
    File? beforePhoto,
    File? afterPhoto,
    Uint8List? signature,
  }) async {
    var req = http.MultipartRequest('POST', Uri.parse(endpoint));
    req.fields.addAll(fields);

    if (checkInFace != null && checkInFace.existsSync()) {
      req.files.add(await http.MultipartFile.fromPath('checkInFace', checkInFace.path));
    }
    if (checkOutFace != null && checkOutFace.existsSync()) {
      req.files.add(await http.MultipartFile.fromPath('checkOutFace', checkOutFace.path));
    }
    if (beforePhoto != null && beforePhoto.existsSync()) {
      req.files.add(await http.MultipartFile.fromPath('beforePhoto', beforePhoto.path));
    }
    if (afterPhoto != null && afterPhoto.existsSync()) {
      req.files.add(await http.MultipartFile.fromPath('afterPhoto', afterPhoto.path));
    }
    if (signature != null) {
      req.files.add(http.MultipartFile.fromBytes('signature', signature, filename: 'signature.png'));
    }

    var streamed = await req.send().timeout(const Duration(seconds: 25));
    var res = await http.Response.fromStream(streamed);

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Server Error (${res.statusCode}): ${res.body}");
    }
  }

  static Future<int> flushQueue() async {
    if (await isOffline()) return 0;
    final prefs = await SharedPreferences.getInstance();
    final queue = prefs.getStringList('fieldops_offline_queue') ?? [];
    if (queue.isEmpty) return 0;

    List<String> failed = [];
    int successCount = 0;

    for (String itemJson in queue) {
      try {
        final data = jsonDecode(itemJson);
        var req = http.MultipartRequest('POST', Uri.parse(endpoint));
        data.forEach((k, v) {
          if (v is String && !k.endsWith('Path') && !k.endsWith('Face') && !k.endsWith('Photo')) {
            req.fields[k] = v;
          }
        });

        for (var key in ['checkInFace', 'checkOutFace', 'beforePhoto', 'afterPhoto']) {
          if (data[key] != null && File(data[key]).existsSync()) {
            req.files.add(await http.MultipartFile.fromPath(key, data[key]));
          }
        }
        if (data['sigPath'] != null && File(data['sigPath']).existsSync()) {
          req.files.add(await http.MultipartFile.fromPath('signature', data['sigPath']));
        }

        var res = await req.send().timeout(const Duration(seconds: 20));
        if (res.statusCode == 200) {
          successCount++;
        } else {
          failed.add(itemJson);
        }
      } catch (_) {
        failed.add(itemJson);
      }
    }

    await prefs.setStringList('fieldops_offline_queue', failed);
    return successCount;
  }
}
