import 'package:flutter/material.dart';
import 'package:global_connect/core/const/responsive_layout.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:provider/provider.dart';

import '../Model/restaurants_model.dart';
import '../Widgets/CustomAppBar.dart' show CustomAppBar2;
import '../core/const/app_color.dart';
import '../core/theme/app_text_style.dart';
import '../Provider/OnboardingProvider.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:global_connect/core/const/responsive_layout.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';

import '../Provider/OnboardingProvider.dart';
import '../Provider/user_profile_provider.dart';

import '../core/const/app_color.dart';
import '../core/const/app_images.dart';
import '../core/theme/app_text_style.dart';

class RestaurantsDetailScreen extends StatefulWidget {
  const RestaurantsDetailScreen({super.key});

  @override
  State<RestaurantsDetailScreen> createState() =>
      _RestaurantsDetailScreenState();
}

class _RestaurantsDetailScreenState extends State<RestaurantsDetailScreen> {
  // Default fallback images
  final List<String> _defaultImages = [
    AppImages.bestRestaurants,
    AppImages.onBoarding1,
    AppImages.onBoarding2,
  ];

  // Calculate distance function (same as in UserTipsScreen)
  String calculateDistance(dynamic currentUser, double? restaurantLat, double? restaurantLng) {
    if (currentUser?.latitude == null ||
        currentUser?.longitude == null ||
        restaurantLat == null ||
        restaurantLng == null) {
      return '-- km';
    }

    try {
      double distanceInMeters = Geolocator.distanceBetween(
        currentUser!.latitude!,
        currentUser!.longitude!,
        restaurantLat,
        restaurantLng,
      );

      double distanceInKm = distanceInMeters / 1000;

      if (distanceInKm < 1) {
        return '${(distanceInKm * 1000).toInt()}m';
      } else {
        return '${distanceInKm.toStringAsFixed(1)}km';
      }
    } catch (e) {
      return '-- km';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the RestaurantModel object from arguments
    final RestaurantsModel? restaurant = ModalRoute.of(context)?.settings.arguments as RestaurantsModel?;

    // If no restaurant data is provided, show error
    if (restaurant == null) {
      return Scaffold(
        appBar: CustomAppBar2(
          title: Text(
            'Restaurant Details',
            style: pjsStyleBlack18600.copyWith(color: AppColors.black),
          ),
        ),
        body: Center(
          child: Text(
            'No restaurant data available',
            style: TextStyle(fontSize: 16, color: Colors.red),
          ),
        ),
      );
    }

    // Use restaurant images or fallback to default
    final List<String> restaurantImages = restaurant.images.isNotEmpty
        ? restaurant.images
        : _defaultImages;

    return ChangeNotifierProvider(
      create: (_) => OnboardingProvider(),
      child: Scaffold(
        appBar: CustomAppBar2(
          title: Text(
            'Restaurant Details',
            style: pjsStyleBlack18600.copyWith(color: AppColors.black),
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.screenWidth * 0.05,
              vertical: context.screenHeight * 0.02,
            ),
            child: Consumer<OnboardingProvider>(
              builder: (context, provider, child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Carousel Image Slider
                    CarouselSlider(
                      carouselController: provider.carouselController,
                      options: CarouselOptions(
                        height: 200,
                        viewportFraction: 1.0,
                        enableInfiniteScroll: false,
                        enlargeCenterPage: false,
                        onPageChanged: (index, reason) {
                          provider.setCurrentIndex(index);
                        },
                      ),
                      items: restaurantImages.map((imgPath) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: restaurantImages == _defaultImages
                              ? Image.asset(
                            imgPath,
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                          )
                              : Image.network(
                            imgPath,
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                width: double.infinity,
                                height: 200,
                                color: Colors.grey[300],
                                child: Center(child: CircularProgressIndicator()),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset(
                                AppImages.bestRestaurants,
                                width: double.infinity,
                                height: 200,
                                fit: BoxFit.cover,
                              );
                            },
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    // Indicator dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(restaurantImages.length, (index) {
                        return Container(
                          width: provider.currentIndex == index ? 24 : 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: provider.currentIndex == index
                                ? AppColors.primary
                                : AppColors.garyModern200,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 20),
                    // Title, subtitle, and featured badge row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                restaurant.restaurantName,
                                style: pStyleBlack16600,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                restaurant.cuisineType,
                                style: pStyleBlack12400.copyWith(
                                  color: AppColors.lightBlack,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (restaurant.featuredRestaurant) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.lightBlue,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.star,
                                  color: AppColors.black,
                                  size: 20,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Featured',
                                  style: pStyleBlack12400.copyWith(
                                    color: AppColors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Details title
                    Text(
                      'Details',
                      style: pStyleBlack14600.copyWith(color: AppColors.black),
                    ),
                    const SizedBox(height: 16),
                    // Rating row
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 22),
                        const SizedBox(width: 4),
                        Text(
                          '${restaurant.rating}',
                          style: pStyleBlack14400.copyWith(
                            color: AppColors.black,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${restaurant.totalReviews})',
                          style: pStyleBlack14400.copyWith(
                            color: AppColors.garyModern400,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Divider(color: AppColors.borderShad),
                    // Distance and location row
                    Consumer<UserProfileProvider>(
                      builder: (context, userProvider, child) {
                        String distance = calculateDistance(
                          userProvider.currentUser,
                          restaurant.latitude,
                          restaurant.longitude,
                        );

                        return Row(
                          children: [
                            Icon(Icons.location_on, color: Colors.red, size: 20),
                            const SizedBox(width: 4),
                            Text(
                              distance,
                              style: pStyleBlack14400.copyWith(
                                color: AppColors.black,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '|',
                              style: pStyleBlack14400.copyWith(
                                color: AppColors.garyModern400,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                restaurant.address.isNotEmpty
                                    ? restaurant.address
                                    : restaurant.city,
                                style: pStyleBlack14400.copyWith(
                                  color: AppColors.black,
                                ),
                                maxLines: 5,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Divider(color: AppColors.borderShad),
                    const SizedBox(height: 8),
                    // Description
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Description: ',
                          style: pStyleBlack14400.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.black,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            restaurant.description,
                            style: pStyleBlack14500.copyWith(
                              color: AppColors.darkGrey,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Divider(color: AppColors.borderShad),
                    const SizedBox(height: 8),
                    // Price Range
                    Row(
                      children: [
                        Text(
                          'Price Range: ',
                          style: pStyleBlack14400.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.black,
                          ),
                        ),
                        Text(
                          restaurant.priceRange.isNotEmpty ? restaurant.priceRange : 'Not specified',
                          style: pStyleBlack14400.copyWith(
                            color: AppColors.darkGrey,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
