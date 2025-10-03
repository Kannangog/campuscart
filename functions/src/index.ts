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
}

// Interface for Cloud Function call data
interface SendNotificationData {
  userId: string;
  title: string;
  message: string;
  type?: string;
  additionalData?: Record<string, unknown>;
}

interface BroadcastNotificationData {
  title: string;
  message: string;
  userType?: string;
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

// Cloud Function to send push notifications when a new notification is created
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

      logger.info(`Processing new notification: ${notificationId}`);
      logger.info("Notification data:", notification);

      // Skip if notification is read or doesn't have userId
      if (notification.read || !notification.userId) {
        logger.info("Skipping - notification is read or missing userId");
        return;
      }

      // Get user's FCM tokens
      const firestore = getFirestore();
      const userDoc = await firestore
        .collection("users")
        .doc(notification.userId)
        .get();

      if (!userDoc.exists) {
        logger.info("User document not found");
        return;
      }

      const userData = userDoc.data();
      const tokens: string[] = userData?.fcmTokens || [];

      if (tokens.length === 0) {
        logger.info("No FCM tokens found for user");
        return;
      }

      logger.info(`Sending to ${tokens.length} tokens`);

      // Prepare the notification message
      const messaging = getMessaging();
      const message = {
        notification: {
          title: notification.title,
          body: notification.message,
        },
        data: {
          notificationId: notificationId,
          type: notification.type || "general",
          title: notification.title,
          body: notification.message,
          userId: notification.userId,
          ...notification.data,
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
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

      // Send the multicast message
      const response = await messaging.sendEachForMulticast(message);

      logger.info("Successfully sent messages:", response);

      // Clean up invalid tokens
      if (response.failureCount > 0) {
        const failedTokens: string[] = [];
        response.responses.forEach((resp, idx) => {
          if (!resp.success) {
            failedTokens.push(tokens[idx]);
          }
        });

        if (failedTokens.length > 0) {
          logger.info("Cleaning up failed tokens:", failedTokens);
          await cleanupFailedTokens(notification.userId, failedTokens);
        }
      }
    } catch (error) {
      logger.error("Error sending push notification:", error);
    }
  }
);

// Additional Cloud Function: Send notification to specific user
export const sendNotificationToUser = onCall(
  {
    enforceAppCheck: false,
    cors: true,
  },
  async (request) => {
    // Check if user is authenticated
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "User must be authenticated"
      );
    }

    const data = request.data as SendNotificationData;
    const {userId, title, message, type = "general", additionalData = {}} = data;

    // Validate required fields
    if (!userId || !title || !message) {
      throw new HttpsError(
        "invalid-argument",
        "Missing required fields: userId, title, message"
      );
    }

    try {
      // Create notification in Firestore
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
        });

      logger.info(`Notification created with ID: ${notificationRef.id}`);

      return {
        success: true,
        notificationId: notificationRef.id,
        message: "Notification sent successfully",
      };
    } catch (error) {
      logger.error("Error creating notification:", error);
      throw new HttpsError(
        "internal",
        "Failed to send notification"
      );
    }
  }
);

// Cloud Function: Send notification to multiple users
export const sendBroadcastNotification = onCall(
  {
    enforceAppCheck: false,
    cors: true,
  },
  async (request) => {
    // Check if user is admin
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "User must be authenticated"
      );
    }

    const data = request.data as BroadcastNotificationData;
    const {title, message, userType = "all", additionalData = {}} = data;

    if (!title || !message) {
      throw new HttpsError(
        "invalid-argument",
        "Missing required fields: title, message"
      );
    }

    try {
      const firestore = getFirestore();
      let usersQuery: FirebaseFirestore.Query = firestore.collection("users");

      // Filter by user type if specified
      if (userType !== "all") {
        usersQuery = usersQuery.where("userType", "==", userType);
      }

      const usersSnapshot = await usersQuery.get();

      const batch = firestore.batch();
      const notificationsCollection = firestore.collection("notifications");

      usersSnapshot.docs.forEach((userDoc) => {
        const notificationRef = notificationsCollection.doc();
        batch.set(notificationRef, {
          userId: userDoc.id,
          title: title,
          message: message,
          type: "broadcast",
          data: additionalData,
          read: false,
          createdAt: FieldValue.serverTimestamp(),
        });
      });

      await batch.commit();

      return {
        success: true,
        message: `Notification sent to ${usersSnapshot.size} users`,
      };
    } catch (error) {
      logger.error("Error sending broadcast notification:", error);
      throw new HttpsError(
        "internal",
        "Failed to send broadcast notification"
      );
    }
  }
);

// Simple test function to verify deployment
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