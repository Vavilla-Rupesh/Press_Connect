class StreamData {
  final String broadcastId;
  final String streamId;
  final String ingestUrl;
  final String streamKey;
  final String? broadcastUrl;
  final DateTime createdAt;
  final String title;

  StreamData({
    required this.broadcastId,
    required this.streamId,
    required this.ingestUrl,
    required this.streamKey,
    this.broadcastUrl,
    required this.createdAt,
    required this.title,
  });

  factory StreamData.fromJson(Map<String, dynamic> json) {
    return StreamData(
      broadcastId: json['broadcastId'] ?? '',
      streamId: json['streamId'] ?? '',
      ingestUrl: json['ingestUrl'] ?? '',
      streamKey: json['streamKey'] ?? '',
      broadcastUrl: json['broadcastUrl'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      title: json['title'] ?? 'Untitled Stream',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'broadcastId': broadcastId,
      'streamId': streamId,
      'ingestUrl': ingestUrl,
      'streamKey': streamKey,
      'broadcastUrl': broadcastUrl,
      'createdAt': createdAt.toIso8601String(),
      'title': title,
    };
  }
}