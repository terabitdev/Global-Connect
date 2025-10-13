import 'package:cloud_firestore/cloud_firestore.dart';

CollectionReference<Map<String, dynamic>> usersCollection =
FirebaseFirestore.instance.collection("users");
CollectionReference<Map<String, dynamic>> eventsCollection =
FirebaseFirestore.instance.collection("events");
CollectionReference<Map<String, dynamic>> usersTipsCollection =
FirebaseFirestore.instance.collection("tips");
CollectionReference<Map<String, dynamic>> chatRoomsCollection =
FirebaseFirestore.instance.collection("chatrooms");