const {initializeApp} = require('firebase-admin/app');
const {getFirestore, FieldValue} = require('firebase-admin/firestore');
const {getMessaging} = require('firebase-admin/messaging');
const {onDocumentCreated} = require('firebase-functions/v2/firestore');
const {onCall} = require('firebase-functions/v2/https');
const {logger} = require('firebase-functions');
const {setGlobalOptions} = require('firebase-functions/v2');
const axios = require('axios');

// Set global options for all functions
setGlobalOptions({
  region: 'us-east1',
  maxInstances: 10,
});

// Initialize Firebase Admin SDK
initializeApp();
const db = getFirestore();
const messaging = getMessaging();

/**
 * Cloud Function v2 that triggers when a new document is created in the 'notifications' collection
 * and sends FCM push notifications to all registered users
 */
exports.sendNotificationToAllUsers = onDocumentCreated(
  {
    document: 'notifications/{notificationId}',
    region: 'us-east1',
  },
  async (event) => {
    const {notificationId} = event.params;
    const notificationData = event.data.data();
    
    try {
      logger.log(`New notification created with ID: ${notificationId}`, notificationData);

      // Extract notification details from the document
      const {
        title = 'New Notification',
        message = 'You have a new notification',
        eventName = '',
        eventCity = '',
        eventDate = '',
        eventTime = '',
        type = 'general',
        targetAudience = 'all'
      } = notificationData;

      // Get all users with FCM tokens
      logger.log('Fetching users with FCM tokens...');
      // Firestore only allows one != filter, so we'll just check for non-null and filter empty strings later
      const usersSnapshot = await db.collection('users')
        .where('fcmToken', '!=', null)
        .get();

      if (usersSnapshot.empty) {
        logger.log('No users found with FCM tokens');
        await event.data.ref.update({
          notificationSent: false,
          error: 'No users with FCM tokens found',
          processedAt: FieldValue.serverTimestamp()
        });
        return {success: false, error: 'No users with FCM tokens'};
      }

      logger.log(`Found ${usersSnapshot.size} users with FCM tokens`);

      // Collect all valid FCM tokens
      const tokens = [];
      const invalidUsers = [];

      usersSnapshot.forEach((doc) => {
        const userData = doc.data();
        const fcmToken = userData.fcmToken;
        
        if (fcmToken && typeof fcmToken === 'string' && fcmToken.trim() !== '') {
          tokens.push(fcmToken.trim());
        } else {
          invalidUsers.push(doc.id);
        }
      });

      if (tokens.length === 0) {
        logger.log('No valid FCM tokens found');
        await event.data.ref.update({
          notificationSent: false,
          error: 'No valid FCM tokens found',
          processedAt: FieldValue.serverTimestamp()
        });
        return {success: false, error: 'No valid FCM tokens'};
      }

      logger.log(`Collected ${tokens.length} valid FCM tokens`);

      // Create the notification payload
      const payload = {
        notification: {
          title: title,
          body: message,
        },
        data: {
          notificationId: notificationId,
          eventName: eventName || '',
          eventCity: eventCity || '',
          eventDate: eventDate || '',
          eventTime: eventTime || '',
          type: type,
          targetAudience: targetAudience,
          clickAction: 'FLUTTER_NOTIFICATION_CLICK',
        },
        android: {
          notification: {
            channelId: 'chat_channel',
            icon: 'ic_launcher',
            color: '#FF6B6B',
            sound: 'default',
            priority: 'high',
          },
          priority: 'high',
        },
        apns: {
          payload: {
            aps: {
              alert: {
                title: title,
                body: message,
              },
              sound: 'default',
              badge: 1,
            },
          },
          headers: {
            'apns-priority': '10',
          },
        },
      };

      // Send notifications in batches (FCM allows max 500 tokens per request)
      const batchSize = 500;
      const batches = [];
      
      for (let i = 0; i < tokens.length; i += batchSize) {
        batches.push(tokens.slice(i, i + batchSize));
      }

      logger.log(`Sending notifications in ${batches.length} batch(es)`);

      let totalSuccessful = 0;
      let totalFailed = 0;
      const failedTokens = [];

      // Process each batch
      for (let batchIndex = 0; batchIndex < batches.length; batchIndex++) {
        const batchTokens = batches[batchIndex];
        
        try {
          logger.log(`Processing batch ${batchIndex + 1}/${batches.length} with ${batchTokens.length} tokens`);
          
          const response = await messaging.sendEachForMulticast({
            tokens: batchTokens,
            ...payload,
          });

          logger.log(`Batch ${batchIndex + 1} results: ${response.successCount} successful, ${response.failureCount} failed`);

          totalSuccessful += response.successCount;
          totalFailed += response.failureCount;

          // Collect failed tokens for cleanup
          if (response.failureCount > 0) {
            response.responses.forEach((resp, idx) => {
              if (!resp.success) {
                const error = resp.error;
                failedTokens.push({
                  token: batchTokens[idx],
                  error: error?.code || 'unknown_error',
                  message: error?.message || 'Unknown error',
                });
              }
            });
          }

        } catch (batchError) {
          logger.error(`Error processing batch ${batchIndex + 1}:`, batchError);
          totalFailed += batchTokens.length;
        }

        // Add small delay between batches to avoid rate limiting
        if (batchIndex < batches.length - 1) {
          await new Promise(resolve => setTimeout(resolve, 100));
        }
      }

      // Clean up invalid tokens
      if (failedTokens.length > 0) {
        logger.log(`Cleaning up ${failedTokens.length} failed tokens`);
        await cleanupInvalidTokens(failedTokens);
      }

      // Log final results
      logger.log('Notification sending completed:', {
        totalTokens: tokens.length,
        totalSuccessful: totalSuccessful,
        totalFailed: totalFailed,
        invalidUsers: invalidUsers.length,
      });

      // Update the notification document with sending results
      await event.data.ref.update({
        notificationSent: true,
        sentAt: FieldValue.serverTimestamp(),
        recipientsCount: totalSuccessful,
        failedCount: totalFailed,
        totalTokens: tokens.length,
        processedAt: FieldValue.serverTimestamp()
      });

      return {
        success: true,
        totalSent: totalSuccessful,
        totalFailed: totalFailed,
        batches: batches.length,
      };

    } catch (error) {
      logger.error('Error in sendNotificationToAllUsers function:', error);
      
      // Update notification document with error status
      try {
        await event.data.ref.update({
          notificationSent: false,
          error: error.message,
          errorAt: FieldValue.serverTimestamp(),
          processedAt: FieldValue.serverTimestamp()
        });
      } catch (updateError) {
        logger.error('Failed to update notification document with error:', updateError);
      }

      // Return error info
      return {
        success: false,
        error: error.message,
      };
    }
  }
);

