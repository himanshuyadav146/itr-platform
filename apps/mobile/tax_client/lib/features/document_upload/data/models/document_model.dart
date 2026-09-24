import 'package:json_annotation/json_annotation.dart';

part 'document_model.g.dart';

@JsonSerializable()
class DocumentModel {
  final String? docId;
  final String? documentName;
  final String? fileName;
  final String? filePath;
  final String fileType;
  final String? uploadedAt;
  final String? filePassword;

  DocumentModel({
    this.docId,
    this.documentName,
    this.fileName,
    this.filePath,
    required this.fileType,
    this.uploadedAt,
    this.filePassword,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    // Derive fileType from fileName
    String fileType = 'pdf'; // default
    if (json['fileName'] != null) {
      final fileName = json['fileName'] as String;
      final extension = fileName.split('.').last.toLowerCase();
      fileType = extension == 'pdf' ? 'pdf' : extension;
    }

    return DocumentModel(
      docId: json['id']?.toString(),
      documentName: json['documentName'] as String? ?? json['documentType'] as String?,
      fileName: json['fileName'] as String?,
      // API returns 'downloadUrl' for the authenticated download link
      filePath: json['downloadUrl'] as String?,
      fileType: fileType,
      uploadedAt: json['createdAt'] as String?,
      filePassword: json['filePassword'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'docId': docId,
      'documentName': documentName,
      'fileName': fileName,
      'filePath': filePath,
      'fileType': fileType,
      'uploadedAt': uploadedAt,
      'filePassword': filePassword,
    };
  }
}
