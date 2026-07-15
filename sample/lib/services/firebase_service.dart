import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

import '../firebase_options.dart';

class FirebaseService {
  static final FirebaseAuth auth = FirebaseAuth.instance;
  static final FirebaseFirestore firestore = FirebaseFirestore.instance;
  static final FirebaseStorage storage = FirebaseStorage.instance;

  /// Initialize Firebase. Call this once at app startup.
  static Future<void> init() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Keep desktop/web uploads compatible with common Storage rules
      // that require request.auth != null.
      if (auth.currentUser == null) {
        try {
          await auth.signInAnonymously();
        } catch (e) {
          debugPrint('Anonymous sign-in skipped: $e');
        }
      }
    } on UnsupportedError catch (e) {
      debugPrint(
        'Firebase initialization is unavailable for ${defaultTargetPlatform.name}: $e',
      );
    }
  }

  /// Create or update user document
  static Future<void> setUser(String uid, Map<String, dynamic> data) async {
    await firestore.collection('users').doc(uid).set(data, SetOptions(merge: true));
  }

  /// Add shop document
  static Future<DocumentReference> addShop(Map<String, dynamic> data) async {
    return await firestore.collection('shops').add(data);
  }

  /// Upload reel video bytes and return download URL
  static Future<String> uploadReel(
    String uid,
    String fileName,
    Uint8List bytes, {
    String? contentType,
    Duration timeout = const Duration(minutes: 10),
    Duration stallTimeout = const Duration(seconds: 45),
    void Function(double progress)? onProgress,
  }) async {
    if (auth.currentUser == null) {
      try {
        await auth.signInAnonymously();
      } catch (e) {
        // Continue without auth. If Storage rules require auth, upload will
        // fail with permission errors that we surface in the UI.
        debugPrint('Anonymous sign-in unavailable, continuing without auth: $e');
      }
    }

    final ref = storage.ref().child('reels/$uid/$fileName');
    final metadata = contentType == null
        ? null
        : SettableMetadata(contentType: contentType);
    final uploadTask = ref.putData(bytes, metadata);

    onProgress?.call(0.01);

    late final StreamSubscription<TaskSnapshot> sub;
    late final Timer stallTimer;
    final stallCompleter = Completer<TaskSnapshot>();
    int lastTransferred = 0;
    DateTime lastChangedAt = DateTime.now();

    if (onProgress != null) {
      sub = uploadTask.snapshotEvents.listen((snapshot) {
        if (snapshot.state == TaskState.running && snapshot.bytesTransferred == 0) {
          onProgress(0.01);
        }

        final transferred = snapshot.bytesTransferred;
        if (transferred > lastTransferred) {
          lastTransferred = transferred;
          lastChangedAt = DateTime.now();
        }

        final total = snapshot.totalBytes;
        if (total > 0) {
          onProgress((snapshot.bytesTransferred / total).clamp(0.0, 1.0));
        } else {
          final fallbackTotal = bytes.length;
          if (fallbackTotal > 0) {
            onProgress((snapshot.bytesTransferred / fallbackTotal).clamp(0.0, 0.99));
          } else {
            onProgress(0.01);
          }
        }
      });
    } else {
      sub = uploadTask.snapshotEvents.listen((snapshot) {
        final transferred = snapshot.bytesTransferred;
        if (transferred > lastTransferred) {
          lastTransferred = transferred;
          lastChangedAt = DateTime.now();
        }
      });
    }

    stallTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      final stalledFor = DateTime.now().difference(lastChangedAt);
      if (stalledFor >= stallTimeout && !stallCompleter.isCompleted) {
        uploadTask.cancel();
        stallCompleter.completeError(
          TimeoutException('Upload stalled for ${stallTimeout.inSeconds}s'),
        );
      }
    });

    try {
      final uploadSnapshot = await Future.any<TaskSnapshot>([
        uploadTask.timeout(timeout),
        stallCompleter.future,
      ]);
      onProgress?.call(1.0);
      return await uploadSnapshot.ref.getDownloadURL();
    } finally {
      stallTimer.cancel();
      await sub.cancel();
    }
  }

  /// Save uploaded video metadata in Firestore.
  static Future<DocumentReference> addReelMetadata(
    Map<String, dynamic> data, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    return await firestore.collection('reels').add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
    }).timeout(timeout);
  }

  /// Fetch uploaded reels metadata (newest first).
  static Future<List<Map<String, dynamic>>> fetchReels({
    int limit = 50,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final snapshot = await firestore
        .collection('reels')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get()
        .timeout(timeout);

    return snapshot.docs
        .map((doc) => <String, dynamic>{
              'id': doc.id,
              ...doc.data(),
            })
        .toList();
  }

  /// Save a commerce order and return created document reference.
  static Future<DocumentReference> createOrder({
    required String buyerUid,
    required List<Map<String, dynamic>> items,
    required int totalPrice,
    String status = 'paid',
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (auth.currentUser == null) {
      try {
        await auth.signInAnonymously();
      } catch (_) {
        // Continue with fallback buyerUid.
      }
    }

    final effectiveBuyerUid = auth.currentUser?.uid ?? buyerUid;

    return await firestore.collection('orders').add({
      'buyerUid': effectiveBuyerUid,
      'items': items,
      'totalPrice': totalPrice,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
    }).timeout(timeout);
  }

  /// Fetch order history for a buyer (newest first).
  static Future<List<Map<String, dynamic>>> fetchOrdersByBuyerUid(
    String buyerUid, {
    int limit = 50,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final snapshot = await firestore
        .collection('orders')
        .where('buyerUid', isEqualTo: buyerUid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get()
        .timeout(timeout);

    return snapshot.docs
        .map((doc) => <String, dynamic>{
              'id': doc.id,
              ...doc.data(),
            })
        .toList();
  }
}
