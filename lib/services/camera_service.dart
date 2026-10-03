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

  // ═══════════════════════════════════════════════════════════
  // تسجيل دخول الوالد
  // ═══════════════════════════════════════════════════════════
  static Future<Map<String, dynamic>> parentLogin(
      String username, String password) async {
    try {
      final res = await http.post(
        Uri.parse("$server/parent/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": username, "password": password}),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        throw Exception("Login failed: ${res.statusCode}");
      }
    } catch (e) {
      debugPrint("[CameraService] parentLogin failed: $e");
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // تسجيل حساب والد جديد
  // ═══════════════════════════════════════════════════════════
  static Future<Map<String, dynamic>> parentRegister(
      String username, String password) async {
    try {
      final res = await http.post(
        Uri.parse("$server/parent/register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": username, "password": password}),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 201 || res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        throw Exception("Register failed: ${res.statusCode}");
      }
    } catch (e) {
      debugPrint("[CameraService] parentRegister failed: $e");
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // نسيان جهاز (حذفه)
  // ═══════════════════════════════════════════════════════════
  static Future<void> forgetDevice(String deviceId, String token) async {
    try {
      final res = await http.delete(
        Uri.parse("$server/device/$deviceId"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode != 200 && res.statusCode != 204) {
        throw Exception("Forget device failed: ${res.statusCode}");
      }
    } catch (e) {
      debugPrint("[CameraService] forgetDevice failed: $e");
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // فصل الجهاز (unpair)
  // ═══════════════════════════════════════════════════════════
  static Future<void> unpairDevice(String token) async {
    try {
      final res = await http.post(
        Uri.parse("$server/device/unpair"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) {
        throw Exception("Unpair failed: ${res.statusCode}");
      }
    } catch (e) {
      debugPrint("[CameraService] unpairDevice failed: $e");
      rethrow;
    }
  }
}
