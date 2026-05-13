'use client';

import { createContext, useContext, useEffect, useState, useCallback } from 'react';

export type Paradigm = {
  palette: string;
  accent: string;
  background: string;
  foreground: string;
  layout: string;
  labelSet: string;
  typography: string;
  mood: string;
};

export type Agent = {
  name: string;
  voice: string;
  persona: string;
  avatar: string | null;
  greeting: string;
};

export type Persona = {
  userId: string;
  name: string;
  household: string;
  role: string;
  paradigm: Paradigm;
  agent: Agent;
};

export type Session = {
  sessionId: string;
  userId: string;
  persona: Persona;
  token?: string;
};

type Ctx = {
  session: Session | null;
  signIn: (faceId: string) => Promise<Session>;
  signOut: () => void;
  authFetch: (url: string, init?: RequestInit) => Promise<Response>;
};

const SessionContext = createContext<Ctx | null>(null);

export function SessionProvider({ children }: { children: React.ReactNode }) {
  const [session, setSession] = useState<Session | null>(null);

  // Restore session from sessionStorage (kiosk-friendly — clears on tab close).
  useEffect(() => {
    const raw = typeof window !== 'undefined' ? sessionStorage.getItem('ysj.session') : null;
    if (raw) {
      try {
        setSession(JSON.parse(raw));
      } catch {}
    }
  }, []);

  // Apply paradigm to CSS variables whenever session changes.
  useEffect(() => {
    if (!session) return;
    const p = session.persona.paradigm;
    document.documentElement.style.setProperty('--bg', p.background);
    document.documentElement.style.setProperty('--fg', p.foreground);
    document.documentElement.style.setProperty('--accent', p.accent);
  }, [session]);

  const signIn = useCallback(async (faceId: string) => {
    const res = await fetch('/api/session', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ faceId }),
    });
    if (!res.ok) throw new Error(`session_failed_${res.status}`);
    const s: Session = await res.json();
    setSession(s);
    sessionStorage.setItem('ysj.session', JSON.stringify(s));
    return s;
  }, []);

  const signOut = useCallback(() => {
    setSession(null);
    sessionStorage.removeItem('ysj.session');
    sessionStorage.removeItem('ysj.onboarded');
    document.documentElement.style.removeProperty('--bg');
    document.documentElement.style.removeProperty('--fg');
    document.documentElement.style.removeProperty('--accent');
  }, []);

  /** Authenticated fetch — attaches the Bearer token if available. */
  const authFetch = useCallback(async (url: string, init?: RequestInit): Promise<Response> => {
    const token = session?.token;
    const headers: Record<string, string> = {
      ...(init?.headers as Record<string, string> | undefined),
    };
    if (token) headers['Authorization'] = `Bearer ${token}`;
    return fetch(url, { ...init, headers });
  }, [session?.token]);

  return (
    <SessionContext.Provider value={{ session, signIn, signOut, authFetch }}>
      {children}
    </SessionContext.Provider>
  );
}

export function useSession() {
  const ctx = useContext(SessionContext);
  if (!ctx) throw new Error('useSession must be used inside SessionProvider');
  return ctx;
}
