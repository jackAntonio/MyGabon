-- ============================================================
-- Centre de notifications in-app. Jusqu'ici, OneSignal poussait des
-- notifications système (nouveaux messages) mais rien n'en gardait la
-- trace côté app : impossible de consulter un historique, seulement
-- ce que l'OS a bien voulu garder dans le tiroir de notifications.
-- ============================================================

CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  type TEXT NOT NULL DEFAULT 'general',
  data JSONB DEFAULT '{}',
  read BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMP DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id, created_at DESC);

ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own notifications" ON notifications
  FOR SELECT USING (auth.uid() = user_id);
-- Permet de marquer comme lu (seul champ que le client a réellement
-- besoin de modifier sur sa propre ligne).
CREATE POLICY "Users can update own notifications" ON notifications
  FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
-- ⚠️ Volontairement aucune policy INSERT côté client : une notification
-- est toujours écrite par une Edge Function (service_role), jamais par
-- l'utilisateur lui-même — sinon n'importe qui pourrait fabriquer une
-- fausse notification "système" au nom d'un autre compte.
