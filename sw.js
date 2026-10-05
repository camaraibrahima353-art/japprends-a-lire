/* J'APPRENDS À LIRE — service worker (généré par build.py)
   Met en cache l'application, les polices, les icônes et les sons listés dans audio/<langue>/index.json
   pour un fonctionnement complet sans Internet. */
const VERSION = 'jal-426f4cdd9e';
const CORE = ["./", "index.html", "manifest.webmanifest", "lib/jszip.min.js", "fonts/andika-latin-400-normal.woff2", "fonts/andika-latin-700-normal.woff2", "fonts/andika-latin-ext-400-normal.woff2", "fonts/andika-latin-ext-700-normal.woff2", "fonts/baloo-2-latin-500-normal.woff2", "fonts/baloo-2-latin-600-normal.woff2", "fonts/baloo-2-latin-700-normal.woff2", "fonts/baloo-2-latin-800-normal.woff2", "fonts/noto-sans-nko-nko-400-normal.woff2", "icons/apple-touch-icon.png", "icons/favicon.png", "icons/icon-192.png", "icons/icon-512.png", "icons/maskable-512.png"];
const LANGS = ['fr','emk-nkoo'];

async function cacheAudio(cache){
  for(const lang of LANGS){
    try{
      const r = await fetch(`audio/${lang}/index.json`, {cache:'no-cache'});
      if(!r.ok) continue;
      await cache.put(`audio/${lang}/index.json`, r.clone());
      const map = await r.json();
      await Promise.all([...new Set(Object.values(map))].map(u => cache.match(u).then(hit => hit || cache.add(u)).catch(()=>{})));
    }catch(e){}
  }
}

self.addEventListener('install', e => {
  e.waitUntil((async () => {
    const cache = await caches.open(VERSION);
    await cache.addAll(CORE);
    await cacheAudio(cache);
    await self.skipWaiting();
  })());
});

self.addEventListener('activate', e => {
  e.waitUntil((async () => {
    for(const k of await caches.keys()) if(k !== VERSION) await caches.delete(k);
    await self.clients.claim();
  })());
});

self.addEventListener('fetch', e => {
  const req = e.request; const url = new URL(req.url);
  if(req.method !== 'GET' || url.origin !== location.origin) return;
  // la liste des sons : réseau d'abord (nouveaux sons), cache sinon ; on télécharge les nouveaux fichiers en arrière-plan
  if(/\/audio\/[^/]+\/index\.json$/.test(url.pathname)){
    e.respondWith(fetch(req).then(async r => {
      const cache = await caches.open(VERSION); cache.put(req, r.clone());
      r.clone().json().then(map => Promise.all(Object.values(map).map(u => cache.match(u).then(hit => hit || cache.add(u)).catch(()=>{})))).catch(()=>{});
      return r;
    }).catch(() => caches.match(req)));
    return;
  }
  // pages : cache d'abord, sinon index.html
  if(req.mode === 'navigate'){
    e.respondWith(caches.match('index.html').then(hit => hit || fetch(req)));
    return;
  }
  // tout le reste : cache d'abord, puis réseau (et mise en cache)
  e.respondWith(caches.match(req, {ignoreSearch:true}).then(hit => hit || fetch(req).then(r => {
    if(r.ok && (r.type === 'basic')){ const copy = r.clone(); caches.open(VERSION).then(c => c.put(req, copy)); }
    return r;
  })));
});
