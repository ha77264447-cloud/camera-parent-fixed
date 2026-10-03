// ✅ استبدل دالة _startMediaSource() الحالية بهذا الكود المُحسّن

Future<void> _startMediaSource() async {
  debugPrint('[StreamService] _startMediaSource called');
  
  // ✅ تحقق من الحالة الحالية
  if (localStream != null) {
    debugPrint('[StreamService] localStream already running, skipping');
    _updateStatus("جاهز للبث!");
    return;
  }

  if (_broadcastFiles) {
    debugPrint('[StreamService] Broadcasting files, skipping camera');
    _updateStatus("جاهز لاستعراض الملفات");
    return;
  }

  if (!_running) {
    debugPrint('[StreamService] Service not running, skipping');
    return;
  }

  _updateStatus(_broadcastScreen
      ? "جاري تجهيز مشاركة الشاشة..."
      : "جاري تجهيز الكاميرا...");

  try {
    // ✅ تنظيف أي موارد قديمة قبل البدء
    debugPrint('[StreamService] Cleaning up old resources before starting');
    await _forceCleanupStream();
    
    // ✅ منع بدء مزدوج
    if (localStream != null) {
      debugPrint('[StreamService] localStream already set, returning');
      return;
    }

    debugPrint('[StreamService] Starting ${_broadcastScreen ? "screen" : "camera"} capture');
    
    final stream = _broadcastScreen
        ? await ScreenCaptureService.startScreenCapture()
        : await CameraService.getUserMedia(
            audio: true,
            video: true,
            videoConstraints: <String, dynamic>{
              'mandatory': <String, dynamic>{
                'minWidth': 320,
                'minHeight': 240,
                'maxWidth': 480,
                'maxHeight': 360,
                'minFrameRate': 10,
                'maxFrameRate': 15,
              },
              'optional': <dynamic>[],
            },
          );

    // ✅ تحقق من أن التطبيق لا يزال يعمل
    if (!_running) {
      debugPrint('[StreamService] Service stopped during stream acquisition, disposing');
      try {
        await stream.dispose();
      } catch (e) {
        debugPrint('[StreamService] Error disposing stream: $e');
      }
      return;
    }

    // ✅ تحقق من أن localStream لم يُعيّن من خيط آخر
    if (localStream != null) {
      debugPrint('[StreamService] localStream was set by another thread, disposing new stream');
      try {
        await stream.dispose();
      } catch (e) {
        debugPrint('[StreamService] Error disposing duplicate stream: $e');
      }
      return;
    }

    // ✅ تأكد من أن البث يحتوي على مسارات
    if (stream.getTracks().isEmpty) {
      debugPrint('[StreamService] Stream has no tracks, disposing');
      try {
        await stream.dispose();
      } catch (e) {
        debugPrint('[StreamService] Error disposing empty stream: $e');
      }
      _error = "فشل تهيئة البث: لا توجد مسارات";
      _updateStatus("خطأ");
      _canRetry = true;
      return;
    }

    localStream = stream;
    _localStreamCtrl.add(stream);
    debugPrint('[StreamService] Stream started successfully with ${stream.getTracks().length} tracks');

    if (_broadcastScreen) {
      _screenStreamStartedAt = DateTime.now();
      _screenAutoStopTimer?.cancel();
      _screenAutoStopTimer = Timer(_screenAutoStopAfter, () async {
        debugPrint('[StreamService] Screen stream auto-stop timer fired');
        await _forceCleanupStream();
      });
    }

    _updateStatus("جاهز للبث!");
    _error = null;
    _canRetry = false;
    debugPrint('[StreamService] Ready for streaming');
    
  } catch (e) {
    debugPrint('[StreamService] Error starting media source: $e');
    _error = "فشل تهيئة البث: $e";
    _updateStatus("خطأ");
    _canRetry = true;
    
    // ✅ تنظيف تلقائي عند الخطأ
    try {
      await _forceCleanupStream();
    } catch (cleanup_e) {
      debugPrint('[StreamService] Error during error cleanup: $cleanup_e');
    }
  }
}
