import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:global_connect/core/const/responsive_layout.dart';
import 'package:provider/provider.dart';

import '../../Provider/SelectionProvider.dart';
import '../../Provider/UserTipsProvider.dart';
import '../../Provider/user_profile_provider.dart';
import '../../Widgets/FilterDropdown.dart';
import '../../Widgets/HeaderWithSearchAndActions.dart';
import '../../Widgets/InfoCardWidget.dart';
import '../../Widgets/RestaurantCard.dart';
import '../../Widgets/UserTipCard.dart' show UserTipCard;
import '../../core/const/app_color.dart';
import '../../core/const/app_images.dart';
import '../../core/theme/app_text_style.dart';
import '../../core/utils/components/CustomButton.dart';
import '../../core/utils/routes/routes.dart';

class UserTipsScreen extends StatefulWidget {
  const UserTipsScreen({super.key});

  @override
  State<UserTipsScreen> createState() => _UserTipsScreenState();
}

class _UserTipsScreenState extends State<UserTipsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProfileProvider>().listenToCurrentUser();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              children: [
                const HeaderWithSearchAndActions(
                  searchHintText: 'Search tips...',
                  useUserTipsProvider: true,
                ),
                const SizedBox(height: 20),

                Column(
                  spacing: 20,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Local Guide',
                                style: pjsStyleBlack14700.copyWith(
                                  color: AppColors.black,
                                ),
                              ),
                              Text(
                                'Showing content near you',
                                style: pjsStyleBlack10400.copyWith(
                                  color: AppColors.darkGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: CustomButton(
                            text: 'Add Tip',
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                RoutesName.shareTipsScreen,
                              );
                            },
                            height: 25,
                            padding: 8,
                            svgAsset: AppImages.addIcon,
                            iconSize: 12,
                            textStyle: pjsStyleBlack12600.copyWith(
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ],
                    ),

                    Consumer<UserTipsProvider>(
                      builder: (context, tipsProvider, child) {
                        return Padding(
                          padding: EdgeInsets.only(right: 20),
                          child: Row(
                            spacing: 10,
                            children: [
                              Text(
                                'Show:',
                                style: pjsStyleBlack14600.copyWith(
                                  color: AppColors.black,
                                ),
                              ),
                              Expanded(
                                child: CustomButton(
                                  borderColor: !tipsProvider.showGlobalTips
                                      ? AppColors.primary
                                      : AppColors.garyModern200,
                                  backgroundColor: !tipsProvider.showGlobalTips
                                      ? AppColors.primary
                                      : AppColors.white,
                                  textColor: !tipsProvider.showGlobalTips
                                      ? AppColors.white
                                      : AppColors.primary,
                                  text: 'Countrymen',
                                  onTap: () {
                                    tipsProvider.setNationalityFilter(false);
                                  },
                                  height: 25,
                                  padding: 8,
                                  svgAsset: AppImages.people,
                                  iconSize: 12,
                                  textStyle: pjsStyleBlack12600.copyWith(
                                    color: !tipsProvider.showGlobalTips
                                        ? AppColors.white
                                        : AppColors.primary,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: CustomButton(
                                  borderColor: tipsProvider.showGlobalTips
                                      ? AppColors.primary
                                      : AppColors.garyModern200,
                                  backgroundColor: tipsProvider.showGlobalTips
                                      ? AppColors.primary
                                      : AppColors.white,
                                  textColor: tipsProvider.showGlobalTips
                                      ? AppColors.white
                                      : AppColors.primary,
                                  text: 'Global',
                                  onTap: () {
                                    tipsProvider.setNationalityFilter(true);
                                  },
                                  height: 25,
                                  padding: 8,
                                  svgAsset: AppImages.word,
                                  iconSize: 12,
                                  textStyle: pjsStyleBlack12600.copyWith(
                                    color: !tipsProvider.showGlobalTips
                                        ? AppColors.primary
                                        : AppColors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    Consumer<SelectionProvider>(
                      builder: (context, selectionProvider, child) {
                        return Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.lightGrey.withOpacity(0.70),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: Row(
                              children: [
                                Flexible(
                                  flex: 1,
                                  child: GestureDetector(
                                    onTap: () async {
                                      selectionProvider.selectOption(0);
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      curve: Curves.easeInOut,
                                      decoration: BoxDecoration(
                                        color: selectionProvider.isSelected(0)
                                            ? AppColors.primary
                                            : AppColors.white,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 8,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            SvgPicture.asset(
                                              AppImages.bulb,
                                              colorFilter: ColorFilter.mode(
                                                selectionProvider.isSelected(0)
                                                    ? AppColors.white
                                                    : AppColors.darkGrey,
                                                BlendMode.srcIn,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              'Local Tips',
                                              style: pjsStyleBlack14700
                                                  .copyWith(
                                                    color:
                                                        selectionProvider
                                                            .isSelected(0)
                                                        ? AppColors.white
                                                        : AppColors.darkGrey,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Flexible(
                                  flex: 1,
                                  child: GestureDetector(
                                    onTap: () async {
                                      selectionProvider.selectOption(1);
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      curve: Curves.easeInOut,
                                      decoration: BoxDecoration(
                                        color: selectionProvider.isSelected(1)
                                            ? AppColors.primary
                                            : AppColors.white,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 8,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            SvgPicture.asset(
                                              AppImages.restaurant,
                                              colorFilter: ColorFilter.mode(
                                                selectionProvider.isSelected(1)
                                                    ? AppColors.white
                                                    : AppColors.darkGrey,
                                                BlendMode.srcIn,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              'Restaurants',
                                              style: pjsStyleBlack14700
                                                  .copyWith(
                                                    color:
                                                        selectionProvider
                                                            .isSelected(1)
                                                        ? AppColors.white
                                                        : AppColors.darkGrey,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    Consumer2<SelectionProvider, UserTipsProvider>(
                      builder:
                          (context, selectionProvider, tipsProvider, child) {
                            if (selectionProvider.selectedIndex == 0) {
                              return Column(
                                spacing: 20,
                                children: [
                                  FilterDropdown(
                                    selectedValue:
                                        tipsProvider.selectedCategory,
                                    items: const [
                                      'All Categories',
                                      'Restaurants',
                                      'Nightlife',
                                      'Sightseeing',
                                      'Shopping',
                                      'Transportation',
                                      'Accommodation',
                                      'Safety',
                                      'Cultural',
                                      'Other',
                                      'Food',
                                      'Warning',
                                      'Tip',
                                      'Life hack',
                                    ],
                                    onChanged: (String? newValue) {
                                      if (newValue != null) {
                                        tipsProvider.filterByCategory(newValue);
                                      }
                                    },
                                  ),
                                  Row(
                                    spacing: 10,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Sort By:',
                                          style: pjsStyleBlack14600.copyWith(
                                            color: AppColors.black,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: CustomButton(
                                          borderColor:
                                              tipsProvider.sortBy == 'Popular'
                                              ? AppColors.primary
                                              : AppColors.garyModern200,
                                          backgroundColor:
                                              tipsProvider.sortBy == 'Popular'
                                              ? AppColors.primary
                                              : AppColors.white,
                                          textColor:
                                              tipsProvider.sortBy == 'Popular'
                                              ? AppColors.white
                                              : AppColors.primary,
                                          text: 'Popular',
                                          onTap: () {
                                            tipsProvider.setSortBy('Popular');
                                          },
                                          height: 25,
                                          padding: 8,
                                          iconSize: 15,
                                        ),
                                      ),
                                      Expanded(
                                        child: CustomButton(
                                          borderColor:
                                              tipsProvider.sortBy == 'Recent'
                                              ? AppColors.primary
                                              : AppColors.garyModern200,
                                          backgroundColor:
                                              tipsProvider.sortBy == 'Recent'
                                              ? AppColors.primary
                                              : AppColors.white,
                                          textColor:
                                              tipsProvider.sortBy == 'Recent'
                                              ? AppColors.white
                                              : AppColors.primary,
                                          text: 'Recent',
                                          onTap: () {
                                            tipsProvider.setSortBy('Recent');
                                          },
                                          height: 25,
                                          padding: 8,
                                          iconSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            } else {
                              return const SizedBox.shrink();
                            }
                          },
                    ),
                    Consumer3<
                      SelectionProvider,
                      UserTipsProvider,
                      UserProfileProvider
                    >(
                      builder:
                          (
                            context,
                            selectionProvider,
                            tipsProvider,
                            userProfileProvider,
                            child,
                          ) {
                            if (selectionProvider.selectedIndex == 0) {
                              return Column(
                                children: [
                                  _buildUserTipsSection(tipsProvider),
                                  const SizedBox(height: 20),
                                ],
                              );
                            } else {
                              return _buildRestaurantsSection(
                                tipsProvider,
                                userProfileProvider.currentUser,
                              );
                            }
                          },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserTipsSection(UserTipsProvider tipsProvider) {
    if (tipsProvider.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (tipsProvider.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Text(
                'Error: ${tipsProvider.error}',
                style: TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => tipsProvider.refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (tipsProvider.allTips.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            spacing: 10,
            children: [
              SvgPicture.asset(
                AppImages.bulb,
                width: 60,
                height: 41,
                color: AppColors.purple2,
              ),
              Text(
                'Be the first to share a travel tip in this area!',
                textAlign: TextAlign.center,
                style: pjsStyleBlack12500.copyWith(
                  color: AppColors.garyModern400,
                ),
              ),
              SizedBox(
                width: context.screenWidth / 3,
                child: CustomButton(
                  text: 'Add First Tip',
                  onTap: () {
                    Navigator.pushNamed(context, RoutesName.shareTipsScreen);
                  },
                  height: 25,
                  padding: 8,
                  svgAsset: AppImages.addIcon,
                  iconSize: 15,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: tipsProvider.allTips.map((tipData) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: UserTipCard(
            tipsCategories: tipData['category'] ?? '',
            userNationality: tipData['userNationality'] ?? '',
            userImage: tipData['userImage'] ?? '',
            userName: tipData['userName'] ?? 'Anonymous',
            countryFlag: tipData['userCountryFlag'] ?? '🌍',
            timeAgo: _formatTimeAgo(tipData['createdAt']),
            title: tipData['title'] ?? '',
            description: tipData['tip'] ?? '',
            location:
                tipData['address'] ?? tipData['userHomeCity'] ?? 'Unknown',
            likesCount: tipData['likeCount'] ?? 0,
            dislikesCount: tipData['dislikeCount'] ?? 0,
            tipId: tipData['id'] ?? '',
            tipOwnerId: tipData['userId'] ?? '',
            userLikeMembers: tipData['userLikeMembers'] != null
                ? List<String>.from(tipData['userLikeMembers'])
                : [],
            userDislikeMembers: tipData['userDislikeMembers'] != null
                ? List<String>.from(tipData['userDislikeMembers'])
                : [],
          ),
        );
      }).toList(),
    );
  }

  // Helper method to format time ago
  String _formatTimeAgo(dynamic timestamp) {
    try {
      DateTime dateTime;
      if (timestamp is Timestamp) {
        dateTime = timestamp.toDate();
      } else if (timestamp is String) {
        dateTime = DateTime.tryParse(timestamp) ?? DateTime.now();
      } else {
        return 'Just now';
      }

      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Just now';
    }
  }

  Widget _buildRestaurantsSection(
    UserTipsProvider tipsProvider,
    dynamic currentUser,
  ) {
    if (tipsProvider.isRestaurantsLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (tipsProvider.restaurantsError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Text(
                'Error: ${tipsProvider.restaurantsError}',
                style: TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => tipsProvider.refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (tipsProvider.allRestaurants.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text(
            'No restaurants available yet.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      children: tipsProvider.allRestaurants.map((restaurant) {
        String calculatedDistance = calculateDistanceToRestaurant(
          currentUser,
          restaurant.latitude,
          restaurant.longitude,
          restaurant.restaurantName,
        );

        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: RestaurantCard(
            latitude: restaurant.latitude,
            longitude: restaurant.longitude,
            restaurantImage: restaurant.images.isNotEmpty
                ? restaurant.images.first
                : AppImages.bestRestaurants,
            restaurantName: restaurant.restaurantName,
            cuisineType: restaurant.cuisineType,
            isFeatured: restaurant.featuredRestaurant,
            rating: restaurant.rating,
            reviewCount: restaurant.totalReviews,
            distance: calculatedDistance,
            description: restaurant.description,
            location: restaurant.address.isNotEmpty
                ? restaurant.address
                : restaurant.city,
            onTap: () {
              Navigator.pushNamed(
                context,
                RoutesName.restaurantsDetailScreen,
                arguments: restaurant,
              );
              print('Restaurant tapped: ${restaurant.restaurantName}');
            },
          ),
        );
      }).toList(),
    );
  }
}