/**
 * Helper function to clean up invalid FCM tokens from users collection
 */
async function cleanupInvalidTokens(failedTokens) {
  try {
    const batch = db.batch();
    let batchCount = 0;

    for (const failedToken of failedTokens) {
      // Only remove tokens that are definitely invalid
      if (isInvalidTokenError(failedToken.error)) {
        // Find users with this invalid token
        const usersWithToken = await db.collection('users')
          .where('fcmToken', '==', failedToken.token)
          .get();

        usersWithToken.forEach((doc) => {
          batch.update(doc.ref, {
            fcmToken: FieldValue.delete(),
            tokenInvalidatedAt: FieldValue.serverTimestamp(),
            lastTokenError: failedToken.error
          });
          batchCount++;
        });

        // Commit batch if it reaches Firebase limit
        if (batchCount >= 500) {
          await batch.commit();
          batchCount = 0;
        }
      }
    }

    // Commit remaining operations
    if (batchCount > 0) {
      await batch.commit();
    }

    logger.log(`Cleaned up ${batchCount} invalid FCM tokens`);

  } catch (cleanupError) {
    logger.error('Error cleaning up invalid tokens:', cleanupError);
  }
}

/**
 * Check if the error indicates an invalid/expired token
 */
function isInvalidTokenError(errorCode) {
  const invalidTokenErrors = [
    'messaging/registration-token-not-registered',
    'messaging/invalid-registration-token',
    'messaging/invalid-argument',
  ];
  
  return invalidTokenErrors.includes(errorCode);
}

/**
 * HTTP callable function v2 to manually test notifications
 */
