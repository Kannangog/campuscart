import * as logger from "firebase-functions/logger";
import {onDocumentCreated} from "firebase-functions/v2/firestore";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {initializeApp} from "firebase-admin/app";
import {getFirestore, FieldValue} from "firebase-admin/firestore";
import {getMessaging} from "firebase-admin/messaging";

// Initialize Firebase Admin
initializeApp();

// Interface for notification data
interface NotificationData {
  userId: string;
  title: string;
  message: string;
  type?: string;
  data?: Record<string, unknown>;
  read: boolean;
  createdAt: FirebaseFirestore.FieldValue;
  userType?: string;
}

// Interface for Cloud Function call data
interface SendNotificationData {
  userId: string;
  title: string;
  message: string;
  type?: string;
  additionalData?: Record<string, unknown>;
}


// Helper function to clean up failed tokens
async function cleanupFailedTokens(userId: string, failedTokens: string[]) {
  try {
    const firestore = getFirestore();
    const userRef = firestore.collection("users").doc(userId);

    await userRef.update({
      fcmTokens: FieldValue.arrayRemove(...failedTokens),
    });

    logger.info(`Removed ${failedTokens.length} invalid tokens for user ${userId}`);
  } catch (error) {
    logger.error("Error cleaning up failed tokens:", error);
  }
}

// ✅ FIXED: Cloud Function to send push notifications
export const sendPushNotification = onDocumentCreated(
  "notifications/{notificationId}",
  async (event) => {
    try {
      const snapshot = event.data;
      if (!snapshot) {
        logger.error("No data associated with the event");
        return;
      }

      const notification = snapshot.data() as NotificationData;
      const notificationId = event.params.notificationId;

      // ✅ ENHANCED LOGGING
      logger.info("🎯 ===== NEW NOTIFICATION TRIGGER =====");
      logger.info(`📄 Notification ID: ${notificationId}`);
      logger.info(`👤 Target User ID: ${notification.userId}`);
      logger.info(`📱 Notification Type: ${notification.type}`);
      logger.info(`👥 User Type: ${notification.userType}`);
      logger.info(`📝 Title: ${notification.title}`);
      logger.info(`📨 Message: ${notification.message}`);

      // Skip if notification is read or doesn't have userId
      if (notification.read || !notification.userId) {
        logger.info("⏭️ Skipping - notification is read or missing userId");
        return;
      }

      // Get user's FCM tokens
      const firestore = getFirestore();
      const userDoc = await firestore
        .collection("users")
        .doc(notification.userId)
        .get();

      if (!userDoc.exists) {
        logger.error(`❌ User document not found for ID: ${notification.userId}`);
        return;
      }

      const userData = userDoc.data();
      const tokens: string[] = userData?.fcmTokens || [];
      const userType = userData?.userType || 'unknown';

      logger.info(`📱 Found ${tokens.length} tokens for user type: ${userType}`);

      if (tokens.length === 0) {
        logger.warn("⚠️ No FCM tokens found for user");
        return;
      }

      logger.info(`🚀 Sending to ${tokens.length} tokens`);

      // ✅ FIXED: Prepare the notification message
      const messaging = getMessaging();
      
      // Build data payload
      const notificationData: Record<string, string> = {
        notificationId: notificationId,
        type: notification.type || "general",
        title: notification.title,
        body: notification.message,
        userId: notification.userId, // ✅ This is the TARGET user ID
        click_action: "FLUTTER_NOTIFICATION_CLICK",
        timestamp: Date.now().toString(),
      };

      // Add additional data from notification
      if (notification.data) {
        Object.entries(notification.data).forEach(([key, value]) => {
          if (typeof value === 'string') {
            notificationData[key] = value;
          } else {
            notificationData[key] = JSON.stringify(value);
          }
        });
      }

      // ✅ CRITICAL: Ensure userType is included
      if (notification.userType) {
        notificationData['userType'] = notification.userType;
      } else if (userType) {
        notificationData['userType'] = userType;
      }

      const message = {
        notification: {
          title: notification.title,
          body: notification.message,
        },
        data: notificationData,
        tokens: tokens,
        android: {
          priority: "high" as const,
        },
        apns: {
          payload: {
            aps: {
              contentAvailable: true,
              badge: 1,
              sound: "default",
            },
          },
        },
      };

      logger.info(`📤 Sending multicast message to ${tokens.length} devices`);

      // Send the multicast message
      const response = await messaging.sendEachForMulticast(message);

      logger.info(`✅ Successfully sent ${response.successCount} messages`);
      logger.info(`❌ Failed to send ${response.failureCount} messages`);

      // Clean up invalid tokens
      if (response.failureCount > 0) {
        const failedTokens: string[] = [];
        response.responses.forEach((resp, idx) => {
          if (!resp.success) {
            logger.error(`🚫 Token failed: ${tokens[idx].substring(0, 15)}..., Error: ${resp.error?.message}`);
            failedTokens.push(tokens[idx]);
          }
        });

        if (failedTokens.length > 0) {
          logger.info(`🧹 Cleaning up ${failedTokens.length} failed tokens`);
          await cleanupFailedTokens(notification.userId, failedTokens);
        }
      }

      logger.info("🎉 Notification processing completed successfully");

    } catch (error) {
      logger.error("💥 Error sending push notification:", error);
    }
  }
);

// Additional Cloud Functions (keep your existing ones)
export const sendNotificationToUser = onCall(
  {
    enforceAppCheck: false,
    cors: true,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "User must be authenticated");
    }

    const data = request.data as SendNotificationData;
    const {userId, title, message, type = "general", additionalData = {}} = data;

    if (!userId || !title || !message) {
      throw new HttpsError("invalid-argument", "Missing required fields: userId, title, message");
    }

    try {
      const firestore = getFirestore();
      const notificationRef = await firestore
        .collection("notifications")
        .add({
          userId: userId,
          title: title,
          message: message,
          type: type,
          data: additionalData,
          read: false,
          createdAt: FieldValue.serverTimestamp(),
          userType: additionalData['userType'] as string || 'customer',
        });

      logger.info(`📝 Notification created with ID: ${notificationRef.id} for user: ${userId}`);

      return {
        success: true,
        notificationId: notificationRef.id,
        message: "Notification sent successfully",
      };
    } catch (error) {
      logger.error("Error creating notification:", error);
      throw new HttpsError("internal", "Failed to send notification");
    }
  }
);

// Simple test function
export const testNotificationFunction = onCall(
  {
    enforceAppCheck: false,
    cors: true,
  },
  async (request) => {
    const data = request.data as {message: string};
    return {
      success: true,
      message: `Test successful: ${data.message}`,
      timestamp: new Date().toISOString(),
    };
  }
);