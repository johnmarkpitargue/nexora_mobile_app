// Nexora Buyer Service Worker for Mobile & Web OS Notifications
// Supports background system notifications, vibration patterns, and app focus on click.

self.addEventListener('install', (event) => {
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(self.clients.claim());
});

self.addEventListener('message', (event) => {
  if (!event.data) return;

  if (event.data.type === 'SHOW_NOTIFICATION') {
    const title = event.data.title || 'Nexora Alert';
    const rawOptions = event.data.options || {};

    const options = {
      body: rawOptions.body || 'You have an update on your order.',
      icon: rawOptions.icon || 'icons/Icon-192.png',
      badge: rawOptions.badge || 'icons/Icon-192.png',
      vibrate: rawOptions.vibrate || [200, 100, 200],
      tag: rawOptions.tag || 'nexora-buyer-' + Date.now(),
      renotify: true,
      requireInteraction: false,
      actions: [
        { action: 'open', title: 'Open Nexora' },
        { action: 'close', title: 'Dismiss' }
      ],
      data: rawOptions.data || { url: '/' }
    };

    event.waitUntil(
      self.registration.showNotification(title, options)
    );
  }
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();

  if (event.action === 'close') return;

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
