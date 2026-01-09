// lib/model/live_channel_model.dart

class LiveChannel {
  final String id;
  final String name;
  final String imageUrl;
  final String streamUrl;
  final String category;
  final String quality;
  final bool isHD;

  LiveChannel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.streamUrl,
    required this.category,
    this.quality = 'HD',
    this.isHD = true,
  });

  factory LiveChannel.fromJson(Map<String, dynamic> json) {
    return LiveChannel(
      id: json['id']?.toString() ?? '0',
      name: json['name']?.toString() ?? 'Unknown Channel',
      imageUrl: json['imageUrl']?.toString() ?? '',
      streamUrl: json['streamUrl']?.toString() ?? '',
      category: json['category']?.toString() ?? 'General',
      quality: json['quality']?.toString() ?? 'HD',
      isHD: json['isHD'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'streamUrl': streamUrl,
      'category': category,
      'quality': quality,
      'isHD': isHD,
    };
  }
}