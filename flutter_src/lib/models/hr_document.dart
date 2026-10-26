class HRDocumentItem {
  final String id;
  final String employeeId;
  final String title;
  final String category;
  final String description;
  final String fileName;
  final String originalName;
  final String filePath;
  final String fileType;
  final int fileSize;
  final String issueDate;
  final String expiryDate;
  final String uploadedBy;
  final String status;
  final int version;
  final DateTime? createdAt;

  HRDocumentItem({
    required this.id,
    required this.employeeId,
    required this.title,
    required this.category,
    this.description = '',
    required this.fileName,
    required this.originalName,
    required this.filePath,
    required this.fileType,
    required this.fileSize,
    this.issueDate = '',
    this.expiryDate = '',
    this.uploadedBy = 'HR Admin',
    this.status = 'ACTIVE',
    this.version = 1,
    this.createdAt,
  });

  factory HRDocumentItem.fromJson(Map<String, dynamic> json) {
    return HRDocumentItem(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      employeeId: json['employee'] is Map
          ? (json['employee']['_id'] ?? json['employee']['id'] ?? '').toString()
          : (json['employee'] ?? json['employeeId'] ?? '').toString(),
      title: (json['title'] ?? json['originalName'] ?? 'Untitled Document')
          .toString(),
      category: (json['category'] ?? 'Other').toString(),
      description: (json['description'] ?? '').toString(),
      fileName: (json['fileName'] ?? '').toString(),
      originalName: (json['originalName'] ?? '').toString(),
      filePath: (json['filePath'] ?? '').toString(),
      fileType: (json['fileType'] ?? 'application/octet-stream').toString(),
      fileSize: (json['fileSize'] is num)
          ? (json['fileSize'] as num).toInt()
          : (int.tryParse(json['fileSize']?.toString() ?? '0') ?? 0),
      issueDate: (json['issueDate'] ?? '').toString(),
      expiryDate: (json['expiryDate'] ?? '').toString(),
      uploadedBy: (json['uploadedBy'] ?? 'HR Admin').toString(),
      status: (json['status'] ?? 'ACTIVE').toString().toUpperCase(),
      version: int.tryParse(json['version']?.toString() ?? '') ?? 1,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'title': title,
      'category': category,
      'description': description,
      'fileName': fileName,
      'originalName': originalName,
      'filePath': filePath,
      'fileType': fileType,
      'fileSize': fileSize,
      'issueDate': issueDate,
      'expiryDate': expiryDate,
      'uploadedBy': uploadedBy,
      'status': status,
      'version': version,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  String get formattedSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get formattedDate {
    final date = createdAt;
    if (date == null) return '—';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  bool get isPdf =>
      fileType.toLowerCase().contains('pdf') ||
      originalName.toLowerCase().endsWith('.pdf');

  bool get isImage =>
      fileType.toLowerCase().contains('image') ||
      originalName.toLowerCase().endsWith('.jpg') ||
      originalName.toLowerCase().endsWith('.jpeg') ||
      originalName.toLowerCase().endsWith('.png');
}
