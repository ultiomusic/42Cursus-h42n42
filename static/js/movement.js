document.addEventListener("DOMContentLoaded", () => {
    const creet = document.getElementById("creet");
    let x = 50, y = 50, vx = 2, vy = 3;
    function move() {
      x += vx; y += vy;
      if (x < 0 || x > window.innerWidth - 20) vx = -vx;
      if (y < 0 || y > window.innerHeight - 20) vy = -vy;
      creet.style.left = x + "px";
      creet.style.top  = y + "px";
      requestAnimationFrame(move);
    }
    move();
  });
  