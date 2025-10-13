// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:provider/provider.dart';
// import '../Provider/UserStatusProvider.dart';
//
// /// Debug widget to test user status feature
// /// Add this temporarily to your home screen to test
// class UserStatusDebugWidget extends StatelessWidget {
//   const UserStatusDebugWidget({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     final currentUser = FirebaseAuth.instance.currentUser;
//
//     if (currentUser == null) {
//       return Card(
//         margin: EdgeInsets.all(16),
//         child: Padding(
//           padding: EdgeInsets.all(16),
//           child: Text('No user logged in'),
//         ),
//       );
//     }
//
//     return Card(
//       margin: EdgeInsets.all(16),
//       color: Colors.blue.shade50,
//       child: Padding(
//         padding: EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Row(
//               children: [
//                 Icon(Icons.bug_report, color: Colors.blue),
//                 SizedBox(width: 8),
//                 Text(
//                   'Status Debug Panel',
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//             Divider(),
//             SizedBox(height: 8),
//
//             // Current User Info
//             Text(
//               'User ID: ${currentUser.uid.substring(0, 8)}...',
//               style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
//             ),
//             SizedBox(height: 8),
//
//             // Real-time Status from Firebase
//             StreamBuilder<DocumentSnapshot>(
//               stream: FirebaseFirestore.instance
//                   .collection('users')
//                   .doc(currentUser.uid)
//                   .snapshots(),
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return Text('Loading status...');
//                 }
//
//                 if (snapshot.hasError) {
//                   return Text(
//                     'Error: ${snapshot.error}',
//                     style: TextStyle(color: Colors.red, fontSize: 12),
//                   );
//                 }
//
//                 if (!snapshot.hasData || !snapshot.data!.exists) {
//                   return Text(
//                     '❌ User document not found!',
//                     style: TextStyle(color: Colors.red),
//                   );
//                 }
//
//                 final data = snapshot.data!.data() as Map<String, dynamic>?;
//                 final status = data?['status'] ?? 'NOT SET';
//                 final lastSeen = data?['lastSeen'] as Timestamp?;
//
//                 return Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       children: [
//                         Container(
//                           width: 12,
//                           height: 12,
//                           decoration: BoxDecoration(
//                             shape: BoxShape.circle,
//                             color: status == 'online'
//                                 ? Colors.green
//                                 : status == 'offline'
//                                     ? Colors.grey
//                                     : Colors.orange,
//                           ),
//                         ),
//                         SizedBox(width: 8),
//                         Text(
//                           'Status: $status',
//                           style: TextStyle(
//                             fontSize: 14,
//                             fontWeight: FontWeight.bold,
//                             color: status == 'online'
//                                 ? Colors.green
//                                 : Colors.grey.shade700,
//                           ),
//                         ),
//                       ],
//                     ),
//                     SizedBox(height: 4),
//                     if (lastSeen != null)
//                       Text(
//                         'Last Seen: ${_formatTimestamp(lastSeen)}',
//                         style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
//                       )
//                     else
//                       Text(
//                         'Last Seen: NOT SET',
//                         style: TextStyle(fontSize: 12, color: Colors.orange),
//                       ),
//                   ],
//                 );
//               },
//             ),
//
//             SizedBox(height: 12),
//             Divider(),
//             SizedBox(height: 8),
//
//             // Manual Test Buttons
//             Text(
//               'Manual Controls:',
//               style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
//             ),
//             SizedBox(height: 8),
//
//             Row(
//               children: [
//                 Expanded(
//                   child: ElevatedButton.icon(
//                     onPressed: () async {
//                       final provider = context.read<UserStatusProvider>();
//                       await provider.setUserOnline();
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         SnackBar(
//                           content: Text('Set to Online - Check console'),
//                           backgroundColor: Colors.green,
//                           duration: Duration(seconds: 2),
//                         ),
//                       );
//                     },
//                     icon: Icon(Icons.circle, size: 12, color: Colors.green),
//                     label: Text('Online', style: TextStyle(fontSize: 12)),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.green.shade50,
//                       foregroundColor: Colors.green.shade700,
//                       padding: EdgeInsets.symmetric(vertical: 8),
//                     ),
//                   ),
//                 ),
//                 SizedBox(width: 8),
//                 Expanded(
//                   child: ElevatedButton.icon(
//                     onPressed: () async {
//                       final provider = context.read<UserStatusProvider>();
//                       await provider.setUserOffline();
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         SnackBar(
//                           content: Text('Set to Offline - Check console'),
//                           backgroundColor: Colors.grey,
//                           duration: Duration(seconds: 2),
//                         ),
//                       );
//                     },
//                     icon: Icon(Icons.circle, size: 12, color: Colors.grey),
//                     label: Text('Offline', style: TextStyle(fontSize: 12)),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.grey.shade200,
//                       foregroundColor: Colors.grey.shade700,
//                       padding: EdgeInsets.symmetric(vertical: 8),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//
//             SizedBox(height: 8),
//
//             // Lifecycle Instructions
//             Container(
//               padding: EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 color: Colors.blue.shade100,
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     '🧪 Test Lifecycle:',
//                     style: TextStyle(
//                       fontWeight: FontWeight.bold,
//                       fontSize: 11,
//                     ),
//                   ),
//                   SizedBox(height: 4),
//                   Text(
//                     '1. Minimize app → Should go offline',
//                     style: TextStyle(fontSize: 10),
//                   ),
//                   Text(
//                     '2. Return to app → Should go online',
//                     style: TextStyle(fontSize: 10),
//                   ),
//                   Text(
//                     '3. Check console logs for details',
//                     style: TextStyle(fontSize: 10),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   String _formatTimestamp(Timestamp timestamp) {
//     final dateTime = timestamp.toDate();
//     final now = DateTime.now();
//     final difference = now.difference(dateTime);
//
//     if (difference.inSeconds < 60) {
//       return 'Just now';
//     } else if (difference.inMinutes < 60) {
//       return '${difference.inMinutes}m ago';
//     } else if (difference.inHours < 24) {
//       return '${difference.inHours}h ago';
//     } else {
//       return '${difference.inDays}d ago';
//     }
//   }
// }

