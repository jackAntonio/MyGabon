# MyGabon Admin Dashboard - Deployment Guide

Complete guide to deploy the admin dashboard to production.

## Prerequisites

- GitHub account with the repository
- Vercel account (free tier available)
- Supabase project created
- Database tables initialized (from SQL_SETUP.sql)

## Step 1: Prepare Supabase

### 1.1 Create Project
1. Go to [supabase.com](https://supabase.com)
2. Sign in or create account
3. Click "New Project"
4. Choose organization and name
5. Set password and region
6. Wait for project to initialize

### 1.2 Initialize Database
1. Open SQL Editor in Supabase console
2. Paste content from `SQL_SETUP.sql`
3. Click "Run" to execute
4. Verify tables are created

### 1.3 Get Credentials
1. Go to "Settings" > "API"
2. Copy:
   - Project URL → `NEXT_PUBLIC_SUPABASE_URL`
   - Anon Public Key → `NEXT_PUBLIC_SUPABASE_ANON_KEY`
   - Service Role Secret → `SUPABASE_SERVICE_ROLE_KEY`

## Step 2: Prepare Code

### 2.1 Create Environment File
```bash
cd admin
cp .env.example .env.local
```

### 2.2 Fill Environment Variables
```
# .env.local
NEXT_PUBLIC_SUPABASE_URL=https://[project-id].supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJ...
SUPABASE_SERVICE_ROLE_KEY=eyJ...
NEXTAUTH_SECRET=your-secret-key-min-32-chars
NEXTAUTH_URL=http://localhost:3000
DATABASE_URL=postgresql://[user]:[password]@[host]:5432/postgres
```

### 2.3 Generate NEXTAUTH_SECRET
```bash
openssl rand -base64 32
# Copy output to NEXTAUTH_SECRET
```

### 2.4 Test Locally
```bash
npm install
npm run dev
# Visit http://localhost:3000/auth/login
# Login: admin@mygabon.com / admin123
```

## Step 3: Deploy to Vercel

### 3.1 Push to GitHub
```bash
# From project root
git add -A
git commit -m "feat: Ready for production deployment"
git push origin master
```

### 3.2 Create Vercel Account
1. Go to [vercel.com](https://vercel.com)
2. Sign up with GitHub account
3. Authorize Vercel to access repositories

### 3.3 Import Project
1. Click "New Project"
2. Select GitHub organization
3. Search for "MyGabon"
4. Click "Import"
5. Configure project:
   - Framework: Next.js
   - Root Directory: `admin`
   - Build Command: `npm run build`
   - Install Command: `npm install`

### 3.4 Add Environment Variables
In Vercel dashboard, go to "Settings" > "Environment Variables"

Add all variables from .env.local:
```
NEXT_PUBLIC_SUPABASE_URL
NEXT_PUBLIC_SUPABASE_ANON_KEY
SUPABASE_SERVICE_ROLE_KEY
NEXTAUTH_SECRET
NEXTAUTH_URL (use production URL)
DATABASE_URL
```

**Important**: For `NEXTAUTH_URL`, use:
```
https://mygabon-admin.vercel.app
```

### 3.5 Deploy
1. Click "Deploy"
2. Wait for build to complete
3. Visit production URL
4. Test login functionality

## Step 4: Post-Deployment

### 4.1 Verify Features
- [ ] Login page loads
- [ ] Demo account works
- [ ] Dashboard displays
- [ ] User list loads
- [ ] Image queue works
- [ ] Database queries succeed

### 4.2 Setup Monitoring
1. Enable Vercel Analytics
2. Setup error tracking (Sentry recommended)
3. Configure logging

### 4.3 Database Backup
```bash
# Supabase automatically backs up
# But setup manual backups
# Settings > Backup > Enable automated backups
```

### 4.4 Security Checklist
- [ ] Change default admin password
- [ ] Enable 2FA (if supported)
- [ ] Review RLS policies
- [ ] Setup API rate limiting
- [ ] Configure CORS properly
- [ ] Enable HTTPS only
- [ ] Setup firewall rules

## Environment Variables Reference

### Required (Production)
```
NEXT_PUBLIC_SUPABASE_URL=https://[project-id].supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJ...
SUPABASE_SERVICE_ROLE_KEY=eyJ...
NEXTAUTH_SECRET=your-secret
NEXTAUTH_URL=https://mygabon-admin.vercel.app
```

### Optional
```
DATABASE_URL=postgresql://...
MYGABON_API_KEY=...
AIRTEL_MONEY_API_KEY=...
```

## Deployment Checklist

### Pre-Deployment
- [ ] All tests pass locally
- [ ] No console errors
- [ ] Environment variables configured
- [ ] Database schema initialized
- [ ] Default admin user created
- [ ] Code committed to main branch

### During Deployment
- [ ] Build succeeds
- [ ] All functions deployed
- [ ] Environment variables set
- [ ] Database connection works
- [ ] Images load correctly

### Post-Deployment
- [ ] Application loads
- [ ] Login works
- [ ] Dashboard displays data
- [ ] All pages accessible
- [ ] API routes respond
- [ ] Audit logs are recorded

## Troubleshooting

### Build Fails
```bash
# Check build logs in Vercel
# Common issues:
# 1. Missing environment variables
# 2. TypeScript errors
# 3. Module not found

# Fix locally first
npm run build
npm run type-check
```

### Login Not Working
1. Verify `NEXTAUTH_SECRET` is set
2. Check Supabase credentials
3. Ensure `NEXTAUTH_URL` matches domain
4. Check database connection

### Database Connection Error
1. Verify `SUPABASE_SERVICE_ROLE_KEY`
2. Check `DATABASE_URL` format
3. Verify Supabase project status
4. Check IP whitelist settings

### Images Not Loading
1. Verify Supabase Storage bucket exists
2. Check CORS settings in Supabase
3. Verify image URLs are accessible
4. Check browser console for errors

### Performance Issues
1. Enable query caching
2. Setup CDN for images
3. Optimize database indexes
4. Monitor Vercel Analytics
5. Check slow API endpoints

## Scaling

### Database
- Monitor connections
- Setup read replicas if needed
- Optimize slow queries
- Enable WAL (Write-Ahead Logging)

### API
- Setup rate limiting
- Cache responses
- Monitor quota usage
- Scale horizontally with Vercel

### Images
- Use Supabase Storage CDN
- Compress images
- Setup image processing
- Cache aggressively

## Maintenance

### Regular Tasks
- [ ] Review audit logs weekly
- [ ] Check error reports daily
- [ ] Monitor performance metrics
- [ ] Update dependencies monthly
- [ ] Rotate secrets quarterly
- [ ] Review security policies monthly

### Backup Strategy
- Supabase automated backups (enabled)
- Manual backups weekly
- Test restore procedures monthly

### Updates
- Keep Next.js updated
- Update dependencies regularly
- Review security advisories
- Test before deploying

## Support & Resources

- [Vercel Docs](https://vercel.com/docs)
- [Supabase Docs](https://supabase.com/docs)
- [Next.js Docs](https://nextjs.org/docs)
- [NextAuth.js Docs](https://next-auth.js.org)

## Contact

For deployment issues or questions:
- Check deployment logs
- Review environment variables
- Test database connection
- Check API responses
