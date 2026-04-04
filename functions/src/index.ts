import { onDocumentCreated, onDocumentUpdated } from "firebase-functions/v2/firestore";
import { onRequest } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";

admin.initializeApp();


async function getUserTokens(uid: string): Promise<string[]> {
  const db = admin.firestore();

  const tokenSnap = await db
    .collection("users")
    .doc(uid)
    .collection("fcmTokens")
    .get();

  return tokenSnap.docs
    .map((doc) => doc.data().token as string | undefined)
    .filter((token): token is string => Boolean(token));
}

async function deleteInvalidTokens(
  uid: string,
  tokens: string[],
  response: admin.messaging.BatchResponse
): Promise<void> {
  const db = admin.firestore();
  const invalidTokens: string[] = [];

  response.responses.forEach((resp, index) => {
    if (!resp.success) {
      const code = resp.error?.code ?? "unknown";
      const msg = resp.error?.message ?? "Unbekannter Fehler";

      console.log(
        `Push-Fehler bei Token ${index}: code=${code}, message=${msg}`
      );

      if (
        code === "messaging/invalid-registration-token" ||
        code === "messaging/registration-token-not-registered"
      ) {
        invalidTokens.push(tokens[index]);
      }
    }
  });

  for (const invalidToken of invalidTokens) {
    await db
      .collection("users")
      .doc(uid)
      .collection("fcmTokens")
      .doc(invalidToken)
      .delete()
      .catch((err) => {
        console.log("Fehler beim Löschen eines ungültigen Tokens:", err);
      });
  }
}

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



/* function buildDisplayName(data: FirebaseFirestore.DocumentData): string {
  const username = (data["username"] as string | undefined) ?? "User";
  const vorname = (data["vorname"] as string | undefined) ?? "";
  const nachname = (data["nachname"] as string | undefined) ?? "";

  const fullName = `${vorname} ${nachname}`.trim();
  return fullName !== "" ? fullName : username;
} */

export const collectPostCommentBatch = onDocumentCreated(
  "comments/{commentId}",
  async (event) => {
    try {
      const snapshot = event.data;
      if (!snapshot) {
        console.log("Kein Comment-Snapshot vorhanden.");
        return;
      }

      const comment = snapshot.data();
      const commentId = snapshot.id;

      const actorId = comment.userId as string | undefined;
      const postId = comment.postId as string | undefined;

      if (!actorId || !postId) {
        console.log("comment.userId oder comment.postId fehlt.");
        return;
      }

      const postSnap = await db.collection("posts").doc(postId).get();
      if (!postSnap.exists) {
        console.log(`Post ${postId} nicht gefunden.`);
        return;
      }

      const postData = postSnap.data() ?? {};
      const recipientId = postData["userid"] as string | undefined;

      if (!recipientId) {
        console.log(`Post ${postId} hat kein userid.`);
        return;
      }

      if (recipientId === actorId) {
        console.log("Eigener Kommentar -> kein Batch.");
        return;
      }

      if (await shouldSuppressPostPush(recipientId, postId)) {
        console.log(`User ${recipientId} hat Post ${postId} offen -> kein Batch.`);
        return;
      }

      const batchId = buildBatchId("post_comment_summary", recipientId, postId);

      await upsertBatch({
        batchId,
        recipientId,
        type: "post_comment_summary",
        entityType: "post",
        entityId: postId,
        postId,
        commentId,
        reactionType: "like",
        actorId,
        countEveryEvent: true,
      });
    } catch (error) {
      console.error("Fehler in collectPostCommentBatch:", error);
    }
  }
);

