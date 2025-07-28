// static/js/movement.js

document.addEventListener("DOMContentLoaded", () => {
    const initialCreets = 10;
    const reproductionInterval = 5000; // ms
    const creets = [];
    const hospital = document.getElementById("hospital");
  
    // Axis-aligned bounding-box çarpışma testi
    function isColliding(a, b) {
      return !(
        a.x + 20 < b.x ||
        b.x + 20 < a.x ||
        a.y + 20 < b.y ||
        b.y + 20 < a.y
      );
    }
  
    // Yeni bir Creet oluşturup diziye ekleyen fabrika fonksiyonu
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
        isInfected: false,
        skipNextClick: false,
        isDragging: false,
        offsetX: 0,
        offsetY: 0
      };
  
      // Click ile enfekte et, skipNextClick kontrolüyle
      el.addEventListener("click", e => {
        e.stopPropagation();
        if (c.skipNextClick) {
          c.skipNextClick = false;
          return;
        }
        if (!c.isInfected) {
          c.isInfected = true;
          el.style.backgroundColor = "blue";
          c.vx *= 0.85;
          c.vy *= 0.85;
          console.log("🦠 creet enfekte oldu (tıkla).");
        }
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
  
    // Başlangıçtaki Creet’leri yarat
    for (let i = 0; i < initialCreets; i++) {
      createCreet();
    }
  
    // Global mousemove ile sürükleme
    document.addEventListener("mousemove", e => {
      creets.forEach(c => {
        if (c.isDragging) {
          c.x = e.clientX - c.offsetX;
          c.y = e.clientY - c.offsetY;
        }
      });
    });
  
    // Global mouseup ile bırakma ve iyileştirme
    document.addEventListener("mouseup", e => {
      const rect = hospital.getBoundingClientRect();
  
      creets.forEach(c => {
        if (c.isDragging) {
          c.isDragging = false;
          c.x = c.el.offsetLeft;
          c.y = c.el.offsetTop;
  
          // Creet’in merkezi
          const cx = c.x + c.el.offsetWidth  / 2;
          const cy = c.y + c.el.offsetHeight / 2;
  
          // Eğer enfekte ve merkezi hastane bölgesindeyse iyileştir
          if (
            c.isInfected &&
            cx >= rect.left && cx <= rect.right &&
            cy >= rect.top  && cy <= rect.bottom
          ) {
            c.isInfected = false;
            c.el.style.backgroundColor = "red";
            c.vx = c.baseVx;
            c.vy = c.baseVy;
            c.skipNextClick = true;
            console.log("❤️ Creet hastanede iyileşti!");
          }
        }
      });
    });
  
    // Üreme mekanizması: sağlıklıların %10'u kadar kopya üret
    setInterval(() => {
      const healthy = creets.filter(c => !c.isInfected);
      const count = Math.floor(healthy.length * 0.1);
      if (count <= 0) return;
  
      // Sağlıklılar arasından benzersiz seçilim için basit shuffle
      const indices = healthy.map((_, idx) => idx);
      for (let i = indices.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [indices[i], indices[j]] = [indices[j], indices[i]];
      }
      const selected = indices.slice(0, count);
  
      selected.forEach(idx => {
        const parent = healthy[idx];
        createCreet(parent.x, parent.y);
      });
  
      console.log(`🐣 ${count} yeni Creet doğdu!`);
    }, reproductionInterval);
  
    // Ana döngü: hareket + bulaş
    function loop() {
      // Hareket
      creets.forEach(c => {
        if (!c.isDragging) {
          c.x += c.vx;
          c.y += c.vy;
          if (c.x < 0 || c.x > window.innerWidth  - 20) c.vx = -c.vx;
          if (c.y < 0 || c.y > window.innerHeight - 20) c.vy = -c.vy;
        }
        c.el.style.left = c.x + "px";
        c.el.style.top  = c.y + "px";
      });
  
      // Bulaş
      for (let i = 0; i < creets.length; i++) {
        for (let j = i + 1; j < creets.length; j++) {
          const A = creets[i], B = creets[j];
          if (isColliding(A, B)) {
            if (A.isInfected && !B.isInfected && Math.random() < 0.02) {
              B.isInfected = true;
              B.el.style.backgroundColor = "blue";
              B.vx *= 0.85; B.vy *= 0.85;
              console.log("🦠 bulaştı (A→B)!");
            } else if (B.isInfected && !A.isInfected && Math.random() < 0.02) {
              A.isInfected = true;
              A.el.style.backgroundColor = "blue";
              A.vx *= 0.85; A.vy *= 0.85;
              console.log("🦠 bulaştı (B→A)!");
            }
          }
        }
      }
  
      requestAnimationFrame(loop);
    }
  
    loop();
  });
  