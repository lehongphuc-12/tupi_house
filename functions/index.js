/**
 * Tupi House – Cloud Functions
 *
 * When a document is created in `notifications`, send an FCM push
 * to the target user's device token(s).
 *
 * Deploy:
 *   cd functions && npm install
 *   firebase deploy --only functions
 */

const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");
const { logger } = require("firebase-functions");

initializeApp();

exports.sendPushOnNotificationCreate = onDocumentCreated(
  "notifications/{notificationId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const data = snap.data();
    const userId = data.userId;
    if (!userId) {
      logger.warn("Notification missing userId", { id: event.params.notificationId });
      return;
    }

    const userDoc = await getFirestore().collection("users").doc(userId).get();
    if (!userDoc.exists) {
      logger.warn("User not found for notification", { userId });
      return;
    }

    const user = userDoc.data() || {};
    const tokens = new Set();

    if (typeof user.fcmToken === "string" && user.fcmToken.length > 0) {
      tokens.add(user.fcmToken);
    }
    if (Array.isArray(user.fcmTokens)) {
      for (const t of user.fcmTokens) {
        if (typeof t === "string" && t.length > 0) tokens.add(t);
      }
    }

    if (tokens.size === 0) {
      logger.info("No FCM tokens for user", { userId });
      return;
    }

    const payload = {
      notification: {
        title: data.title || "Tupi House",
        body: data.body || "",
      },
      data: {
        notificationId: event.params.notificationId,
        type: String(data.type || "system"),
        orderId: String(data.orderId || ""),
        title: String(data.title || ""),
        body: String(data.body || ""),
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
      android: {
        priority: "high",
        notification: {
          channelId: "tupi_house_orders",
          sound: "default",
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
          },
        },
      },
    };

    const tokenList = [...tokens];
    const response = await getMessaging().sendEachForMulticast({
      tokens: tokenList,
      ...payload,
    });

    logger.info("FCM send result", {
      userId,
      success: response.successCount,
      failure: response.failureCount,
    });

    // Clean up invalid tokens
    const invalid = [];
    response.responses.forEach((res, idx) => {
      if (!res.success) {
        const code = res.error && res.error.code;
        if (
          code === "messaging/invalid-registration-token" ||
          code === "messaging/registration-token-not-registered"
        ) {
          invalid.push(tokenList[idx]);
        }
      }
    });

    if (invalid.length > 0) {
      const updates = {
        fcmTokens: FieldValue.arrayRemove(...invalid),
      };
      if (invalid.includes(user.fcmToken)) {
        updates.fcmToken = FieldValue.delete();
      }
      await getFirestore().collection("users").doc(userId).set(updates, {
        merge: true,
      });
    }
  }
);
