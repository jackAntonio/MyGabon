# 🎯 MyGabon Admin Dashboard - Configuration Complète

Interface d'administration web complète pour MyGabon avec gestion des utilisateurs, images, wallets, analytics et modération IA.

---

## 📦 Stack Technologique

```
Frontend:     Next.js 14 + TypeScript
UI:           Shadcn/ui + Tailwind CSS
State:        TanStack Query + Zustand
Real-time:    Supabase Realtime
Auth:         NextAuth.js + Supabase
Database:     Supabase (PostgreSQL)
Deployment:   Vercel
Analytics:    PostHog
Monitoring:   Sentry
```

---

## 🚀 Installation rapide

### 1. Naviguer vers le dossier admin
```bash
cd admin
npm install
```

### 2. Variables d'environnement
Créer `.env.local`:
```env
NEXT_PUBLIC_SUPABASE_URL=https://kbggddignhydzxjzdera.supabase.com
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_key_here

SUPABASE_SERVICE_ROLE_KEY=your_service_key

NEXTAUTH_SECRET=your_secret_key
NEXTAUTH_URL=http://localhost:3000

OPENAI_API_KEY=your_openai_key_for_image_moderation
```

### 3. Démarrer le serveur de développement
```bash
npm run dev
```

Ouvrir [http://localhost:3000/admin](http://localhost:3000/admin)

---

## 📁 Structure du projet

```
admin/
├── app/
│   ├── layout.tsx                    # Root layout
│   ├── page.tsx                      # Redirect vers /admin
│   ├── admin/
│   │   ├── layout.tsx               # Admin layout (sidebar, navbar)
│   │   ├── page.tsx                 # Dashboard principal
│   │   │
│   │   ├── users/
│   │   │   ├── page.tsx             # Liste utilisateurs
│   │   │   ├── columns.tsx          # Colonnes tableau
│   │   │   ├── [id]/
│   │   │   │   ├── page.tsx         # Détails utilisateur
│   │   │   │   └── edit.tsx         # Éditer utilisateur
│   │   │   └── components/
│   │   │       ├── user-list.tsx
│   │   │       ├── user-modal.tsx
│   │   │       └── user-filters.tsx
│   │   │
│   │   ├── images/
│   │   │   ├── page.tsx             # Modération images
│   │   │   ├── queue.tsx            # Queue de validation
│   │   │   ├── gallery.tsx          # Galerie approuvées
│   │   │   ├── rejected.tsx         # Images rejetées
│   │   │   └── components/
│   │   │       ├── image-preview.tsx
│   │   │       ├── moderation-modal.tsx
│   │   │       └── ai-analyzer.tsx
│   │   │
│   │   ├── wallet/
│   │   │   ├── page.tsx             # Gestion wallets
│   │   │   ├── transactions.tsx     # Historique
│   │   │   ├── adjustments.tsx      # Ajustements
│   │   │   └── components/
│   │   │       ├── wallet-table.tsx
│   │   │       └── adjustment-modal.tsx
│   │   │
│   │   ├── analytics/
│   │   │   ├── page.tsx             # Dashboard analytics
│   │   │   ├── charts.tsx           # Graphiques
│   │   │   ├── reports.tsx          # Rapports
│   │   │   └── components/
│   │   │       ├── stats-card.tsx
│   │   │       ├── chart-section.tsx
│   │   │       └── kpi-grid.tsx
│   │   │
│   │   ├── notifications/
│   │   │   ├── page.tsx             # Centre notifications
│   │   │   ├── templates.tsx        # Templates email
│   │   │   └── components/
│   │   │       ├── notification-list.tsx
│   │   │       └── template-editor.tsx
│   │   │
│   │   ├── webhooks/
│   │   │   ├── page.tsx             # Gestion webhooks
│   │   │   ├── logs.tsx             # Logs webhooks
│   │   │   └── components/
│   │   │       ├── webhook-form.tsx
│   │   │       └── webhook-logs.tsx
│   │   │
│   │   ├── settings/
│   │   │   ├── page.tsx             # Paramètres admin
│   │   │   ├── roles.tsx            # Gestion rôles
│   │   │   ├── permissions.tsx      # Permissions
│   │   │   └── components/
│   │   │       ├── role-manager.tsx
│   │   │       └── permission-editor.tsx
│   │   │
│   │   └── api/
│   │       ├── auth/
│   │       │   ├── [...nextauth].ts # NextAuth config
│   │       │   └── callback.ts
│   │       ├── users/
│   │       │   ├── route.ts         # GET/POST/DELETE users
│   │       │   └── [id].ts          # GET/PUT user
│   │       ├── images/
│   │       │   ├── route.ts
│   │       │   ├── approve.ts
│   │       │   ├── reject.ts
│   │       │   └── analyze.ts       # IA moderation
│   │       ├── wallet/
│   │       │   ├── route.ts
│   │       │   └── adjust.ts
│   │       ├── analytics/
│   │       │   └── route.ts
│   │       └── webhooks/
│   │           ├── route.ts
│   │           └── logs.ts
│   │
│   └── auth/
│       └── login/
│           └── page.tsx             # Page login admin
│
├── components/
│   ├── ui/                          # Shadcn components
│   │   ├── button.tsx
│   │   ├── card.tsx
│   │   ├── dialog.tsx
│   │   ├── dropdown-menu.tsx
│   │   ├── input.tsx
│   │   ├── table.tsx
│   │   ├── tabs.tsx
│   │   ├── alert.tsx
│   │   ├── badge.tsx
│   │   ├── pagination.tsx
│   │   └── ...
│   │
│   ├── layout/
│   │   ├── sidebar.tsx
│   │   ├── navbar.tsx
│   │   ├── footer.tsx
│   │   └── breadcrumb.tsx
│   │
│   └── shared/
│       ├── loading.tsx
│       ├── empty-state.tsx
│       ├── error-boundary.tsx
│       ├── confirmation-dialog.tsx
│       └── toast-provider.tsx
│
├── lib/
│   ├── supabase.ts                  # Client Supabase
│   ├── auth.ts                      # Auth logic
│   ├── validators.ts                # Zod schemas
│   ├── utils.ts                     # Utilitaires
│   ├── constants.ts                 # Constantes
│   ├── hooks/
│   │   ├── useAuth.ts
│   │   ├── useUsers.ts
│   │   ├── useImages.ts
│   │   ├── useWallet.ts
│   │   ├── useAnalytics.ts
│   │   └── useRealtime.ts
│   ├── api/
│   │   ├── users.ts
│   │   ├── images.ts
│   │   ├── wallet.ts
│   │   ├── analytics.ts
│   │   └── webhooks.ts
│   └── store/
│       ├── auth.ts                  # Zustand store
│       ├── ui.ts
│       └── filters.ts
│
├── styles/
│   └── globals.css                  # Tailwind + globals
│
├── public/
│   └── logo.svg
│
├── .env.local                       # Variables d'environnement
├── .eslintrc.json
├── package.json
├── next.config.js
├── tailwind.config.ts
├── tsconfig.json
└── README.md
```

---

## 🔐 Authentification Admin

### Table Supabase

```sql
CREATE TABLE admin_users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  full_name TEXT,
  role ENUM ('super_admin', 'moderator', 'analyst') DEFAULT 'moderator',
  permissions JSON DEFAULT '{"users": true, "images": true}',
  status ENUM ('active', 'inactive', 'suspended') DEFAULT 'active',
  last_login TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE admin_audit_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  admin_id UUID REFERENCES admin_users(id),
  action TEXT NOT NULL,
  resource_type TEXT,
  resource_id TEXT,
  changes JSON,
  ip_address TEXT,
  user_agent TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);
```

### NextAuth Configuration

```typescript
// app/api/auth/[...nextauth].ts
import NextAuth from "next-auth"
import CredentialsProvider from "next-auth/providers/credentials"
import { supabase } from "@/lib/supabase"

export const authOptions = {
  providers: [
    CredentialsProvider({
      async authorize(credentials) {
        const { email, password } = credentials || {}
        
        // Vérifier dans admin_users
        const { data: admin } = await supabase
          .from('admin_users')
          .select('*')
          .eq('email', email)
          .single()
        
        if (!admin) return null
        
        // Vérifier password (bcrypt)
        const isValid = await bcrypt.compare(password, admin.password_hash)
        if (!isValid) return null
        
        return {
          id: admin.id,
          email: admin.email,
          name: admin.full_name,
          role: admin.role,
        }
      },
    }),
  ],
  pages: {
    signIn: '/auth/login',
  },
  callbacks: {
    async jwt({ token, user }) {
      if (user) {
        token.role = user.role
      }
      return token
    },
    async session({ session, token }) {
      session.user.role = token.role
      return session
    },
  },
}

export default NextAuth(authOptions)
```

---

## 📊 Features par section

### 👥 **User Management**

```typescript
// Features:
✅ Liste avec pagination/tri/recherche
✅ Édition rapide (inline)
✅ Soft-delete / Hard-delete
✅ Historique actions
✅ Export CSV
✅ Actions batch
✅ Filtres avancés
✅ Statut utilisateur

// Filtres:
- Par statut (actif, suspendu, supprimé)
- Par rôle (vendeur, acheteur, admin)
- Par date d'inscription
- Par pays/ville
- Wallet > X FCFA
```

---

### 🖼️ **Image Moderation**

```typescript
// Queue de validation
✅ Images en attente
✅ Preview côte à côte
✅ Raison rejet (dropdown)
✅ IA analysis (OpenAI Vision)
✅ Détection nudité/violence
✅ Détection contenu illégal
✅ Stats modération
✅ Bulk approve/reject

// Statuts images:
- pending (attente)
- approved (validée)
- rejected (rejetée)
- flagged (suspecte)
- under_review (réexamen)
```

---

### 💰 **Wallet Management**

```typescript
// Features:
✅ Soldes en temps réel
✅ Historique transactions
✅ Ajustements manuels (avec raison)
✅ Blocage/déblocage wallet
✅ Export transactions
✅ Alertes anomalies
✅ Réconciliation
✅ Logs audit

// Actions admin:
- Ajouter solde
- Retirer solde
- Corriger erreur
- Bloquer wallet
- Débloquer wallet
```

---

### 📊 **Analytics Real-time**

```typescript
// Dashboards:
✅ Users: DAU, MAU, churn
✅ Revenue: total, par jour, par méthode
✅ Images: uploads/jour, taux rejet
✅ Transactions: volume, value, fee
✅ Geolocation: heat map
✅ Retention: cohorts
✅ Funnel: signup → first order

// Graphiques:
- Line charts (trends)
- Bar charts (comparaisons)
- Pie charts (répartition)
- Heat maps
- Funnels
```

---

### 🔔 **Notifications Real-time**

```typescript
// Features:
✅ Toast notifications
✅ Sound alerts
✅ Desktop notifications
✅ Email digests
✅ Webhooks events
✅ Custom templates
✅ Scheduling

// Events:
- Utilisateur créé
- Image rejetée
- Paiement échoué
- Fraude détectée
- Wallet modifié
- Compte suspendu
```

---

### 🔗 **Webhooks**

```typescript
// Management:
✅ Créer/éditer/supprimer
✅ Retry automatique
✅ Logs complets
✅ Test webhook
✅ Signing secrets
✅ Rate limiting

// Events:
POST /webhooks/events
- user.created
- user.deleted
- image.approved
- image.rejected
- payment.completed
- payment.failed
- wallet.adjusted
```

---

### ⚙️ **Settings Admin**

```typescript
// Rôles & Permissions:
✅ Super Admin: accès total
✅ Moderator: users + images
✅ Analyst: analytics seulement
✅ Support: users seulement

// Features:
✅ Créer rôles custom
✅ Permissions granulaires
✅ Sessions admin
✅ 2FA/MFA
✅ Audit logs
✅ IP whitelist
```

---

## 🤖 AI Image Moderation

### Intégration OpenAI Vision

```typescript
// lib/api/images.ts
async function analyzeImageWithAI(imageUrl: string) {
  const response = await openai.vision.analyze({
    image_url: imageUrl,
    questions: [
      "Contains nudity?",
      "Contains violence?",
      "Contains illegal content?",
      "Quality score (1-10)?",
    ],
  })
  
  return {
    nudity: response.nudity_score,
    violence: response.violence_score,
    illegal: response.illegal_score,
    quality: response.quality_score,
    recommendation: response.recommendation, // approve/reject/review
  }
}
```

---

## 🔄 Real-time Features

### Supabase Realtime

```typescript
// lib/hooks/useRealtime.ts
export function useRealtimeUsers() {
  const queryClient = useQueryClient()
  
  useEffect(() => {
    const channel = supabase
      .channel('users')
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: 'users' },
        (payload) => {
          queryClient.invalidateQueries({ queryKey: ['users'] })
          toast.success(`User ${payload.eventType}`)
        }
      )
      .subscribe()
    
    return () => {
      channel.unsubscribe()
    }
  }, [])
}
```

---

## 📈 Export & Rapports

```typescript
// Features:
✅ Export CSV (users, transactions)
✅ Export PDF (rapports)
✅ Scheduled reports
✅ Email delivery
✅ S3 archiving
✅ Retention policy
```

---

## 🚀 Déploiement

### Vercel

```bash
# 1. Créer compte Vercel
vercel login

# 2. Déployer
vercel --prod

# 3. Variables d'environnement
vercel env add NEXT_PUBLIC_SUPABASE_URL
vercel env add NEXT_PUBLIC_SUPABASE_ANON_KEY
vercel env add SUPABASE_SERVICE_ROLE_KEY
vercel env add NEXTAUTH_SECRET
vercel env add OPENAI_API_KEY
```

### URL Production
```
https://mygabon-admin.vercel.app
ou
https://admin.mygabon.com (avec domaine custom)
```

---

## 🔐 Security Checklist

- [ ] NextAuth CSRF protection
- [ ] Rate limiting API
- [ ] HTTPS only
- [ ] Audit logs pour toutes actions
- [ ] 2FA pour admin
- [ ] IP whitelist (optionnel)
- [ ] Supabase RLS policies
- [ ] Input validation (Zod)
- [ ] CORS configuration
- [ ] Helmet.js pour headers

---

## 📚 Prochaines étapes

1. **Setup local** (npm install, .env.local)
2. **Créer tables Supabase** (SQL scripts)
3. **Configurer NextAuth**
4. **Implémenter User Management** (CRUD)
5. **Ajouter Image Moderation**
6. **Configurer Analytics**
7. **Setup real-time** (Supabase)
8. **Tests & QA**
9. **Déployer sur Vercel**

---

## 📞 Support

Pour des questions:
- Docs Next.js: https://nextjs.org/docs
- Shadcn/ui: https://ui.shadcn.com
- Supabase: https://supabase.com/docs
- NextAuth: https://next-auth.js.org

