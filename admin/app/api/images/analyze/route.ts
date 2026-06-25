import { NextRequest, NextResponse } from 'next/server'
import { requirePermission } from '@/lib/apiAuth'

export async function POST(request: NextRequest) {
  try {
    const { response } = await requirePermission('images:read')
    if (response) return response

    const body = await request.json()
    const { imageUrl } = body

    if (!imageUrl) {
      return NextResponse.json({ error: 'Image URL is required' }, { status: 400 })
    }

    // ⚠️ PLACEHOLDER NON FONCTIONNEL : scores générés aléatoirement, ne
    // reflètent aucune analyse réelle de l'image. Aucun fournisseur IA
    // (Google Vision API, AWS Rekognition, Azure Computer Vision...) n'est
    // branché. Ne JAMAIS utiliser ces scores pour auto-approuver une image :
    // l'approbation/rejet doit rester une décision humaine explicite via
    // /api/images/[id]/approve|reject tant qu'un vrai service n'est pas
    // intégré ici.
    const placeholderAnalysis = {
      mock: true,
      ai_nudity_score: Math.random() * 0.3,
      ai_violence_score: Math.random() * 0.2,
      ai_illegal_score: Math.random() * 0.15,
      ai_quality_score: 0.7 + Math.random() * 0.3,
      ai_recommendation: 'Analyse IA non implémentée — ces scores sont fictifs, revue humaine obligatoire.',
    }

    return NextResponse.json(placeholderAnalysis)
  } catch (error) {
    console.error('POST /api/images/analyze error:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}
