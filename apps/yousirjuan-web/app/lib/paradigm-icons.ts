export type IconKind = 'day' | 'tasks' | 'world' | 'signOut' | 'voice';

const iconMap: Record<string, Record<IconKind, string>> = {
  executive: { day: 'Calendar', tasks: 'FileText', world: 'Building', signOut: 'LogOut',          voice: 'Mic'       },
  warm:      { day: 'Sunrise',  tasks: 'CheckSquare', world: 'Home', signOut: 'Heart',            voice: 'Mic2'      },
  technical: { day: 'Terminal', tasks: 'Clipboard', world: 'Server', signOut: 'Power',            voice: 'Radio'     },
  sovereign: { day: 'Crown',    tasks: 'Scroll',    world: 'Globe',  signOut: 'ArrowLeftSquare',  voice: 'MicVocal'  },
  casual:    { day: 'Sun',      tasks: 'CheckCircle', world: 'Map',  signOut: 'LogOut',           voice: 'Mic'       },
};

export function paradigmIcon(labelSet: string, kind: IconKind): string {
  return iconMap[labelSet]?.[kind] ?? 'Circle';
}