exports.testNotification = onCall(async (request) => {
  // Ensure user is authenticated
  if (!request.auth) {
    throw new Error('User must be authenticated to call this function.');
  }

  try {
    const {
      title = 'Test Notification',
      message = 'This is a test notification from admin panel',
      eventName = 'Test Event',
      eventCity = 'Test City',
    } = request.data;

    // Create a test notification document that will trigger the main function
    const testNotification = {
      title,
      message,
      eventName,
      eventCity,
      eventDate: new Date().toISOString().split('T')[0],
      eventTime: new Date().toLocaleTimeString(),
      type: 'test',
      targetAudience: 'all',
      isRead: false,
      createdAt: FieldValue.serverTimestamp(),
      createdBy: request.auth.uid,
    };

    const docRef = await db.collection('notifications').add(testNotification);
    
    return {
      success: true,
      message: 'Test notification created and will be sent to all users',
      notificationId: docRef.id,
    };

  } catch (error) {
    logger.error('Error in testNotification function:', error);
    throw new Error(`Failed to create test notification: ${error.message}`);
  }
});

/**
 * Cloud Function v2 to create notification when connection request is sent
 * This only creates the notification, push notification is handled by sendAllNotifications
 */
exports.createConnectionRequestNotification = onDocumentCreated(
  {
    document: 'users/{userId}/ReceivedConnectionRequests/{requesterId}',
    region: 'us-east1',
  },
  async (event) => {
    try {
      const userId = event.params.userId;
      const requesterId = event.params.requesterId;
      
      logger.log(`Creating connection request notification for user: ${userId} from: ${requesterId}`);

      // Create notification in user's notifications subcollection
      const notificationData = {
        type: 'connection_request',
        fromUserId: requesterId,
        createdAt: FieldValue.serverTimestamp(),
        isRead: false,
        status: 'pending',
      };

      await db.collection('users')
        .doc(userId)
        .collection('notifications')
        .add(notificationData);

      logger.log('Connection request notification created successfully');
      return { success: true };
    } catch (error) {
      logger.error('Error in createConnectionRequestNotification:', error);
      return null;
    }
  }
);

/**
 * Cloud Function v2 to send push notifications for all notification types
 */
exports.sendAllNotifications = onDocumentCreated(
  {
    document: 'users/{userId}/notifications/{notificationId}',
    region: 'us-east1',
  },
  async (event) => {
    try {
      const notificationData = event.data.data();
      const userId = event.params.userId;
      const notificationId = event.params.notificationId;
      
      logger.log(`🚀 CLOUD FUNCTION TRIGGERED: Processing ${notificationData.type} notification for user: ${userId}`);
      logger.log('🔍 Full notification data:', JSON.stringify(notificationData, null, 2));

      // Get the user's FCM token
      const userDoc = await db.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        logger.log('User document does not exist');
        return null;
      }

      const userData = userDoc.data();
      const fcmToken = userData.fcmToken;

      if (!fcmToken) {
        logger.log('No FCM token found for user');
        return null;
      }

      logger.log(`Found FCM token for user ${userId}: ${fcmToken.substring(0, 20)}...`);

      // Get sender's name for the notification
      const fromUserId = notificationData.fromUserId;
      let senderName = 'Someone';
      
      if (fromUserId) {
        try {
          const senderDoc = await db.collection('users').doc(fromUserId).get();
          if (senderDoc.exists) {
            senderName = senderDoc.data().fullName || 'Someone';
          }
        } catch (error) {
          logger.error('Error fetching sender info:', error);
        }
      }

      // Prepare notification payload based on type
      let title, body, channelId, color;
      
      switch (notificationData.type) {
        case 'connection_request':
          title = 'New Connection Request';
          body = `${senderName} wants to connect with you`;
          channelId = 'connection_requests';
          color = '#FF6B6B';
          break;
        case 'connection_accepted':
          title = 'Connection Accepted';
          body = `${senderName} accepted your connection request`;
          channelId = 'connection_updates';
          color = '#4CAF50';
          break;
        case 'follow':
          title = 'New Follower';
          body = `${senderName} started following you`;
          channelId = 'follow_notifications';
          color = '#4CAF50';
          break;
        case 'follow_back':
          title = 'Followed You Back';
          body = `${senderName} followed you back`;
          channelId = 'follow_notifications';
          color = '#4CAF50';
          break;
        case 'like':
          title = 'New Like';
          body = `${senderName} liked your post`;
          channelId = 'post_interactions';
          color = '#FF6B6B';
          break;
        case 'comment':
          title = 'New Comment';
          const commentText = notificationData.commentText;
          if (commentText && commentText.trim() !== '') {
            body = `${senderName}: "${commentText}"`;
          } else {
            body = `${senderName} commented on your post`;
          }
          channelId = 'post_interactions';
          color = '#4CAF50';
          break;
        default:
          title = 'New Notification';
          body = `You have a new notification from ${senderName}`;
          channelId = 'general';
          color = '#FF6B6B';
      }

      const payload = {
        notification: {
          title: title,
          body: body,
        },
        data: {
          type: notificationData.type,
          fromUserId: fromUserId || '',
          postId: notificationData.postId || '',
          notificationId: notificationId,
          clickAction: 'FLUTTER_NOTIFICATION_CLICK',
        },
        android: {
          notification: {
            channelId: channelId,
            priority: 'high',
            icon: 'ic_launcher',
            color: color,
            sound: 'default',
          },
          priority: 'high',
        },
        apns: {
          payload: {
            aps: {
              alert: {
                title: title,
                body: body,
              },
              sound: 'default',
              badge: 1,
            },
          },
          headers: {
            'apns-priority': '10',
          },
        },
      };

      logger.log(`Sending ${notificationData.type} notification with payload:`, JSON.stringify(payload, null, 2));

      // Send the notification
      const response = await messaging.send({
        token: fcmToken,
        ...payload,
      });
      
      logger.log(`${notificationData.type} notification sent successfully:`, response);
      return response;

    } catch (error) {
      logger.error(`Error sending ${notificationData.type} notification:`, error);
      return null;
    }
  }
);

