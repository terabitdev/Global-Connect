import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
// import 'package:global_connect/core/const/responsive_layout.dart';
import 'package:provider/provider.dart';
// import 'package:shimmer_animation/shimmer_animation.dart';

import '../Model/EventModel.dart';
import '../Provider/EventsProvider.dart';
import '../Provider/SelectionProvider.dart';
import '../Provider/user_profile_provider.dart';
import '../Widgets/HeaderWithSearchAndActions.dart';
// import '../Widgets/InfoCardWidget.dart';
import '../Widgets/RestaurantCard.dart';
// import '../Widgets/UserTipCard.dart' show UserTipCard;
import '../core/const/app_color.dart';
import '../core/const/app_images.dart';
import '../core/theme/app_text_style.dart';

class FestivalsEvents extends StatefulWidget {
  const FestivalsEvents({super.key});

  @override
  State<FestivalsEvents> createState() => _FestivalsEventsState();
}

class _FestivalsEventsState extends State<FestivalsEvents> {
  EventsProvider? _eventsProvider;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      _eventsProvider = Provider.of<EventsProvider>(context, listen: false);
      _eventsProvider?.startListeningToEvents();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProfileProvider>().listenToCurrentUser();
    });
  }

  @override
  void dispose() {
    _eventsProvider?.stopListeningToEvents();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      top: true,
      child: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Consumer<EventsProvider>(
                  builder: (context, eventsProvider, child) {
                    return HeaderWithSearchAndActions(
                      searchHintText: 'Search festivals, cities, users... ',
                      controller: eventsProvider.searchController,
                      onChanged: eventsProvider.onSearchChanged,
                    );
                  },
                ),
                const SizedBox(height: 20),
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
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
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
                                          AppImages.music,
                                          colorFilter: ColorFilter.mode(
                                            selectionProvider.isSelected(0)
                                                ? AppColors.white
                                                : AppColors.darkGrey,
                                            BlendMode.srcIn,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          'Nearby Events',
                                          style: pjsStyleBlack14700.copyWith(
                                            color:
                                                selectionProvider.isSelected(0)
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
                                  duration: const Duration(milliseconds: 200),
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
                                          AppImages.word,
                                          colorFilter: ColorFilter.mode(
                                            selectionProvider.isSelected(1)
                                                ? AppColors.white
                                                : AppColors.darkGrey,
                                            BlendMode.srcIn,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          'Community',
                                          style: pjsStyleBlack14700.copyWith(
                                            color:
                                                selectionProvider.isSelected(1)
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
                const SizedBox(height: 20),

                Column(
                  spacing: 10,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upcoming Festivals',
                      style: pjsStyleBlack18600.copyWith(
                        color: AppColors.black,
                      ),
                    ),
                    Consumer<EventsProvider>(
                      builder: (context, eventsProvider, child) {
                        if (eventsProvider.events.isEmpty) {
                          return Container(
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              border: Border.all(color: AppColors.garyModern400.withOpacity(0.5)),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10,horizontal: 10),
                              child: Column(
                                children: [
                                  Center(
                                    child: Column(
                                      spacing: 10,
                                      children: [
                                        SvgPicture.asset(AppImages.music, width: 60, height: 41,color: AppColors.purple2,),
                                        Text(
                                          'No Events Found',
                                          style: pjsStyleBlack16600
                                        ),
                                        Text(
                                            'No upcoming events found in your area. Try\n expanding your search radius.',
                                            textAlign: TextAlign.center,
                                            style: pjsStyleBlack12500.copyWith(color: AppColors.darkGrey)
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return _buildEventsList(eventsProvider.filteredEvents);
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

  Widget _buildEventsList(List<EventModel> events) {
    return ListView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: RestaurantCard(
            restaurantImage: event.images.isNotEmpty
                ? event.images[0]
                : AppImages.bestRestaurants,
            restaurantName: event.eventName,
            cuisineType: event.eventType,
            isFeatured: event.featuredEvent,
            reviewCount: 100,
            distance: '${event.city}',
            openingHours: event.time,
            description: event.description,
            location: event.venue,
            ticketLink: event.ticketLink,
            onTap: () {
              print('Event tapped: ${event.eventName}');
              // Navigate to event details page
              // Navigator.push(context, MaterialPageRoute(
              //   builder: (context) => EventDetailsPage(event: event),
              // ));
            },
            isUpcomingFestival: true,
            onGetTickets: () {},
          ),
        );
      },
    );
  }

  // Filtering now handled by EventsProvider.filteredEvents

}
