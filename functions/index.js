const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
admin.initializeApp();

// Function to send notification to specific driver
exports.sendNotificationToDriver = functions.https.onCall(async (data, context) => {
  try {
    // Check if user is authenticated
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const { driverId, requestData } = data;

    if (!driverId || !requestData) {
      throw new functions.https.HttpsError('invalid-argument', 'Missing required parameters');
    }

    // Get driver's FCM token from Firestore
    const driverDoc = await admin.firestore()
      .collection('partners')
      .doc(driverId)
      .get();

    if (!driverDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Driver not found');
    }

    const driverData = driverDoc.data();
    const fcmToken = driverData.fcmToken;

    if (!fcmToken) {
      throw new functions.https.HttpsError('not-found', 'Driver FCM token not found');
    }

    // Get user info
    const userId = context.auth.uid;
    const userDoc = await admin.firestore()
      .collection('users')
      .doc(userId)
      .get();

    const userData = userDoc.exists ? userDoc.data() : {};
    const userName = userData.name || 'User';

    // Prepare notification message
    const message = {
      token: fcmToken,
      notification: {
        title: '🚗 নতুন রাইড রিকুয়েস্ট',
        body: `${userName} আপনার কাছে একটি রাইড রিকুয়েস্ট পাঠিয়েছেন`,
      },
      data: {
        type: 'ride_request',
        requestId: requestData.requestId || '',
        userId: userId,
        userName: userName,
        userPhone: userData.phone || '',
        pickupLocation: JSON.stringify(requestData.pickupLocation || {}),
        destinationLocation: JSON.stringify(requestData.destinationLocation || {}),
        pickupAddress: requestData.pickupAddress || '',
        destinationAddress: requestData.destinationAddress || '',
        urgency: requestData.urgency || 'normal',
        notes: requestData.notes || '',
        timestamp: Date.now().toString(),
      },
      android: {
        priority: 'high',
        notification: {
          channelId: 'ride_requests',
          sound: 'default',
          priority: 'high',
        }
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
          }
        }
      }
    };

    // Send notification
    const response = await admin.messaging().send(message);
    console.log('Successfully sent notification:', response);

    // Save notification log
    await admin.firestore()
      .collection('notification_logs')
      .add({
        type: 'ride_request',
        fromUserId: userId,
        toDriverId: driverId,
        requestId: requestData.requestId,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        success: true,
        messageId: response,
      });

    return {
      success: true,
      messageId: response,
      message: 'Notification sent successfully'
    };

  } catch (error) {
    console.error('Error sending notification:', error);
    
    // Log error
    if (context.auth) {
      await admin.firestore()
        .collection('notification_logs')
        .add({
          type: 'ride_request',
          fromUserId: context.auth.uid,
          toDriverId: data.driverId || '',
          error: error.message,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          success: false,
        });
    }

    throw new functions.https.HttpsError('internal', error.message);
  }
});

