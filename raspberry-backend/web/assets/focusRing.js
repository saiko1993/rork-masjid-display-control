/**
 * focusRing.js
 *
 * Highlights the next-prayer row in the prayer table and adds
 * a glow ring to the phase badge.
 *
 * Called from display.html after prayer rows are rendered:
 *   updateFocusRing(nextPrayerKey)
 */

"use strict";

/**
 * @param {string|null} nextPrayerKey – e.g. "fajr", "dhuhr", …
 */
function updateFocusRing(nextPrayerKey) {
  // ── Prayer table rows ─────────────────────────────────────────
  const rows = document.querySelectorAll("#prayer-table tbody tr");
  rows.forEach(function (tr) {
    const key = tr.dataset.prayerKey;
    if (key && key === nextPrayerKey) {
      tr.classList.add("focus-row");
    } else {
      tr.classList.remove("focus-row");
    }
  });

  // ── Phase badge ───────────────────────────────────────────────
  const badge = document.getElementById("phase-badge");
  if (!badge) return;

  const phase = document.body.classList.contains("adhan-active")
    ? "adhan_active"
    : document.body.classList.contains("iqama-active")
    ? "iqama_countdown"
    : "normal";

  if (phase === "adhan_active" || phase === "iqama_countdown") {
    badge.classList.add("focus-phase");
  } else {
    badge.classList.remove("focus-phase");
  }
}

// Expose globally so display.html inline script can call it
window.updateFocusRing = updateFocusRing;
