import 'dart:async';
import 'package:flutter/material.dart';
import '../Model/EventModel.dart';
import '../core/services/firebase_services.dart';


class EventsProvider with ChangeNotifier {
  List<EventModel> _events = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription<List<EventModel>>? _eventsSubscription;
  // Search state
  final TextEditingController searchController = TextEditingController();
  String _searchQuery = '';

  List<EventModel> get events => _events;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  List<EventModel> get filteredEvents {
    if (_searchQuery.isEmpty) return _events;
    final q = _searchQuery.toLowerCase();
    return _events.where((e) {
      return e.eventName.toLowerCase().contains(q) ||
          e.eventType.toLowerCase().contains(q) ||
          e.city.toLowerCase().contains(q) ||
          e.venue.toLowerCase().contains(q);
    }).toList();
  }

  void startListeningToEvents() {
    _isLoading = true;
    _error = null;
    notifyListeners();

    _eventsSubscription = FirebaseServices.instance.getEventsStream().listen(
          (events) {
        _events = events;
        _isLoading = false;
        _error = null;
        notifyListeners();

        print('✅ Events updated: ${_events.length}');
        for (var event in _events) {
          print('📌 Event: ${event.eventName} at ${event.venue}');
        }
      },
      onError: (error) {
        _error = 'Failed to load events: $error';
        _isLoading = false;
        notifyListeners();
        print('❌ Error in events stream: $error');
      },
    );
  }

  void onSearchChanged(String value) {
    _searchQuery = value.trim();
    notifyListeners();
  }

  void stopListeningToEvents() {
    _eventsSubscription?.cancel();
    _eventsSubscription = null;
  }

  @override
  void dispose() {
    stopListeningToEvents();
    searchController.dispose();
    super.dispose();
  }
}
