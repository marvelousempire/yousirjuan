'use client';

import { useEffect } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { motion } from 'framer-motion';
import { useSession } from '../session-provider';
import { paradigmIcon, type IconKind } from '../lib/paradigm-icons';

// Per-paradigm label vocabularies — same data, different language.
const LABEL_SETS: Record<string, { day: string; tasks: string; world: string; signOut: string }> = {
  executive: { day: 'Today', tasks: 'Briefings', world: 'Operations', signOut: 'End session' },
  warm:      { day: 'Your day', tasks: 'On your list', world: 'Home', signOut: 'See you later' },
  casual:    { day: 'Right now', tasks: 'Stuff to do', world: 'World', signOut: 'Peace out' },
  technical: { day: 'Session', tasks: 'Queue', world: 'Runtime', signOut: 'End session' },
  sovereign: { day: 'Agenda', tasks: 'Directives', world: 'Domain', signOut: 'Adjourn' },
};

const LAYOUTS: Record<string, string> = {
  'executive-grid':   'grid grid-cols-1 md:grid-cols-3 gap-4',
  'soft-stack':       'flex flex-col gap-3',
  'playful-cards':    'grid grid-cols-2 md:grid-cols-2 gap-4',
  'developer-dense':  'grid grid-cols-1 md:grid-cols-3 gap-4',
  'command-center':   'grid grid-cols-1 md:grid-cols-3 gap-4',
};

export default function HomePage() {
  const router = useRouter();
  const { session, signOut } = useSession();

  useEffect(() => {
    if (!session) {
      router.replace('/auth');
      return;
    }
    // Elevation C: redirect to onboarding if the user hasn't completed it yet
    const onboarded = sessionStorage.getItem('ysj.onboarded');
    if (!onboarded) {
      router.replace('/onboard');
    }
  }, [session, router]);

  // Elevation D: SSE listener — re-apply CSS variables when paradigm changes on another device.
  // Token is passed as a query param because EventSource does not support custom headers.
  useEffect(() => {
    if (!session) return;
    const tokenParam = session.token ? `?token=${encodeURIComponent(session.token)}` : '';
    const es = new EventSource('/api/sync/' + session.userId + tokenParam);
    es.onmessage = (e) => {
      try {
        const data = JSON.parse(e.data);
        if (data.type === 'paradigm_updated' && data.paradigm) {
          const p = data.paradigm;
          if (p.background) document.documentElement.style.setProperty('--bg', p.background);
          if (p.foreground) document.documentElement.style.setProperty('--fg', p.foreground);
          if (p.accent)     document.documentElement.style.setProperty('--accent', p.accent);
        }
      } catch (_) {}
    };
    return () => es.close();
  }, [session?.userId]);

  if (!session) return null;

  const { persona } = session;
  const labelSet = persona.paradigm.labelSet;
  const labels = LABEL_SETS[labelSet] ?? LABEL_SETS.executive;
  const layoutClass = LAYOUTS[persona.paradigm.layout] ?? LAYOUTS['executive-grid'];

  return (
    <main className="min-h-screen p-8 md:p-12">
      <motion.header
        initial={{ opacity: 0, y: -8 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5 }}
        className="flex items-center justify-between mb-12"
      >
        <div>
          <p className="text-xs uppercase tracking-[0.3em] opacity-50">{persona.household}</p>
          <h1 className="text-4xl md:text-5xl mt-2" style={{ fontFamily: typographyFor(persona.paradigm.typography) }}>
            Hello, {persona.name}.
          </h1>
        </div>
        <div className="flex items-center gap-4">
          {/* Gap 10: Gear icon → paradigm settings */}
          <Link
            href="/settings"
            aria-label="Shape your world"
            className="w-9 h-9 flex items-center justify-center rounded-full border border-white/15 hover:bg-white/[0.07] transition-colors opacity-70 hover:opacity-100"
          >
            <GearIcon />
          </Link>
          <button
            onClick={() => { signOut(); router.replace('/auth'); }}
            className="text-sm opacity-70 hover:opacity-100 underline-offset-4 hover:underline"
          >
            {labels.signOut}
          </button>
        </div>
      </motion.header>

      <motion.section
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ duration: 0.7, delay: 0.1 }}
        className="mb-12 p-6 rounded-2xl border border-white/10"
        style={{ background: 'color-mix(in srgb, var(--accent) 12%, transparent)' }}
      >
        <p className="text-sm opacity-60 mb-2">{persona.agent.name} says</p>
        <p className="text-2xl md:text-3xl leading-snug">{persona.agent.greeting}</p>
      </motion.section>

      <div className={layoutClass}>
        <Tile labelSet={labelSet} kind="day"   title={labels.day}   body="Calm. Nothing demanding." />
        <Tile labelSet={labelSet} kind="tasks" title={labels.tasks} body="Your associate is keeping the list." />
        <Tile labelSet={labelSet} kind="world" title={labels.world} body="All household systems online." />
      </div>

      <motion.div
        initial={{ opacity: 0, y: 12 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5, delay: 0.3 }}
        className="fixed bottom-8 left-1/2 -translate-x-1/2"
      >
        <Link
          href="/voice"
          className="px-8 py-4 rounded-full border border-white/20 text-lg flex items-center gap-3"
          style={{ background: 'var(--accent)', color: '#fff' }}
        >
          <ParadigmIcon labelSet={labelSet} kind="voice" size={18} />
          Talk to {persona.agent.name}
        </Link>
      </motion.div>
    </main>
  );
}

