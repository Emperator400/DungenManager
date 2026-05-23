# Plan: Campaign Marketplace

Erlaubt Creators, fertige Kampagnen als `.DMpack` zu veröffentlichen (kostenlos oder
kostenpflichtig). Käufer laden diese direkt in die App und spielen sie sofort.
Setzt **Firebase Foundation** voraus.

---

## Rollen

| Rolle | Beschreibung |
|-------|-------------|
| **Creator** | Veröffentlicht eigene Kampagnen, legt Preis fest |
| **Käufer** | Durchsucht Marketplace, kauft / lädt herunter |
| **Admin** | Prüft Listings (moderiert), kann delistieren |

---

## Firestore-Datenstruktur

```
listings/{listingId}
  ├── creatorUid: string
  ├── creatorName: string
  ├── title: string
  ├── description: string          // Markdown
  ├── tags: string[]               // ['OSR', 'Einsteiger', 'Horror', ...]
  ├── playerCount: {min, max}
  ├── estimatedSessions: number
  ├── price: number                // 0 = kostenlos, sonst Cent
  ├── currency: 'EUR'
  ├── coverImagePath: string       // Firebase Storage
  ├── previewImagePaths: string[]  // bis zu 5 Screenshots
  ├── packStoragePath: string      // .DMpack in Storage (nur für Käufer zugänglich)
  ├── version: string              // '1.0.2'
  ├── downloadCount: number
  ├── ratingAvg: number            // 0–5
  ├── ratingCount: number
  ├── status: 'draft'|'pending'|'published'|'delisted'
  └── publishedAt: timestamp
  
purchases/{userId}_{listingId}
  ├── userId: string
  ├── listingId: string
  ├── purchasedAt: timestamp
  ├── stripePaymentIntentId: string?
  └── packStoragePath: string      // Snapshot des Pfads zum Zeitpunkt des Kaufs

reviews/{listingId}/entries/{reviewId}
  ├── authorUid: string
  ├── rating: number               // 1–5
  ├── text: string
  └── createdAt: timestamp
```

---

## Neue Flutter-Pakete

```yaml
# Zu pubspec.yaml hinzufügen (nach Firebase Foundation)
stripe_flutter: ^10.x      # Stripe Checkout (iOS + Android)
cached_network_image: ^3.x # Cover-Bilder cachen
flutter_markdown: ^0.7.x   # Beschreibungen rendern
```

Für Windows-Desktop: Stripe-Checkout via Webview oder externem Browser (kein natives SDK).

---

## Neue Dateien

### Backend / Services

| Datei | Inhalt |
|-------|--------|
| `lib/models/marketplace_listing.dart` | Listing-Model |
| `lib/models/marketplace_purchase.dart` | Purchase-Record |
| `lib/models/marketplace_review.dart` | Review-Model |
| `lib/services/marketplace_service.dart` | CRUD Listings, Suche, Download-URL |
| `lib/services/marketplace_publish_service.dart` | Pack hochladen, Listing erstellen |
| `lib/services/marketplace_purchase_service.dart` | Kauf-Flow, Stripe-Intent |

### ViewModels

| Datei | Inhalt |
|-------|--------|
| `lib/viewmodels/marketplace_viewmodel.dart` | Browse + Suche |
| `lib/viewmodels/marketplace_publish_viewmodel.dart` | Creator-Flow |
| `lib/viewmodels/marketplace_purchase_viewmodel.dart` | Kauf + Download |

### Screens

| Datei | Inhalt |
|-------|--------|
| `lib/screens/marketplace/marketplace_screen.dart` | Übersicht / Suche |
| `lib/screens/marketplace/listing_detail_screen.dart` | Detailseite + Kauf-Button |
| `lib/screens/marketplace/publish_listing_screen.dart` | Kampagne veröffentlichen |
| `lib/screens/marketplace/my_purchases_screen.dart` | Gekaufte Kampagnen |
| `lib/screens/marketplace/creator_dashboard_screen.dart` | Eigene Listings verwalten |

---

## Geänderte Dateien

