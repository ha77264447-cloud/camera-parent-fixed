// أضيف هذا في _createPeerConnection أو في WebRTC initialization:

// بعد إنشاء RTCPeerConnection:
final pc = await createPeerConnection(
  {
    'iceServers': _iceServers,
    'iceTransportPolicy': 'all', // جرب candidates من STUN
  },
);

// ✅ أضيف timeout
Future.delayed(Duration(seconds: 15), () {
  if (pc.connectionState == RTCPeerConnectionState.RTCPeerConnectionStateConnecting) {
    debugPrint("[StreamService] ICE timeout - forcing reconnect");
    _reconnectWebSocket();
  }
});
