import 'package:flutter/material.dart';
import 'package:global_connect/core/const/responsive_layout.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../Provider/LocationProvider.dart';
import '../../Provider/PrivateChatProvider.dart';
import '../../Widgets/CustomAppBar.dart';
import '../../Widgets/buildTabButton.dart';
import '../../core/const/app_color.dart';
import '../../core/theme/app_text_style.dart';
class DiscoveryRadiusScreen extends StatefulWidget {
  const DiscoveryRadiusScreen({super.key});

  @override
  State<DiscoveryRadiusScreen> createState() => _DiscoveryRadiusScreenState();
}

class _DiscoveryRadiusScreenState extends State<DiscoveryRadiusScreen> {
  double _selectedVisibilityRadius = 5.0; // Default visibility radius
  bool _isLoadingVisibility = true;
  double? _updatingRadius;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationProvider>().getCurrentLocation();
      _loadUserVisibilityRadius();
      
      // Sync with LocationProvider's current radius
      final locationProvider = context.read<LocationProvider>();
      setState(() {
        _selectedVisibilityRadius = locationProvider.selectedRadius;
      });
    });
  }

  // Load user's current visibility radius from Firebase
  Future<void> _loadUserVisibilityRadius() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final DocumentSnapshot userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (userDoc.exists && mounted) {
        final data = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _selectedVisibilityRadius = data['visibilityRadius']?.toDouble() ?? 5.0;
          _isLoadingVisibility = false;
        });
      }
    } catch (e) {
      print('❌ Error loading user visibility radius: $e');
      if (mounted) {
        setState(() {
          _isLoadingVisibility = false;
        });
      }
    }
  }

  // Save user's visibility radius to Firebase
  Future<void> _saveVisibilityRadius(double radius) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) return;

      await _firestore.collection('users').doc(currentUser.uid).update({
        'visibilityRadius': radius,
        'lastVisibilityUpdate': FieldValue.serverTimestamp(),
      });

      print('💾 Saved visibility radius: ${radius}km to Firebase');
      
      // Show feedback to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Visibility set to ${radius.toInt()}km'),
            duration: Duration(seconds: 2),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      print('❌ Error saving visibility radius: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save visibility setting'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Method to handle radius selection with immediate feedback
  Future<void> _onRadiusSelected(int tabIndex, double radius) async {
    try {
      print('🎯 User selected radius: ${radius}km (tab: $tabIndex)');

      // Update the tab selection immediately
      context.read<PrivateChatProvider>().setSelectedTab(tabIndex);

      // Update the map radius and zoom with real-time feedback
      await context.read<LocationProvider>().setDiscoveryRadius(radius);

      print('✅ Radius selection completed successfully');
    } catch (e) {
      print('❌ Error in radius selection: $e');
      // Optionally show a snackbar or error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update radius: $e'),
              backgroundColor: Colors.red,
            )
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: true,
      top: false,
      child: Scaffold(
        appBar: CustomAppBar2(
          title: Text(
            'Discovery & Visibility',
            style: pjsStyleBlack18600.copyWith(color: AppColors.black),
          ),
        ),
        body: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.screenWidth * 0.05,
            vertical: context.screenHeight * 0.02,
          ),
          child: SingleChildScrollView(
            child: Column(
              spacing: 20,
              children: [
                // Discovery Section
                // _buildSectionContainer(
                //   title: 'Discovery Radius',
                //   subtitle: 'How far you want to discover other travelers',
                //   icon: Icons.explore,
                //   child: Consumer<PrivateChatProvider>(
                //     builder: (context, privateChatProvider, child) =>
                //         Container(
                //           decoration: BoxDecoration(
                //             color: AppColors.lightGrey,
                //             borderRadius: BorderRadius.circular(12),
                //           ),
                //           child: Padding(
                //             padding: const EdgeInsets.all(8.0),
                //             child: Row(
                //               children: [
                //                 buildTabButton(
                //                   context,
                //                   '5Km',
                //                   0,
                //                   privateChatProvider.selectedTabIndex == 0,
                //                       () => _onRadiusSelected(0, 5.0),
                //                 ),
                //                 buildTabButton(
                //                   context,
                //                   '15Km',
                //                   1,
                //                   privateChatProvider.selectedTabIndex == 1,
                //                       () => _onRadiusSelected(1, 15.0),
                //                 ),
                //                 buildTabButton(
                //                   context,
                //                   '25Km',
                //                   2,
                //                   privateChatProvider.selectedTabIndex == 2,
                //                       () => _onRadiusSelected(2, 25.0),
                //                 ),
                //               ],
                //             ),
                //           ),
                //         ),
                //   ),
                // ),

                // Visibility Section
                _buildSectionContainer(
                  title: 'Discovery Radius',
                  subtitle: 'How far you want to discover other travelers',
                  icon: Icons.explore,
                  child: Consumer<LocationProvider>(
                    builder: (context, locationProvider, child) {
                      return Container(
                        decoration: BoxDecoration(
                          color: AppColors.lightGrey,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              _buildVisibilityTabButton('5Km', 5.0, locationProvider),
                              _buildVisibilityTabButton('15Km', 15.0, locationProvider),
                              _buildVisibilityTabButton('25Km', 25.0, locationProvider),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                _buildCountrymenContent(),
              ],
            ),
          ),
        ),
      ),
    );
  }



  // Helper method to build section containers
  Widget _buildSectionContainer({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 20),
                SizedBox(width: 8),
                Text(
                  title,
                  style: pjsStyleBlack16600.copyWith(color: AppColors.black),
                ),
              ],
            ),
            SizedBox(height: 4),
            Text(
              subtitle,
              style: pjsStyleBlack12400.copyWith(color: Colors.grey.shade600),
            ),
            SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  // Helper method to build visibility tab buttons
  Widget _buildVisibilityTabButton(String label, double radius, LocationProvider locationProvider) {
    final bool isSelected = locationProvider.selectedRadius == radius;
    final bool isThisButtonUpdating = _updatingRadius == radius;
    final bool isLoading = _isLoadingVisibility;
    
    return Expanded(
      child: GestureDetector(
        onTap: (isLoading || _updatingRadius != null) ? null : () async {
          setState(() {
            _updatingRadius = radius;
          });
          
          try {
            // Update LocationProvider's radius immediately (this updates map instantly)
            await locationProvider.setDiscoveryRadius(radius);
            
            // Also save to Firebase for persistence
            setState(() {
              _selectedVisibilityRadius = radius;
            });
            await _saveVisibilityRadius(radius);
            
            print('✅ Discovery radius updated to ${radius}km with immediate visual feedback');
          } catch (e) {
            print('❌ Error updating discovery radius: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to update radius'),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          } finally {
            if (mounted) {
              setState(() {
                _updatingRadius = null;
              });
            }
          }
        },
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 4),
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: (isLoading || isThisButtonUpdating) ? 
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isSelected ? Colors.white : AppColors.primary,
                  ),
                ),
              )
              : Text(
                label,
                style: pjsStyleBlack14500.copyWith(
                  color: isSelected ? Colors.white : AppColors.black,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
          ),
        ),
      ),
    );
  }

  Widget _buildCountrymenContent() {
    return Consumer<LocationProvider>(
      builder: (context, locationProvider, child) {
        return Column(
          children: [
            Container(
              height: context.screenHeight * 0.5,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: locationProvider.isLoading
                    ? Shimmer(
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
                      color: AppColors.garyModern200.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),

                  ),
                )
                    : Stack(
                  children: [
                    GoogleMap(
                      key: ValueKey(
                          'googlemap_${locationProvider.selectedRadius}'),
                      // Force rebuild
                      onMapCreated: locationProvider.onMapCreated,
                      initialCameraPosition: CameraPosition(
                        target: locationProvider.currentPosition ??
                            const LatLng(33.6844, 73.0479),
                        zoom: locationProvider.currentZoom,
                      ),
                      markers: locationProvider.markers,
                      circles: locationProvider.circles,
                      // Add radius circles
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                      compassEnabled: false,
                      scrollGesturesEnabled: false,
                      rotateGesturesEnabled: false,
                      tiltGesturesEnabled: false,
                      zoomGesturesEnabled: false,
                      onTap: (LatLng location) {
                        print('Tapped at: ${location.latitude}, ${location
                            .longitude}');
                      },
                    ),

                    // Loading overlay for when updating markers
                    if (locationProvider.isLoadingUsers)
                      Container(
                        color: Colors.black.withOpacity(0.3),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Updating...',
                                  style: pjsStyleBlack14500.copyWith(
                                    color: AppColors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

          ],
        );
      },
    );
  }

}