export const collectCommentReplyBatch = onDocumentCreated(
  "replies/{replyId}",
  async (event) => {
    try {
      const snapshot = event.data;
      if (!snapshot) {
        console.log("Kein Reply-Snapshot vorhanden.");
        return;
      }

      const reply = snapshot.data();
      const replyId = snapshot.id;

      const actorId = reply.userId as string | undefined;
      const commentId = reply.commentId as string | undefined;

      if (!actorId || !commentId) {
        console.log("reply.userId oder reply.commentId fehlt.");
        return;
      }

      const commentSnap = await db.collection("comments").doc(commentId).get();
      if (!commentSnap.exists) {
        console.log(`Kommentar ${commentId} nicht gefunden.`);
        return;
      }

      const commentData = commentSnap.data() ?? {};
      const recipientId = commentData["userId"] as string | undefined;
      const postId = commentData["postId"] as string | undefined;

      if (!recipientId || !postId) {
        console.log(`Kommentar ${commentId} hat kein userId oder postId.`);
        return;
      }

      if (recipientId === actorId) {
        console.log("Eigene Reply -> kein Batch.");
        return;
      }

      const userSnap = await db.collection("users").doc(recipientId).get();
      const userData = userSnap.data() ?? {};
      const activePostId = (userData["activePostId"] as string | undefined) ?? "";
      const activeCommentId =
        (userData["activeCommentId"] as string | undefined) ?? "";

      if (activePostId === postId && activeCommentId === commentId) {
        console.log(
          `User ${recipientId} ist aktiv im Kommentar ${commentId} -> kein Batch.`
        );
        return;
      }

      const batchId = buildBatchId("comment_reply_summary", recipientId, commentId);

      await upsertBatch({
        batchId,
        recipientId,
        type: "comment_reply_summary",
        entityType: "comment",
        entityId: commentId,
        postId,
        commentId,
        replyId,
        reactionType: "like",
        actorId,
        countEveryEvent: true,
      });
    } catch (error) {
      console.error("Fehler in collectCommentReplyBatch:", error);
    }
  }
);


const db = admin.firestore();

type BatchType =
  | "post_like_summary"
  | "post_dislike_summary"
  | "comment_like_summary"
  | "reply_like_summary"
  | "post_comment_summary"
  | "comment_reply_summary";

type EntityType = "post" | "comment" | "reply";

interface BatchPayload {
  recipientId: string;
  type: BatchType;
  entityType: EntityType;
  entityId: string;
  postId: string;
  commentId: string;
  replyId: string;
  reactionType: "like" | "dislike";
  count: number;
  actorIds: string[];
  sent: boolean;
  firstCreatedAt: admin.firestore.FieldValue | admin.firestore.Timestamp;
  lastUpdatedAt: admin.firestore.FieldValue | admin.firestore.Timestamp;
  lastSentAt: admin.firestore.FieldValue | admin.firestore.Timestamp | null;
}

/* =========================================================
   HELPERS
========================================================= */


function buildBatchId(
  type: BatchType,
  recipientId: string,
  entityId: string
): string {
  return `${type}_${recipientId}_${entityId}`;
}

function isNewLike(
  beforeData: FirebaseFirestore.DocumentData | undefined,
  afterData: FirebaseFirestore.DocumentData | undefined
): boolean {
  const beforeLiked = (beforeData?.liked as boolean | undefined) ?? false;
  const afterLiked = (afterData?.liked as boolean | undefined) ?? false;
  return beforeLiked !== true && afterLiked === true;
}

function isNewDislike(
  beforeData: FirebaseFirestore.DocumentData | undefined,
  afterData: FirebaseFirestore.DocumentData | undefined
): boolean {
  const beforeDisliked = (beforeData?.disliked as boolean | undefined) ?? false;
  const afterDisliked = (afterData?.disliked as boolean | undefined) ?? false;
  return beforeDisliked !== true && afterDisliked === true;
}

async function upsertBatch(params: {
  batchId: string;
  recipientId: string;
  type: BatchType;
  entityType: EntityType;
  entityId: string;
  postId: string;
  commentId?: string;
  replyId?: string;
  reactionType: "like" | "dislike";
  actorId: string;
  countEveryEvent?: boolean;
}) {
  const batchRef = db.collection("notification_batches").doc(params.batchId);

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(batchRef);

    if (!snap.exists) {
      const newBatch: BatchPayload = {
        recipientId: params.recipientId,
        type: params.type,
        entityType: params.entityType,
        entityId: params.entityId,
        postId: params.postId,
        commentId: params.commentId ?? "",
        replyId: params.replyId ?? "",
        reactionType: params.reactionType,
        count: 1,
        actorIds: [params.actorId],
        sent: false,
        firstCreatedAt: admin.firestore.FieldValue.serverTimestamp(),
        lastUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
        lastSentAt: null,
      };

      tx.set(batchRef, newBatch);
      return;
    }

    const data = snap.data() ?? {};
    const actorIds = ((data["actorIds"] as string[] | undefined) ?? []).slice();

    let increment = 0;

    if (params.countEveryEvent === true) {
      increment = 1;

      if (!actorIds.includes(params.actorId)) {
        actorIds.push(params.actorId);
      }
    } else {
      if (!actorIds.includes(params.actorId)) {
        actorIds.push(params.actorId);
        increment = 1;
      }
    }

    tx.update(batchRef, {
      actorIds,
      count: admin.firestore.FieldValue.increment(increment),
      sent: false,
      lastUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });
}