| Datei | Änderung |
|-------|----------|
| `lib/screens/navigation/home_screen.dart` | „Marketplace"-Kachel in `_bereiche` |
| `lib/main.dart` | MarketplaceViewModel registrieren |

---

## Kauf-Flow

```
Käufer öffnet listing_detail_screen
    ↓
[Kostenlos herunterladen] ODER [Kaufen für X €]
    ↓ (kostenpflichtig)
Cloud Function: createPaymentIntent(listingId, userId)
    → Stripe Payment Intent erstellen
    → Intent-Client-Secret zurückgeben
    ↓
Stripe-Sheet in App (iOS/Android) oder Browser-Redirect (Windows)
    ↓
Zahlung erfolgreich → Cloud Function: fulfillPurchase(paymentIntentId)
    → purchase-Dokument in Firestore anlegen
    → temporäre Download-URL für .DMpack erzeugen (1h gültig)
    ↓
App lädt .DMpack herunter
marketplace_purchase_service.installPack(localPath)
    → campaign_template_export_import_service.importFromFile()
    → Kampagne erscheint lokal in der App
```

---

## Publish-Flow (Creator)

```
Creator öffnet publish_listing_screen
    → wählt lokale Kampagne aus
    → füllt Metadaten aus (Titel, Beschreibung, Tags, Preis)
    → lädt Cover-Bild hoch (Storage: listings/{id}/cover.jpg)
    → lädt bis zu 5 Screenshots hoch
    ↓
[Veröffentlichen]
    ↓
marketplace_publish_service.publishCampaign(campaign, metadata)
    → exportiert .DMpack lokal (campaign_template_export_import_service)
    → lädt .DMpack zu Storage hoch (listings/{id}/pack.DMpack)
    → erstellt Listing-Dokument (status: 'pending')
    ↓
Admin prüft Listing → status → 'published'
```

---

## Cloud Functions (Node.js / TypeScript)

| Funktion | Trigger | Aufgabe |
|----------|---------|---------|
| `createPaymentIntent` | HTTPS callable | Stripe Intent erstellen, Preis aus Listing lesen |
| `fulfillPurchase` | Stripe Webhook | Purchase-Dokument anlegen, Download-URL erzeugen |
| `onReviewCreated` | Firestore trigger | `ratingAvg` + `ratingCount` im Listing aktualisieren |
| `onListingPublished` | Firestore trigger | Creator-E-Mail-Benachrichtigung |

---

## Sicherheitsregeln (Firestore)

```
listings/{listingId}
  read: resource.data.status == 'published'    // alle dürfen lesen
     OR request.auth.uid == resource.data.creatorUid  // Creator auch draft/pending
  write: request.auth.uid == resource.data.creatorUid
      && resource.data.status in ['draft', 'pending']  // nach publish kein edit
  
purchases/{purchaseId}
  read: request.auth.uid == resource.data.userId
  write: false   // nur Cloud Function schreibt
```

---

## Stripe-Setup

1. Stripe-Konto mit MCC 5734 (Software) anlegen
2. Produkte sind „one-time purchases" (kein Abo)
3. Platform-Fee: z.B. 30 % DungenManager-Anteil via Stripe Connect
4. Auszahlung an Creators via Stripe Connect Express (monatlich)
5. Keine Steuerberechnung nötig (Stripe Tax optional)

---

## Verifikation

1. `flutter analyze` — null Warnungen
2. Marketplace-Screen öffnet, Listings werden geladen (Suche, Filter)
3. Kostenlose Kampagne herunterladen → erscheint in Kampagnen-Liste
4. Kostenpflichtige Kampagne → Stripe-Sheet öffnet sich, Test-Karte akzeptiert
5. Nach Kauf → .DMpack wird heruntergeladen und importiert
6. Creator veröffentlicht Kampagne → Listing im Status 'pending' sichtbar
7. Admin-Review → nach Freigabe 'published', in Suche sichtbar
8. Bewertung abgeben → `ratingAvg` im Listing aktualisiert sich
9. Creator-Dashboard zeigt Downloads + Einnahmen
