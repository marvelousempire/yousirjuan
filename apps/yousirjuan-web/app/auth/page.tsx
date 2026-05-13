'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { motion, AnimatePresence } from 'framer-motion';
import { useSession } from '../session-provider';

type EnrolledFace = { faceId: string; userId: string };
type AuthMode = 'face' | 'passkey-flow';

export default function AuthPage() {
  const router = useRouter();
  const { signIn } = useSession();
  const [faces, setFaces] = useState<EnrolledFace[]>([]);
  const [recognizing, setRecognizing] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [authMode, setAuthMode] = useState<AuthMode>('face');
  const [passkeyDone, setPasskeyDone] = useState(false);
  const [supportsPasskey, setSupportsPasskey] = useState(false);

  useEffect(() => {
    setSupportsPasskey(typeof window !== 'undefined' && !!window.PublicKeyCredential);
  }, []);

  useEffect(() => {
    fetch('/api/identity/faces')
      .then((r) => r.json())
      .then((d) => setFaces(d.enrolled ?? []))
      .catch(() => setError('Could not reach the family registry.'));
  }, []);

  const pick = async (faceId: string) => {
    setRecognizing(faceId);
    setError(null);
    try {
      await new Promise((r) => setTimeout(r, 900));
      await signIn(faceId);
      router.replace('/home');
    } catch {
      setError('We could not place you. Try again.');
      setRecognizing(null);
    }
  };

  const handlePasskey = async () => {
    setError(null);
    try {
      const { challenge } = await fetch('/api/auth/webauthn/challenge').then((r) => r.json());
      const credential = await navigator.credentials.get({
        publicKey: {
          challenge: base64urlToBuffer(challenge),
          rpId: window.location.hostname,
          userVerification: 'preferred',
          timeout: 60_000,
        },
      });
      if (!credential) throw new Error('no_credential');
      // Passkey recognized — show face picker to map to a user
      setPasskeyDone(true);
      setAuthMode('passkey-flow');
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : String(e);
      if (msg !== 'AbortError') {
        setError('Passkey sign-in failed or was cancelled.');
      }
    }
  };

  const showFaceGrid = authMode === 'face' || passkeyDone;

  return (
    <main className="min-h-screen flex flex-col items-center justify-center p-8 text-center">
      <motion.div
        initial={{ opacity: 0, y: 12 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.6, ease: [0.22, 1, 0.36, 1] }}
        className="max-w-2xl w-full"
      >
        <p className="uppercase tracking-[0.3em] text-xs opacity-60 mb-4">You-Sir Juan</p>
        <h1 className="text-5xl md:text-6xl font-serif leading-tight mb-3">
          Step into your world.
        </h1>
        <p className="opacity-70 text-lg mb-12">
          {passkeyDone
            ? 'Passkey recognized. Select your profile to continue.'
            : 'Face recognition would normally identify you on contact. For this preview, choose who you are.'}
        </p>

        <AnimatePresence mode="wait">
          {showFaceGrid && (
            <motion.div
              key="face-grid"
              initial={{ opacity: 0, y: 8 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -8 }}
              transition={{ duration: 0.4 }}
              className="grid gap-4 md:grid-cols-2"
            >
              {faces.map((f) => {
                const isMe = recognizing === f.faceId;
                return (
                  <motion.button
                    key={f.faceId}
                    onClick={() => pick(f.faceId)}
                    disabled={!!recognizing}
                    whileHover={{ scale: recognizing ? 1 : 1.02 }}
                    whileTap={{ scale: 0.98 }}
                    className="relative rounded-2xl border border-white/15 bg-white/[0.04] backdrop-blur-sm p-6 text-left transition-colors hover:bg-white/[0.07] disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    <div className="text-xs uppercase tracking-widest opacity-50 mb-2">
                      {f.userId.replace('u_', '')}
                    </div>
                    <div className="text-2xl font-medium">
                      {labelForUser(f.userId)}
                    </div>
                    <AnimatePresence>
                      {isMe && (
                        <motion.div
                          initial={{ opacity: 0 }}
                          animate={{ opacity: 1 }}
                          exit={{ opacity: 0 }}
                          className="absolute inset-0 rounded-2xl flex items-center justify-center bg-black/30 backdrop-blur-sm"
                        >
                          <div className="flex items-center gap-3">
                            <Spinner />
                            <span className="text-sm opacity-90">Recognizing…</span>
                          </div>
                        </motion.div>
                      )}
                    </AnimatePresence>
                  </motion.button>
                );
              })}
            </motion.div>
          )}
        </AnimatePresence>

        {supportsPasskey && !passkeyDone && authMode === 'face' && (
          <motion.div
            initial={{ opacity: 0, y: 8 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5, delay: 0.3 }}
            className="mt-8"
          >
            <div className="flex items-center gap-4 mb-6">
              <div className="flex-1 h-px bg-white/10" />
              <span className="text-xs uppercase tracking-widest opacity-40">or</span>
              <div className="flex-1 h-px bg-white/10" />
            </div>
            <motion.button
              onClick={handlePasskey}
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.97 }}
              className="w-full rounded-2xl border border-white/20 bg-white/[0.05] backdrop-blur-sm px-6 py-4 flex items-center justify-center gap-3 hover:bg-white/[0.09] transition-colors"
            >
              <PasskeyIcon />
              <span className="text-base font-medium">Sign in with passkey</span>
            </motion.button>
          </motion.div>
        )}

        {error && (
          <p className="mt-8 text-sm text-red-300/80">{error}</p>
        )}
      </motion.div>
    </main>
  );
}

function labelForUser(userId: string): string {
  const map: Record<string, string> = {
    u_avery: 'Avery Goodman',
    u_bobby: 'Robert Bobby',
    u_nivram: 'NIVRAM',
    u_yousirjuan: 'Yousir Juan',
  };
  return map[userId] ?? userId;
}

function base64urlToBuffer(b64url: string): ArrayBuffer {
  const b64 = b64url.replace(/-/g, '+').replace(/_/g, '/');
  const binary = atob(b64);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) {
    bytes[i] = binary.charCodeAt(i);
  }
  return bytes.buffer;
}

function Spinner() {
  return (
    <motion.span
      className="inline-block w-4 h-4 rounded-full border-2 border-white/40 border-t-white"
      animate={{ rotate: 360 }}
      transition={{ duration: 0.9, repeat: Infinity, ease: 'linear' }}
    />
  );
}

function PasskeyIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M2 18v3c0 .6.4 1 1 1h4v-3h3v-3h2l1.4-1.4a6.5 6.5 0 1 0-4-4Z" />
      <circle cx="16.5" cy="7.5" r=".5" fill="currentColor" />
    </svg>
  );
}
