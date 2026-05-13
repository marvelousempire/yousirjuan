'use client';

import { useEffect, useRef, useState } from 'react';
import { useRouter } from 'next/navigation';
import { motion, AnimatePresence } from 'framer-motion';
import { useSession } from '../session-provider';

type Step = 1 | 2 | 3 | 4;

const VOICE_OPTIONS = [
  { id: 'deep_male_calm',        label: 'Deep & Calm',     sample: 'Ready to assist at any moment, with quiet authority.' },
  { id: 'warm_female_bright',    label: 'Warm & Bright',   sample: 'Here whenever you need me — let\'s make today great!' },
  { id: 'precise_neutral_tech',  label: 'Precise & Clear', sample: 'Systems are nominal. Your next task is ready to execute.' },
  { id: 'resonant_authority',    label: 'Resonant',        sample: 'The domain is prepared. I await your directive.' },
];

export default function OnboardPage() {
  const router = useRouter();
  const { session, authFetch } = useSession();

  const [step, setStep] = useState<Step>(1);
  const [preferredName, setPreferredName] = useState('');
  const [voice, setVoice] = useState('');
  const [lessons, setLessons] = useState(['', '', '']);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    if (!session) {
      router.replace('/auth');
    }
  }, [session, router]);

  if (!session) return null;

  const accentColor = session.persona.paradigm.accent;

  const speakSample = (text: string, voiceId: string) => {
    if (typeof window === 'undefined' || !window.speechSynthesis) return;
    window.speechSynthesis.cancel();
    const u = new SpeechSynthesisUtterance(text);
    u.rate = 1.0;
    u.pitch = voiceId.includes('deep') ? 0.85 : voiceId.includes('youthful') ? 1.15 : 1.0;
    window.speechSynthesis.speak(u);
  };

  const handleFinish = async () => {
    setSaving(true);
    try {
      await authFetch(`/api/memory/${session.userId}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ entry: { role: 'config', text: `preferred_name: ${preferredName.trim() || session.persona.name}` } }),
      });
      if (voice) {
        await authFetch(`/api/memory/${session.userId}`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ entry: { role: 'config', text: `voice_preference: ${voice}` } }),
        });
      }
      for (const lesson of lessons) {
        if (lesson.trim()) {
          await authFetch(`/api/memory/${session.userId}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ entry: { role: 'training', text: lesson.trim() } }),
          });
        }
      }
    } catch (_) {
      // memory writes are best-effort during onboarding
    } finally {
      setSaving(false);
      setStep(4);
    }
  };

  const handleComplete = () => {
    sessionStorage.setItem('ysj.onboarded', '1');
    router.replace('/home');
  };

  return (
    <main className="min-h-screen flex flex-col items-center justify-center p-8">
      <AnimatePresence mode="wait">
        {step === 1 && (
          <StepCard key="step1" accent={accentColor}>
            <StepLabel step={1} />
            <h2 className="text-4xl md:text-5xl font-serif mb-3 leading-tight">
              What should I call you?
            </h2>
            <p className="opacity-60 mb-8">
              I know your profile name is {session.persona.name}, but a preferred name feels more personal.
            </p>
            <input
              type="text"
              placeholder={session.persona.name}
              value={preferredName}
              onChange={(e) => setPreferredName(e.target.value)}
              className="w-full rounded-2xl px-5 py-4 bg-white/[0.07] border border-white/15 outline-none focus:border-white/40 text-xl mb-8"
              autoFocus
            />
            <NextButton accent={accentColor} onClick={() => setStep(2)}>
              Continue
            </NextButton>
          </StepCard>
        )}

        {step === 2 && (
          <StepCard key="step2" accent={accentColor}>
            <StepLabel step={2} />
            <h2 className="text-4xl md:text-5xl font-serif mb-3 leading-tight">
              Pick your associate's voice.
            </h2>
            <p className="opacity-60 mb-8">Hover to hear a sample.</p>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 mb-8 w-full">
              {VOICE_OPTIONS.map((v) => (
                <motion.button
                  key={v.id}
                  onMouseEnter={() => speakSample(v.sample, v.id)}
                  onFocus={() => speakSample(v.sample, v.id)}
                  onClick={() => setVoice(v.id)}
                  whileHover={{ scale: 1.03 }}
                  whileTap={{ scale: 0.97 }}
                  className="rounded-2xl border p-5 text-left transition-colors"
                  style={{
                    borderColor: voice === v.id ? accentColor : 'rgba(255,255,255,0.12)',
                    background: voice === v.id ? `color-mix(in srgb, ${accentColor} 12%, transparent)` : 'rgba(255,255,255,0.03)',
                  }}
                  aria-pressed={voice === v.id}
                >
                  <p className="font-medium text-base mb-1">{v.label}</p>
                  <p className="text-xs opacity-50 line-clamp-2">{v.sample}</p>
                </motion.button>
              ))}
            </div>
            <NextButton accent={accentColor} onClick={() => setStep(3)}>
              Continue
            </NextButton>
          </StepCard>
        )}

        {step === 3 && (
          <StepCard key="step3" accent={accentColor}>
            <StepLabel step={3} />
            <h2 className="text-4xl md:text-5xl font-serif mb-3 leading-tight">
              Teach me 3 things about your household.
            </h2>
            <p className="opacity-60 mb-8">
              Routines, preferences, people — anything that helps me serve you better.
            </p>
            <div className="flex flex-col gap-4 mb-8 w-full">
              {lessons.map((l, i) => (
                <input
                  key={i}
                  type="text"
                  placeholder={`Household fact ${i + 1}…`}
                  value={l}
                  onChange={(e) => {
                    const next = [...lessons];
                    next[i] = e.target.value;
                    setLessons(next);
                  }}
                  className="w-full rounded-2xl px-5 py-4 bg-white/[0.07] border border-white/15 outline-none focus:border-white/40 text-base"
                />
              ))}
            </div>
            <NextButton accent={accentColor} onClick={handleFinish} disabled={saving}>
              {saving ? 'Setting up…' : 'Finish setup'}
            </NextButton>
          </StepCard>
        )}

        {step === 4 && (
          <motion.div
            key="step4"
            initial={{ opacity: 0, scale: 0.88 }}
            animate={{ opacity: 1, scale: 1 }}
            exit={{ opacity: 0, scale: 1.06 }}
            transition={{ duration: 0.6, ease: [0.22, 1, 0.36, 1] }}
            className="text-center max-w-lg"
          >
            <motion.div
              initial={{ scale: 0 }}
              animate={{ scale: 1 }}
              transition={{ delay: 0.2, type: 'spring', stiffness: 260, damping: 18 }}
              className="w-24 h-24 rounded-full mx-auto mb-8 flex items-center justify-center text-4xl"
              style={{ background: `color-mix(in srgb, ${accentColor} 20%, transparent)`, border: `2px solid ${accentColor}` }}
            >
              ✓
            </motion.div>
            <motion.h2
              initial={{ opacity: 0, y: 12 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.35, duration: 0.5 }}
              className="text-5xl font-serif mb-4"
            >
              We're set.
            </motion.h2>
            <motion.p
              initial={{ opacity: 0, y: 8 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.5, duration: 0.5 }}
              className="opacity-60 text-lg mb-10"
            >
              {session.persona.agent.name} is ready to serve you,{' '}
              {preferredName.trim() || session.persona.name}.
            </motion.p>
            <motion.div
              initial={{ opacity: 0, y: 8 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.7, duration: 0.5 }}
            >
              <NextButton accent={accentColor} onClick={handleComplete}>
                Enter your world
              </NextButton>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Step dots */}
      {step < 4 && (
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          className="fixed bottom-10 flex gap-2"
        >
          {([1, 2, 3] as Step[]).map((n) => (
            <span
              key={n}
              className="w-2 h-2 rounded-full transition-colors"
              style={{ background: step >= n ? accentColor : 'rgba(255,255,255,0.25)' }}
            />
          ))}
        </motion.div>
      )}
    </main>
  );
}

function StepCard({ children, accent }: { children: React.ReactNode; accent: string }) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 16 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, y: -16 }}
      transition={{ duration: 0.45, ease: [0.22, 1, 0.36, 1] }}
      className="w-full max-w-lg flex flex-col"
      style={{ '--accent': accent } as React.CSSProperties}
    >
      {children}
    </motion.div>
  );
}

function StepLabel({ step }: { step: number }) {
  return (
    <p className="text-xs uppercase tracking-[0.3em] opacity-50 mb-6">
      Step {step} of 3
    </p>
  );
}

function NextButton({
  children,
  accent,
  onClick,
  disabled,
}: {
  children: React.ReactNode;
  accent: string;
  onClick: () => void;
  disabled?: boolean;
}) {
  return (
    <motion.button
      onClick={onClick}
      disabled={disabled}
      whileHover={{ scale: disabled ? 1 : 1.02 }}
      whileTap={{ scale: 0.97 }}
      className="w-full py-4 rounded-2xl text-base font-medium disabled:opacity-50"
      style={{ background: accent, color: '#fff' }}
    >
      {children}
    </motion.button>
  );
}
