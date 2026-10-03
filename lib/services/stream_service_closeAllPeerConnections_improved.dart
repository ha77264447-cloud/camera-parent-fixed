// ✅ استبدل دالة _closeAllPeerConnections() الحالية بهذا الكود المُحسّن

Future<void> _closeAllPeerConnections() async {
  debugPrint('[StreamService] _closeAllPeerConnections: closing ${_peerConnections.length} connections');
  
  final pcs = List<RTCPeerConnection>.from(_peerConnections.values);
  _peerConnections.clear();
  _callerNames.clear();
  _remoteStreams.clear();
  _pendingRemoteIceByViewer.clear();
  _approvalInFlight.clear();
  _approvedFileViewers.clear();
  _activeViewerId = null;
  _hasRemoteVideo = false;

  // ✅ إرسال تحديثات فارغة للـ listeners
  _callersCtrl.add({});
  _remoteCtrl.add({});
  _mediaCtrl.add(null);

  // ✅ إغلاق كل peer بشكل آمن وتدريجي
  for (int i = 0; i < pcs.length; i++) {
    final pc = pcs[i];
    try {
      debugPrint('[StreamService] Closing peer connection $i/${pcs.length}');
      
      // ✅ 1. أوقف إرسال المسارات
      try {
        final senders = await pc.getSenders();
        for (final sender in senders) {
          try {
            await sender.replaceTrack(null);
            debugPrint('[StreamService] Track replaced with null');
          } catch (e) {
            debugPrint('[StreamService] replaceTrack error: $e');
          }
        }
      } catch (e) {
        debugPrint('[StreamService] getSenders error: $e');
      }
      
      // ✅ 2. أزل جميع معالجات الأحداث
      try {
        pc.onRenegotiationNeeded = null;
        pc.onTrack = null;
        pc.onIceCandidate = null;
        pc.onConnectionStateChange = null;
        pc.onIceConnectionStateChange = null;
        pc.onSignalingStateChange = null;
        pc.onIceGatheringStateChange = null;
        debugPrint('[StreamService] Event handlers removed');
      } catch (e) {
        debugPrint('[StreamService] Error removing event handlers: $e');
      }
      
      // ✅ 3. أغلق الاتصال
      await pc.close();
      debugPrint('[StreamService] Peer connection $i closed');
      
      // ✅ انتظر قليلاً بين الإغلاقات
      if (i < pcs.length - 1) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    } catch (e) {
      debugPrint('[StreamService] Error closing peer connection $i: $e');
    }
  }
  
  debugPrint('[StreamService] All peer connections closed successfully');
}
