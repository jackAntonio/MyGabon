# 🔥 Firebase Setup Guide pour GabonConnect

## ✅ État actuel

```
✅ Node.js v24.16.0 installé
✅ npm v11.13.0 installé  
✅ Firebase CLI v15.22.0 installé
✅ GabonConnect app lancée sur web
```

---

## 📋 Prochaines Étapes

### Étape 1: Se connecter à Firebase

```bash
cd C:\Users\HP\Downloads\MyGabon

# Lancer le script PowerShell (en admin si possible)
powershell -ExecutionPolicy Bypass -File firebase-setup.ps1

# Ou lancer directement
C:\Users\HP\AppData\Roaming\npm\firebase.cmd login
```

Cela va:
1. Ouvrir un navigateur
2. Te demander de te connecter avec ton compte Google
3. Donner permission à Firebase CLI d'accéder à tes projets

### Étape 2: Créer un projet Firebase

**Option A: Via Console** (Plus facile)
1. Aller à https://console.firebase.google.com
2. Cliquer "Créer un projet"
3. Nommer: `gabon-connect`
4. Activer Google Analytics (optionnel)
5. Créer

**Option B: Via CLI**
```bash
firebase init hosting
# Répondre aux questions
```

### Étape 3: Initialiser Firebase dans le projet

```bash
cd C:\Users\HP\Downloads\MyGabon

# Initialiser
firebase init

# Choix à faire:
# ✅ Firestore
# ✅ Cloud Functions  
# ✅ Hosting
# ✅ Cloud Messaging
```

---

## 🗂️ Structure Firebase pour GabonConnect

### Collections Firestore à créer:

```
gabon-connect-db/
├── users/
│   ├── {userId}
│   │   ├── email: string
│   │   ├── displayName: string
│   │   ├── phoneNumber: string
│   │   ├── verified: boolean
│   │   └── createdAt: timestamp
│
├── services/
│   ├── {serviceId}
│   │   ├── title: string
│   │   ├── description: string
│   │   ├── price: number
│   │   ├── category: string
│   │   ├── providerId: string
│   │   └── rating: number
│
├── auditLogs/              ← PHASE 2
│   ├── {logId}
│   │   ├── userId: string
│   │   ├── action: string (login, logout, otpSent, etc)
│   │   ├── timestamp: timestamp
│   │   ├── status: string (success, failure)
│   │   └── details: object
│
├── notifications/
│   ├── {notificationId}
│   │   ├── userId: string
│   │   ├── title: string
│   │   ├── body: string
│   │   ├── read: boolean
│   │   └── createdAt: timestamp
│
├── marketplace/
│   ├── {productId}
│   │   ├── title: string
│   │   ├── price: number
│   │   ├── seller: string
│   │   └── images: array
│
└── messages/
    ├── {conversationId}
    │   ├── participants: array
    │   ├── messages: array
    │   └── updatedAt: timestamp
```

---

## 🔐 Configuration Firestore Rules

Après créer les collections, ajoute ces règles de sécurité:

```firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Users - Lecture propre, écriture admin
    match /users/{userId} {
      allow read: if request.auth.uid == userId;
      allow create: if request.auth.uid == userId;
      allow update: if request.auth.uid == userId;
      allow delete: if false; // Pas de suppression
    }
    
    // Services - Lecture publique, écriture admin
    match /services/{serviceId} {
      allow read: if true;
      allow write: if request.auth != null && 
                      request.auth.uid == resource.data.providerId;
    }
    
    // Audit Logs - Écriture utilisateurs authentifiés, lecture admin
    match /auditLogs/{logId} {
      allow create: if request.auth != null;
      allow read: if request.auth.uid == resource.data.userId;
      allow delete: if false;
    }
    
    // Notifications - Lecture propre
    match /notifications/{notificationId} {
      allow read: if request.auth.uid == resource.data.userId;
      allow write: if request.auth != null;
    }
    
    // Messages - Lecture participants, écriture participants
    match /messages/{conversationId} {
      allow read, write: if request.auth.uid in resource.data.participants;
    }
  }
}
```

---

