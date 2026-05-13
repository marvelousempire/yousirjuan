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

const MOCK_FACES = {
  enrolled: [
    { faceId: 'face-avery-001', userId: 'u_avery' },
    { faceId: 'face-bobby-001', userId: 'u_bobby' },
    { faceId: 'face-nivram-001', userId: 'u_nivram' },
    { faceId: 'face-yousirjuan-001', userId: 'u_yousirjuan' },
  ],
};

test.describe('Auth page', () => {
  test('navigating to / redirects to /auth', async ({ page }) => {
    // No session in sessionStorage — should redirect to /auth
    await page.goto('/');
    await expect(page).toHaveURL(/\/auth/, { timeout: 5000 });
  });

  test('picking u_avery calls the session API and redirects to /home', async ({ page }) => {
    // Mock the faces list
    await page.route('/api/identity/faces', (route) => {
      route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify(MOCK_FACES),
      });
    });

    // Mock the session creation
    await page.route('/api/session', (route) => {
      route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify(MOCK_SESSION),
      });
    });

    // Mock the SSE sync endpoint so EventSource doesn't cause issues
    await page.route('/api/sync/**', (route) => {
      route.fulfill({
        status: 200,
        contentType: 'text/event-stream',
        body: ': keep-alive\n\n',
      });
    });

    await page.goto('/auth');

    // Wait for the face grid to appear and click Avery's card
    await page.waitForSelector('text=Avery Goodman');
    await page.click('text=Avery Goodman');

    // After the mock session resolves, should redirect to /home (or /onboard on first run)
    await expect(page).toHaveURL(/\/(home|onboard)/, { timeout: 5000 });
  });
});
