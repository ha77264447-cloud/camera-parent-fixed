Future<void> stop() async {
  _running = false;
  _keepScreenStreamAlive = false;
  
  _ws?.close();
  _ws = null;
  
  _reconnectTimer?.cancel();
  _pingTimer?.cancel();
  _screenAutoStopTimer?.cancel();
  
  for (var pc in _peerConnections.values) {
    try {
      await pc.close();
    } catch (e) {
      debugPrint("[StreamService] Error closing PC: $e");
    }
  }
  _peerConnections.clear();
  
  try {
    localStream?.getTracks().forEach((track) {
      track.stop();
    });
  } catch (e) {
    debugPrint("[StreamService] Error stopping tracks: $e");
  }
  localStream = null;
  
  _remoteStreams.clear();
  _callerNames.clear();
  
  debugPrint("[StreamService] Stopped successfully");
}
