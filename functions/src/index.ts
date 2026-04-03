import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { onRequest } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

admin.initializeApp();

export const notifySubscribersOnNewPost = onDocumentCreated(
  "posts/{postId}",
  async (event) => {
    try {
      const snapshot = event.data;

      if (!snapshot) {
        console.log("Kein Snapshot vorhanden.");
        return;
      }

      const post = snapshot.data();
      const postId = snapshot.id;

      console.log("Neuer Post erkannt:", postId);
      console.log("Post-Daten:", JSON.stringify(post));

      const creatorId = post.userid;
      const username = post.benutzername ?? "User";
      const vorname = post.vorname ?? "";
      const nachname = post.nachname ?? "";
      const type = post.type ?? "image";

      let fullName = `${vorname} ${nachname}`.trim();
      if (fullName === "") fullName = username;

      let emoji = "📢";
      let uploadText = "hat etwas hochgeladen";

      if (type === "image") {
        emoji = "📸";
        uploadText = "hat ein neues Bild hochgeladen";
      }

      if (type === "video") {
        emoji = "🎬";
        uploadText = "hat ein neues Video hochgeladen";
      }

      const pushTitle = `${emoji} Neues von ${fullName}`;
      const pushBody = `${username} ${uploadText}`;

      const imageUrl =
        post.thumbnailUrl && post.thumbnailUrl !== ""
          ? post.thumbnailUrl
          : post.mediaUrl ?? "";

      const db = admin.firestore();

      const subsSnapshot = await db
        .collection("subscriptions")
        .where("subscribedToId", "==", creatorId)
        .get();

      console.log("Gefundene Subscriptions:", subsSnapshot.size);

      const subscriberIds: string[] = [];

      subsSnapshot.docs.forEach((doc) => {
        const data = doc.data();
        const subscriberId = data.subscriberId as string | undefined;

        if (!subscriberId) return;

        if (subscriberId === creatorId) {
          console.log("Uploader wird übersprungen.");
          return;
        }

        subscriberIds.push(subscriberId);
      });

      const uniqueSubscriberIds = [...new Set(subscriberIds)];

      console.log("SubscriberIds:", JSON.stringify(uniqueSubscriberIds));

      const tokenEntries: { uid: string; token: string }[] = [];

      for (const uid of uniqueSubscriberIds) {
        const tokenSnapshot = await db
          .collection("users")
          .doc(uid)
          .collection("fcmTokens")
          .get();

        console.log(`Tokens für ${uid}:`, tokenSnapshot.size);

        tokenSnapshot.docs.forEach((doc) => {
          const token = doc.data().token as string | undefined;
          if (token) {
            tokenEntries.push({ uid, token });
          }
        });
      }

      const creatorTokenSnapshot = await db
        .collection("users")
        .doc(creatorId)
        .collection("fcmTokens")
        .get();

      const creatorTokens = creatorTokenSnapshot.docs
        .map((doc) => doc.data().token as string | undefined)
        .filter((token): token is string => Boolean(token));

      console.log("Creator Tokens:", JSON.stringify(creatorTokens));

      const uniqueTokens = [
        ...new Set(tokenEntries.map((entry) => entry.token)),
      ].filter((token) => !creatorTokens.includes(token));

      console.log(
        "Gesammelte Tokens nach Creator-Filter:",
        uniqueTokens.length
      );

      if (uniqueTokens.length === 0) {
        console.log("Keine Tokens nach Creator-Filter übrig.");
        return;
      }

      // DATA-ONLY
      const message: admin.messaging.MulticastMessage = {
        tokens: uniqueTokens,

        data: {
          action: "open_creator_group",
          title: pushTitle,
          body: pushBody,
          postId: String(postId),
          creatorId: String(creatorId),
          creatorName: String(fullName),
          type: String(type),
          imageUrl: String(imageUrl),
          mediaUrl: String(post.mediaUrl ?? ""),
          thumbnailUrl: String(post.thumbnailUrl ?? ""),
          postTitle: String(post.title ?? ""),
        },

        android: {
          priority: "high",
        },

        apns: {
          headers: {
            "apns-priority": "5",
          },
          payload: {
            aps: {
              "content-available": 1,
            },
          },
        },
      };

      const response = await admin.messaging().sendEachForMulticast(message);

      console.log("Push gesendet:", response.successCount);
      console.log("Push Fehler:", response.failureCount);

      const invalidTokens: { uid: string; token: string }[] = [];

      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          const error = resp.error;

          if (
            error?.code === "messaging/registration-token-not-registered" ||
            error?.code === "messaging/invalid-registration-token"
          ) {
            const token = uniqueTokens[idx];
            const entry = tokenEntries.find((e) => e.token === token);

            if (entry) {
              invalidTokens.push(entry);
            }
          }
        }
      });

      for (const entry of invalidTokens) {
        console.log("Lösche ungültigen Token:", entry.token);

        await db
          .collection("users")
          .doc(entry.uid)
          .collection("fcmTokens")
          .doc(entry.token)
          .delete();
      }
    } catch (error) {
      console.error("Fehler in notifySubscribersOnNewPost:", error);
    }
  }
);





