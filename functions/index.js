const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

admin.initializeApp();
const db = admin.firestore();

const emailUser = defineSecret("EMAIL_USER");
const emailPass = defineSecret("EMAIL_PASS");

function generateCode() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

exports.sendVerificationCode = onCall(
  { secrets: [emailUser, emailPass] },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Sign in first.");
    }

    const uid = request.auth.uid;
    const email = request.auth.token.email;
    const code = generateCode();
    const expiresAt = admin.firestore.Timestamp.fromMillis(Date.now() + 10 * 60 * 1000);

    await db.collection("emailCodes").doc(uid).set({
      code,
      email,
      expiresAt,
      attempts: 0,
    });

    const transporter = nodemailer.createTransport({
      service: "gmail",
      auth: {
        user: emailUser.value(),
        pass: emailPass.value(),
      },
    });

    await transporter.sendMail({
      from: `EmoSense AI <${emailUser.value()}>`,
      to: email,
      subject: "Your verification code",
      text: `Your EmoSense AI verification code is ${code}. It expires in 10 minutes.`,
    });

    return { success: true };
  }
);

exports.verifyEmailCode = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in first.");
  }

  const uid = request.auth.uid;
  const code = request.data.code;
  const ref = db.collection("emailCodes").doc(uid);
  const snap = await ref.get();

  if (!snap.exists) {
    throw new HttpsError("not-found", "No code was requested.");
  }

  const record = snap.data();

  if (record.attempts >= 5) {
    throw new HttpsError("resource-exhausted", "Too many attempts. Request a new code.");
  }

  if (record.expiresAt.toMillis() < Date.now()) {
    await ref.delete();
    throw new HttpsError("deadline-exceeded", "Code expired. Request a new one.");
  }

  if (record.code !== code) {
    await ref.update({ attempts: admin.firestore.FieldValue.increment(1) });
    throw new HttpsError("invalid-argument", "Incorrect code.");
  }

  await admin.auth().updateUser(uid, { emailVerified: true });
  await ref.delete();

  return { success: true };
});
