// ✅ استبدل دالة stop() الحالية بهذا الكود المُحسّن

Future<void> stop() async {
  if (!_running) return; // تجنب التكرار
  
  CryptoService.instance.clear();
  _running = false;
  
  // ✅ 1. إيقاف جميع المؤقتات
  debugPrint('[StreamService] Stopping all timers...');
  _reconnectTimer?.cancel();
  _reconnectTimer = null;
  _reconnectAttempts = 0;
  _pingTimer?.cancel();
  _pingTimer = null;
  _consecutivePingFailures = 0;
  _screenAutoStopTimer?.cancel();
  _screenAutoStopTimer = null;

  // ✅ 2. إغلاق WebSocket
  debugPrint('[StreamService] Closing WebSocket...');
  try { 
    await _ws?.close(); 
  } catch (e) {
    debugPrint('[StreamService] ws close error: $e');
  }
  _ws = null;

  // ✅ 3. إغلاق جميع اتصالات Peer
  debugPrint('[StreamService] Closing all peer connections...');
  await _closeAllPeerConnections();
  
  // ✅ 4. تنظيف الكاميرا والشاشة
  debugPrint('[StreamService] Cleaning up media stream...');
  await _forceCleanupStream();
  
  // ✅ 5. تنظيف البيانات
  _canceledDownloads.clear();
  _pendingViewers.clear();

  // ✅ 6. إغلاق StreamControllers (بحذر)
  debugPrint('[StreamService] Closing stream controllers...');
  try {
    if (!_statusCtrl.isClosed) await _statusCtrl.close();
    if (!_callersCtrl.isClosed) await _callersCtrl.close();
    if (!_remoteCtrl.isClosed) await _remoteCtrl.close();
    if (!_pendingCtrl.isClosed) await _pendingCtrl.close();
    if (!_mediaCtrl.isClosed) await _mediaCtrl.close();
    if (!_localStreamCtrl.isClosed) await _localStreamCtrl.close();
    if (!_fileRequestCtrl.isClosed) await _fileRequestCtrl.close();
  } catch (e) {
    debugPrint('[StreamService] Stream controller close error: $e');
  }

  _updateStatus("متوقف");
  ConnectionStateManager.instance.update(ConnectionStatus.idle);
  debugPrint('[StreamService] Stopped completely');
}
