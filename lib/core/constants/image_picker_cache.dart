import 'package:image_picker/image_picker.dart';

/// Singleton ImagePicker instance to reduce memory overhead
/// Creating multiple ImagePicker instances wastes memory and resources
class ImagePickerCache {
  static ImagePicker? _instance;

  /// Get the singleton ImagePicker instance
  static ImagePicker get instance {
    _instance ??= ImagePicker();
    return _instance!;
  }

  /// Clear the cache (useful for testing)
  static void clearCache() {
    _instance = null;
  }
}
