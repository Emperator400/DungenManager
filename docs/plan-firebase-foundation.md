# Plan: Firebase Foundation (Gemeinsame Basis)

Beide geplanten Features — Companion Mode und Marketplace — bauen auf derselben
Firebase-Infrastruktur auf. Diese Phase muss zuerst umgesetzt werden.

---

## Firebase Services

| Service | Verwendung |
|---------|-----------|
| **Firebase Auth** | User-Accounts (E-Mail/Passwort + Google Sign-In) |
| **Cloud Firestore** | Echtzeit-Datenbank (Companion-Sessions, Marketplace-Listings) |
| **Firebase Storage** | Kampagnen-Dateien (.DMpack), Karten-Bilder |
| **Cloud Functions** | Zahlungsabwicklung (Stripe), automatische Reviews |

---

## Neue Flutter-Pakete

```yaml
firebase_core: ^3.x
firebase_auth: ^5.x
cloud_firestore: ^5.x
firebase_storage: ^12.x
```

---

## Neue Dateien

| Datei | Inhalt |
|-------|--------|
| `lib/services/auth_service.dart` | Login, Registrierung, Logout, aktueller User |
| `lib/viewmodels/auth_viewmodel.dart` | Auth-State für UI |
| `lib/screens/auth/login_screen.dart` | Login / Registrierung |
| `lib/models/app_user.dart` | User-Profil (uid, displayName, avatarUrl) |

## Geänderte Dateien

| Datei | Änderung |
|-------|----------|
| `lib/main.dart` | Firebase initialisieren, Auth-Gate vor HomeScreen |
| `lib/screens/navigation/home_screen.dart` | User-Avatar + Logout in AppBar |

---

## Auth-Gate Pattern

```
App startet
    ↓
Firebase.initializeApp()
    ↓
StreamBuilder<User?>(stream: FirebaseAuth.instance.authStateChanges())
    ├── User == null  →  LoginScreen
    └── User != null  →  HomeScreen (bisherige App)
```

Nicht eingeloggte Nutzer können die App lokal weiter nutzen — Auth ist optional
bis Companion Mode oder Marketplace verwendet werden.

---

## Verifikation

1. App startet ohne Firebase-Fehler
2. Registrierung + Login mit E-Mail/Passwort funktioniert
3. Nicht eingeloggte Nutzer sehen weiterhin die normale App
4. `flutter analyze` — null Warnungen
