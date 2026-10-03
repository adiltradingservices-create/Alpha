import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class SyncService {
  static const String endpoint = "https://api.alphatechnetworks.com/api/work-orders/submit";

  static Future<bool> isOffline() async {
    final conn = await Connectivity().checkConnectivity();
    return conn.contains(ConnectivityResult.none);
  }

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