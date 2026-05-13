import { test, expect } from '@playwright/test';

const MOCK_SESSION = {
  sessionId: 's_test_001',
  userId: 'u_avery',
  token: 'test-token',
  persona: {
    userId: 'u_avery',
    name: 'Avery Goodman',
    household: 'yousirjuan',
    role: 'principal',
    paradigm: {
      palette: 'obsidian',
      accent: '#7C5CFF',
      background: '#0A0A12',
      foreground: '#F5F3FF',
      layout: 'executive-grid',
      labelSet: 'executive',
      typography: 'serif-strong',
      mood: 'focused',
    },
    agent: {
      name: 'Sterling',
      voice: 'deep_male_calm',
      persona: 'executive-associate',
      avatar: null,
      greeting: 'Welcome back, Avery. The household is steady.',
    },
  },
};

test.describe('Home page', () => {
  test('loads with a mocked session and shows the agent greeting', async ({ page }) => {
    // Stub SSE so EventSource doesn't hang
    await page.route('/api/sync/**', (route) => {
      route.fulfill({
        status: 200,
        contentType: 'text/event-stream',
        body: ': keep-alive\n\n',
      });
    });

    // Inject session and onboarded flag into sessionStorage before navigation
    await page.addInitScript((session) => {
      sessionStorage.setItem('ysj.session', JSON.stringify(session));
      sessionStorage.setItem('ysj.onboarded', '1');
    }, MOCK_SESSION);

    await page.goto('/home');

    // The agent greeting should be visible
    await expect(page.getByText('Welcome back, Avery. The household is steady.')).toBeVisible({
      timeout: 5000,
    });

    // The associate's name label should be present
    await expect(page.getByText('Sterling says')).toBeVisible();
  });
});
