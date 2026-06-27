---
name: run-flutter-web
description: Launch and visually verify the MyGabon Flutter app via a static web build + headless Playwright (Python). Use whenever asked to run/launch/test this app or check that a UI change actually renders.
---

# Running MyGabon (Flutter web) headlessly

This environment has no GUI screenshot/browser-automation tool built in, and
`flutter run -d chrome` (the dev server with hot reload) is **unreliable**
here: it opens its own real Chrome window, and once a second Chromium
instance (e.g. Playwright) also connects, the dev server's `dwds` debug
socket becomes flaky — the process exits or the page never finishes loading
(`net::ERR_CONNECTION_REFUSED` / blank screen even though the build log says
it's ready). Don't fight it; use a static build instead.

## 1. Build a static bundle (one-time per code change)

```bash
cd c:/Users/pc/Desktop/MyGabon
flutter build web --dart-define-from-file=env.json
```

`env.json` must exist locally with real `SUPABASE_URL` / `SUPABASE_ANON_KEY`
/ `ONESIGNAL_APP_ID` (gitignored, never commit it — see `env.json.example`).
Takes ~3-4 min the first time.

## 2. Serve it

```bash
cd c:/Users/pc/Desktop/MyGabon/build/web
python -m http.server 8990   # run_in_background; pick a free port
```

## 3. Install Playwright once per machine (skip if already done)

```bash
pip install playwright
python -m playwright install chromium
```

## 4. Drive it

Flutter web renders to a `<canvas>` (CanvasKit/HTML renderer) — there is
**no real DOM to query by CSS selector**. The only reliable approach is
coordinate-based clicking against a known viewport size, driven by what you
see in screenshots.

```python
from playwright.sync_api import sync_playwright

with sync_playwright() as p:
    browser = p.chromium.launch()
    page = browser.new_page(viewport={"width": 412, "height": 915})
    msgs = []
    page.on("console", lambda m: msgs.append(f"[{m.type}] {m.text}"))
    page.on("pageerror", lambda e: msgs.append(f"[pageerror] {e}"))
    page.goto("http://localhost:8990", wait_until="load", timeout=60000)
    page.wait_for_timeout(12000)  # first paint is slow even on a static build
    page.screenshot(path="shot.png")
    # IMPORTANT: write console/pageerror text to a UTF-8 file, never print()
    # it directly — Windows' default cp1252 stdout crashes on emoji (✅❌⚠️)
    # used throughout this app's debugPrint() calls.
    with open("shot.log.txt", "w", encoding="utf-8") as f:
        f.write("\n".join(msgs))

    # Example: click a known button by its approximate screenshot position
    page.mouse.click(206, 608)
    page.wait_for_timeout(2000)
    page.screenshot(path="shot2.png")

    # Example: type into a text field (click first to focus, then keyboard.type)
    page.mouse.click(206, 403)
    page.wait_for_timeout(300)
    page.keyboard.type("someone@gmail.com", delay=20)
```

**A blank white screenshot is a failure to launch, not "still loading"** —
if it's still blank after 10-15s, check `shot.log.txt` for a `[pageerror]`
line (an uncaught exception during `main()`/service init will blank the
whole widget tree before first paint; this is exactly how the OneSignal
web-incompatibility crash was caught and fixed in `notification_service.dart`).

## Gotchas specific to this app

- **No seeded users.** The current Supabase project (`ssmveuinnmoywlhefqka`)
  has no demo data. To get past the login screen you must register a test
  account through the UI first.
- **Email domain validation.** Supabase Auth rejects obviously-fake domains
  like `@example.com` (`AuthApiException: email_address_invalid`). Use a
  real-looking domain, e.g. `testmygabon<timestamp>@gmail.com`.
- **Email confirmation may be required.** If registration succeeds but
  nothing happens (no error, no navigation), the project likely requires
  email confirmation and there's no real inbox to click. Confirm manually:
  ```sql
  UPDATE auth.users SET email_confirmed_at = now() WHERE email = '...';
  ```
  via `mcp__claude_ai_Supabase__execute_sql`, then log in normally.
- **Clean up test accounts after.** A test signup leaves rows in
  `public.users`, `public.audit_logs`, and `auth.users`. Delete in that
  order (audit_logs has a FK to users):
  ```sql
  DELETE FROM public.audit_logs WHERE user_id = '<uuid>';
  DELETE FROM public.wallet_topups WHERE user_id = '<uuid>';
  DELETE FROM public.user_wallets WHERE user_id = '<uuid>';
  DELETE FROM public.users WHERE id = '<uuid>';
  DELETE FROM auth.users WHERE id = '<uuid>';
  ```

## Cleanup after testing

Stop the background `http.server` task and kill any orphaned
`flutter run` processes left over from earlier attempts (Windows doesn't
always release the port immediately — `taskkill //PID <pid> //F` in Git
Bash, note the double slash to stop MSYS path-mangling `/PID`).