/**
 * Simple test function to verify notifications are being created
 */
exports.testNotificationCreation = onDocumentCreated(
  {
    document: 'users/{userId}/notifications/{notificationId}',
    region: 'us-east1',
  },
  async (event) => {
    const notificationData = event.data.data();
    const userId = event.params.userId;
    const notificationId = event.params.notificationId;
    
    logger.log('🔥 TEST FUNCTION: Notification created!');
    logger.log('🔥 TEST: User ID:', userId);
    logger.log('🔥 TEST: Notification ID:', notificationId);
    logger.log('🔥 TEST: Type:', notificationData.type);
    logger.log('🔥 TEST: From User:', notificationData.fromUserId);
    
    return { success: true, message: 'Test function executed' };
  }
);

/**
 * Cloud Function v2 to create connection accepted notification when connection is established
 */
exports.onConnectionEstablished = onDocumentCreated(
  {
    document: 'users/{userId}/Connections/{connectionId}',
    region: 'us-east1',
  },
  async (event) => {
    try {
      const connectionData = event.data.data();
      const userId = event.params.userId;
      const connectionId = event.params.connectionId;
      
      // Only process accepted connections
      if (connectionData.status !== 'accepted') {
        logger.log('Connection not accepted, skipping...');
        return null;
      }

      // Check if this is the requester's connection document
      // The requester is the one who should get the "connection accepted" notification
      // This happens when User B accepts User A's request, so User A gets notification
      if (connectionData.userId === connectionId) {
        logger.log(`Creating connection accepted notification for requester: ${connectionId}`);
        
        const notificationData = {
          type: 'connection_accepted',
          fromUserId: userId, // The user who accepted the request
          createdAt: FieldValue.serverTimestamp(),
          isRead: false,
          status: 'accepted',
        };

        // Create notification for the original requester
        await db.collection('users')
          .doc(connectionId)
          .collection('notifications')
          .add(notificationData);

        logger.log('Connection accepted notification created successfully');
      } else {
        logger.log('This is accepter document, no notification needed');
      }

      return { success: true };
    } catch (error) {
      logger.error('Error in onConnectionEstablished:', error);
      return null;
    }
  }
);

/**
 * Cloud Function v2 to create individual notifications for all users when an event is created
 */
