'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { motion } from 'framer-motion';
import { useSession } from '../session-provider';

const ACCENT_SWATCHES = [
  { label: 'Violet',  value: '#7C5CFF' },
  { label: 'Ember',   value: '#FF6B35' },
  { label: 'Jade',    value: '#00FF88' },
];

const MOOD_OPTIONS = [
  { label: 'Focused',   value: 'focused' },
  { label: 'Warm',      value: 'warm'    },
  { label: 'Energised', value: 'energised' },
];

export default function SettingsPage() {
  const router = useRouter();
  const { session, authFetch } = useSession();

  const [accent, setAccent] = useState('');
  const [mood, setMood] = useState('');
  const [saving, setSaving] = useState(false);
  const [saved, setSaved] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!session) {
      router.replace('/auth');
      return;
    }
    setAccent(session.persona.paradigm.accent);
    setMood(session.persona.paradigm.mood);
  }, [session, router]);

  if (!session) return null;

  const handleSave = async () => {
    setSaving(true);
    setError(null);
    setSaved(false);
    try {
      const res = await authFetch(`/api/personas/${session.userId}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ paradigm: { accent, mood } }),
      });
      if (!res.ok) throw new Error(`save_failed_${res.status}`);
      // Apply immediately to CSS variables
      document.documentElement.style.setProperty('--accent', accent);
      setSaved(true);
      setTimeout(() => setSaved(false), 2500);
    } catch {
      setError('Could not save. Please try again.');
    } finally {
      setSaving(false);
    }
  };

  return (
    <main className="min-h-screen p-8 md:p-12 max-w-lg mx-auto">
      <motion.header
        initial={{ opacity: 0, y: -8 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5 }}
        className="flex items-center justify-between mb-12"
      >
        <Link href="/home" className="text-sm opacity-70 hover:opacity-100">
          ← Back
        </Link>
        <p className="text-xs uppercase tracking-[0.3em] opacity-50">Shape your world</p>
      </motion.header>

      <motion.section
        initial={{ opacity: 0, y: 8 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5, delay: 0.1 }}
        className="mb-10"
      >
        <h2 className="text-sm uppercase tracking-widest opacity-60 mb-5">Accent colour</h2>
        <div className="flex gap-4">
          {ACCENT_SWATCHES.map((s) => {
            const isActive = accent === s.value;
            return (
              <motion.button
                key={s.value}
                onClick={() => setAccent(s.value)}
                whileHover={{ scale: 1.08 }}
                whileTap={{ scale: 0.94 }}
                animate={{ scale: isActive ? 1.12 : 1 }}
                transition={{ type: 'spring', stiffness: 380, damping: 22 }}
                className="relative flex flex-col items-center gap-2"
                aria-pressed={isActive}
                aria-label={s.label}
              >
                <span
                  className="w-12 h-12 rounded-full border-2 transition-all"
                  style={{
                    background: s.value,
                    borderColor: isActive ? '#fff' : 'transparent',
                    boxShadow: isActive ? `0 0 0 3px ${s.value}55` : 'none',
                  }}
                />
                <span className="text-xs opacity-60">{s.label}</span>
              </motion.button>
            );
          })}
        </div>
      </motion.section>

      <motion.section
        initial={{ opacity: 0, y: 8 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5, delay: 0.2 }}
        className="mb-10"
      >
        <h2 className="text-sm uppercase tracking-widest opacity-60 mb-5">Mood</h2>
        <div className="flex flex-col gap-3">
          {MOOD_OPTIONS.map((m) => {
            const isActive = mood === m.value;
            return (
              <motion.button
                key={m.value}
                onClick={() => setMood(m.value)}
                whileHover={{ x: 4 }}
                whileTap={{ scale: 0.98 }}
                className="flex items-center gap-4 rounded-xl border px-5 py-4 text-left transition-colors"
                style={{
                  borderColor: isActive ? accent : 'rgba(255,255,255,0.12)',
                  background: isActive ? `color-mix(in srgb, ${accent} 10%, transparent)` : 'transparent',
                }}
                aria-pressed={isActive}
              >
                <span
                  className="w-2.5 h-2.5 rounded-full flex-shrink-0 transition-colors"
                  style={{ background: isActive ? accent : 'rgba(255,255,255,0.25)' }}
                />
                <span className="text-base capitalize">{m.label}</span>
              </motion.button>
            );
          })}
        </div>
      </motion.section>

      <motion.div
        initial={{ opacity: 0, y: 8 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5, delay: 0.3 }}
        className="flex flex-col gap-3"
      >
        <motion.button
          onClick={handleSave}
          disabled={saving}
          whileHover={{ scale: saving ? 1 : 1.02 }}
          whileTap={{ scale: 0.97 }}
          className="w-full py-4 rounded-2xl text-base font-medium disabled:opacity-50 transition-colors"
          style={{ background: accent, color: '#fff' }}
        >
          {saving ? 'Saving…' : saved ? 'Saved.' : 'Save changes'}
        </motion.button>

        {error && <p className="text-sm text-red-300/80 text-center">{error}</p>}
      </motion.div>
    </main>
  );
}
