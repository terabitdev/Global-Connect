import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:global_connect/Provider/LocationProvider.dart';
import 'package:global_connect/core/const/responsive_layout.dart';
import 'package:global_connect/core/utils/components/CustomButton.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import '../Provider/SelectionProvider.dart';
import '../Provider/user_profile_provider.dart';
import '../Widgets/ProfileCard.dart';
import '../core/const/app_color.dart';
import '../core/const/app_images.dart';
import '../core/theme/app_text_style.dart';
import '../core/utils/components/HomeAppBar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  VoidCallback? _userProviderListener;
  VoidCallback? _locationListener;
  Timer? _zoomDebounceTimer;
  LatLng? _lastKnownPosition;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initial location fetch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final locationProvider = context.read<LocationProvider>();
      final userProvider = context.read<UserProfileProvider>();
      locationProvider.setUserProfileProvider(userProvider);
      final selectionProvider = context.read<SelectionProvider>();
      locationProvider.updateFilterMode(
        selectionProvider.selectedIndex == 1,
      );

      locationProvider.refreshUserLocationAfterAuth();

      // Only fetch location if we don't have it yet and not loading
      if (locationProvider.currentPosition == null &&
          !locationProvider.isLoading) {
        locationProvider.getCurrentLocation(context: context);
      }

      userProvider.listenToCurrentUser();
      userProvider.listenToAllUsers();

      // Add listener to sync map markers with ProfileCard list changes
      _userProviderListener = () {
        // Only update markers if we're not already updating to prevent loops
        if (!locationProvider.isUpdatingMarkers) {
          locationProvider.refreshMarkersFromUserProvider();
        }
      };
      userProvider.addListener(_userProviderListener!);
      
      // Add listener for location changes to update camera position
      _locationListener = () {
        final currentPos = locationProvider.currentPosition;
        // Update camera when location changes
        if (currentPos != null && 
            _lastKnownPosition != currentPos &&
            locationProvider.mapController != null) {
          _lastKnownPosition = currentPos;
          locationProvider.mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(
              currentPos,
              locationProvider.currentZoom,
            ),
          );
        }
      };
      locationProvider.addListener(_locationListener!);
    });
  }

  @override
  void dispose() {
    _zoomDebounceTimer?.cancel();
    if (_userProviderListener != null) {
      context.read<UserProfileProvider>().removeListener(
        _userProviderListener!,
      );
    }
    if (_locationListener != null) {
      context.read<LocationProvider>().removeListener(
        _locationListener!,
      );
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Optimized camera move handler with debouncing
  void _onCameraMoveOptimized(CameraPosition position) {
    // Cancel any pending zoom debounce
    _zoomDebounceTimer?.cancel();

    // Only handle essential camera moves, skip heavy operations
    final locationProvider = context.read<LocationProvider>();

    // Store current zoom level without triggering expensive operations
    if (locationProvider.currentZoom != position.zoom) {
      // Use debouncing for zoom changes to avoid excessive operations
      _zoomDebounceTimer = Timer(const Duration(milliseconds: 150), () {
        // Only call the provider's camera move if it's essential
        locationProvider.onCameraMove(position);
      });
    }
  }

  // Optimized camera idle handler
  void _onCameraIdleOptimized() {
    _zoomDebounceTimer?.cancel();
    final locationProvider = context.read<LocationProvider>();

    // Use a small delay to ensure camera has fully stopped
    Timer(const Duration(milliseconds: 100), () {
      locationProvider.onCameraIdle();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final locationProvider = context.read<LocationProvider>();

    if (state == AppLifecycleState.resumed) {
      // Handle app resuming from background
      locationProvider.onAppResumed();
    } else if (state == AppLifecycleState.paused) {
      // Handle app going to background
      locationProvider.onAppPaused();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          //const HomeAppBar(),
          Expanded(
            child: Consumer<SelectionProvider>(
              builder: (context, selectionProvider, child) {
                return _buildCountrymenContent();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountrymenContent() {
    return Consumer<LocationProvider>(
      builder: (context, locationProvider, child) {
        if (locationProvider.isInitializing) {
          return Container(
            width: double.infinity,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Shimmer(
                duration: Duration(seconds: 1),
                interval: Duration(milliseconds: 800),
                color: Colors.white,
                colorOpacity: 0.9,
                enabled: true,
                direction: ShimmerDirection.fromLTRB(),
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.garyModern200.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          );
        }

        bool showLocationIssue = false;
        String issueMessage = '';
        IconData issueIcon = Icons.location_off;
        if (!locationProvider.hasLocationAccess) {
          if (!locationProvider.locationServicesEnabled) {
            showLocationIssue = true;
            issueMessage =
                'Location services are disabled. Please enable them to see nearby travelers.';
            issueIcon = Icons.location_disabled;
          } else if (locationProvider.locationPermission ==
                  LocationPermission.denied ||
              locationProvider.locationPermission ==
                  LocationPermission.deniedForever) {
            showLocationIssue = true;
            issueMessage =
                locationProvider.locationPermission ==
                    LocationPermission.deniedForever
                ? 'Location permission is permanently denied. Please enable it in app settings.'
                : 'Location permission is required to show nearby travelers.';
            issueIcon = Icons.location_off;
          } else if (locationProvider.errorMessage != null &&
              !locationProvider.isLoading) {
            showLocationIssue = true;
            issueMessage = locationProvider.errorMessage!;
            issueIcon = Icons.error_outline;
          }
        }

        return Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                if (locationProvider.isLoading ||
                    (locationProvider.isInitializing && !showLocationIssue))
                  Shimmer(
                    duration: Duration(seconds: 1),
                    interval: Duration(milliseconds: 800),
                    color: Colors.white,
                    colorOpacity: 0.9,
                    enabled: true,
                    direction: ShimmerDirection.fromLTRB(),
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.garyModern200.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  )
                else if (locationProvider.hasLocationAccess &&
                    locationProvider.currentPosition != null)
                  GoogleMap(
                    onMapCreated: (controller) {
                      locationProvider.onMapCreated(controller);
                      // Move camera to current position when map is created
                      if (locationProvider.currentPosition != null) {
                        controller.animateCamera(
                          CameraUpdate.newLatLngZoom(
                            locationProvider.currentPosition!,
                            locationProvider.currentZoom,
                          ),
                        );
                      }
                    },
                    initialCameraPosition: CameraPosition(
                      target:
                          locationProvider.currentPosition ??
                          const LatLng(33.6844, 73.0479),
                      zoom: locationProvider.currentZoom,
                    ),
                    markers: locationProvider.markers,
                    circles: locationProvider.circles,
                    // myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    zoomControlsEnabled: true,
                    mapToolbarEnabled: false,
                    compassEnabled: true,
                    minMaxZoomPreference: MinMaxZoomPreference(
                      locationProvider.minZoomLevel,
                      locationProvider.maxZoomLevel,
                    ),
                    onCameraMove: _onCameraMoveOptimized,
                    onCameraIdle: _onCameraIdleOptimized,
                    zoomGesturesEnabled: true,
                    rotateGesturesEnabled: false,
                    tiltGesturesEnabled:
                        false, // Disable tilt for better performance
                    onTap: (LatLng location) {
                      // Remove print statement for production performance
                      // print('Tapped at: ${location.latitude}, ${location.longitude}');
                    },
                  )
                else
                  // Placeholder for when location is not available
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.map_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Map will appear here',
                            style: pjsStyleBlack16500.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Overlay for location issues
                if (showLocationIssue)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Container(
                          margin: EdgeInsets.all(20),
                          padding: EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                issueIcon,
                                size: 48,
                                color: AppColors.primary,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Location Access Required',
                                style: pjsStyleBlack18600.copyWith(
                                  color: AppColors.black,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 12),
                              Text(
                                issueMessage,
                                style: pjsStyleBlack14400.copyWith(
                                  color: Colors.grey.shade700,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Message button
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () async {
                                        await locationProvider
                                            .forceRefreshLocationStatus();
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: AppColors.white,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color: AppColors.primary,
                                          ),
                                        ),

                                        height: 50,
                                        child: Center(
                                          child: Text(
                                            'Retry',
                                            style: pStyleBlack10400.copyWith(
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  SizedBox(width: 10),

                                  // View Profile button
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () async {
                                        await locationProvider
                                            .retryLocationAccess(
                                              context: context,
                                            );
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        height: 50,
                                        child: Center(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 5,
                                            ),
                                            child: Text(
                                              locationProvider
                                                      .locationServicesEnabled
                                                  ? 'Grant Permission'
                                                  : 'Enable Location',
                                              style: pStyleBlack10400.copyWith(
                                                color: AppColors.white,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                // // Custom my location button
                // Positioned(
                //   top: 40,
                //   right: 16,
                //   child: Container(
                //     width: 45,
                //     height: 45,
                //     decoration: BoxDecoration(
                //       color: Colors.white,
                //       borderRadius: BorderRadius.circular(8),
                //       boxShadow: [
                //         BoxShadow(
                //           color: Colors.black.withOpacity(0.1),
                //           blurRadius: 4,
                //           offset: Offset(0, 2),
                //         ),
                //       ],
                //     ),
                //     child: Material(
                //       color: Colors.transparent,
                //       child: InkWell(
                //         borderRadius: BorderRadius.circular(8),
                //         onTap: () {
                //           final locationProvider = context.read<LocationProvider>();
                //           locationProvider.getCurrentLocation(context: context);
                //         },
                //         child: Icon(
                //           Icons.my_location,
                //           color: AppColors.primary,
                //           size: 24,
                //         ),
                //       ),
                //     ),
                //   ),
                // ),
                // Floating bottom button on the map
                Positioned(
                  bottom: 10,
                  left: 120,
                  right: 120,
                  child: CustomButton(
                    text: 'Nearby Travelers',
                    onTap: () {
                      _showNearbyTravelersBottomSheet(context);
                    },
                    height: 36,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showNearbyTravelersBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header with tabs
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Nearby Travelers',
                      style: pjsStyleBlack18600.copyWith(
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Consumer<SelectionProvider>(
                      builder: (context, selectionProvider, child) {
                        return Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.lightGrey,
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
                                      await context
                                          .read<LocationProvider>()
                                          .updateFilterMode(false);
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
                                              AppImages.homeTab1,
                                              colorFilter: ColorFilter.mode(
                                                selectionProvider.isSelected(0)
                                                    ? AppColors.white
                                                    : AppColors.darkGrey,
                                                BlendMode.srcIn,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              'Countrymen',
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
                                      await context
                                          .read<LocationProvider>()
                                          .updateFilterMode(true);
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
                                          vertical: 5,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            SvgPicture.asset(
                                              AppImages.homeTab2,
                                              colorFilter: ColorFilter.mode(
                                                selectionProvider.isSelected(1)
                                                    ? AppColors.white
                                                    : AppColors.darkGrey,
                                                BlendMode.srcIn,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              'Global',
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
                  ],
                ),
              ),
              Divider(height: 1),
              // List of ProfileCards
              Expanded(
                child: Consumer2<UserProfileProvider, SelectionProvider>(
                  builder: (context, usersProvider, selectionProvider, child) {
                    final currentUser = usersProvider.currentUser;
                    final nearbyUsers = usersProvider.getFilteredUsers(
                      selectionProvider.selectedIndex == 1,
                    );

                    if (nearbyUsers.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_search,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No nearby travelers found',
                              style: pjsStyleBlack16500.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              selectionProvider.selectedIndex == 1
                                  ? 'Try expanding your search radius'
                                  : 'No countrymen nearby',
                              style: pjsStyleBlack14400.copyWith(
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: nearbyUsers.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final user = nearbyUsers[index];
                        String distance = 'Distance unknown';

                        if (currentUser?.latitude != null &&
                            currentUser?.longitude != null &&
                            user.latitude != null &&
                            user.longitude != null) {
                          final distanceInKm = usersProvider
                              .calculateDistanceToUser(user);
                          if (distanceInKm != null) {
                            distance =
                                '${distanceInKm.toStringAsFixed(1)} km away';
                          }
                        }

                        return ProfileCard(
                          status: user.status,
                          user: user,
                          name: user.fullName,
                          distance: distance,
                          countryFlag: getFlagByNationality(user.nationality),
                          countryName: user.nationality,
                          bio: user.bio.toString(),
                          profileImagePath:
                              user.profileImageUrl ?? AppImages.profileImage,
                          onChatTap: () {
                            Navigator.pop(context);
                            print('Chat with ${user.fullName}');
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
