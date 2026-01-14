
const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.onAtrValidated = functions.database.ref('/atr/{atrId}')
    .onUpdate((change, context) => {
      const beforeData = change.before.val();
      const afterData = change.after.val();

      if (beforeData.status !== 'validated' && afterData.status === 'validated') {
        const executor = afterData.depPersonExecuter;
        if (executor) {
          const payload = {
            notification: {
              title: 'New Issue Assigned',
              body: `A new issue has been assigned to you: ${afterData.observationOrIssueOrHazard}`,
            },
          };

          // This is a placeholder for sending a notification.
          // In a real application, you would use a service like FCM to send a push notification.
          console.log(`Sending notification to ${executor}`, payload);

          // You would typically use something like this:
          // return admin.messaging().sendToDevice(executor.token, payload);
        }
      }
      return null;
    });
