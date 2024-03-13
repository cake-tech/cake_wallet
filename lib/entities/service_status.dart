class ServiceStatus {
  final String title;
  final String description;
  final String? image;
  final String? status;
  final DateTime date;

  ServiceStatus(
      {required this.title,
      required this.description,
      required this.date,
      this.image,
      this.status});

  factory ServiceStatus.fromJson(Map<String, dynamic> json) => ServiceStatus(
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
        image: json['image'] as String?,
        status: json['status'] as String?,
      );
}

class ServicesResponse {
  final List<ServiceStatus> servicesStatus;
  final bool hasUpdates;
  final String currentSha;

  ServicesResponse(this.servicesStatus, this.hasUpdates, this.currentSha);

  factory ServicesResponse.fromJson(
      Map<String, dynamic> json, bool hasUpdates, String currentSha) {
    return ServicesResponse(
      (json['notices'] as List? ?? [])
          .map((e) => ServiceStatus.fromJson(e as Map<String, dynamic>))
          .toList(),
      hasUpdates,
      currentSha,
    );
  }
}
