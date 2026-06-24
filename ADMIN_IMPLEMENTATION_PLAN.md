# 📋 Plan d'implémentation Admin Dashboard

Guide étape par étape pour construire le dashboard MyGabon Admin.

---

## 🎯 Phase 1: Fondations (Semaine 1)

### Étape 1.1: Setup Initial
- [ ] Créer dossier `admin/`
- [ ] `npm install` (dependencies)
- [ ] Configurer `.env.local`
- [ ] Setup Tailwind CSS
- [ ] Setup TypeScript
- [ ] Créer structure de dossiers

**Commandes:**
```bash
mkdir admin && cd admin
npm install
cp .env.example .env.local
npm run dev
```

### Étape 1.2: Authentification Admin
- [ ] Créer table `admin_users` dans Supabase
- [ ] Installer NextAuth.js
- [ ] Créer page `/auth/login`
- [ ] Implémenter provider CredentialsProvider
- [ ] Tester login

**Fichiers à créer:**
```
app/auth/login/page.tsx
app/api/auth/[...nextauth].ts
lib/auth.ts
components/auth/login-form.tsx
```

**SQL Setup:**
```sql
CREATE TABLE admin_users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  full_name TEXT,
  role TEXT DEFAULT 'moderator',
  status TEXT DEFAULT 'active',
  created_at TIMESTAMP DEFAULT NOW()
);

-- Créer user admin de test
INSERT INTO admin_users (email, password_hash, full_name, role)
VALUES ('admin@mygabon.com', '$2a$10$...', 'Admin MyGabon', 'super_admin');
```

### Étape 1.3: Layout Principal
- [ ] Créer Sidebar navigation
- [ ] Créer Navbar avec user menu
- [ ] Créer layout `/admin`
- [ ] Ajouter theme toggle
- [ ] Protéger routes avec middleware

**Fichiers à créer:**
```
app/admin/layout.tsx
components/layout/sidebar.tsx
components/layout/navbar.tsx
middleware.ts
lib/hooks/useAuth.ts
```

---

## 🎯 Phase 2: User Management (Semaine 2)

### Étape 2.1: Liste Utilisateurs
- [ ] Créer API route `GET /api/users`
- [ ] Créer page `/admin/users`
- [ ] Implémenter tableau avec TanStack Table
- [ ] Ajouter pagination
- [ ] Ajouter recherche

**Fichiers à créer:**
```
app/admin/users/page.tsx
app/admin/users/columns.tsx
app/api/users/route.ts
components/users/user-table.tsx
lib/hooks/useUsers.ts
lib/api/users.ts
```

### Étape 2.2: CRUD Utilisateurs
- [ ] Créer API `POST /api/users` (créer)
- [ ] Créer API `PUT /api/users/[id]` (éditer)
- [ ] Créer API `DELETE /api/users/[id]` (supprimer)
- [ ] Créer modal d'édition
- [ ] Ajouter confirmations

**Fonctionnalités:**
```typescript
✅ Soft-delete
✅ Inline editing
✅ Statut utilisateur
✅ Historique actions
```

### Étape 2.3: Filtres et Recherche
- [ ] Filtre par statut
- [ ] Filtre par rôle
- [ ] Filtre par date
- [ ] Recherche par email/nom
- [ ] Sauvegarde filtres

---

## 🎯 Phase 3: Image Moderation (Semaine 2-3)

### Étape 3.1: Queue de Validation
- [ ] Créer table `image_moderation` dans Supabase
- [ ] Créer API `GET /api/images/queue`
- [ ] Créer page `/admin/images`
- [ ] Afficher preview images
- [ ] Afficher métadonnées

**Fichiers à créer:**
```
app/admin/images/page.tsx
app/admin/images/queue.tsx
app/api/images/route.ts
components/images/image-preview.tsx
lib/api/images.ts
lib/hooks/useImages.ts
```

**SQL Setup:**
```sql
CREATE TABLE image_moderation (
  id UUID PRIMARY KEY,
  product_id UUID REFERENCES products(id),
  image_url TEXT,
  status TEXT DEFAULT 'pending',
  ai_score DECIMAL,
  reason_rejected TEXT,
  created_at TIMESTAMP,
  reviewed_by UUID,
  reviewed_at TIMESTAMP
);
```

