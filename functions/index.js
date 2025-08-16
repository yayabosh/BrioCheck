// functions/index.js
const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.clearPlayersDailyHTTP = functions.https.onRequest(async (req, res) => {
  // Optional: Implement a basic API key for minimal security
  const API_KEY = functions.config().apikey.secret;
  if (req.query.key !== API_KEY) {
    console.warn("Unauthorized attempt to clear players.");
    return res.status(403).send("Unauthorized");
  }

  const db = admin.firestore();
  const collectionRef = db.collection("players");

  console.log("Starting HTTP-triggered clear of players collection...");

  try {
    const snapshot = await collectionRef.get();
    if (snapshot.empty) {
      console.log("No players to clear. Collection is already empty.");
      return res.status(200).send("Collection already empty.");
    }

    const batch = db.batch();
    snapshot.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });

    await batch.commit();
    console.log(`Successfully cleared ${snapshot.size} players`);
    return res.status(200).send(`Successfully cleared snapshot.size} players.`);
  } catch (error) {
    console.error("Error clearing players collection:", error);
    return res.status(500).send("Error clearing players: " + error.message);
  }
});
