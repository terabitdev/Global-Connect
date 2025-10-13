import 'package:cloud_firestore/cloud_firestore.dart';

class RestaurantsModel {
  final String id;
  final String restaurantName;
  final String address;
  final String city;
  final String createdByEmail;
  final String cuisineType;
  final String description;
  final bool featuredRestaurant;
  final List<String> images;
  final String phoneNumber;
  final String priceRange;
  final double rating;
  final double latitude;
  final double longitude;
  final int totalReviews;
  final DateTime createdAt;
  final DateTime updatedAt;

  RestaurantsModel({
    required this.id,
    required this.restaurantName,
    required this.address,
    required this.city,
    required this.createdByEmail,
    required this.cuisineType,
    required this.description,
    required this.featuredRestaurant,
    required this.images,
    required this.phoneNumber,
    required this.priceRange,
    required this.rating,
    required this.latitude,
    required this.longitude,
    required this.totalReviews,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RestaurantsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return RestaurantsModel(
      id: doc.id,
      restaurantName: data['restaurantName'] ?? '',
      address: data['address'] ?? '',
      city: data['city'] ?? '',
      createdByEmail: data['createdByEmail'] ?? '',
      cuisineType: data['cuisineType'] ?? '',
      description: data['description'] ?? '',
      featuredRestaurant: data['featuredRestaurant'] ?? false,
      images: List<String>.from(data['images'] ?? []),
      phoneNumber: data['phoneNumber'] ?? '',
      priceRange: data['priceRange'] ?? '',
      rating: (data['rating'] ?? 0).toDouble(),
      latitude: (data['latitude'] ?? 0).toDouble(),
      longitude: (data['longitude'] ?? 0).toDouble(),
      totalReviews: data['totalReviews'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'restaurantName': restaurantName,
      'address': address,
      'city': city,
      'createdByEmail': createdByEmail,
      'cuisineType': cuisineType,
      'description': description,
      'featuredRestaurant': featuredRestaurant,
      'images': images,
      'phoneNumber': phoneNumber,
      'priceRange': priceRange,
      'rating': rating,
      'latitude': latitude,
      'longitude': longitude,
      'totalReviews': totalReviews,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
