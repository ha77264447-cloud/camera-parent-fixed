import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:http/http.dart' as http;

class CameraService {
  static const String server = "https://camera-parent-server.onrender.com";

  // ═══════════════════════════════════════════════════════════
  // ICE Servers - مع fallback متعدد
  // ═══════════════════════════════════════════════════════════

  static Future<List<Map<String, dynamic>>> fetchIceServers() async {
    try {
      final res = await http
          .get(Uri.parse("$server/ice-servers"))
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final data = body["data"];
        if (data is List) {
          return data.map((e) => Map<String, dynamic>.from(e)).toList();
        }
      }
    } catch (e) {
      debugPrint("[CameraService] fetchIceServers failed: $e");
    }

    // ✅ fallback: STUN servers متعددة
    return [
      {"urls": "stun:stun.l.google.com:19302"},
      {"urls": "stun:stun1.l.google.com:19302"},
      {"urls": "stun:stun2.l.google.com:19302"},
    ];
  }

  // ═══════════════════════════════════════════════════════════
  // getUserMedia
  // ═══════════════════════════════════════════════════════════

  static Future<MediaStream> getUserMedia({
    bool audio = true,
    bool video = true,
    Map<String, dynamic>? videoConstraints,
  }) async {
    final constraints = <String, dynamic>{
      "audio": audio,
      "video": video ? (videoConstraints ?? true) : false,
    };
    return navigator.mediaDevices.getUserMedia(constraints);
  }
}