### Étape 3.2: Approbation/Rejet
- [ ] Créer API `POST /api/images/approve`
- [ ] Créer API `POST /api/images/reject`
- [ ] Ajouter raisons de rejet (dropdown)
- [ ] Ajouter logging audit
- [ ] Notification au vendeur

**Endpoints:**
```typescript
POST /api/images/approve
  { id: string, notes?: string }

POST /api/images/reject
  { id: string, reason: string }

DELETE /api/images/:id
  (suppression définitive)
```

### Étape 3.3: IA Moderation (OpenAI)
- [ ] Configurer OpenAI API key
- [ ] Créer fonction d'analyse IA
- [ ] Détection nudité/violence
- [ ] Score qualité image
- [ ] Recommandations automatiques

**Fichiers à créer:**
```
lib/ai/image-analyzer.ts
app/api/images/analyze.ts
components/images/ai-analyzer.tsx
```

**Code exemple:**
```typescript
// lib/ai/image-analyzer.ts
import OpenAI from "openai"

export async function analyzeImageWithAI(imageUrl: string) {
  const client = new OpenAI()
  
  const response = await client.vision.analyze({
    model: "gpt-4-vision",
    messages: [
      {
        role: "user",
        content: [
          {
            type: "image_url",
            image_url: { url: imageUrl },
          },
          {
            type: "text",
            text: `Analyse cette image pour modération. Réponds en JSON:
            {
              "nudity_score": 0-100,
              "violence_score": 0-100,
              "illegal_content_score": 0-100,
              "quality_score": 0-100,
              "recommendation": "approve|reject|review",
              "reasons": ["raison1", "raison2"]
            }`,
          },
        ],
      },
    ],
  })
  
  return JSON.parse(response.content[0].text)
}
```

---

## 🎯 Phase 4: Wallet Management (Semaine 3)

### Étape 4.1: Affichage Wallets
- [ ] Créer page `/admin/wallet`
- [ ] Créer tableau avec soldes
- [ ] Afficher historique transactions
- [ ] Recherche par utilisateur
- [ ] Filtres par méthode

**Fichiers à créer:**
```
app/admin/wallet/page.tsx
app/admin/wallet/transactions.tsx
app/api/wallet/route.ts
components/wallet/wallet-table.tsx
lib/api/wallet.ts
```

### Étape 4.2: Ajustements Manuels
- [ ] Créer API `POST /api/wallet/adjust`
- [ ] Ajouter modal d'ajustement
- [ ] Raison obligatoire
- [ ] Logging audit
- [ ] Approbation double (si > 100k)

**Endpoint:**
```typescript
POST /api/wallet/adjust
{
  user_id: string,
  amount: number,
  reason: "correction" | "refund" | "bonus" | "penalty",
  notes?: string,
  approved_by?: string // pour montants élevés
}
```

### Étape 4.3: Alertes et Rapports
- [ ] Détection anomalies
- [ ] Alertes Slack
- [ ] Rapports quotidiens
- [ ] Réconciliation
- [ ] Export CSV

---

## 🎯 Phase 5: Analytics (Semaine 4)

### Étape 5.1: Dashboard Analytics
- [ ] Créer page `/admin/analytics`
- [ ] KPIs principaux (DAU, revenue, etc.)
- [ ] Graphiques Recharts
- [ ] Période sélectionnable
- [ ] Real-time updates

**Fichiers à créer:**
```
app/admin/analytics/page.tsx
app/admin/analytics/charts.tsx
app/api/analytics/route.ts
components/analytics/stats-card.tsx
components/analytics/chart-section.tsx
lib/api/analytics.ts
```

**KPIs:**
```typescript
const kpis = [
  { title: "DAU", value: 1234, trend: "+5%" },
  { title: "Revenue", value: "42.5M FCFA", trend: "+12%" },
  { title: "Transactions", value: 3456, trend: "+8%" },
  { title: "Images Approved", value: 234, trend: "-3%" },
]
```

### Étape 5.2: Graphiques
- [ ] Line chart (trends)
- [ ] Bar chart (comparaisons)
- [ ] Pie chart (répartition)
- [ ] Export données
- [ ] Rapports PDF

---

## 🎯 Phase 6: Notifications & Webhooks (Semaine 4-5)

### Étape 6.1: Real-time Notifications
- [ ] Supabase Realtime setup
- [ ] Toast notifications (Sonner)
- [ ] Sound alerts
- [ ] Desktop notifications
- [ ] Notification center

