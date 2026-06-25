# 🎯 MyGabon Admin Dashboard

Production-grade admin interface for MyGabon marketplace with user management, image moderation, wallet management, analytics, and real-time features.

## ⚡ Quick Start

```bash
# Install dependencies
npm install

# Setup environment
cp .env.example .env.local
# Edit .env.local with your credentials

# Start development server
npm run dev

# Visit http://localhost:3000/admin
```

## 📦 Features

### 👥 User Management
- User listing with pagination/search/filters
- Create/edit/delete users
- Soft-delete support
- User status management
- Audit logs
- Export to CSV
- Batch actions

### 🖼️ Image Moderation
- Real-time moderation queue
- AI-powered image analysis (OpenAI Vision)
- Approve/reject with reasons
- Nudity/violence/illegal content detection
- Quality scoring
- Bulk operations
- Moderation stats

### 💰 Wallet Management
- User wallet overview
- Transaction history
- Manual balance adjustments
- Wallet blocking/unblocking
- Anomaly detection
- Audit trail
- Reconciliation tools

### 📊 Analytics Dashboard
- Real-time KPIs (DAU, revenue, transactions)
- Interactive charts (Recharts)
- User retention analysis
- Revenue trends
- Geographic heat maps
- Custom date ranges
- PDF export

### 🔔 Real-time Notifications
- Toast notifications (Sonner)
- Sound alerts
- Desktop notifications
- Notification center
- Email digests
- Custom templates

### 🔗 Webhooks Management
- Create/edit/delete webhooks
- Webhook logging
- Retry mechanism
- Event testing
- Signing verification

### ⚙️ Settings & Security
- Role-based access control
- Admin roles (Super Admin, Moderator, Analyst)
- Custom permissions
- 2FA/MFA support
- Session management
- Audit logs
- IP whitelist

## 🛠 Tech Stack

- **Frontend:** Next.js 14 + TypeScript
- **UI:** Shadcn/ui + Tailwind CSS
- **State:** TanStack Query + Zustand
- **Auth:** NextAuth.js
- **Database:** Supabase (PostgreSQL)
- **Real-time:** Supabase Realtime
- **Charts:** Recharts
- **AI:** OpenAI Vision API
- **Deployment:** Vercel

## 📂 Project Structure

```
admin/
├── app/
│   ├── admin/              # Protected routes
│   │   ├── users/
│   │   ├── images/
│   │   ├── wallet/
│   │   ├── analytics/
│   │   ├── notifications/
│   │   ├── webhooks/
│   │   └── settings/
│   ├── auth/
│   │   └── login/
│   └── api/                # API routes
├── components/
│   ├── ui/                 # Shadcn components
│   ├── layout/
│   └── shared/
├── lib/
│   ├── api/                # API helpers
│   ├── hooks/              # Custom hooks
│   ├── store/              # Zustand stores
│   └── utils/
├── styles/
└── public/
```

## 🔐 Authentication

Admin users have roles:
- **Super Admin:** Full access
- **Moderator:** User + Image management
- **Analyst:** Analytics only
- **Support:** User support only

## 🚀 Deployment

Deploy to Vercel:

```bash
# Install Vercel CLI
npm i -g vercel

# Login and deploy
vercel login
vercel --prod

# Add environment variables
vercel env add NEXT_PUBLIC_SUPABASE_URL
vercel env add NEXT_PUBLIC_SUPABASE_ANON_KEY
vercel env add SUPABASE_SERVICE_ROLE_KEY
vercel env add NEXTAUTH_SECRET
vercel env add OPENAI_API_KEY
```

Production URL: `https://mygabon-admin.vercel.app`

## 📋 Setup Checklist

- [ ] Install dependencies: `npm install`
- [ ] Setup `.env.local`
- [ ] Create Supabase tables (SQL scripts in docs)
- [ ] Configure NextAuth
- [ ] Test authentication
- [ ] Create admin user
- [ ] Deploy to Vercel
- [ ] Setup custom domain

## 📚 Documentation

- [Setup Guide](../ADMIN_DASHBOARD_SETUP.md) - Detailed setup instructions
- [Implementation Plan](../ADMIN_IMPLEMENTATION_PLAN.md) - Phase-by-phase implementation guide
- [API Documentation](./API.md) - API endpoints reference

## 🐛 Common Issues

### Login not working
- Check `.env.local` has valid Supabase credentials
- Verify `dashboard_admins` table exists in Supabase
- Ensure NextAuth secret is set

### Images not loading
- Verify Supabase Storage bucket is public
- Check image URLs are accessible
- Validate CORS settings

### Real-time not updating
- Ensure Supabase Realtime is enabled
- Check subscription listeners
- Verify connection to Supabase

## 🔒 Security Best Practices

- Never commit `.env.local`
- Rotate secrets regularly
- Enable 2FA for all admins
- Use strong passwords
- Audit logs for all actions
- Rate limit API endpoints
- HTTPS only in production

## 📞 Support

For issues or questions:
- Check the [Implementation Plan](../ADMIN_IMPLEMENTATION_PLAN.md)
- Review [Setup Guide](../ADMIN_DASHBOARD_SETUP.md)
- Check Supabase docs: https://supabase.com/docs
- NextAuth docs: https://next-auth.js.org

## 📈 Performance

- Optimized image loading with next/image
- Server-side pagination
- Query caching with TanStack Query
- Incremental Static Regeneration (ISR)
- API route caching
- Database indexing

## 🤝 Contributing

1. Follow TypeScript best practices
2. Use Shadcn/ui components
3. Add proper error handling
4. Write meaningful commit messages
5. Test before deploying

## 📄 License

Same as MyGabon main project