function Tile({ labelSet, kind, title, body }: { labelSet: string; kind: IconKind; title: string; body: string }) {
  return (
    <motion.div
      whileHover={{ y: -4 }}
      transition={{ type: 'spring', stiffness: 280, damping: 22 }}
      className="rounded-2xl border border-white/10 bg-white/[0.03] p-6"
    >
      <div className="flex items-center gap-2 mb-3">
        <ParadigmIcon labelSet={labelSet} kind={kind} size={14} />
        <p className="text-xs uppercase tracking-widest opacity-60">{title}</p>
      </div>
      <p className="text-lg leading-snug opacity-90">{body}</p>
    </motion.div>
  );
}

/** Renders a paradigm-appropriate SVG icon inline using a simple lookup. */
function ParadigmIcon({ labelSet, kind, size }: { labelSet: string; kind: IconKind; size: number }) {
  const iconName = paradigmIcon(labelSet, kind);
  return <InlineIcon name={iconName} size={size} />;
}

/** Minimal SVG icon renderer for a curated subset of Lucide-compatible paths. */
function InlineIcon({ name, size }: { name: string; size: number }) {
  const paths = ICON_PATHS[name] ?? ICON_PATHS['Circle'];
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden
    >
      {paths.map((d, i) => (
        <path key={i} d={d} />
      ))}
    </svg>
  );
}

