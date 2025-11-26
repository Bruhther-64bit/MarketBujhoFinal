import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Add to wishlist
  Future<void> addToWishlist(String userId, Product product) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('wishlist')
        .doc(product.link.hashCode.toString())
        .set(product.toMap());
  }

  // Update wishlist note
  Future<void> updateWishlistNote(
      String userId, String productId, String note) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('wishlist')
        .doc(productId)
        .update({'note': note});
  }

  // Update wishlist category
  Future<void> updateWishlistCategory(
      String userId, String productId, String? category) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('wishlist')
        .doc(productId)
        .update({'category': category});
  }

  // Remove from wishlist
  Future<void> removeFromWishlist(String userId, String productId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('wishlist')
        .doc(productId)
        .delete();
  }

  // Get wishlist
  Stream<List<Product>> getWishlist(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('wishlist')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Product.fromMap(doc.data())).toList());
  }

  // Check if product is in wishlist
  Future<bool> isInWishlist(String userId, String productId) async {
    final doc = await _db
        .collection('users')
        .doc(userId)
        .collection('wishlist')
        .doc(productId)
        .get();
    return doc.exists;
  }

  // Save user profile
  Future<void> saveUserProfile(String userId, Map<String, dynamic> data) async {
    await _db
        .collection('users')
        .doc(userId)
        .set(data, SetOptions(merge: true));
  }

  // Get user profile
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    return doc.data();
  }
}