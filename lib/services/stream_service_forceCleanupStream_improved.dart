// ✅ استبدل دالة _forceCleanupStream() الحالية بهذا الكود المُحسّن
// أضف في الأعلى: import 'dart:io';

Future<void> _forceCleanupStream() async {
  debugPrint('[StreamService] _forceCleanupStream: cleaning up media resources');
  
  // ✅ إيقاف المؤقت
  _screenAutoStopTimer?.cancel();
  _screenAutoStopTimer = null;
  _screenStreamStartedAt = null;

  final old = localStream;
  localStream = null;
  _broadcastScreen = false;
  _broadcastFiles = false;

  if (old != null) {
    try {
      final tracks = old.getTracks();
      debugPrint('[StreamService] Stopping ${tracks.length} tracks');
      
      // ✅ 1. إيقاف كل مسار بشكل صريح
      for (int i = 0; i < tracks.length; i++) {
        final t = tracks[i];
        try {
          debugPrint('[StreamService] Stopping track $i: ${t.kind}');
          await t.stop();
          debugPrint('[StreamService] Track $i stopped successfully');
          
          // ✅ انتظر قليلاً لضمان إيقاف المسار
          await Future.delayed(const Duration(milliseconds: 150));
        } catch (e) {
          debugPrint('[StreamService] Track $i stop error: $e');
        }
      }

      // ✅ 2. تنظيف الكاميرا على مستوى Android
      if (Platform.isAndroid) {
        try {
          debugPrint('[StreamService] Releasing camera on Android...');
          const cameraChannel = MethodChannel('camera_parent/camera');
          await cameraChannel.invokeMethod('releaseCamera');
          debugPrint('[StreamService] Camera released on Android');
        } catch (e) {
          debugPrint('[StreamService] releaseCamera error: $e');
        }
      }

      // ✅ 3. حرر الـ MediaStream
      try {
        debugPrint('[StreamService] Disposing MediaStream...');
        await old.dispose();
        debugPrint('[StreamService] MediaStream disposed successfully');
      } catch (e) {
        debugPrint('[StreamService] MediaStream dispose error: $e');
      }
      
      // ✅ انتظر قليلاً لضمان تحرر الموارد بالكامل
      await Future.delayed(const Duration(milliseconds: 300));
      
    } catch (e) {
      debugPrint('[StreamService] Error in cleanup stream: $e');
    }
  }

  // ✅ إخطار المستمعين بأن البث توقف
  _localStreamCtrl.add(null);
  debugPrint('[StreamService] Media cleanup completed');
}
