'use client';

import { useEffect, useRef, useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { motion, AnimatePresence } from 'framer-motion';
import { useSession } from '../session-provider';
import { paradigmIcon } from '../lib/paradigm-icons';

type Turn = { role: 'user' | 'agent'; text: string };

export default function VoicePage() {
  const router = useRouter();
  const { session, authFetch } = useSession();
  const [transcript, setTranscript] = useState<Turn[]>([]);
  const [listening, setListening] = useState(false);
  const [draft, setDraft] = useState('');
  const recognitionRef = useRef<{ start(): void; onresult: ((e: { results: { [i: number]: { [j: number]: { transcript: string } } } }) => void) | null; onend: (() => void) | null; continuous: boolean; interimResults: boolean; lang: string } | null>(null);

  useEffect(() => {
    if (!session) router.replace('/auth');
  }, [session, router]);

  // Wire Web Speech API if available.
  useEffect(() => {
    if (typeof window === 'undefined') return;
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const SR: (new () => typeof recognitionRef.current) | undefined = (window as any).SpeechRecognition ?? (window as any).webkitSpeechRecognition;
    if (!SR) return;
    const r = new SR();
    if (!r) return;
    r.continuous = false;
    r.interimResults = false;
    r.lang = 'en-US';
    r.onresult = (e) => {
      const text = e.results[0][0].transcript;
      setDraft(text);
    };
    r.onend = () => setListening(false);
    recognitionRef.current = r;
  }, []);

  if (!session) return null;
  const persona = session.persona;
  const labelSet = persona.paradigm.labelSet;
  const voiceIconName = paradigmIcon(labelSet, 'voice');

  const speak = (text: string) => {
    if (typeof window === 'undefined' || !window.speechSynthesis) return;
    const u = new SpeechSynthesisUtterance(text);
    u.rate = 1.0;
    u.pitch = persona.agent.voice.includes('deep') ? 0.85
            : persona.agent.voice.includes('youthful') ? 1.15
            : 1.0;
    window.speechSynthesis.speak(u);
  };

  const startListening = () => {
    const r = recognitionRef.current;
    if (!r) return;
    setListening(true);
    setDraft('');
    try { r.start(); } catch {}
  };

  const send = async (utterance: string) => {
    if (!utterance.trim()) return;
    setTranscript((t) => [...t, { role: 'user', text: utterance }]);
    setDraft('');

    const res = await authFetch('/api/voice/turn', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ userId: session.userId, utterance }),
    });
    const data = await res.json();
    setTranscript((t) => [...t, { role: 'agent', text: data.reply }]);
    speak(data.reply);
  };

  const hasMic = !!recognitionRef.current;

  return (
    <main className="min-h-screen p-8 md:p-12 flex flex-col">
      <header className="flex items-center justify-between mb-8">
        <Link href="/home" className="text-sm opacity-70 hover:opacity-100">← Back</Link>
        <p className="text-xs uppercase tracking-widest opacity-50">Talking to {persona.agent.name}</p>
      </header>

      <section className="flex-1 max-w-2xl mx-auto w-full flex flex-col gap-4">
        <AnimatePresence initial={false}>
          {transcript.map((turn, i) => (
            <motion.div
              key={i}
              initial={{ opacity: 0, y: 8 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.35 }}
              className={turn.role === 'user' ? 'self-end max-w-[80%]' : 'self-start max-w-[80%]'}
            >
              <p className="text-xs uppercase tracking-widest opacity-50 mb-1">
                {turn.role === 'user' ? persona.name : persona.agent.name}
              </p>
              <div
                className="rounded-2xl px-5 py-3 text-lg leading-snug"
                style={
                  turn.role === 'user'
                    ? { background: 'color-mix(in srgb, var(--accent) 18%, transparent)' }
                    : { background: 'rgba(255,255,255,0.06)' }
                }
              >
                {turn.text}
              </div>
            </motion.div>
          ))}
        </AnimatePresence>
      </section>

      <footer className="max-w-2xl mx-auto w-full mt-8">
        <div className="flex items-center gap-3">
          <motion.button
            onClick={startListening}
            disabled={!hasMic || listening}
            whileTap={{ scale: 0.95 }}
            className="w-14 h-14 rounded-full flex items-center justify-center border border-white/20 disabled:opacity-40"
            style={{ background: listening ? 'var(--accent)' : 'transparent' }}
            title={hasMic ? 'Speak' : 'Speech recognition not available in this browser'}
          >
            <VoiceIcon iconName={voiceIconName} listening={listening} />
          </motion.button>
          <input
            value={draft}
            onChange={(e) => setDraft(e.target.value)}
            onKeyDown={(e) => { if (e.key === 'Enter') send(draft); }}
            placeholder={hasMic ? 'Or type…' : 'Type to talk to your associate…'}
            className="flex-1 rounded-full px-5 py-3 bg-white/[0.05] border border-white/10 outline-none focus:border-white/30"
          />
          <button
            onClick={() => send(draft)}
            className="px-5 py-3 rounded-full text-sm"
            style={{ background: 'var(--accent)', color: '#fff' }}
          >
            Send
          </button>
        </div>
        {!hasMic && (
          <p className="text-xs opacity-50 mt-3">
            Your browser doesn't expose the Web Speech API. Typing still works — voice will return on iOS native.
          </p>
        )}
      </footer>
    </main>
  );
}

function VoiceIcon({ iconName, listening }: { iconName: string; listening: boolean }) {
  // Mic path — default fallback for paradigm-specific voice icons that are mic-shaped
  const defaultPaths = [
    'M12 2a3 3 0 0 0-3 3v7a3 3 0 0 0 6 0V5a3 3 0 0 0-3-3z',
    'M19 10v2a7 7 0 0 1-14 0v-2',
    'M12 19v3',
  ];
  // Use mic paths universally; the paradigmIcon name is for tile headers only here
  void iconName;
  return (
    <motion.svg
      width="20"
      height="20"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      animate={listening ? { scale: [1, 1.15, 1] } : { scale: 1 }}
      transition={{ duration: 1.2, repeat: listening ? Infinity : 0 }}
      aria-hidden
    >
      {defaultPaths.map((d, i) => <path key={i} d={d} />)}
    </motion.svg>
  );
}
