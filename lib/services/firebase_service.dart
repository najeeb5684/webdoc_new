import 'package:firebase_database/firebase_database.dart';
import '../models/call_model.dart'; // Import the CallModel

class FirebaseService {
  static final FirebaseDatabase database = FirebaseDatabase.instance;

  static Future<void> updateCallStatus(
      String channelName, CallModel callData) async {
    try {
      DatabaseReference ref =
      database.ref('DoctorCall/${channelName.replaceAll('.', '')}');
      await ref.update(callData.toJson());
      print('Firebase update successful');
    } catch (e) {
      print('Firebase update failed: $e');
      rethrow; // Re-throw the error so calling function knows it failed
    }
  }
}