// Subset of Lucide icon path data used by this app
const ICON_PATHS: Record<string, string[]> = {
  Calendar:        ['M8 2v4','M16 2v4','M3 10h18','M3 6a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V6z'],
  FileText:        ['M15 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7z','M14 2v4a2 2 0 0 0 2 2h4','M10 9H8','M16 13H8','M16 17H8'],
  Building:        ['M6 22V4a2 2 0 0 1 2-2h8a2 2 0 0 1 2 2v18','M6 12H4a2 2 0 0 0-2 2v6a2 2 0 0 0 2 2h2','M18 9h2a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2h-2','M10 6h4','M10 10h4','M10 14h4','M10 18h4'],
  LogOut:          ['M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4','M16 17l5-5-5-5','M21 12H9'],
  Mic:             ['M12 2a3 3 0 0 0-3 3v7a3 3 0 0 0 6 0V5a3 3 0 0 0-3-3z','M19 10v2a7 7 0 0 1-14 0v-2','M12 19v3'],
  Sunrise:         ['M12 2v8','M4.93 10.93l1.41 1.41','M2 18h2','M20 18h2','M19.07 10.93l-1.41 1.41','M22 22H2','M8 6l4-4 4 4','M16 18a4 4 0 0 0-8 0'],
  CheckSquare:     ['M9 11l3 3L22 4','M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11'],
  Home:            ['M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z','M9 22V12h6v10'],
  Heart:           ['M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z'],
  Mic2:            ['M12 2a3 3 0 0 0-3 3v7a3 3 0 0 0 6 0V5a3 3 0 0 0-3-3z','M19 10v2a7 7 0 0 1-14 0v-2','M12 19v3','M8 23h8'],
  Terminal:        ['M4 17l6-6-6-6','M12 19h8'],
  Clipboard:       ['M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2','M15 2H9a1 1 0 0 0-1 1v2a1 1 0 0 0 1 1h6a1 1 0 0 0 1-1V3a1 1 0 0 0-1-1z'],
  Server:          ['M2 9a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v6a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V9z','M6 12h.01','M2 3a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v4a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V3z','M6 6h.01'],
  Power:           ['M18.36 6.64a9 9 0 1 1-12.73 0','M12 2v10'],
  Radio:           ['M4.9 19.1C1 15.2 1 8.8 4.9 4.9','M7.8 16.2c-2.3-2.3-2.3-6.1 0-8.5','M19.1 4.9C23 8.8 23 15.2 19.1 19.1','M16.2 7.8c2.3 2.3 2.3 6.1 0 8.5','M12 12a1 1 0 1 0 0-2 1 1 0 0 0 0 2z'],
  Crown:           ['M2 20h20','M5 20V8l7-6 7 6v12','M12 8v4','M9 20v-6a3 3 0 0 1 6 0v6'],
  Scroll:          ['M8 21h12a2 2 0 0 0 2-2v-2H10v2a2 2 0 1 1-4 0V5a2 2 0 1 0-4 0v3h4','M12 4H6','M12 8H6','M12 12H6'],
  Globe:           ['M12 2a10 10 0 1 0 0 20 10 10 0 0 0 0-20z','M2 12h20','M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z'],
  ArrowLeftSquare: ['M3 5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5z','M15 12H9','M12 9l-3 3 3 3'],
  MicVocal:        ['M12 2a3 3 0 0 0-3 3v7a3 3 0 0 0 6 0V5a3 3 0 0 0-3-3z','M19 10v2a7 7 0 0 1-14 0v-2','M12 19v3','M8 23h8','M6 19l-1-2','M18 19l1-2'],
  Sun:             ['M12 8a4 4 0 1 0 0 8 4 4 0 0 0 0-8z','M12 2v2','M12 20v2','M4.93 4.93l1.41 1.41','M17.66 17.66l1.41 1.41','M2 12h2','M20 12h2','M6.34 17.66l-1.41 1.41','M19.07 4.93l-1.41 1.41'],
  CheckCircle:     ['M22 11.08V12a10 10 0 1 1-5.93-9.14','M9 11l3 3L22 4'],
  Map:             ['M1 6v16l7-4 8 4 7-4V2l-7 4-8-4-7 4z','M8 2v16','M16 6v16'],
  Circle:          ['M12 2a10 10 0 1 0 0 20 10 10 0 0 0 0-20z'],
  Settings:        ['M12 20a8 8 0 1 0 0-16 8 8 0 0 0 0 16z','M12 14a2 2 0 1 0 0-4 2 2 0 0 0 0 4z'],
};

function typographyFor(token: string) {
  switch (token) {
    case 'serif-strong':       return 'var(--font-serif)';
    case 'humanist-rounded':   return 'var(--font-sans)';
    case 'geometric-bold':     return 'var(--font-sans)';
    case 'monospace-sharp':    return 'monospace';
    case 'display-bold':       return 'var(--font-serif)';
    default:                   return 'var(--font-sans)';
  }
}

function GearIcon() {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden>
      <path d="M12 15a3 3 0 1 0 0-6 3 3 0 0 0 0 6z" />
      <path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83-2.83l.06-.06A1.65 1.65 0 0 0 4.68 15a1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 2.83-2.83l.06.06A1.65 1.65 0 0 0 9 4.68a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 2.83l-.06.06A1.65 1.65 0 0 0 19.4 9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z" />
    </svg>
  );
}
