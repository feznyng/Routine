class InstalledApp {
  final String name;
  final String filePath;

  InstalledApp({
    required this.name,
    required this.filePath,
  });

  @override
  String toString() => 'InstalledApplication(name: $name, filePath: $filePath)';
}