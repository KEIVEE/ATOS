class AudioTitle {
  final String title;

  AudioTitle({required this.title});

  factory AudioTitle.fromJson(Map<String, dynamic> json) {
    return AudioTitle(
      title: json['title'],
    );
  }
}
