import '../../domain/models/document_folder_model.dart';
import '../../domain/models/document_file_model.dart';

/// Document data provider
class DocumentData {
  /// Get document folders
  static List<DocumentFolderModel> getDocumentFolders() {
    return [
      const DocumentFolderModel(
        id: '1',
        name: 'Shared',
        fileCount: 6,
        folderType: 'shared',
      ),
      const DocumentFolderModel(
        id: '2',
        name: 'EMP-0018-Employee...',
        fileCount: 12,
        folderType: 'employee',
        employeeId: 'EMP-0018',
      ),
      const DocumentFolderModel(
        id: '3',
        name: 'EMP-0019-Employee...',
        fileCount: 8,
        folderType: 'employee',
        employeeId: 'EMP-0019',
      ),
      const DocumentFolderModel(
        id: '4',
        name: 'EMP-0020-Employee...',
        fileCount: 15,
        folderType: 'employee',
        employeeId: 'EMP-0020',
      ),
      const DocumentFolderModel(
        id: '5',
        name: 'EMP-0021-Employee...',
        fileCount: 20,
        folderType: 'employee',
        employeeId: 'EMP-0021',
      ),
      const DocumentFolderModel(
        id: '6',
        name: 'EMP-0022-Employee...',
        fileCount: 5,
        folderType: 'employee',
        employeeId: 'EMP-0022',
      ),
      const DocumentFolderModel(
        id: '7',
        name: 'EMP-0023-Employee...',
        fileCount: 10,
        folderType: 'employee',
        employeeId: 'EMP-0023',
      ),
      const DocumentFolderModel(
        id: '8',
        name: 'EMP-0024-Employee...',
        fileCount: 7,
        folderType: 'employee',
        employeeId: 'EMP-0024',
      ),
    ];
  }

  /// Get shared folders
  static List<DocumentFolderModel> getSharedFolders() {
    return getDocumentFolders().where((folder) => folder.folderType == 'shared').toList();
  }

  /// Get employee folders
  static List<DocumentFolderModel> getEmployeeFolders() {
    return getDocumentFolders().where((folder) => folder.folderType == 'employee').toList();
  }

  /// Get files for a folder
  static List<DocumentFileModel> getFilesForFolder(String folderId) {
    // Sample files matching the design
    return [
      // PDF files
      DocumentFileModel(
        id: '1',
        name: 'Addhar Card.pdf',
        fileType: 'pdf',
        fileSize: '208kb',
        date: 'Dec 19',
        folderId: folderId,
      ),
      DocumentFileModel(
        id: '2',
        name: 'Passport Photo.jpg',
        fileType: 'pdf', // As shown in design (inconsistent)
        fileSize: '512kb',
        date: 'Jan 05',
        folderId: folderId,
      ),
      DocumentFileModel(
        id: '3',
        name: 'Resume.docx',
        fileType: 'pdf', // As shown in design (inconsistent)
        fileSize: '200kb',
        date: 'Mar 15',
        folderId: folderId,
      ),
      // Document files
      DocumentFileModel(
        id: '4',
        name: 'Bank Statement.doc',
        fileType: 'doc',
        fileSize: '1.2MB',
        date: 'Dec 19',
        folderId: folderId,
      ),
      DocumentFileModel(
        id: '5',
        name: 'Invoice_January.pdf',
        fileType: 'doc', // As shown in design (inconsistent)
        fileSize: '850KB',
        date: 'Jan 15',
        folderId: folderId,
      ),
      // JPG files
      DocumentFileModel(
        id: '6',
        name: 'Bank Statement.doc',
        fileType: 'jpg', // As shown in design (inconsistent)
        fileSize: '1.2MB',
        date: 'Dec 19',
        folderId: folderId,
      ),
    ];
  }

  /// Get all files (for shared view)
  static List<DocumentFileModel> getAllFiles() {
    return getFilesForFolder('1'); // Using shared folder files
  }

  /// Get files filtered by type
  static List<DocumentFileModel> getFilesByType(String type, {String? folderId}) {
    final files = folderId != null ? getFilesForFolder(folderId) : getAllFiles();
    return files.where((file) => file.fileTypeCategory == type.toLowerCase()).toList();
  }
}
