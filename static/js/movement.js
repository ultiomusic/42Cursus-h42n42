// static/js/movement.js

document.addEventListener("DOMContentLoaded", () => {
    const initialCreets = 10;
    const reproductionInterval = 5000; // ms
    const deathTime = 10000;           // ms until infected creet dies
    const berserkChance = 0.1;
    const meanChance   = 0.1;
    const berserkGrowthRate = 0.07;    // px per frame
    const creets = [];
    const hospital = document.getElementById("hospital");
  
    // Axis-aligned bounding-box çarpışma testi
    function isColliding(a, b) {
      return !(
        a.x + a.size < b.x ||
        b.x + b.size < a.x ||
        a.y + a.size < b.y ||
        b.y + b.size < a.y
      );
    }
  
    // Bir creet’i öldüren yardımcı fonksiyon
    function killCreet(c) {
      clearTimeout(c.deathTimeout);
      if (c.el.parentNode) c.el.remove();
      const idx = creets.indexOf(c);
      if (idx !== -1) creets.splice(idx, 1);
      console.log("💀 Creet öldü!");
    }
  
    // Enfekte etme & mod atama
    function infect(c) {
      if (c.isInfected) return;
      c.isInfected = true;
      clearTimeout(c.deathTimeout);
      c.deathTimeout = setTimeout(() => killCreet(c), deathTime);
  
      const r = Math.random();
      if (r < berserkChance) {
        c.mode = "berserk";
        c.el.style.backgroundColor = "grey";
        c.size = 30;
        console.log("🤯 Creet berserk moda geçti!");
        // berserk de enfekte yavaşlaması: 
        c.vx = c.baseVx * 0.85;
        c.vy = c.baseVy * 0.85;
      } else if (r < berserkChance + meanChance) {
        c.mode = "mean";
        c.el.style.backgroundColor = "green";
        c.size = 15;
        console.log("😈 Creet mean moda geçti!");
        // mean %50 hızlı
        c.vx = c.baseVx * 1.5;
        c.vy = c.baseVy * 1.5;
      } else {
        c.mode = "normal";
        c.el.style.backgroundColor = "blue";
        c.size = 20;
        // normal enfekte yavaşlaması
        c.vx = c.baseVx * 0.85;
        c.vy = c.baseVy * 0.85;
      }
  
      console.log("🦠 Creet enfekte oldu!");
    }
  
    // Yeni creet oluşturma
    function createCreet(x0 = Math.random() * (window.innerWidth - 20),
                         y0 = Math.random() * (window.innerHeight - 20)) {
      const el = document.createElement("div");
      el.className = "creet";
      Object.assign(el.style, {
        position: "absolute",
        width:  "20px",
        height: "20px",
        backgroundColor: "red",
        cursor: "pointer",
        zIndex: 1
      });
      el.style.left = x0 + "px";
      el.style.top  = y0 + "px";
      document.body.appendChild(el);
  
      const vx0 = 2 + Math.random() * 2;
      const vy0 = 2 + Math.random() * 2;
  
      const c = {
        el,
        x: x0,
        y: y0,
        vx: vx0,
        vy: vy0,
        baseVx: vx0,
        baseVy: vy0,
        size: 20,
        isInfected: false,
        mode: "normal",       // "normal", "berserk", or "mean"
        target: null,         // mean modu için takip edilecek hedef
        skipNextClick: false,
        isDragging: false,
        offsetX: 0,
        offsetY: 0,
        deathTimeout: null
      };
  
      // Click ile enfekte et
      el.addEventListener("click", e => {
        e.stopPropagation();
        if (c.skipNextClick) {
          c.skipNextClick = false;
          return;
        }
        if (!c.isInfected) infect(c);
      });
  
      // Sürükleme başlangıcı
      el.addEventListener("mousedown", e => {
        c.isDragging = true;
        c.offsetX = e.clientX - c.x;
        c.offsetY = e.clientY - c.y;
      });
  
      creets.push(c);
      return c;
    }
  
    // Başlangıç creet’leri
    for (let i = 0; i < initialCreets; i++) {
      createCreet();
    }
  
    // Global fare dinleyicileri
    document.addEventListener("mousemove", e => {
      creets.forEach(c => {
        if (c.isDragging) {
          c.x = e.clientX - c.offsetX;
          c.y = e.clientY - c.offsetY;
        }
      });
    });
    document.addEventListener("mouseup", e => {
      const rect = hospital.getBoundingClientRect();
      creets.forEach(c => {
        if (c.isDragging) {
          c.isDragging = false;
          c.x = c.el.offsetLeft;
          c.y = c.el.offsetTop;
  
          // Hastanede iyileşme
          const cx = c.x + c.size/2;
          const cy = c.y + c.size/2;
          if (
            c.isInfected &&
            cx >= rect.left && cx <= rect.right &&
            cy >= rect.top  && cy <= rect.bottom
          ) {
            c.isInfected = false;
            c.mode = "normal";
            c.size = 20;
            c.el.style.backgroundColor = "red";
            c.vx = c.baseVx;
            c.vy = c.baseVy;
            c.skipNextClick = true;
            clearTimeout(c.deathTimeout);
            console.log("❤️ Creet hastanede iyileşti!");
          }
        }
      });
    });
  
    // Üreme mekanizması
    setInterval(() => {
      const healthy = creets.filter(c => !c.isInfected);
      const count = Math.floor(healthy.length * 0.1);
      if (count < 1) return;
      const indices = healthy.map((_, i) => i);
      for (let i = indices.length-1; i>0; i--) {
        const j = Math.floor(Math.random()*(i+1));
        [indices[i], indices[j]] = [indices[j], indices[i]];
      }
      indices.slice(0, count).forEach(idx => {
        const p = healthy[idx];
        createCreet(p.x, p.y);
      });
      console.log(`🐣 ${count} yeni Creet doğdu!`);
    }, reproductionInterval);
  
    // Ana döngü
    function loop() {
      const healthyList = creets.filter(c => !c.isInfected);
  
      creets.forEach(c => {
        // Berserk büyümesi
        if (c.mode === "berserk") {
          c.size += berserkGrowthRate;
        }
  
        if (!c.isDragging) {
          if (c.mode === "mean") {
            if (healthyList.length > 0) {
              // hedef yoksa veya geçersizse seç
              if (!c.target || c.target.isInfected || !creets.includes(c.target)) {
                let nearest = null, minD = Infinity;
                healthyList.forEach(h => {
                  const dx = h.x - c.x, dy = h.y - c.y;
                  const d = dx*dx + dy*dy;
                  if (d < minD) { minD = d; nearest = h; }
                });
                c.target = nearest;
              }
              // kovala
              const dx = c.target.x - c.x, dy = c.target.y - c.y;
              const m = Math.hypot(dx,dy)||1;
              c.x += (dx/m)*c.vx;
              c.y += (dy/m)*c.vy;
            } else {
              // takip edilecek hiç sağlıklı yoksa bounce
              c.x += c.vx;
              c.y += c.vy;
              c.target = null;
            }
          } else {
            // normal & berserk sekme
            c.x += c.vx;
            c.y += c.vy;
          }
          // sınır çarpma
          if (c.x<0||c.x>window.innerWidth-c.size) c.vx=-c.vx;
          if (c.y<0||c.y>window.innerHeight-c.size) c.vy=-c.vy;
        }
  
        // stil güncelle
        Object.assign(c.el.style, {
          left: `${c.x}px`,
          top:  `${c.y}px`,
          width:  `${c.size}px`,
          height: `${c.size}px`
        });
      });
  
      // çarpışma ve bulaş
      for (let i=0; i<creets.length; i++){
        for (let j=i+1; j<creets.length; j++){
          const A=creets[i], B=creets[j];
          if (isColliding(A,B)){
            if (A.isInfected && !B.isInfected){
              infect(B);
              if (A.mode==="mean") A.target=null;
            } else if (B.isInfected && !A.isInfected){
              infect(A);
              if (B.mode==="mean") B.target=null;
            }
          }
        }
      }
  
      requestAnimationFrame(loop);
    }
  
    loop();
  });
  