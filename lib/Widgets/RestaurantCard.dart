import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:global_connect/core/const/responsive_layout.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

import '../core/const/app_color.dart';
import '../core/const/app_images.dart' show AppImages;
import '../core/theme/app_text_style.dart';
import '../core/services/firebase_services.dart';
import '../Model/userModel.dart';
import '../core/utils/components/CustomButton.dart';
import '../core/utils/routes/routes.dart';

class RestaurantCard extends StatelessWidget {
  final String restaurantImage;
  final String restaurantName;
  final String cuisineType;
  final bool isFeatured;
  final double? rating;
  final int reviewCount;
  final String distance;
  final bool isUpcomingFestival;
  final String? openingHours;
  final String description;
  final String location;
  final double? longitude;
  final double? latitude;
  final bool isUpcoming;
  final String? ticketLink;

  final VoidCallback? onTap;
  final VoidCallback? onGetTickets;

  const RestaurantCard({
    Key? key,
    required this.restaurantImage,
    required this.restaurantName,
    required this.cuisineType,
    this.isFeatured = false,
    this.rating,
    required this.reviewCount,
    required this.distance,
    this.openingHours,
    required this.description,
    required this.location,
    this.longitude,
    this.latitude,
    this.ticketLink,
    this.onTap,

    this.isUpcoming = false,
    this.onGetTickets,
    this.isUpcomingFestival = false,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        //height: isUpcomingFestival ? 200 : 200,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderShad),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            restaurantName,
                            style: pjsStyleBlack14600,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isFeatured) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.lightBlue,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.star,
                                    size: 14,
                                    color: AppColors.black,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Featured',
                                    style: psjStyleBlack12400,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      spacing: 10,
                      children: [
                        // Rating
                        if (rating != null) ...[
                          Icon(Icons.star, size: 16, color: Colors.amber),
                          Text('$rating', style: pjsStyleBlack12600),
                          Text(
                            '($reviewCount Reviews)',
                            style: pjsStyleBlack12400.copyWith(
                              color: AppColors.black.withOpacity(0.34),
                            ),
                          ),
                        ],

                        if (onGetTickets != null) ...[
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: AppColors.darkGrey,
                          ),
                          Text(
                            openingHours!,
                            style: pjsStyleBlack12400.copyWith(
                              color: AppColors.darkGrey,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Cuisine Type
                    Text(
                      cuisineType,
                      style: psjStyleBlack10400.copyWith(
                        color: AppColors.lightBlack,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Description
                    Text(
                      description,
                      style: psjStyleBlack12400.copyWith(
                        color: AppColors.black,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 8),

                    // Location
                    Row(
                      spacing: 5,
                      children: [
                        SvgPicture.asset(
                          AppImages.locationIcon,
                          width: 14,
                          height: 14,
                          color: AppColors.black.withOpacity(0.34),
                        ),
                        Expanded(
                          child: Text(
                            location,
                            style: pjsStyleBlack12400.copyWith(
                              color: AppColors.black.withOpacity(0.34),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      spacing: 5,
                      children: [
                        SvgPicture.asset(
                          AppImages.clock,
                          width: 14,
                          height: 14,
                          color: AppColors.black.withOpacity(0.34),
                        ),
                        Expanded(
                          child: Text(
                            distance,
                            style: pjsStyleBlack12400.copyWith(
                              color: AppColors.black.withOpacity(0.34),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Divider(color: AppColors.garyModern200, thickness: 1),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 120,
                      child: CustomButton(
                        height: 30,
                        backgroundColor: AppColors.white,
                        textColor: AppColors.primary,
                        borderColor: AppColors.primary,
                        text: 'Write Review',
                        onTap: () {
                          Navigator.pushNamed(context, RoutesName.tipReviewScreen);
                        },
                      ),
                    ),
                    if (ticketLink != null && ticketLink != '') ...[
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: onGetTickets,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '🎫 Get Tickets',
                                style: psjStyleBlack10400.copyWith(
                                  color: AppColors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LocalEventCard extends StatefulWidget {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String time;
  final String location;
  final String imageUrl;
  final String category;
  final int maxAttendees;
  final List<String> attendeesIds;
  final String cityName;
  final String createdById;
  final double? eventLatitude;
  final double? eventLongitude;
  final VoidCallback? onTap;

  const LocalEventCard({
    Key? key,
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.time,
    required this.location,
    required this.imageUrl,
    required this.category,
    required this.maxAttendees,
    required this.attendeesIds,
    required this.cityName,
    required this.createdById,
    this.eventLatitude,
    this.eventLongitude,
    this.onTap,
  }) : super(key: key);

  @override
  State<LocalEventCard> createState() => _LocalEventCardState();
}

class _LocalEventCardState extends State<LocalEventCard> {
  String? distanceText;
  bool _isJoining = false;
  final FirebaseServices _firebaseServices = FirebaseServices.instance;

  @override
  void initState() {
    super.initState();
    _calculateDistance();
  }

  bool get _isUserJoined {
    final String? currentUserId = _firebaseServices.getCurrentUserId();
    return currentUserId != null && widget.attendeesIds.contains(currentUserId);
  }

  bool get _isEventFull {
    return widget.attendeesIds.length >= widget.maxAttendees;
  }

  bool get _isEventCreator {
    final String? currentUserId = _firebaseServices.getCurrentUserId();
    return currentUserId != null && currentUserId == widget.createdById;
  }

  Future<void> _toggleJoinEvent() async {
    if (_isJoining) return;

    final String? currentUserId = _firebaseServices.getCurrentUserId();
    if (currentUserId == null) return;

    setState(() {
      _isJoining = true;
    });

    try {
      final DocumentReference eventDoc = FirebaseFirestore.instance
          .collection('localgroupchat')
          .doc(widget.cityName)
          .collection('localEvent')
          .doc(widget.id);

      if (_isUserJoined) {
        // Leave event
        await eventDoc.update({
          'attendeesIds': FieldValue.arrayRemove([currentUserId]),
        });
      } else {
        // Join event (only if not full)
        if (!_isEventFull) {
          await eventDoc.update({
            'attendeesIds': FieldValue.arrayUnion([currentUserId]),
          });
        }
      }
    } catch (e) {
      // Handle error silently or show snackbar
    } finally {
      if (mounted) {
        setState(() {
          _isJoining = false;
        });
      }
    }
  }

  double _calculateDistanceInKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371;
    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);

    double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  void _calculateDistance() async {
    if (widget.eventLatitude == null || widget.eventLongitude == null) {
      setState(() {
        distanceText = 'N/A';
      });
      return;
    }

    try {
      final String? currentUserId = _firebaseServices.getCurrentUserId();
      if (currentUserId == null) {
        setState(() {
          distanceText = 'N/A';
        });
        return;
      }

      final DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .get();

      if (userDoc.exists) {
        final UserModel user = UserModel.fromMap(
          userDoc.data() as Map<String, dynamic>,
        );

        if (user.latitude != null && user.longitude != null) {
          final double distance = _calculateDistanceInKm(
            user.latitude!,
            user.longitude!,
            widget.eventLatitude!,
            widget.eventLongitude!,
          );

          setState(() {
            if (distance < 1) {
              distanceText = '${(distance * 1000).round()}m';
            } else {
              distanceText = '${distance.toStringAsFixed(1)}km';
            }
          });
        } else {
          setState(() {
            distanceText = 'N/A';
          });
        }
      } else {
        setState(() {
          distanceText = 'N/A';
        });
      }
    } catch (e) {
      setState(() {
        distanceText = 'N/A';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderShad),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Restaurant Image
            SizedBox(
              width: context.screenWidth * 0.3,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                child: Image.network(
                  widget.imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Shimmer(
                      color: Colors.grey[300]!,
                      child: Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: Icon(
                        Icons.image_not_supported,
                        color: Colors.grey[400],
                      ),
                    );
                  },
                ),
              ),
            ),

            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.title,
                            style: pjsStyleBlack14600,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.category,
                                  style: psjStyleBlack12400.copyWith(
                                    color: AppColors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          spacing: 5,
                          children: [
                            SvgPicture.asset(
                              AppImages.location,
                              height: 14,
                              colorFilter: ColorFilter.mode(
                                AppColors.darkGrey,
                                BlendMode.srcIn,
                              ),
                            ),
                            Text(
                              distanceText ?? 'Calculating...',
                              style: pjsStyleBlack12400.copyWith(
                                color: AppColors.darkGrey,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(width: 4),
                        Row(
                          spacing: 5,
                          children: [
                            Icon(
                              Icons.person,
                              size: 14,
                              color: AppColors.darkGrey,
                            ),
                            Text(
                              '${widget.attendeesIds.length}/${widget.maxAttendees}',
                              style: pjsStyleBlack12400.copyWith(
                                color: AppColors.darkGrey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: AppColors.darkGrey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.date.day} ${monthName(widget.date.month)} ${widget.date.year}',
                          style: pjsStyleBlack12400.copyWith(
                            color: AppColors.darkGrey,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.time,
                          style: pjsStyleBlack12400.copyWith(
                            color: AppColors.darkGrey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Cuisine Type
                    Text(
                      widget.description,
                      style: psjStyleBlack10400.copyWith(
                        color: AppColors.lightBlack,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      spacing: 5,
                      children: [
                        SvgPicture.asset(AppImages.pin, width: 12, height: 12),
                        Expanded(
                          child: Text(
                            widget.location,
                            style: pjsStyleBlack12400.copyWith(
                              color: AppColors.darkGrey,
                            ),
                            textAlign: TextAlign.justify,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _isEventCreator || (_isEventFull && !_isUserJoined)
                          ? null
                          : _toggleJoinEvent,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _isEventCreator
                              ? AppColors.lightBlue
                              : _isEventFull && !_isUserJoined
                              ? AppColors.darkGrey
                              : _isUserJoined
                              ? Colors.red
                              : AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isJoining && !_isEventCreator) ...[
                              SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Text(
                              _isEventCreator
                                  ? 'Your Event'
                                  : _isEventFull && !_isUserJoined
                                  ? 'Event Full'
                                  : _isUserJoined
                                  ? 'You Joined'
                                  : 'Join',
                              style: psjStyleBlack10400.copyWith(
                                color: AppColors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String monthName(int month) {
  const months = [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return months[month];
}