## ☁️ Cloud Functions pour Phase 2

### Créer fonction sendOTP:

```bash
cd C:\Users\HP\Downloads\MyGabon
firebase functions:create sendOTP --runtime nodejs-18
```

**functions/sendOTP/index.js:**
```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');
const twilio = require('twilio');

admin.initializeApp();

const twilioClient = twilio(
  process.env.TWILIO_ACCOUNT_SID,
  process.env.TWILIO_AUTH_TOKEN
);

exports.sendOTP = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  const { phoneNumber, otp } = data;

  try {
    const message = await twilioClient.messages.create({
      body: `Votre code OTP GabonConnect est: ${otp}`,
      from: process.env.TWILIO_PHONE_NUMBER,
      to: phoneNumber,
    });

    // Log audit
    await admin.firestore().collection('auditLogs').add({
      userId: context.auth.uid,
      action: 'otpSent',
      phoneNumber: phoneNumber.slice(-4),
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      status: 'success',
    });

    return { success: true, sid: message.sid };
  } catch (error) {
    // Log erreur
    await admin.firestore().collection('auditLogs').add({
      userId: context.auth.uid,
      action: 'otpSent',
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      status: 'failure',
      error: error.message,
    });

    throw new functions.https.HttpsError('internal', error.message);
  }
});
```

---

## 🚀 Déployer à Firebase

### 1. Firestore Rules:
```bash
firebase deploy --only firestore:rules
```

### 2. Cloud Functions:
```bash
firebase deploy --only functions
```

### 3. Hosting (App web):
```bash
firebase deploy --only hosting
```

### Tout déployer:
```bash
firebase deploy
```

---

## 🔌 Connecter l'app Flutter à Firebase

### Dans main.dart:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const GabonConnectApp());
}
```

### Variables d'environnement (.env):

```ini
FIREBASE_PROJECT_ID=gabon-connect-xxxxx
FIREBASE_API_KEY=AIzaSyD...
FIREBASE_MESSAGING_SENDER_ID=123456789
FIREBASE_APP_ID=1:123456789:web:abc123def456

TWILIO_ACCOUNT_SID=ACxxxxxxxx
TWILIO_AUTH_TOKEN=your-token
TWILIO_PHONE_NUMBER=+1234567890
```

---

## 📱 Exécuter sur mobile (Android/iOS)

Une fois Firebase configuré:

```bash
# Android
flutter run

# iOS (Mac uniquement)
flutter run -d ios
```

---

## 🧪 Tester Firebase Localement

```bash
# Démarrer l'émulateur Firebase
firebase emulators:start

# Cela lance:
# ✅ Firestore émulateur (localhost:8080)
# ✅ Functions émulateur (localhost:5001)
# ✅ Auth émulateur (localhost:9099)
```

---

## 📊 Commandes utiles

```bash
# Vérifier connexion
firebase auth:export users.json

# Voir logs functions
firebase functions:log

# Voir état du déploiement
firebase deploy:list

# Nettoyer
firebase use --unset
```

---

## ✅ Checklist Complète

- [ ] Node.js + npm installés
- [ ] Firebase CLI installé
- [ ] Connecté à Firebase (`firebase login`)
- [ ] Projet Firebase créé
- [ ] Collections Firestore créées
- [ ] Firestore Rules déployées
- [ ] Cloud Functions créées
- [ ] App Flutter connectée à Firebase
- [ ] Credentials configurés dans .env
- [ ] Tout déployé (`firebase deploy`)
- [ ] Tests effectués

---

## 🆘 Troubleshooting

### "firebase: command not found"
```bash
# Solution:
export PATH="$PATH:C:\Users\HP\AppData\Roaming\npm"
firebase --version
```

### "Authentication failed"
```bash
# Réinitialiser authentification:
firebase logout
firebase login
```

### Firestore Rules rejection
```bash
# Vérifier règles:
firebase firestore:get-rules

# Redéployer:
firebase deploy --only firestore:rules
```

---

**Tu es prêt pour Phase 2 de GabonConnect!** 🎉

Contact Firebase support: https://firebase.google.com/support/troubleshooter

