import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  FirebaseStorage get _storage => FirebaseStorage.instance;

  Future<String> uploadImage(XFile imageFile, String folder) async {
    try {
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${imageFile.name}';
      final Reference ref = _storage.ref().child('$folder/$fileName');
      
      // For mobile (File) vs Web (Bytes) - simpler to just use putFile for mobile
      // assuming this is primarily valid for mobile now.
      await ref.putFile(File(imageFile.path));
      
      return await ref.getDownloadURL();
    } catch (e) {
      throw 'Image upload failed: $e';
    }
  }
}
