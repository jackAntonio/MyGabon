import { NextRequest, NextResponse } from 'next/server'
import { requirePermission } from '@/lib/apiAuth'

const GOOGLE_VISION_API_KEY = process.env.GOOGLE_VISION_API_KEY ?? ''

const LIKELIHOOD_SCORES: Record<string, number> = {
  UNKNOWN: 0.5,
  VERY_UNLIKELY: 0.1,
  UNLIKELY: 0.3,
  POSSIBLE: 0.5,
  LIKELY: 0.7,
  VERY_LIKELY: 0.9,
}

interface SafeSearchAnnotation {
  adult?: string
  violence?: string
  racy?: string
}

// ✅ Google Cloud Vision SafeSearch — actif uniquement si GOOGLE_VISION_API_KEY
// est configurée (`vercel env add GOOGLE_VISION_API_KEY` ou équivalent).
// Vision ne fournit ni catégorie "contenu illégal" ni score de qualité
// dédiés : ai_illegal_score utilise `racy` comme proxy le plus proche
// (à affiner si un vrai classifieur de contenu illégal est ajouté plus
// tard) et ai_quality_score reste neutre (1) — non évalué par ce
// fournisseur. Dans tous les cas, l'approbation/rejet reste une décision
// humaine explicite via /api/images/[id]/approve|reject : ces scores ne
// servent qu'à prioriser la revue, jamais à auto-approuver.
async function analyzeWithGoogleVision(imageUrl: string) {
  const res = await fetch(
    `https://vision.googleapis.com/v1/images:annotate?key=${GOOGLE_VISION_API_KEY}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        requests: [
          {
            image: { source: { imageUri: imageUrl } },
            features: [{ type: 'SAFE_SEARCH_DETECTION' }],
          },
        ],
      }),
    }
  )

  if (!res.ok) {
    throw new Error(`Google Vision API error: ${res.status}`)
  }

  const data = await res.json()
  const annotation: SafeSearchAnnotation = data.responses?.[0]?.safeSearchAnnotation ?? {}

  const score = (likelihood?: string) => LIKELIHOOD_SCORES[likelihood ?? 'UNKNOWN'] ?? 0.5

  return {
    mock: false,
    ai_nudity_score: score(annotation.adult),
    ai_violence_score: score(annotation.violence),
    ai_illegal_score: score(annotation.racy),
    ai_quality_score: 1,
    ai_recommendation:
      'Analyse Google Vision SafeSearch — revue humaine toujours requise avant approbation/rejet.',
  }
}

function placeholderAnalysis() {
  // ⚠️ PLACEHOLDER NON FONCTIONNEL : scores générés aléatoirement, ne
  // reflètent aucune analyse réelle de l'image. Actif tant que
  // GOOGLE_VISION_API_KEY n'est pas configurée. Ne JAMAIS utiliser ces
  // scores pour auto-approuver une image.
  return {
    mock: true,
    ai_nudity_score: Math.random() * 0.3,
    ai_violence_score: Math.random() * 0.2,
    ai_illegal_score: Math.random() * 0.15,
    ai_quality_score: 0.7 + Math.random() * 0.3,
    ai_recommendation: 'Analyse IA non implémentée — ces scores sont fictifs, revue humaine obligatoire.',
  }
}

export async function POST(request: NextRequest) {
  try {
    const { response } = await requirePermission('images:read')
    if (response) return response

    const body = await request.json()
    const { imageUrl } = body

    if (!imageUrl) {
      return NextResponse.json({ error: 'Image URL is required' }, { status: 400 })
    }

    if (!GOOGLE_VISION_API_KEY) {
      return NextResponse.json(placeholderAnalysis())
    }

    try {
      const analysis = await analyzeWithGoogleVision(imageUrl)
      return NextResponse.json(analysis)
    } catch (visionError) {
      console.error('Google Vision analysis failed, falling back to placeholder:', visionError)
      return NextResponse.json(placeholderAnalysis())
    }
  } catch (error) {
    console.error('POST /api/images/analyze error:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}
