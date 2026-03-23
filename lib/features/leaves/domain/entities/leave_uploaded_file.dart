class LeaveUploadedFile {
  final String uid;
  final int lastModified;
  final String lastModifiedDate;
  final String name;
  final int size;
  final String type;
  final int percent;
  final String status;

  const LeaveUploadedFile({
    required this.uid,
    required this.lastModified,
    required this.lastModifiedDate,
    required this.name,
    required this.size,
    required this.type,
    this.percent = 0,
    this.status = 'uploading',
  });
}
