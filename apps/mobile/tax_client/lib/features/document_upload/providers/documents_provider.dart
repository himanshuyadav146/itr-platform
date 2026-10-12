import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
class DocumentCategory {
  final String title;
  final List<File> files;
  DocumentCategory({required this.title, required this.files});

  DocumentCategory copyWith({List<File>? files}) {
    return DocumentCategory(title: title, files: files ?? this.files);
  }
}

final documentsProvider =
    StateNotifierProvider<DocumentsNotifier, Map<String, DocumentCategory>>((
      ref,
    ) {
      return DocumentsNotifier(ref);
    });

class DocumentsNotifier extends StateNotifier<Map<String, DocumentCategory>> {
  final Ref ref;
  
  DocumentsNotifier(this.ref)
    : super({
        'form16a': DocumentCategory(title: 'Form 16-A', files: []),
        'form16b': DocumentCategory(title: 'Form 16-B', files: []),
        'others': DocumentCategory(title: 'Other Documents', files: []),
      });

  Future<void> pickDocument(String categoryKey) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final category = state[categoryKey]!;
      final updatedCategory = category.copyWith(
        files: [...category.files, file],
      );

      state = {...state, categoryKey: updatedCategory};
      
      // Call upload API through ViewModel
      // Import the provider at the top of the screen where this is used
      // The screen will handle the API call
    }
  }

  void removeDocument(String categoryKey, File file) {
    final category = state[categoryKey]!;
    final updatedFiles = category.files
        .where((f) => f.path != file.path)
        .toList();

    state = {...state, categoryKey: category.copyWith(files: updatedFiles)};
  }

  // Method to set files for a category (used when loading from server)
  void setCategoryFiles(String categoryKey, List<File> files) {
    final category = state[categoryKey]!;
    state = {...state, categoryKey: category.copyWith(files: files)};
  }
}