exports.createEventNotificationsForAllUsers = onDocumentCreated(
  {
    document: 'notifications/{notificationId}',
    region: 'us-east1',
  },
  async (event) => {
    try {
      const notificationData = event.data.data();
      const notificationId = event.params.notificationId;
      
      logger.log(`Creating individual notifications for event: ${notificationId}`);

      // Get all users
      const usersSnapshot = await db.collection('users')
        .where('role', '==', 'user')
        .get();

      if (usersSnapshot.empty) {
        logger.log('No users found to create notifications for');
        return null;
      }

      logger.log(`Creating notifications for ${usersSnapshot.size} users`);

      // Create notifications in batches
      const batch = db.batch();
      let batchCount = 0;

      for (const userDoc of usersSnapshot.docs) {
        const userId = userDoc.id;
        
        // Create individual notification for each user
        const userNotificationRef = db.collection('users')
          .doc(userId)
          .collection('notifications')
          .doc();

        batch.set(userNotificationRef, {
          ...notificationData,
          createdAt: FieldValue.serverTimestamp(),
        });

        batchCount++;

        // Commit batch if it reaches Firebase limit (500)
        if (batchCount >= 500) {
          await batch.commit();
          logger.log(`Committed batch of ${batchCount} notifications`);
          batchCount = 0;
        }
      }

      // Commit remaining notifications
      if (batchCount > 0) {
        await batch.commit();
        logger.log(`Committed final batch of ${batchCount} notifications`);
      }

      logger.log('Individual notifications created for all users successfully');
      return { success: true, usersCount: usersSnapshot.size };

    } catch (error) {
      logger.error('Error creating individual notifications:', error);
      return null;
    }
  }
);

/**
 * Cloud Function v2 to send location-based notifications when new tips are created
 * Triggers when a new tip is added to the 'tips' collection
 */
