// lib/model/episode.dart
class Episode {
  final int id;
  final String title;
  final String description;
  final String videoUrl;
  final String imageUrl;
  final String duration;
  final int episodeNumber;
  final int seasonNumber;

  Episode({
    required this.id,
    required this.title,
    required this.description,
    required this.videoUrl,
    required this.imageUrl,
    required this.duration,
    required this.episodeNumber,
    required this.seasonNumber,
  });

  factory Episode.fromJson(Map<String, dynamic> json) {
    return Episode(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      title: json['title']?.toString() ?? 'No Title',
      description: json['description']?.toString() ?? '',
      videoUrl: json['videoUrl']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      duration: json['duration']?.toString() ?? '0m',
      episodeNumber: json['episodeNumber'] is int ? json['episodeNumber'] : int.tryParse(json['episodeNumber'].toString()) ?? 0,
      seasonNumber: json['seasonNumber'] is int ? json['seasonNumber'] : int.tryParse(json['seasonNumber'].toString()) ?? 1,
    );
  }

  get overview => null;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'videoUrl': videoUrl,
      'imageUrl': imageUrl,
      'duration': duration,
      'episodeNumber': episodeNumber,
      'seasonNumber': seasonNumber,
    };
  }
}