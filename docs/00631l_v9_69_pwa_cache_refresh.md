# 00631L lab v9.69 PWA cache refresh

v9.69 reduces stale public PWA behavior after a new GitHub Pages deploy.

## Changes

- The loading page checks service worker registrations scoped to this GitHub
  Pages app.
- If an old registration exists, it is unregistered and the page reloads once
  in the same browser session.
- A metadata test verifies that the startup page includes the service worker
  cleanup hook.

## Runtime behavior

- Existing phone/PWA sessions are less likely to keep an old Flutter bundle
  after deployment.
- The app still loads normally when no service worker is registered.
- Live data labels remain controlled by the repository and backend responses.