export const notifyReceiverOnNewMessage = onDocumentCreated(
  "chats/{chatId}/messages/{messageId}",
  async (event) => {
    try {
      const snapshot = event.data;
      if (!snapshot) {
        console.log("Kein Message-Snapshot vorhanden.");
        return;
      }

      const message = snapshot.data();
      const chatId = event.params.chatId;
      const messageId = snapshot.id;

      const senderId = message.senderId as string | undefined;
      const receiverId = message.receiverId as string | undefined;
      const text = (message.text as string | undefined) ?? "";
      const type = (message.type as string | undefined) ?? "text";

      if (!senderId || !receiverId) {
        console.log("senderId oder receiverId fehlt.");
        return;
      }

      if (senderId === receiverId) {
        console.log("Sender und Empfänger identisch, kein Push.");
        return;
      }

      const db = admin.firestore();

      const receiverSnap = await db.collection("users").doc(receiverId).get();
      const receiverData = receiverSnap.data() ?? {};
      const receiverActiveChatId =
        (receiverData["activeChatId"] as string | undefined) ?? "";

      if (receiverActiveChatId === chatId) {
        console.log(
          `Empfänger ${receiverId} hat Chat ${chatId} offen -> kein Push.`,
        );
        return;
      }

      const senderSnap = await db.collection("users").doc(senderId).get();
      const senderData = senderSnap.data() ?? {};

      const senderUsername =
        (senderData["benutzername"] as string | undefined) ?? "User";
      const senderVorname =
        (senderData["vorname"] as string | undefined) ?? "";
      const senderNachname =
        (senderData["nachname"] as string | undefined) ?? "";

      let fullName = `${senderVorname} ${senderNachname}`.trim();
      if (fullName === "") {
        fullName = senderUsername;
      }

      const tokenSnap = await db
        .collection("users")
        .doc(receiverId)
        .collection("fcmTokens")
        .get();

      const tokens = tokenSnap.docs
        .map((doc) => doc.data().token as string | undefined)
        .filter((token): token is string => Boolean(token));

      const uniqueTokens = [...new Set(tokens)];

      if (uniqueTokens.length === 0) {
        console.log("Keine Tokens für Empfänger gefunden.");
        return;
      }

      let body = text;
      if (type !== "text") {
        body = "Hat dir eine Nachricht gesendet";
      }

      // DATA-ONLY
      const response = await admin.messaging().sendEachForMulticast({
        tokens: uniqueTokens,
        data: {
          action: "open_chat",
          title: `💬 ${fullName}`,
          body: body,
          chatId: String(chatId),
          messageId: String(messageId),
          senderId: String(senderId),
          receiverId: String(receiverId),
          senderName: String(fullName),
          senderUsername: String(senderUsername),
          type: String(type),
          text: String(text),
        },
        android: {
          priority: "high",
        },
        apns: {
          headers: {
            "apns-priority": "5",
          },
          payload: {
            aps: {
              "content-available": 1,
            },
          },
        },
      });

      console.log("Chat-Push gesendet:", response.successCount);
      console.log("Chat-Push Fehler:", response.failureCount);

      const invalidTokens: string[] = [];

      response.responses.forEach((resp, index) => {
        if (!resp.success) {
          const code = resp.error?.code ?? "unknown";
          const msg = resp.error?.message ?? "Unbekannter Fehler";
          console.log(`Fehler bei Token ${index}: code=${code}, message=${msg}`);

          if (
            code === "messaging/invalid-registration-token" ||
            code === "messaging/registration-token-not-registered"
          ) {
            invalidTokens.push(uniqueTokens[index]);
          }
        }
      });

      for (const invalidToken of invalidTokens) {
        await db
          .collection("users")
          .doc(receiverId)
          .collection("fcmTokens")
          .doc(invalidToken)
          .delete()
          .catch((err) => {
            console.log("Fehler beim Löschen eines ungültigen Chat-Tokens:", err);
          });
      }
    } catch (error) {
      console.error("Fehler in notifyReceiverOnNewMessage:", error);
    }
  },
);





export const sendTestPushToAll = onRequest(async (req, res) => {
  const secret = req.query.secret;

  if (secret !== "MEIN_SUPER_SECRET_123") {
    res.status(403).send("Forbidden");
    return;
  }

  const usersSnapshot = await admin.firestore().collection("users").get();
  const tokens: string[] = [];

  for (const userDoc of usersSnapshot.docs) {
    const tokenSnapshot = await admin
      .firestore()
      .collection("users")
      .doc(userDoc.id)
      .collection("fcmTokens")
      .get();

    tokenSnapshot.docs.forEach((doc) => {
      const token = doc.data().token as string | undefined;
      if (token) {
        tokens.push(token);
      }
    });
  }

  const uniqueTokens = [...new Set(tokens)];

  if (uniqueTokens.length === 0) {
    res.status(200).send("Keine Tokens gefunden.");
    return;
  }

  let successTotal = 0;
  let failureTotal = 0;
  const chunkSize = 500;

  const imageUrl =
    "https://firebasestorage.googleapis.com/v0/b/social-media-app-68600.firebasestorage.app/o/Testbild%2F49436b01-fc28-45c1-9725-2055237ae835.jpg?alt=media&token=e0187890-15fd-4af7-80ab-cca259af9cfc";

  for (let i = 0; i < uniqueTokens.length; i += chunkSize) {
    const chunk = uniqueTokens.slice(i, i + chunkSize);

    const response = await admin.messaging().sendEachForMulticast({
      tokens: chunk,
      notification: {
        title: "Test Push mit Bild",
        body: "Das ist eine Test Push Nachricht mit Bild 🚀",
      },
      android: {
        priority: "high",
        notification: {
          channelId: "high_importance_channel",
          imageUrl: imageUrl,
        },
      },
      data: {
        type: "test",
        imageUrl: imageUrl,
      },
    });

    successTotal += response.successCount;
    failureTotal += response.failureCount;
  }

  res
    .status(200)
    .send(`Push gesendet. Erfolgreich: ${successTotal}, Fehler: ${failureTotal}`);
});