// Function to send notification to nearby drivers
exports.sendNotificationToNearbyDrivers = functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const { userLocation, requestData, radiusInKm = 5 } = data;

    if (!userLocation || !requestData) {
      throw new functions.https.HttpsError('invalid-argument', 'Missing required parameters');
    }

    // Get user info
    const userId = context.auth.uid;
    const userDoc = await admin.firestore()
      .collection('users')
      .doc(userId)
      .get();

    const userData = userDoc.exists ? userDoc.data() : {};
    const userName = userData.name || 'User';

    // Get all online drivers
    const driversSnapshot = await admin.firestore()
      .collection('partners')
      .where('role', '==', 'driver')
      .where('isOnline', '==', true)
      .get();

    const notifications = [];
    let sentCount = 0;

    for (const driverDoc of driversSnapshot.docs) {
      const driverData = driverDoc.data();
      const driverLocation = driverData.currentLocation;
      const fcmToken = driverData.fcmToken;

      if (driverLocation && fcmToken) {
        // Calculate distance (simple calculation)
        const distance = calculateDistance(
          userLocation.latitude,
          userLocation.longitude,
          driverLocation.latitude,
          driverLocation.longitude
        );

        if (distance <= radiusInKm) {
          const message = {
            token: fcmToken,
            notification: {
              title: '🚗 নতুন রাইড রিকুয়েস্ট',
              body: `${userName} আপনার এলাকায় রাইড খুঁজছেন (${distance.toFixed(1)} কিমি দূরে)`,
            },
            data: {
              type: 'ride_request',
              requestId: requestData.requestId || `${Date.now()}_${driverDoc.id}`,
              userId: userId,
              userName: userName,
              userPhone: userData.phone || '',
              pickupLocation: JSON.stringify(userLocation),
              destinationLocation: JSON.stringify(requestData.destinationLocation || {}),
              pickupAddress: requestData.pickupAddress || '',
              destinationAddress: requestData.destinationAddress || '',
              urgency: requestData.urgency || 'normal',
              notes: requestData.notes || '',
              distance: distance.toString(),
              timestamp: Date.now().toString(),
            },
            android: {
              priority: 'high',
              notification: {
                channelId: 'ride_requests',
                sound: 'default',
              }
            }
          };

          notifications.push(
            admin.messaging().send(message).then(response => {
              sentCount++;
              console.log(`Notification sent to driver ${driverDoc.id}:`, response);
              return { driverId: driverDoc.id, success: true, messageId: response };
            }).catch(error => {
              console.error(`Failed to send to driver ${driverDoc.id}:`, error);
              return { driverId: driverDoc.id, success: false, error: error.message };
            })
          );
        }
      }
    }

    const results = await Promise.all(notifications);

    // Log the batch notification
    await admin.firestore()
      .collection('notification_logs')
      .add({
        type: 'nearby_drivers_notification',
        fromUserId: userId,
        requestId: requestData.requestId,
        totalDriversFound: driversSnapshot.size,
        nearbyDriversCount: notifications.length,
        successfulSends: sentCount,
        results: results,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

    return {
      success: true,
      totalDriversFound: driversSnapshot.size,
      nearbyDriversCount: notifications.length,
      notificationResults: results,
      message: `Notifications sent to ${sentCount} nearby drivers`
    };

  } catch (error) {
    console.error('Error sending notifications to nearby drivers:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

// Function to send ambulance request notification
exports.sendAmbulanceNotification = functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const { partnerId, requestData } = data;

    if (!partnerId || !requestData) {
      throw new functions.https.HttpsError('invalid-argument', 'Missing required parameters');
    }

    // Get partner's FCM token
    const partnerDoc = await admin.firestore()
      .collection('partners')
      .doc(partnerId)
      .get();

    if (!partnerDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Partner not found');
    }

    const partnerData = partnerDoc.data();
    const fcmToken = partnerData.fcmToken;

    if (!fcmToken) {
      throw new functions.https.HttpsError('not-found', 'Partner FCM token not found');
    }

    // Get user info
    const userId = context.auth.uid;
    const userDoc = await admin.firestore()
      .collection('users')
      .doc(userId)
      .get();

    const userData = userDoc.exists ? userDoc.data() : {};
    const patientName = userData.name || 'Patient';

    const message = {
      token: fcmToken,
      notification: {
        title: '🚑 জরুরি অ্যাম্বুলেন্স রিকুয়েস্ট',
        body: `রোগী: ${patientName} | জরুরি মাত্রা: ${requestData.urgency || 'উচ্চ'}`,
      },
      data: {
        type: 'ambulance_request',
        orderId: requestData.orderId || '',
        userId: userId,
        patientName: patientName,
        userPhone: userData.phone || '',
        pickupLocation: JSON.stringify(requestData.userLocation || {}),
        pickupAddress: requestData.pickupAddress || '',
        urgency: requestData.urgency || 'high',
        notes: requestData.notes || '',
        companyName: requestData.companyName || '',
        timestamp: Date.now().toString(),
      },
      android: {
        priority: 'high',
        notification: {
          channelId: 'ambulance_requests',
          sound: 'default',
          priority: 'high',
        }
      }
    };

    const response = await admin.messaging().send(message);

    // Log notification
    await admin.firestore()
      .collection('notification_logs')
      .add({
        type: 'ambulance_request',
        fromUserId: userId,
        toPartnerId: partnerId,
        orderId: requestData.orderId,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        success: true,
        messageId: response,
      });

    return {
      success: true,
      messageId: response,
      message: 'Ambulance notification sent successfully'
    };

  } catch (error) {
    console.error('Error sending ambulance notification:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

// Helper function to calculate distance between two points
function calculateDistance(lat1, lon1, lat2, lon2) {
  const R = 6371; // Radius of the Earth in kilometers
  const dLat = deg2rad(lat2 - lat1);
  const dLon = deg2rad(lon2 - lon1);
  const a = 
    Math.sin(dLat/2) * Math.sin(dLat/2) +
    Math.cos(deg2rad(lat1)) * Math.cos(deg2rad(lat2)) * 
    Math.sin(dLon/2) * Math.sin(dLon/2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
  const distance = R * c; // Distance in kilometers
  return distance;
}

function deg2rad(deg) {
  return deg * (Math.PI/180);
}