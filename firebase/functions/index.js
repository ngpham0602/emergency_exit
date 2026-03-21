const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

/**
 * When a new emergency alert is created in Firestore,
 * send a high-priority FCM push notification to ALL devices
 * subscribed to the "emergency_alerts" topic.
 *
 * This notification arrives even when the app is closed or the screen is off.
 */
exports.onEmergencyAlertCreated = onDocumentCreated(
  "emergencyAlerts/{alertId}",
  async (event) => {
    const alert = event.data.data();

    if (!alert || !alert.isActive) {
      console.log("Alert is not active, skipping push.");
      return;
    }

    const typeDisplayNames = {
      fire: "FIRE EMERGENCY",
      active_shooter: "ACTIVE SHOOTER",
      earthquake: "EARTHQUAKE ALERT",
      other: "EMERGENCY ALERT",
    };

    const typeInstructions = {
      fire: "Evacuate now. Find the nearest exit immediately.",
      active_shooter: "Run, Hide. Get to safety now.",
      earthquake: "Drop, Cover, Hold On. Move to open area when safe.",
      other: "Emergency alert. Find the nearest exit now.",
    };

    const title = typeDisplayNames[alert.type] || "EMERGENCY ALERT";
    const body = typeInstructions[alert.type] || "Find the nearest exit now.";

    // FCM message — sent to ALL devices subscribed to "emergency_alerts" topic
    const message = {
      topic: "emergency_alerts",
      notification: {
        title: title,
        body: body,
      },
      data: {
        emergencyType: alert.type || "other",
        alertId: event.params.alertId,
        sentBy: alert.sentByName || "Security",
      },
      apns: {
        headers: {
          // High priority ensures immediate delivery even when device is sleeping
          "apns-priority": "10",
          // Critical alert — bypasses DND and silent mode on iOS
          "apns-push-type": "alert",
        },
        payload: {
          aps: {
            alert: {
              title: title,
              body: body,
            },
            sound: {
              // Critical sound bypasses silent switch
              critical: 1,
              name: "default",
              volume: 1.0,
            },
            // Show on lock screen immediately
            "interruption-level": "critical",
            "content-available": 1,
            "mutable-content": 1,
          },
        },
      },
    };

    try {
      const response = await getMessaging().send(message);
      console.log(`Emergency push sent: ${response}, type: ${alert.type}`);
    } catch (error) {
      console.error("Failed to send emergency push:", error);
    }
  }
);

/**
 * When an emergency alert is deactivated (isActive set to false),
 * send an "all clear" notification so employees know it's over.
 */
exports.onEmergencyAlertUpdated = onDocumentUpdated(
  "emergencyAlerts/{alertId}",
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();

    // Only fire when alert transitions from active → inactive
    if (before.isActive === true && after.isActive === false) {
      const message = {
        topic: "emergency_alerts",
        notification: {
          title: "ALL CLEAR",
          body: "The emergency alert has been cancelled. Resume normal operations.",
        },
        data: {
          emergencyType: "clear",
          alertId: event.params.alertId,
        },
        apns: {
          payload: {
            aps: {
              alert: {
                title: "ALL CLEAR",
                body: "The emergency alert has been cancelled. Resume normal operations.",
              },
              sound: "default",
            },
          },
        },
      };

      try {
        const response = await getMessaging().send(message);
        console.log(`All-clear push sent: ${response}`);
      } catch (error) {
        console.error("Failed to send all-clear push:", error);
      }
    }
  }
);
