import 'package:image_picker/image_picker.dart';

abstract class IRepoObjectDetector {
  Future<void> loadModel();
  
  /// Returns a list of detections. 
  /// Each detection is a Map: {'label': String, 'confidence': double, 'box': Rect}
  Future<List<Map<String, dynamic>>> detect(XFile image);
  
  bool get isLoaded;
}