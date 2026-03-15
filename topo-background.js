/**
 * topo-background.js
 *
 * Draws an animated topographic contour line background on a <canvas> element.
 *
 * Algorithm overview:
 *   1. Generate a random height field by summing several Gaussian "peaks" across the canvas.
 *   2. Sample that height field onto a regular grid.
 *   3. Run Marching Squares on the grid to extract contour line segments at evenly spaced
 *      elevation levels.
 *   4. Chain the raw segments into continuous polylines.
 *   5. Animate each polyline drawing itself in, staggered by elevation level, using an
 *      ease-out curve for a smooth reveal.
 *   6. Re-run everything on window resize.
 */

(function () {

  const canvas = document.getElementById('topo-bg');
  if (!canvas) return;
  const ctx = canvas.getContext('2d');

  // ── Helpers ──────────────────────────────────────────────────────────────

  /** Returns a random float in [min, max). */
  function rand(min, max) {
    return min + Math.random() * (max - min);
  }

  /** Ease-out quad: fast start, decelerates to rest at t=1. */
  function easeOut(t) {
    return 1 - (1 - t) * (1 - t);
  }

  // ── Step 1 & 2: Build the height field grid ───────────────────────────────

  /**
   * Samples a superposition of Gaussian peaks onto a grid.
   *
   * Each peak is defined by:
   *   cx, cy  – world-space centre (can be outside the canvas for edge features)
   *   amp     – peak height (0–1)
   *   sig     – standard deviation controlling how wide/flat the hill is
   *
   * The value at grid cell (r, c) is:
   *   v = Σ amp_i * exp( -(dx² + dy²) / (2 * sig_i²) )
   *
   * @param {number}   w     Canvas width in pixels
   * @param {number}   h     Canvas height in pixels
   * @param {number}   step  Grid cell size in pixels
   * @param {object[]} peaks Array of { cx, cy, amp, sig }
   * @returns {{ grid: Float32Array[], rows: number, cols: number }}
   */
  function computeGrid(w, h, step, peaks) {
    const cols = Math.ceil(w / step) + 1;
    const rows = Math.ceil(h / step) + 1;
    const grid = [];

    for (let r = 0; r < rows; r++) {
      grid[r] = new Float32Array(cols);
      for (let c = 0; c < cols; c++) {
        const x = c * step;
        const y = r * step;
        let v = 0;
        for (const p of peaks) {
          const dx = x - p.cx;
          const dy = y - p.cy;
          // Gaussian radial basis function
          v += p.amp * Math.exp(-(dx * dx + dy * dy) / (2 * p.sig * p.sig));
        }
        grid[r][c] = v;
      }
    }

    return { grid, rows, cols };
  }

  // ── Step 3: Marching Squares ──────────────────────────────────────────────

  /**
   * Extracts contour segments at a given elevation level using Marching Squares.
   *
   * For each 2×2 cell of grid vertices, a 4-bit index is built by testing whether
   * each corner is above or below the target level:
   *
   *   bit 3 (8) = top-left    bit 2 (4) = top-right
   *   bit 0 (1) = bottom-left bit 1 (2) = bottom-right
   *
   * The 16 possible index values map to 0, 1, or 2 line segments per cell.
   * Segment endpoints are linearly interpolated along cell edges for accuracy.
   *
   * Cases 5 and 10 are "saddle points" with two ambiguous segments — we resolve
   * them consistently by always splitting them the same way.
   *
   * @param {Float32Array[]} grid
   * @param {number} rows
   * @param {number} cols
   * @param {number} step   Grid cell size in pixels
   * @param {number} level  Elevation threshold to contour
   * @returns {Array<[[number,number],[number,number]]>} Raw segment pairs
   */
  function marchSquares(grid, rows, cols, step, level) {
    const segs = [];

    for (let r = 0; r < rows - 1; r++) {
      for (let c = 0; c < cols - 1; c++) {
        // Corner values (tl = top-left, etc.)
        const tl = grid[r][c];
        const tr = grid[r][c + 1];
        const bl = grid[r + 1][c];
        const br = grid[r + 1][c + 1];

        // Pixel coordinates of the cell corners
        const x0 = c * step, x1 = x0 + step;
        const y0 = r * step, y1 = y0 + step;

        // Linear interpolation helpers along horizontal and vertical edges
        const lx = (va, vb, xa, xb) =>
          Math.abs(vb - va) < 1e-9 ? (xa + xb) / 2 : xa + (xb - xa) * (level - va) / (vb - va);
        const ly = (va, vb, ya, yb) =>
          Math.abs(vb - va) < 1e-9 ? (ya + yb) / 2 : ya + (yb - ya) * (level - va) / (vb - va);

        // Midpoints on each edge where the contour crosses
        const T = [lx(tl, tr, x0, x1), y0]; // top edge
        const R = [x1, ly(tr, br, y0, y1)]; // right edge
        const B = [lx(bl, br, x0, x1), y1]; // bottom edge
        const L = [x0, ly(tl, bl, y0, y1)]; // left edge

        // Build the 4-bit case index
        const idx = (tl > level ? 8 : 0) | (tr > level ? 4 : 0) |
                    (br > level ? 2 : 0) | (bl > level ? 1 : 0);

        // Emit segment(s) for this cell
        switch (idx) {
          case  1: segs.push([L, B]); break;
          case  2: segs.push([B, R]); break;
          case  3: segs.push([L, R]); break;
          case  4: segs.push([T, R]); break;
          case  5: segs.push([T, R]); segs.push([L, B]); break; // saddle
          case  6: segs.push([T, B]); break;
          case  7: segs.push([T, L]); break;
          case  8: segs.push([T, L]); break;
          case  9: segs.push([T, B]); break;
          case 10: segs.push([T, L]); segs.push([R, B]); break; // saddle
          case 11: segs.push([T, R]); break;
          case 12: segs.push([L, R]); break;
          case 13: segs.push([R, B]); break;
          case 14: segs.push([L, B]); break;
          // case 0 and case 15: fully outside or inside — no contour
        }
      }
    }

    return segs;
  }

  // ── Step 4: Chain segments into polylines ─────────────────────────────────

  /**
   * Greedily chains raw segment pairs into longer polylines by matching endpoints.
   *
   * Each segment [A, B] contributes two endpoint keys. We build an adjacency map
   * from key → list of (segmentIndex, endIndex) and walk it depth-first, extending
   * the current polyline forward then backward until no more neighbours are found.
   *
   * This won't always produce perfect closed loops for noisy data, but it
   * significantly reduces draw calls and produces smoother-looking lines.
   *
   * @param {Array} segs  Output of marchSquares()
   * @returns {Array<[number,number][]>} Array of point arrays (each a polyline)
   */
  function connectSegments(segs) {
    if (!segs.length) return [];

    // Round coordinates to 0.5px to handle floating-point endpoint mismatches
    const key = ([x, y]) => `${Math.round(x * 2)},${Math.round(y * 2)}`;

    // Build adjacency: endpoint key → [{segIndex, endIndex}]
    const adj = new Map();
    for (let i = 0; i < segs.length; i++) {
      for (const e of [0, 1]) {
        const k = key(segs[i][e]);
        if (!adj.has(k)) adj.set(k, []);
        adj.get(k).push([i, e]);
      }
    }

    const used = new Uint8Array(segs.length);
    const lines = [];

    for (let i = 0; i < segs.length; i++) {
      if (used[i]) continue;
      used[i] = 1;

      // Walk forward from segs[i][1]
      const fwd = [...segs[i]];
      for (;;) {
        const k = key(fwd[fwd.length - 1]);
        let found = false;
        for (const [j, e] of (adj.get(k) || [])) {
          if (used[j]) continue;
          used[j] = 1;
          fwd.push(segs[j][e ^ 1]); // add the opposite endpoint
          found = true;
          break;
        }
        if (!found) break;
      }

      // Walk backward from segs[i][0]
      const bwd = [];
      for (;;) {
        const k = key(bwd.length ? bwd[bwd.length - 1] : segs[i][0]);
        let found = false;
        for (const [j, e] of (adj.get(k) || [])) {
          if (used[j]) continue;
          used[j] = 1;
          bwd.push(segs[j][e ^ 1]);
          found = true;
          break;
        }
        if (!found) break;
      }

      lines.push([...bwd.reverse(), ...fwd]);
    }

    return lines;
  }

  // ── Step 5: Build the full set of animated polylines ─────────────────────

  /**
   * Generates random terrain peaks, runs the full contour pipeline, and returns
   * an array of polyline descriptors ready for animation.
   *
   * @param {number} w  Canvas width
   * @param {number} h  Canvas height
   * @returns {Array<{ pts: [number,number][], delay: number, duration: number }>}
   */
  function buildPolylines(w, h) {
    // Scatter 4–6 random Gaussian peaks, allowed to extend slightly off-canvas
    // so contours don't all terminate at the edges
    const numPeaks = Math.floor(rand(4, 7));
    const peaks = [];
    for (let i = 0; i < numPeaks; i++) {
      peaks.push({
        cx:  rand(-w * 0.2, w * 1.2),
        cy:  rand(-h * 0.2, h * 1.2),
        amp: rand(0.5, 1.0),
        sig: rand(Math.min(w, h) * 0.18, Math.min(w, h) * 0.40),
      });
    }

    const step = 14; // grid resolution in pixels — lower = more detail, slower
    const { grid, rows, cols } = computeGrid(w, h, step, peaks);

    // Find the actual peak value so we can distribute contour levels proportionally
    let maxVal = 0;
    for (let r = 0; r < rows; r++)
      for (let c = 0; c < cols; c++)
        if (grid[r][c] > maxVal) maxVal = grid[r][c];

    if (maxVal < 0.01) return []; // degenerate field, skip

    // Generate 8 contour levels evenly distributed between 5% and 90% of max height
    const numLevels = 8;
    const polylines = [];

    for (let li = 1; li <= numLevels; li++) {
      const level = maxVal * (0.05 + 0.85 * li / (numLevels + 1));
      const lines = connectSegments(marchSquares(grid, rows, cols, step, level));

      for (const pts of lines) {
        if (pts.length < 2) continue;
        polylines.push({
          pts,
          delay:    li * 140,           // lower levels animate in first (ms)
          duration: rand(700, 1100),    // each line takes 0.7–1.1 s to draw
        });
      }
    }

    return polylines;
  }

  // ── Step 6: Draw a single polyline at a given progress (0–1) ─────────────

  /**
   * Strokes a polyline up to `progress` fraction of its total points.
   * Called every animation frame with an increasing progress value.
   */
  function drawPolyline(pts, progress) {
    const count = Math.floor(progress * (pts.length - 1));
    if (count < 1) return;
    ctx.beginPath();
    ctx.moveTo(pts[0][0], pts[0][1]);
    for (let i = 1; i <= count; i++) ctx.lineTo(pts[i][0], pts[i][1]);
    ctx.stroke();
  }

  // ── Animation loop ────────────────────────────────────────────────────────

  let polylines = [];
  let animId    = null;
  let animStart = null;

  /** Rebuilds the canvas and restarts the animation. Called on load and resize. */
  function start() {
    canvas.width  = window.innerWidth;
    canvas.height = window.innerHeight;
    polylines  = buildPolylines(canvas.width, canvas.height);
    animStart  = null;
    if (animId) cancelAnimationFrame(animId);
    animId = requestAnimationFrame(animate);
  }

  /** rAF callback — clears canvas, draws all polylines at their current progress. */
  function animate(ts) {
    if (!animStart) animStart = ts;
    const elapsed = ts - animStart;

    ctx.clearRect(0, 0, canvas.width, canvas.height);
    ctx.strokeStyle = 'rgba(63,182,139,0.35)'; // accent green, semi-transparent
    ctx.lineWidth   = 1.5;
    ctx.lineCap     = 'round';
    ctx.lineJoin    = 'round';

    let done = true;
    for (const pl of polylines) {
      const t = (elapsed - pl.delay) / pl.duration; // normalised time for this line
      if (t < 1) done = false;
      const p = easeOut(Math.max(0, Math.min(1, t)));
      if (p > 0) drawPolyline(pl.pts, p);
    }

    // Keep looping until every polyline has fully drawn in
    if (!done) animId = requestAnimationFrame(animate);
  }

  // Kick off after first paint, debounce resize events
  requestAnimationFrame(() => setTimeout(start, 0));

  let resizeTimer;
  window.addEventListener('resize', () => {
    clearTimeout(resizeTimer);
    resizeTimer = setTimeout(start, 250);
  });

})();