**Fichiers à créer:**
```
lib/hooks/useRealtime.ts
components/notifications/notification-center.tsx
lib/store/notifications.ts
```

### Étape 6.2: Webhooks Management
- [ ] Créer page `/admin/webhooks`
- [ ] CRUD webhooks
- [ ] Test webhook
- [ ] Logs webhooks
- [ ] Retry policy

**Fichiers à créer:**
```
app/admin/webhooks/page.tsx
app/admin/webhooks/logs.tsx
app/api/webhooks/route.ts
components/webhooks/webhook-form.tsx
```

---

## 🎯 Phase 7: Settings & Sécurité (Semaine 5)

### Étape 7.1: Settings Admin
- [ ] Page `/admin/settings`
- [ ] Gestion rôles
- [ ] Permissions granulaires
- [ ] Sessions admin
- [ ] Audit logs

### Étape 7.2: Sécurité
- [ ] 2FA setup
- [ ] Rate limiting
- [ ] IP whitelist
- [ ] Session timeout
- [ ] Password policies

---

## 📦 Fichiers à créer (Checklist)

### Composants UI (Shadcn)
```
components/ui/
  ├── button.tsx
  ├── card.tsx
  ├── dialog.tsx
  ├── dropdown-menu.tsx
  ├── input.tsx
  ├── table.tsx
  ├── tabs.tsx
  ├── badge.tsx
  ├── pagination.tsx
  ├── alert.tsx
  └── toast.tsx
```

**Installation:**
```bash
npx shadcn-ui@latest init
npx shadcn-ui@latest add button card dialog input table tabs badge
```

### Hooks Custom
```
lib/hooks/
  ├── useAuth.ts
  ├── useUsers.ts
  ├── useImages.ts
  ├── useWallet.ts
  ├── useAnalytics.ts
  ├── useRealtime.ts
  └── useTable.ts
```

### API Routes
```
app/api/
  ├── auth/[...nextauth].ts
  ├── users/route.ts
  ├── users/[id].ts
  ├── images/route.ts
  ├── images/approve.ts
  ├── images/reject.ts
  ├── images/analyze.ts
  ├── wallet/route.ts
  ├── wallet/adjust.ts
  ├── analytics/route.ts
  └── webhooks/route.ts
```

---

## 🚀 Ordre de priorité recommandé

```
SEMAINE 1:
  ✅ Setup initial
  ✅ Authentification admin
  ✅ Layout principal

SEMAINE 2:
  ✅ User management (CRUD)
  ✅ Image queue de validation
  ✅ Approbation/rejet images

SEMAINE 3:
  ✅ IA Moderation
  ✅ Wallet management
  ✅ Ajustements manuels

SEMAINE 4:
  ✅ Analytics dashboard
  ✅ Graphiques
  ✅ Real-time notifications

SEMAINE 5:
  ✅ Webhooks
  ✅ Settings admin
  ✅ Sécurité avancée
  ✅ Tests & polish
  ✅ Déploiement Vercel
```

---

## 🔑 Commandes importantes

```bash
# Démarrer le projet
cd admin && npm run dev

# Build pour production
npm run build && npm start

# Type checking
npm run type-check

# Installer composants Shadcn
npx shadcn-ui@latest add [component-name]

# Déployer sur Vercel
vercel --prod

# Générer secret NextAuth
openssl rand -base64 32
```

---

## 📚 Ressources

- **Next.js Docs:** https://nextjs.org/docs
- **Shadcn/ui:** https://ui.shadcn.com
- **TanStack Table:** https://tanstack.com/table
- **Supabase:** https://supabase.com/docs
- **NextAuth:** https://next-auth.js.org
- **Recharts:** https://recharts.org
- **Tailwind:** https://tailwindcss.com

---

## ✅ Test Checklist

- [ ] Login/logout fonctionne
- [ ] User CRUD complet
- [ ] Image moderation fonctionne
- [ ] Wallet adjustments fonctionne
- [ ] Analytics affiche les bonnes données
- [ ] Real-time notifications
- [ ] Audit logs complets
- [ ] Performance acceptable
- [ ] Responsive design OK
- [ ] Sécurité validée

---

## 🎯 Next Steps

1. Commencer Phase 1 (Setup + Auth)
2. Créer tables Supabase
3. Tester login
4. Progresser phase par phase
5. Tester chaque étape
6. Déployer quand prêt

Bonne chance! 🚀
