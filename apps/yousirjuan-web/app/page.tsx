'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useSession } from './session-provider';

export default function Index() {
  const { session } = useSession();
  const router = useRouter();

  useEffect(() => {
    router.replace(session ? '/home' : '/auth');
  }, [session, router]);

  return null;
}
