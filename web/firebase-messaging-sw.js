// firebase-messaging-sw.js
// Service Worker para Firebase Cloud Messaging en la versión Web
// Permite recibir notificaciones push incluso con la app en segundo plano

importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js");

// IMPORTANTE: Reemplazar con los valores de tu proyecto Firebase
// (se rellenarán después de ejecutar FlutterFire CLI)
firebase.initializeApp({
  apiKey: "AIzaSyAQQDuaIYUTVZ39jOiA1epngNtaYzNYmGc",
  authDomain: "securpasstactical.firebaseapp.com",
  projectId: "securpasstactical",
  storageBucket: "securpasstactical.firebasestorage.app",
  messagingSenderId: "92615492487",
  appId: "1:92615492487:web:aa1779f777d8e2efab8922",
});

const messaging = firebase.messaging();

// Manejo de mensajes en segundo plano
messaging.onBackgroundMessage(function(payload) {
  console.log('[SecurPass SW] Mensaje en segundo plano:', payload);

  const alertTypes = {
    'vip_entry_inbound': '⭐ VIP ENTRANTE',
    'security_incident': '🚨 INCIDENTE',
    'part_novedad': '⚠️ NOVEDAD',
    'general_notice': '📢 AVISO',
  };

  const notificationTitle =
    alertTypes[payload.data?.alert_type] || '🛡️ SecurPass Tactical';

  const notificationOptions = {
    body: payload.notification?.body || payload.data?.message || 'Nueva alerta del sistema',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    tag: payload.data?.alert_id || 'securpass-alert',
    requireInteraction: payload.data?.priority === 'high',
    data: {
      url: payload.data?.deep_link || '/',
    },
    actions: [
      { action: 'view', title: 'Ver Alerta' },
      { action: 'dismiss', title: 'Ignorar' },
    ],
    vibrate: [200, 100, 200],
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});

// Click en la notificación
self.addEventListener('notificationclick', function(event) {
  event.notification.close();
  if (event.action === 'dismiss') return;

  const url = event.notification.data?.url || '/';
  event.waitUntil(
    clients.matchAll({ type: 'window' }).then(function(clientList) {
      for (const client of clientList) {
        if (client.url === url && 'focus' in client) {
          return client.focus();
        }
      }
      if (clients.openWindow) {
        return clients.openWindow(url);
      }
    })
  );
});
