(function () {
  const project = window.PGM_PROJECT;
  const canvas = document.getElementById('game');
  const ctx = canvas.getContext('2d');
  canvas.width = project.width; canvas.height = project.height;
  const keys = Object.create(null);
  const pressed = Object.create(null);
  addEventListener('keydown', e => { if (!keys[e.key]) pressed[e.key] = true; keys[e.key] = true; });
  addEventListener('keyup', e => { keys[e.key] = false; });
  addEventListener('pointerdown', e => { keys['mouse'] = true; });
  addEventListener('pointerup', e => { keys['mouse'] = false; });

  const scene = project.scenes[0];
  const objects = scene.objects.map(o => ({ ...o, behaviors: (o.behaviors || []).map(b => ({ ...b, params: { ...(b.params || {}) } })) }));
  const images = {};
  for (const a of project.assets || []) {
    if (a.type === 'image') {
      const img = new Image();
      const ext = (a.name.split('.').pop() || '').toLowerCase();
      const mime = ({png:'image/png',jpg:'image/jpeg',jpeg:'image/jpeg',gif:'image/gif',svg:'image/svg+xml'})[ext] || 'application/octet-stream';
      img.src = 'data:' + mime + ';base64,' + a.data;
      images[a.id] = img;
    }
  }

  let score = 0;
  let timeLeft = null;
  let last = performance.now();
  const runtime = {
    canvas, ctx, objects,
    input: { down: k => !!keys[k], pressed: k => !!pressed[k] },
    score: { get: () => score, add: n => score += Number(n || 0), set: n => score = Number(n || 0) },
    timer: { seconds: () => timeLeft },
    restart: () => location.reload(),
    find: name => objects.find(o => o.name === name),
    apiVersion: '1.0',
    onUpdate: null
  };

  function aabb(a, b) { return a.x < b.x+b.width && a.x+a.width > b.x && a.y < b.y+b.height && a.y+a.height > b.y; }
  function isSolid(o) { return o.kind === 'platform' || o.behaviors.some(b => b.type === 'collision' && b.params?.solid !== false); }
  function num(p, key, d) { const v = Number(p?.[key]); return Number.isFinite(v) ? v : d; }

  function behavior(o, b, dt) {
    const p = b.params || {};
    if (b.type === 'move') {
      const speed = num(p, 'speed', 140);
      let dx = 0, dy = 0;
      if (keys['ArrowLeft'] || keys['a']) dx -= 1;
      if (keys['ArrowRight'] || keys['d']) dx += 1;
      if (keys['ArrowUp'] || keys['w']) dy -= 1;
      if (keys['ArrowDown'] || keys['s']) dy += 1;
      o.x += dx * speed * dt; o.y += dy * speed * dt;
    } else if (b.type === 'gravity') {
      o.vy = (o.vy || 0) + num(p, 'gravity', 800) * dt;
      o.y += o.vy * dt;
    } else if (b.type === 'collision') {
      for (const other of objects) {
        if (other === o || !isSolid(other)) continue;
        if (!aabb(o, other)) continue;
        const prevY = o.y - (o.vy || 0) * dt;
        if (prevY + o.height <= other.y + 8) { o.y = other.y - o.height; o.vy = 0; o.onGround = true; }
        else if (o.x < other.x) o.x = other.x - o.width;
        else o.x = other.x + other.width;
      }
      if (o.y + o.height >= canvas.height) { o.y = canvas.height - o.height; o.vy = 0; o.onGround = true; }
    } else if (b.type === 'score') {
      const points = num(p, 'points', 10);
      for (const other of objects) {
        if (other !== o && other.kind === 'coin' && !other.collected && aabb(o, other)) {
          other.collected = true; score += points;
        }
      }
    } else if (b.type === 'timer') {
      if (timeLeft === null) timeLeft = num(p, 'seconds', 60);
      timeLeft -= dt;
      if (timeLeft < 0) timeLeft = 0;
    } else if (b.type === 'trigger') {
      const key = p.key || 'Space';
      if (pressed[key]) {
        const action = p.action || 'addScore';
        if (action === 'addScore') score += num(p, 'points', 1);
        if (action === 'restart') location.reload();
        if (action === 'jump') { o.vy = -num(p, 'jump', 300); }
      }
    }
  }

  function draw(o) {
    if (o.collected) return;
    ctx.save();
    const img = o.assetId ? images[o.assetId] : null;
    if (img && img.complete) ctx.drawImage(img, o.x, o.y, o.width, o.height);
    else {
      ctx.fillStyle = '#' + (o.color >>> 0).toString(16).padStart(8, '0').slice(2);
      if (o.kind === 'coin') { ctx.beginPath(); ctx.arc(o.x+o.width/2, o.y+o.height/2, Math.min(o.width,o.height)/2, 0, Math.PI*2); ctx.fill(); }
      else ctx.fillRect(o.x, o.y, o.width, o.height);
      if (o.kind === 'text') { ctx.fillStyle = '#fff'; ctx.font = '18px system-ui'; ctx.fillText(o.text || o.name, o.x, o.y + o.height); }
    }
    ctx.restore();
  }

  try {
    if (project.customJs && project.customJs.trim()) {
      new Function('game', project.customJs)(runtime);
    }
  } catch (e) { console.error('Custom JS error:', e); }

  function frame(now) {
    const dt = Math.min(0.032, (now - last) / 1000); last = now;
    ctx.clearRect(0,0,canvas.width,canvas.height);
    ctx.fillStyle = '#0f172a'; ctx.fillRect(0,0,canvas.width,canvas.height);
    if (typeof runtime.onUpdate === 'function') {
      try { runtime.onUpdate(dt); } catch (e) { console.error('Custom JS update error:', e); }
    }
    for (const o of objects) {
      o.onGround = false;
      for (const b of o.behaviors) behavior(o, b, dt);
      o.x = Math.max(0, Math.min(canvas.width - o.width, o.x));
      o.y = Math.max(0, Math.min(canvas.height - o.height, o.y));
    }
    for (const o of objects) draw(o);
    ctx.fillStyle = '#ffffff'; ctx.font = 'bold 16px system-ui'; ctx.fillText('SCORE ' + score, 14, 24);
    if (timeLeft !== null) ctx.fillText('TIME ' + Math.ceil(timeLeft), canvas.width - 92, 24);
    for (const k in pressed) delete pressed[k];
    requestAnimationFrame(frame);
  }
  requestAnimationFrame(frame);
})();
