const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

exports.sendNotification = functions.firestore
  .document('notifications/{notificationId}')
  .onCreate(async (snap, context) => {
    const notification = snap.data();

    const message = {
      notification: {
        title: notification.title,
        body: notification.body
      },
      topic: notification.topic
    };

    try {
      const response = await admin.messaging().send(message);
      console.log('Successfully sent message:', response);
      return null;
    } catch (error) {
      console.log('Error sending message:', error);
      return null;
    }
  });