exports.sendTipLocationNotifications = onDocumentCreated(
  {
    document: 'tips/{tipId}',
    region: 'us-east1',
  },
  async (event) => {
    try {
      const tipData = event.data.data();
      const tipId = event.params.tipId;
      
      logger.log(`Processing new tip notification: ${tipId}`);
      logger.log('Tip data:', JSON.stringify(tipData, null, 2));

      // Extract location information from tip
      // Check if tip data is in userTips array format
      let actualTipData = tipData;
      if (tipData.userTips && Array.isArray(tipData.userTips) && tipData.userTips.length > 0) {
        actualTipData = tipData.userTips[0]; // Get the first tip from the array
        logger.log('Found tip in userTips array format');
      }
      
      const { latitude, longitude, city, tipCity, title, category, createdBy } = actualTipData;
      
      if (!latitude || !longitude) {
        logger.log('Tip has no location coordinates, skipping location-based notifications');
        return null;
      }

      // Get city name from tip data (prioritize tipCity, then city, then reverse geocode)
      let targetCity = tipCity || city;
      
      if (!targetCity && latitude && longitude) {
        logger.log('No city in tip data, performing reverse geocoding...');
        targetCity = await reverseGeocode(latitude, longitude);
      }

      if (!targetCity) {
        logger.log('Could not determine city for tip, skipping notifications');
        return null;
      }

      logger.log(`Looking for users in city: ${targetCity}`);

      // Get tip creator's name for notification
      let creatorName = 'Someone';
      try {
        const creatorDoc = await db.collection('users').doc(createdBy).get();
        if (creatorDoc.exists) {
          creatorName = creatorDoc.data().fullName || 'Someone';
        }
      } catch (error) {
        logger.error('Error fetching tip creator info:', error);
      }

      // Find users in the same city with newTipsAndEvents enabled
      // Note: Firestore allows only one inequality filter, so we'll filter in two steps
      const usersSnapshot = await db.collection('users')
        .where('currentCity', '==', targetCity)
        .get();

      if (usersSnapshot.empty) {
        logger.log(`No users found in ${targetCity}`);
        return null;
      }

      logger.log(`Found ${usersSnapshot.size} users in ${targetCity}, filtering for notification settings...`);

      // Collect FCM tokens for eligible users (exclude tip creator, check notification settings)
      const tokens = [];
      const notificationRecipients = [];

      usersSnapshot.forEach((doc) => {
        const userData = doc.data();
        const userId = doc.id;
        
        // Don't notify the tip creator
        if (userId === createdBy) {
          logger.log(`Skipping tip creator: ${userId}`);
          return;
        }

        // Check if user has tip notifications enabled
        const appSettings = userData.appSettings || {};
        const newTipsAndEvents = appSettings.newTipsAndEvents;
        
        if (!newTipsAndEvents) {
          logger.log(`User ${userId} has tip notifications disabled`);
          return;
        }

        const fcmToken = userData.fcmToken;
        if (fcmToken && typeof fcmToken === 'string' && fcmToken.trim() !== '') {
          tokens.push(fcmToken.trim());
          notificationRecipients.push({
            userId: userId,
            token: fcmToken.trim(),
            name: userData.fullName || 'User'
          });
          logger.log(`Added user ${userId} (${userData.fullName}) for tip notification`);
        } else {
          logger.log(`User ${userId} has no valid FCM token`);
        }
      });

      if (tokens.length === 0) {
        logger.log('No valid FCM tokens found for users in target city');
        return null;
      }

      logger.log(`Sending tip notifications to ${tokens.length} users`);

      // Create notification payload
      const payload = {
        notification: {
          title: `New ${category || 'Travel'} Tip in ${targetCity}`,
          body: `${creatorName} shared a tip: "${title}"`,
        },
        data: {
          type: 'new_tip',
          tipId: tipId,
          city: targetCity,
          category: category || '',
          createdBy: createdBy,
          clickAction: 'FLUTTER_NOTIFICATION_CLICK',
        },
        android: {
          notification: {
            channelId: 'tips_notifications',
            icon: 'ic_launcher',
            color: '#4CAF50',
            sound: 'default',
            priority: 'high',
          },
          priority: 'high',
        },
        apns: {
          payload: {
            aps: {
              alert: {
                title: `New ${category} Tip in ${targetCity}`,
                body: `${creatorName} shared: "${title}"`,
              },
              sound: 'default',
              badge: 1,
            },
          },
          headers: {
            'apns-priority': '10',
          },
        },
      };

      // Send notifications in batches
      const batchSize = 500;
      const batches = [];
      
      for (let i = 0; i < tokens.length; i += batchSize) {
        batches.push(tokens.slice(i, i + batchSize));
      }

      logger.log(`Sending tip notifications in ${batches.length} batch(es)`);

      let totalSuccessful = 0;
      let totalFailed = 0;

      // Process each batch
      for (let batchIndex = 0; batchIndex < batches.length; batchIndex++) {
        const batchTokens = batches[batchIndex];
        
        try {
          const response = await messaging.sendEachForMulticast({
            tokens: batchTokens,
            ...payload,
          });

          logger.log(`Tip notification batch ${batchIndex + 1} results: ${response.successCount} successful, ${response.failureCount} failed`);
          totalSuccessful += response.successCount;
          totalFailed += response.failureCount;

        } catch (batchError) {
          logger.error(`Error processing tip notification batch ${batchIndex + 1}:`, batchError);
          totalFailed += batchTokens.length;
        }

        // Add delay between batches
        if (batchIndex < batches.length - 1) {
          await new Promise(resolve => setTimeout(resolve, 100));
        }
      }

      // Create individual notification documents for users in the city
      await createIndividualTipNotifications(notificationRecipients, actualTipData, tipId, targetCity, creatorName);

      logger.log('Tip location notifications completed:', {
        tipId: tipId,
        targetCity: targetCity,
        totalNotified: totalSuccessful,
        totalFailed: totalFailed,
      });

      return {
        success: true,
        tipId: tipId,
        city: targetCity,
        totalNotified: totalSuccessful,
        totalFailed: totalFailed,
      };

    } catch (error) {
      logger.error('Error in sendTipLocationNotifications:', error);
      return null;
    }
  }
);

/**
 * Helper function to perform reverse geocoding using Google Maps API
 */