async function shouldSuppressPostPush(recipientId: string, postId: string): Promise<boolean> {
  const userSnap = await db.collection("users").doc(recipientId).get();
  const userData = userSnap.data() ?? {};
  const activePostId = (userData["activePostId"] as string | undefined) ?? "";
  return activePostId === postId;
}

async function sendBatchNotification(batchId: string, batchData: FirebaseFirestore.DocumentData) {
  const recipientId = batchData["recipientId"] as string | undefined;
  if (!recipientId) {
    console.log(`Batch ${batchId} ohne recipientId.`);
    return;
  }

  const tokens = [...new Set(await getUserTokens(recipientId))];
  if (tokens.length === 0) {
    console.log(`Keine Tokens für recipient ${recipientId} gefunden.`);
    return;
  }

  const type = (batchData["type"] as BatchType | undefined) ?? "post_like_summary";
  const count = Number(batchData["count"] ?? 0);
  const postId = (batchData["postId"] as string | undefined) ?? "";
  const commentId = (batchData["commentId"] as string | undefined) ?? "";
  const replyId = (batchData["replyId"] as string | undefined) ?? "";

  if (count <= 0) {
    console.log(`Batch ${batchId} hat count <= 0.`);
    return;
  }

  let title = "Neue Aktivität";
  let body = `${count} neue Interaktionen`;
  let payloadType = type;

  switch (type) {
    case "post_like_summary":
      title = "👍 Neue Likes";
      body = `${count} ${count === 1 ? "Person hat" : "Personen haben"} deinen Beitrag geliked`;
      break;

    case "post_dislike_summary":
      title = "👎 Neue Dislikes";
      body = `${count} ${count === 1 ? "Person hat" : "Personen haben"} deinen Beitrag disliked`;
      break;

    case "comment_like_summary":
      title = "👍 Neue Likes auf Kommentar";
      body = `${count} ${count === 1 ? "Person hat" : "Personen haben"} deinen Kommentar geliked`;
      break;

    case "reply_like_summary":
      title = "👍 Neue Likes auf Antwort";
      body = `${count} ${count === 1 ? "Person hat" : "Personen haben"} deine Antwort geliked`;
      break;

    case "post_comment_summary":
      title = "💬 Neue Kommentare";
      body = `${count} ${count === 1 ? "neuer Kommentar" : "neue Kommentare"} zu deinem Beitrag`;
      break;

    case "comment_reply_summary":
      title = "↩️ Neue Antworten";
      body = `${count} ${count === 1 ? "neue Antwort" : "neue Antworten"} auf deinen Kommentar`;
      break;

  }

  const response = await admin.messaging().sendEachForMulticast({
    tokens,
    data: {
      action: "open_post",
      type: payloadType,
      title,
      body,
      postId: String(postId),
      commentId: String(commentId),
      replyId: String(replyId),
      count: String(count),
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

  console.log(`Batch ${batchId} gesendet:`, response.successCount);
  console.log(`Batch ${batchId} Fehler:`, response.failureCount);

  await deleteInvalidTokens(recipientId, tokens, response);

  await db.collection("notification_batches").doc(batchId).update({
    sent: true,
    lastSentAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

/* =========================================================
   POST LIKES / DISLIKES
========================================================= */

export const collectPostLikeBatch = onDocumentUpdated(
  "posts/{postId}/userInteractions/{userId}",
  async (event) => {
    try {
      const beforeData = event.data?.before.data();
      const afterData = event.data?.after.data();

      if (!isNewLike(beforeData, afterData)) {
        return;
      }

      const postId = event.params.postId;
      const actorId = event.params.userId;

      const postSnap = await db.collection("posts").doc(postId).get();
      if (!postSnap.exists) {
        console.log(`Post ${postId} nicht gefunden.`);
        return;
      }

      const postData = postSnap.data() ?? {};
      const recipientId = postData["userid"] as string | undefined;

      if (!recipientId) {
        console.log(`Post ${postId} hat kein userid.`);
        return;
      }

      if (recipientId === actorId) {
        console.log("Eigenes Post-Like -> kein Batch.");
        return;
      }

      if (await shouldSuppressPostPush(recipientId, postId)) {
        console.log(`User ${recipientId} hat Post ${postId} offen -> kein Batch.`);
        return;
      }

      const batchId = buildBatchId("post_like_summary", recipientId, postId);

      await upsertBatch({
        batchId,
        recipientId,
        type: "post_like_summary",
        entityType: "post",
        entityId: postId,
        postId,
        reactionType: "like",
        actorId,
      });
    } catch (error) {
      console.error("Fehler in collectPostLikeBatch:", error);
    }
  }
);

export const collectPostDislikeBatch = onDocumentUpdated(
  "posts/{postId}/userInteractions/{userId}",
  async (event) => {
    try {
      const beforeData = event.data?.before.data();
      const afterData = event.data?.after.data();

      if (!isNewDislike(beforeData, afterData)) {
        return;
      }

      const postId = event.params.postId;
      const actorId = event.params.userId;

      const postSnap = await db.collection("posts").doc(postId).get();
      if (!postSnap.exists) {
        console.log(`Post ${postId} nicht gefunden.`);
        return;
      }

      const postData = postSnap.data() ?? {};
      const recipientId = postData["userid"] as string | undefined;

      if (!recipientId) {
        console.log(`Post ${postId} hat kein userid.`);
        return;
      }

      if (recipientId === actorId) {
        console.log("Eigenes Post-Dislike -> kein Batch.");
        return;
      }

      if (await shouldSuppressPostPush(recipientId, postId)) {
        console.log(`User ${recipientId} hat Post ${postId} offen -> kein Batch.`);
        return;
      }

      const batchId = buildBatchId("post_dislike_summary", recipientId, postId);

      await upsertBatch({
        batchId,
        recipientId,
        type: "post_dislike_summary",
        entityType: "post",
        entityId: postId,
        postId,
        reactionType: "dislike",
        actorId,
      });
    } catch (error) {
      console.error("Fehler in collectPostDislikeBatch:", error);
    }
  }
);

/* =========================================================
   COMMENT LIKES
========================================================= */

export const collectCommentLikeBatch = onDocumentUpdated(
  "comments/{commentId}/userInteractions/{userId}",
  async (event) => {
    try {
      const beforeData = event.data?.before.data();
      const afterData = event.data?.after.data();

      if (!isNewLike(beforeData, afterData)) {
        return;
      }

      const commentId = event.params.commentId;
      const actorId = event.params.userId;

      const commentSnap = await db.collection("comments").doc(commentId).get();
      if (!commentSnap.exists) {
        console.log(`Kommentar ${commentId} nicht gefunden.`);
        return;
      }

      const commentData = commentSnap.data() ?? {};
      const recipientId = commentData["userId"] as string | undefined;
      const postId = commentData["postId"] as string | undefined;

      if (!recipientId || !postId) {
        console.log(`Kommentar ${commentId} hat kein userId oder postId.`);
        return;
      }

      if (recipientId === actorId) {
        console.log("Eigenes Kommentar-Like -> kein Batch.");
        return;
      }

      if (await shouldSuppressPostPush(recipientId, postId)) {
        console.log(`User ${recipientId} hat Post ${postId} offen -> kein Batch.`);
        return;
      }

      const batchId = buildBatchId("comment_like_summary", recipientId, commentId);

      await upsertBatch({
        batchId,
        recipientId,
        type: "comment_like_summary",
        entityType: "comment",
        entityId: commentId,
        postId,
        commentId,
        reactionType: "like",
        actorId,
      });
    } catch (error) {
      console.error("Fehler in collectCommentLikeBatch:", error);
    }
  }
);

/* =========================================================
   REPLY LIKES
========================================================= */

export const collectReplyLikeBatch = onDocumentUpdated(
  "replies/{replyId}/userInteractions/{userId}",
  async (event) => {
    try {
      const beforeData = event.data?.before.data();
      const afterData = event.data?.after.data();

      if (!isNewLike(beforeData, afterData)) {
        return;
      }

      const replyId = event.params.replyId;
      const actorId = event.params.userId;

      const replySnap = await db.collection("replies").doc(replyId).get();
      if (!replySnap.exists) {
        console.log(`Reply ${replyId} nicht gefunden.`);
        return;
      }

      const replyData = replySnap.data() ?? {};
      const recipientId = replyData["userId"] as string | undefined;
      const commentId = replyData["commentId"] as string | undefined;

      if (!recipientId || !commentId) {
        console.log(`Reply ${replyId} hat kein userId oder commentId.`);
        return;
      }

      if (recipientId === actorId) {
        console.log("Eigenes Reply-Like -> kein Batch.");
        return;
      }

      const commentSnap = await db.collection("comments").doc(commentId).get();
      if (!commentSnap.exists) {
        console.log(`Kommentar ${commentId} für Reply ${replyId} nicht gefunden.`);
        return;
      }

      const commentData = commentSnap.data() ?? {};
      const postId = commentData["postId"] as string | undefined;

      if (!postId) {
        console.log(`Kommentar ${commentId} hat kein postId.`);
        return;
      }

      if (await shouldSuppressPostPush(recipientId, postId)) {
        console.log(`User ${recipientId} hat Post ${postId} offen -> kein Batch.`);
        return;
      }

      const batchId = buildBatchId("reply_like_summary", recipientId, replyId);

      await upsertBatch({
        batchId,
        recipientId,
        type: "reply_like_summary",
        entityType: "reply",
        entityId: replyId,
        postId,
        commentId,
        replyId,
        reactionType: "like",
        actorId,
      });
    } catch (error) {
      console.error("Fehler in collectReplyLikeBatch:", error);
    }
  }
);

/* =========================================================
   SCHEDULED FLUSH
========================================================= */

export const flushNotificationBatches = onSchedule(
  {
    schedule: "every 1 minutes",
    timeZone: "Europe/Berlin",
  },
  async () => {
    try {
      const now = admin.firestore.Timestamp.now();
      const minAgeMs = 2 * 60 * 1000; // 2 Minuten Sammelzeit

      const batchSnap = await db
        .collection("notification_batches")
        .where("sent", "==", false)
        .get();

      if (batchSnap.empty) {
        console.log("Keine offenen Notification-Batches.");
        return;
      }

      for (const doc of batchSnap.docs) {
        const data = doc.data();
        const lastUpdatedAt = data["lastUpdatedAt"] as admin.firestore.Timestamp | undefined;

        if (!lastUpdatedAt) {
          console.log(`Batch ${doc.id} ohne lastUpdatedAt -> übersprungen.`);
          continue;
        }

        const ageMs = now.toMillis() - lastUpdatedAt.toMillis();

        if (ageMs < minAgeMs) {
          console.log(`Batch ${doc.id} noch zu frisch (${ageMs} ms).`);
          continue;
        }

        await sendBatchNotification(doc.id, data);
      }
    } catch (error) {
      console.error("Fehler in flushNotificationBatches:", error);
    }
  }
);

export const cleanupNotificationBatches = onSchedule(
  {
    schedule: "every day 03:00",
    timeZone: "Europe/Berlin",
  },
  async () => {
    try {
      const now = admin.firestore.Timestamp.now();

      // 7 Tage
      const maxAgeMs = 7 * 24 * 60 * 60 * 1000;
      const cutoff = admin.firestore.Timestamp.fromMillis(
        now.toMillis() - maxAgeMs
      );

      const snap = await db
        .collection("notification_batches")
        .where("sent", "==", true)
        .where("lastSentAt", "<", cutoff)
        .limit(300)
        .get();

      if (snap.empty) {
        console.log("Keine alten notification_batches zum Löschen gefunden.");
        return;
      }

      const batch = db.batch();

      for (const doc of snap.docs) {
        batch.delete(doc.ref);
      }

      await batch.commit();

      console.log(
        `cleanupNotificationBatches: ${snap.size} alte Batches gelöscht.`
      );
    } catch (error) {
      console.error("Fehler in cleanupNotificationBatches:", error);
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