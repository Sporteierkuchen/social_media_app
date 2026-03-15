import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { onRequest } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

admin.initializeApp();

export const notifySubscribersOnNewPost = onDocumentCreated(
  "posts/{postId}",
  async (event) => {
    const post = event.data?.data();
    const postId = event.data?.id;

    if (!post) {
      console.log("Kein Post-Dokument gefunden.");
      return;
    }

    console.log("Neuer Post erkannt:", postId);
    console.log("Post-Daten:", JSON.stringify(post));

    const creatorId = post.userid as string | undefined;
    const type = (post.type as string | undefined) ?? "post";

    const username = (post.benutzername as string | undefined) ?? "Ein Nutzer";
    const vorname = (post.vorname as string | undefined) ?? "";
    const nachname = (post.nachname as string | undefined) ?? "";

    let fullName = `${vorname} ${nachname}`.trim();
    if (fullName === "") {
    fullName = username;
    }

    let emoji = "📢";

    if (type.toLowerCase() === "video") {
    emoji = "🎬";
    } else if (type.toLowerCase() === "image" || type.toLowerCase() === "bild") {
    emoji = "📸";
    }

    const title = (post.title as string | undefined) ?? "";
    const thumbnailUrl = (post.thumbnailUrl as string | undefined) ?? "";
    const mediaUrl = (post.mediaUrl as string | undefined) ?? "";

    if (!creatorId) {
      console.log("Abbruch: Post hat kein userid-Feld.");
      return;
    }

    const imageUrl =
      thumbnailUrl.trim() !== "" ? thumbnailUrl : mediaUrl;

    let uploadText = "hat einen neuen Beitrag hochgeladen";
    if (type.toLowerCase() === "video") {
      uploadText = "hat ein neues Video hochgeladen";
    } else if (
      type.toLowerCase() === "image" ||
      type.toLowerCase() === "bild"
    ) {
      uploadText = "hat ein neues Bild hochgeladen";
    }

    const subsSnapshot = await admin
      .firestore()
      .collection("subscriptions")
      .where("subscribedToId", "==", creatorId)
      .get();

    console.log("Gefundene Subscriptions:", subsSnapshot.size);

    if (subsSnapshot.empty) {
      console.log("Keine Abonnenten gefunden.");
      return;
    }

    const subscriberIds: string[] = [];

    subsSnapshot.docs.forEach((doc) => {
      const data = doc.data();
      if (data.subscriberId) {
        subscriberIds.push(data.subscriberId as string);
      }
    });

    console.log("SubscriberIds:", JSON.stringify(subscriberIds));

    const tokenEntries: { uid: string; token: string }[] = [];

    for (const uid of subscriberIds) {
      const tokenSnapshot = await admin
        .firestore()
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

    if (tokenEntries.length === 0) {
      console.log("Keine Tokens gefunden.");
      return;
    }

    const uniqueTokens = [...new Set(tokenEntries.map((entry) => entry.token))];
    console.log("Gesammelte Tokens:", uniqueTokens.length);

    const androidNotification: {
    channelId: string;
    imageUrl?: string;
    } = {
    channelId: "high_importance_channel",
    };

    if (imageUrl.trim() !== "") {
    androidNotification.imageUrl = imageUrl;
    }

    const response = await admin.messaging().sendEachForMulticast({
    tokens: uniqueTokens,
    notification: {
    title: `${emoji} Neues von ${fullName}`,
    body: `${username} ${uploadText}`,
    },
    android: {
        priority: "high",
        notification: androidNotification,
    },
    data: {
        postId: String(postId),
        creatorId: String(creatorId),
        type: String(type),
        postTitle: String(title),
        imageUrl: String(imageUrl),
        thumbnailUrl: String(thumbnailUrl),
        mediaUrl: String(mediaUrl),
    },
    });


    console.log("Push gesendet:", response.successCount);
    console.log("Push Fehler:", response.failureCount);

    const invalidTokens: string[] = [];

    response.responses.forEach((resp, index) => {
      if (!resp.success) {
        const errorCode = resp.error?.code ?? "unknown";
        const errorMessage = resp.error?.message ?? "Unbekannter Fehler";

        console.log(
          `Fehler bei Token ${index}: code=${errorCode}, message=${errorMessage}`,
        );

        if (
          errorCode === "messaging/invalid-registration-token" ||
          errorCode === "messaging/registration-token-not-registered"
        ) {
          invalidTokens.push(uniqueTokens[index]);
        }
      }
    });

    if (invalidTokens.length > 0) {
      console.log(
        "Ungültige Tokens werden gelöscht:",
        JSON.stringify(invalidTokens),
      );

      for (const invalidToken of invalidTokens) {
        const affectedEntries = tokenEntries.filter(
          (entry) => entry.token === invalidToken,
        );

        for (const entry of affectedEntries) {
          await admin
            .firestore()
            .collection("users")
            .doc(entry.uid)
            .collection("fcmTokens")
            .doc(invalidToken)
            .delete()
            .then(() => {
              console.log(
                `Ungültiges Token gelöscht bei User ${entry.uid}: ${invalidToken}`,
              );
            })
            .catch((err) => {
              console.log(
                `Fehler beim Löschen von Token ${invalidToken} bei User ${entry.uid}:`,
                err,
              );
            });
        }
      }
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