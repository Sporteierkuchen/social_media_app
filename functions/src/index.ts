import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { onRequest } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

admin.initializeApp();

export const notifySubscribersOnNewPost = onDocumentCreated(
  "posts/{postId}",
  async (event) => {
    const post = event.data?.data();
    if (!post) {
      return;
    }

    const creatorId = post.userid as string | undefined;
    const creatorName = (post.benutzername as string | undefined) ?? "Ein Nutzer";
    const type = (post.type as string | undefined) ?? "post";
    const postId = event.data?.id;

    if (!creatorId) {
      console.log("Post hat keinen userid");
      return;
    }

    console.log("Neuer Post erkannt:", postId);

    const subsSnapshot = await admin
      .firestore()
      .collection("subscriptions")
      .where("subscribedToId", "==", creatorId)
      .get();

    if (subsSnapshot.empty) {
      console.log("Keine Abonnenten gefunden");
      return;
    }

    const subscriberIds: string[] = [];

    subsSnapshot.docs.forEach((doc) => {
      const data = doc.data();
      if (data.subscriberId) {
        subscriberIds.push(data.subscriberId as string);
      }
    });

    const tokens: string[] = [];

    for (const uid of subscriberIds) {
      const tokenSnapshot = await admin
        .firestore()
        .collection("users")
        .doc(uid)
        .collection("fcmTokens")
        .get();

      tokenSnapshot.docs.forEach((doc) => {
        const token = doc.data().token as string | undefined;
        if (token) {
          tokens.push(token);
        }
      });
    }

    if (tokens.length === 0) {
      console.log("Keine Tokens gefunden");
      return;
    }

    const response = await admin.messaging().sendEachForMulticast({
      tokens,
      notification: {
        title: "Neuer Upload",
        body: `${creatorName} hat ein neues ${type} hochgeladen`,
      },
      data: {
        postId: String(postId),
        creatorId: String(creatorId),
        type: String(type),
      },
    });

    console.log("Push gesendet:", response.successCount);
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

  for (let i = 0; i < uniqueTokens.length; i += chunkSize) {
    const chunk = uniqueTokens.slice(i, i + chunkSize);

    const response = await admin.messaging().sendEachForMulticast({
      tokens: chunk,
      notification: {
        title: "Test Push",
        body: "Das ist eine Test Push Nachricht 🚀",
      },
      data: {
        type: "test",
      },
    });

    successTotal += response.successCount;
    failureTotal += response.failureCount;
  }

  res
    .status(200)
    .send(`Push gesendet. Erfolgreich: ${successTotal}, Fehler: ${failureTotal}`);
});