async function reverseGeocode(latitude, longitude) {
  try {
    // Use the Google Maps API key from functions config
    const apiKey = 'AIzaSyAKw20hLIUV61yatHnIRjoYB-oaCnLT-1c';
    
    if (!apiKey) {
      logger.error('GOOGLE_MAPS_API_KEY environment variable not set');
      return null;
    }

    const url = `https://maps.googleapis.com/maps/api/geocode/json?latlng=${latitude},${longitude}&key=${apiKey}`;
    
    const response = await axios.get(url);
    
    if (response.data.status === 'OK' && response.data.results.length > 0) {
      const result = response.data.results[0];
      
      // Look for locality (city) in address components
      for (const component of result.address_components) {
        if (component.types.includes('locality')) {
          return component.long_name;
        }
        // Fallback to administrative_area_level_2 if locality not found
        if (component.types.includes('administrative_area_level_2')) {
          return component.long_name;
        }
      }
    }
    
    logger.error('Could not extract city from reverse geocoding result');
    return null;
    
  } catch (error) {
    logger.error('Error in reverse geocoding:', error);
    return null;
  }
}

/**
 * Helper function to create individual notification documents for tip recipients
 */
async function createIndividualTipNotifications(recipients, tipData, tipId, city, creatorName) {
  try {
    const batch = db.batch();
    let batchCount = 0;

    for (const recipient of recipients) {
      const notificationRef = db.collection('users')
        .doc(recipient.userId)
        .collection('notifications')
        .doc();

      const notificationData = {
        type: 'new_tip',
        tipId: tipId,
        fromUserId: tipData.createdBy,
        city: city,
        category: tipData.category || '',
        tipTitle: tipData.title || '',
        creatorName: creatorName,
        createdAt: FieldValue.serverTimestamp(),
        isRead: false,
      };

      batch.set(notificationRef, notificationData);
      batchCount++;

      // Commit batch if it reaches Firebase limit
      if (batchCount >= 500) {
        await batch.commit();
        logger.log(`Committed batch of ${batchCount} tip notifications`);
        batchCount = 0;
      }
    }

    // Commit remaining notifications
    if (batchCount > 0) {
      await batch.commit();
      logger.log(`Committed final batch of ${batchCount} tip notifications`);
    }

    logger.log(`Created individual tip notifications for ${recipients.length} users`);

  } catch (error) {
    logger.error('Error creating individual tip notifications:', error);
  }
}

/**
 * Cloud Function v2 to send location-based notifications when new events are created
 * Triggers when a new event is added to the 'events' collection
 */
