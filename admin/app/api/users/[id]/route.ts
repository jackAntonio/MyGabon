import { NextRequest, NextResponse } from 'next/server'
import { getServerSession } from 'next-auth/next'
import { authOptions } from '@/app/api/auth/[...nextauth]'
import { supabaseAdmin } from '@/lib/supabase'

interface RouteParams {
  params: {
    id: string
  }
}

export async function GET(request: NextRequest, { params }: RouteParams) {
  try {
    const session = await getServerSession(authOptions)
    if (!session) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    const { data, error } = await supabaseAdmin
      .from('users')
      .select('*')
      .eq('id', params.id)
      .single()

    if (error) throw error
    if (!data) {
      return NextResponse.json({ error: 'User not found' }, { status: 404 })
    }

    return NextResponse.json(data)
  } catch (error) {
    console.error('GET /api/users/[id] error:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}

export async function PUT(request: NextRequest, { params }: RouteParams) {
  try {
    const session = await getServerSession(authOptions)
    if (!session) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    const body = await request.json()

    // Get current user to track changes
    const { data: currentData } = await supabaseAdmin
      .from('users')
      .select('*')
      .eq('id', params.id)
      .single()

    // Update user
    const { data, error } = await supabaseAdmin
      .from('users')
      .update(body)
      .eq('id', params.id)
      .select()
      .single()

    if (error) throw error
    if (!data) {
      return NextResponse.json({ error: 'User not found' }, { status: 404 })
    }

    // Log audit
    const changes = Object.keys(body).reduce((acc: any, key) => {
      if (currentData[key] !== body[key]) {
        acc[key] = { from: currentData?.[key], to: body[key] }
      }
      return acc
    }, {})

    await supabaseAdmin.from('admin_audit_logs').insert({
      admin_id: (session.user as any).id,
      action: 'user_updated',
      resource_type: 'users',
      resource_id: params.id,
      changes,
    })

    return NextResponse.json(data)
  } catch (error) {
    console.error('PUT /api/users/[id] error:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}

export async function DELETE(request: NextRequest, { params }: RouteParams) {
  try {
    const session = await getServerSession(authOptions)
    if (!session) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    // Soft delete (set status to 'deleted')
    const { data, error } = await supabaseAdmin
      .from('users')
      .update({ status: 'deleted' })
      .eq('id', params.id)
      .select()
      .single()

    if (error) throw error
    if (!data) {
      return NextResponse.json({ error: 'User not found' }, { status: 404 })
    }

    // Log audit
    await supabaseAdmin.from('admin_audit_logs').insert({
      admin_id: (session.user as any).id,
      action: 'user_deleted',
      resource_type: 'users',
      resource_id: params.id,
    })

    return NextResponse.json({ message: 'User deleted successfully' })
  } catch (error) {
    console.error('DELETE /api/users/[id] error:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}
