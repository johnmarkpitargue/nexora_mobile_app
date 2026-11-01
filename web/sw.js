// Nexora Rider Service Worker for Mobile & Web OS Notifications
// Supports background system notifications, vibration patterns, lock-screen alerts, and notification click navigation.

self.addEventListener('install', (event) => {
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(self.clients.claim());
});

// Handle notification show requests sent from Flutter Web
self.addEventListener('message', (event) => {
  if (!event.data) return;

  if (event.data.type === 'SHOW_NOTIFICATION') {
    const title = event.data.title || 'Nexora Dispatch Alert';
    const rawOptions = event.data.options || {};

    const options = {
      body: rawOptions.body || 'You have an active dispatch or chat update.',
      icon: rawOptions.icon || 'icons/Icon-192.png',
      badge: rawOptions.badge || 'icons/Icon-192.png',
      vibrate: rawOptions.vibrate || [250, 100, 250, 100, 250],
      tag: rawOptions.tag || 'nexora-dispatch-' + Date.now(),
      renotify: true,
      requireInteraction: true,
      silent: false,
      actions: [
        { action: 'open', title: 'Open Rider App' },
        { action: 'close', title: 'Dismiss' }
      ],
      data: rawOptions.data || { url: '/' }
    };

    event.waitUntil(
      self.registration.showNotification(title, options)
    );
  }
});

// Handle incoming Web Push notifications (if backend triggers push)
self.addEventListener('push', (event) => {
  let data = {};
  if (event.data) {
    try {
      data = event.data.json();
    } catch (_) {
      data = { title: 'Nexora Dispatch', body: event.data.text() };
    }
  }

  const title = data.title || 'Nexora Rider Alert';
  const options = {
    body: data.body || 'New order dispatch or customer update.',
    icon: 'icons/Icon-192.png',
    badge: 'icons/Icon-192.png',
    vibrate: [250, 100, 250, 100, 250],
    tag: data.tag || 'nexora-push-' + Date.now(),
    renotify: true,
    requireInteraction: true,
    actions: [
      { action: 'open', title: 'Open App' },
      { action: 'close', title: 'Dismiss' }
    ],
    data: data
  };

  event.waitUntil(
    self.registration.showNotification(title, options)
  );
});

// Handle notification clicks: brings the rider back into the app
self.addEventListener('notificationclick', (event) => {
  event.notification.close();

  if (event.action === 'close') {
    return;
  }

  const targetUrl = (event.notification.data && event.notification.data.url) ? event.notification.data.url : '/';

  event.waitUntil(
    self.clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
      for (const client of clientList) {
        if ('focus' in client) {
          return client.focus();
        }
      }
      if (self.clients.openWindow) {
        return self.clients.openWindow(targetUrl);
      }
    })
  );
});