exports.sendEventLocationNotifications = onDocumentCreated(
  {
    document: 'events/{eventId}',
    region: 'us-east1',
  },
  async (event) => {
    try {
      const eventData = event.data.data();
      const eventId = event.params.eventId;
      
      logger.log(`Processing new event notification: ${eventId}`);
      logger.log('Event data:', JSON.stringify(eventData, null, 2));

      // Extract information from event
      const { city, eventName, eventType, date, time, createdBy, venue } = eventData;
      
      if (!city) {
        logger.log('Event has no city specified, skipping location-based notifications');
        return null;
      }

      logger.log(`Looking for users in city: ${city}`);

      // Get event creator's name for notification
      let creatorName = 'Someone';
      try {
        const creatorDoc = await db.collection('users').doc(createdBy).get();
        if (creatorDoc.exists) {
          creatorName = creatorDoc.data().fullName || 'Someone';
        }
      } catch (error) {
        logger.error('Error fetching event creator info:', error);
      }

      // Find users in the same city with newTipsAndEvents enabled
      const usersSnapshot = await db.collection('users')
        .where('currentCity', '==', city)
        .where('appSettings.newTipsAndEvents', '==', true)
        .get();

      if (usersSnapshot.empty) {
        logger.log(`No users found in ${city} with event notifications enabled`);
        return null;
      }

      logger.log(`Found ${usersSnapshot.size} users in ${city} to notify`);

      // Collect FCM tokens for eligible users (exclude event creator)
      const tokens = [];
      const notificationRecipients = [];

      usersSnapshot.forEach((doc) => {
        const userData = doc.data();
        const userId = doc.id;
        
        // Don't notify the event creator
        if (userId === createdBy) {
          return;
        }

        const fcmToken = userData.fcmToken;
        if (fcmToken && typeof fcmToken === 'string' && fcmToken.trim() !== '') {
          tokens.push(fcmToken.trim());
          notificationRecipients.push({
            userId: userId,
            token: fcmToken.trim(),
            name: userData.fullName || 'User'
          });
        }
      });

      if (tokens.length === 0) {
        logger.log('No valid FCM tokens found for users in target city');
        return null;
      }

      logger.log(`Sending event notifications to ${tokens.length} users`);

      // Create notification payload
      const payload = {
        notification: {
          title: `New ${eventType} Event in ${city}`,
          body: `${creatorName} created: "${eventName}" on ${date}`,
        },
        data: {
          type: 'new_event',
          eventId: eventId,
          city: city,
          eventType: eventType || '',
          eventName: eventName || '',
          date: date || '',
          time: time || '',
          venue: venue || '',
          createdBy: createdBy,
          clickAction: 'FLUTTER_NOTIFICATION_CLICK',
        },
        android: {
          notification: {
            channelId: 'events_notifications',
            icon: 'ic_launcher',
            color: '#FF6B6B',
            sound: 'default',
            priority: 'high',
          },
          priority: 'high',
        },
        apns: {
          payload: {
            aps: {
              alert: {
                title: `New ${eventType} Event in ${city}`,
                body: `${creatorName} created: "${eventName}" on ${date}`,
              },
              sound: 'default',
              badge: 1,
            },
          },
          headers: {
            'apns-priority': '10',
          },
        },
      };

      // Send notifications in batches
      const batchSize = 500;
      const batches = [];
      
      for (let i = 0; i < tokens.length; i += batchSize) {
        batches.push(tokens.slice(i, i + batchSize));
      }

      logger.log(`Sending event notifications in ${batches.length} batch(es)`);

      let totalSuccessful = 0;
      let totalFailed = 0;

      // Process each batch
      for (let batchIndex = 0; batchIndex < batches.length; batchIndex++) {
        const batchTokens = batches[batchIndex];
        
        try {
          const response = await messaging.sendEachForMulticast({
            tokens: batchTokens,
            ...payload,
          });

          logger.log(`Event notification batch ${batchIndex + 1} results: ${response.successCount} successful, ${response.failureCount} failed`);
          totalSuccessful += response.successCount;
          totalFailed += response.failureCount;

        } catch (batchError) {
          logger.error(`Error processing event notification batch ${batchIndex + 1}:`, batchError);
          totalFailed += batchTokens.length;
        }

        // Add delay between batches
        if (batchIndex < batches.length - 1) {
          await new Promise(resolve => setTimeout(resolve, 100));
        }
      }

      // Create individual notification documents for users in the city
      await createIndividualEventNotifications(notificationRecipients, eventData, eventId, city, creatorName);

      logger.log('Event location notifications completed:', {
        eventId: eventId,
        targetCity: city,
        totalNotified: totalSuccessful,
        totalFailed: totalFailed,
      });

      return {
        success: true,
        eventId: eventId,
        city: city,
        totalNotified: totalSuccessful,
        totalFailed: totalFailed,
      };

    } catch (error) {
      logger.error('Error in sendEventLocationNotifications:', error);
      return null;
    }
  }
);

/**
 * Helper function to create individual notification documents for event recipients
 */
async function createIndividualEventNotifications(recipients, eventData, eventId, city, creatorName) {
  try {
    const batch = db.batch();
    let batchCount = 0;

    for (const recipient of recipients) {
      const notificationRef = db.collection('users')
        .doc(recipient.userId)
        .collection('notifications')
        .doc();

      const notificationData = {
        type: 'new_event',
        eventId: eventId,
        fromUserId: eventData.createdBy,
        city: city,
        eventType: eventData.eventType || '',
        eventName: eventData.eventName || '',
        eventDate: eventData.date || '',
        eventTime: eventData.time || '',
        eventVenue: eventData.venue || '',
        creatorName: creatorName,
        createdAt: FieldValue.serverTimestamp(),
        isRead: false,
      };

      batch.set(notificationRef, notificationData);
      batchCount++;

      // Commit batch if it reaches Firebase limit
      if (batchCount >= 500) {
        await batch.commit();
        logger.log(`Committed batch of ${batchCount} event notifications`);
        batchCount = 0;
      }
    }

    // Commit remaining notifications
    if (batchCount > 0) {
      await batch.commit();
      logger.log(`Committed final batch of ${batchCount} event notifications`);
    }

    logger.log(`Created individual event notifications for ${recipients.length} users`);

  } catch (error) {
    logger.error('Error creating individual event notifications:', error);
  }
}