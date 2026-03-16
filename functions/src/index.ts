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

      const imageUrl =
        post.thumbnailUrl && post.thumbnailUrl !== ""
          ? post.thumbnailUrl
          : post.mediaUrl ?? "";

      const db = admin.firestore();

      /*
       ----------------------------------------
       SUBSCRIPTIONS LADEN
       ----------------------------------------
      */

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

      /*
       ----------------------------------------
       TOKENS SAMMELN
       ----------------------------------------
      */

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
            tokenEntries.push({
              uid,
              token,
            });
          }
        });
      }

      /*
       ----------------------------------------
       CREATOR TOKENS LADEN
       ----------------------------------------
      */

      const creatorTokenSnapshot = await db
        .collection("users")
        .doc(creatorId)
        .collection("fcmTokens")
        .get();

      const creatorTokens = creatorTokenSnapshot.docs
        .map((doc) => doc.data().token as string | undefined)
        .filter((token): token is string => Boolean(token));

      console.log("Creator Tokens:", JSON.stringify(creatorTokens));

      /*
       ----------------------------------------
       TOKENS FILTERN
       ----------------------------------------
      */

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

      /*
       ----------------------------------------
       PUSH SENDEN
       ----------------------------------------
      */

      const message: admin.messaging.MulticastMessage = {
        tokens: uniqueTokens,

        notification: {
          title: `${emoji} Neues von ${fullName}`,
          body: `${username} ${uploadText}`,
        },

        data: {
          postId: postId,
          creatorId: creatorId,
          type: type,
          imageUrl: imageUrl,
          mediaUrl: post.mediaUrl ?? "",
          thumbnailUrl: post.thumbnailUrl ?? "",
          postTitle: post.title ?? "",
        },

        android: {
          notification: {
            imageUrl: imageUrl,
            priority: "high",
          },
        },
      };

      const response = await admin.messaging().sendEachForMulticast(message);

      console.log("Push gesendet:", response.successCount);
      console.log("Push Fehler:", response.failureCount);

      /*
       ----------------------------------------
       UNGÜLTIGE TOKENS LÖSCHEN
       ----------------------------------------
      */

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
    "https://firebasestorage.googleapis.com/v0/b/egon-kowalski-db.appspot.com/o/Testbild%2FgwyifGmXWbMFI7KFTZLgJZpFlGd2.jpg?alt=media&token=b7244df0-6d04-4476-bfb5-4edc3445d9d4";

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