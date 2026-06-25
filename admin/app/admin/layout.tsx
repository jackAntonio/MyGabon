'use client'

import { ReactNode } from 'react'
import Link from 'next/link'
import { useRouter, usePathname } from 'next/navigation'
import { signOut, useSession } from 'next-auth/react'
import {
  LayoutDashboard,
  Users,
  ImageIcon,
  Wallet,
  BarChart3,
  LogOut,
  Menu,
  X,
  ChevronDown,
} from 'lucide-react'
import { useState } from 'react'

interface AdminLayoutProps {
  children: ReactNode
}

export default function AdminLayout({ children }: AdminLayoutProps) {
  const router = useRouter()
  const pathname = usePathname()
  const { data: session, status } = useSession()
  const [sidebarOpen, setSidebarOpen] = useState(true)
  const [userMenuOpen, setUserMenuOpen] = useState(false)

  if (status === 'loading') {
    return (
      <div className="flex items-center justify-center min-h-screen bg-gray-50">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
      </div>
    )
  }

  if (status === 'unauthenticated') {
    router.push('/auth/login')
    return null
  }

  const menuItems = [
    {
      label: 'Dashboard',
      href: '/admin',
      icon: LayoutDashboard,
      exact: true,
    },
    {
      label: 'Utilisateurs',
      href: '/admin/users',
      icon: Users,
    },
    {
      label: 'Modération Images',
      href: '/admin/images',
      icon: ImageIcon,
    },
    {
      label: 'Portefeuille',
      href: '/admin/wallet',
      icon: Wallet,
    },
    {
      label: 'Analytiques',
      href: '/admin/analytics',
      icon: BarChart3,
    },
  ]

  const isActive = (href: string, exact = false) => {
    if (exact) return pathname === href
    return pathname.startsWith(href)
  }

  return (
    <div className="flex h-screen bg-gray-50">
      {/* Sidebar */}
      <aside
        className={`bg-white border-r border-gray-200 transition-all duration-300 ${
          sidebarOpen ? 'w-64' : 'w-20'
        }`}
      >
        <div className="flex flex-col h-full">
          {/* Logo */}
          <div className="flex items-center justify-between h-16 px-4 border-b border-gray-200">
            {sidebarOpen && (
              <Link href="/admin" className="flex items-center gap-2 font-bold text-lg text-primary">
                <span className="text-2xl">🎯</span>
                <span>MyGabon</span>
              </Link>
            )}
            <button
              onClick={() => setSidebarOpen(!sidebarOpen)}
              className="p-1 hover:bg-gray-100 rounded"
            >
              {sidebarOpen ? <X size={20} /> : <Menu size={20} />}
            </button>
          </div>

          {/* Menu Items */}
          <nav className="flex-1 px-3 py-6 space-y-2 overflow-y-auto">
            {menuItems.map((item) => {
              const Icon = item.icon
              const active = isActive(item.href, item.exact)

              return (
                <Link
                  key={item.href}
                  href={item.href}
                  className={`flex items-center gap-3 px-3 py-2 rounded-lg transition-colors ${
                    active
                      ? 'bg-primary/10 text-primary font-medium'
                      : 'text-gray-600 hover:bg-gray-100'
                  }`}
                  title={!sidebarOpen ? item.label : undefined}
                >
                  <Icon size={20} className="flex-shrink-0" />
                  {sidebarOpen && <span>{item.label}</span>}
                </Link>
              )
            })}
          </nav>

          {/* User Section */}
          <div className="border-t border-gray-200 p-3">
            <div className="relative">
              <button
                onClick={() => setUserMenuOpen(!userMenuOpen)}
                className="w-full flex items-center justify-between gap-2 px-3 py-2 hover:bg-gray-100 rounded-lg text-sm"
              >
                <div className="flex items-center gap-2 min-w-0">
                  <div className="w-8 h-8 bg-primary/20 rounded-full flex items-center justify-center flex-shrink-0">
                    <span className="text-xs font-bold text-primary">
                      {session?.user?.email?.[0]?.toUpperCase()}
                    </span>
                  </div>
                  {sidebarOpen && (
                    <div className="text-left min-w-0 truncate">
                      <p className="font-medium truncate text-gray-900">
                        {session?.user?.name || 'Admin'}
                      </p>
                      <p className="text-xs text-gray-500 truncate">{(session?.user as any)?.role}</p>
                    </div>
                  )}
                </div>
                {sidebarOpen && <ChevronDown size={16} />}
              </button>

              {userMenuOpen && sidebarOpen && (
                <div className="absolute bottom-full left-0 right-0 bg-white border border-gray-200 rounded-lg shadow-lg mb-2">
                  <button
                    onClick={() => signOut({ redirect: true, callbackUrl: '/auth/login' })}
                    className="w-full flex items-center gap-2 px-3 py-2 text-red-600 hover:bg-red-50 rounded-lg text-sm"
                  >
                    <LogOut size={16} />
                    Déconnexion
                  </button>
                </div>
              )}
            </div>
          </div>
        </div>
      </aside>

      {/* Main Content */}
      <div className="flex-1 flex flex-col overflow-hidden">
        {/* Top Bar */}
        <header className="h-16 bg-white border-b border-gray-200 flex items-center justify-between px-8">
          <div>
            <h1 className="text-2xl font-bold text-gray-900">Dashboard Admin</h1>
          </div>
          <div className="flex items-center gap-4">
            <span className="text-sm text-gray-600">{session?.user?.email}</span>
          </div>
        </header>

        {/* Page Content */}
        <main className="flex-1 overflow-auto">
          <div className="p-8">{children}</div>
        </main>
      </div>
    </div>
  )
}
