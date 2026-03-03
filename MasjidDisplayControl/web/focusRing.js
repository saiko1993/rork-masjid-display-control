(function () {
  'use strict';

  var prevNextPrayer = null;
  var prevTickerText = '';

  function highlightNextPrayer() {
    var rows = document.querySelectorAll('.prayer-row, [data-prayer]');
    if (!rows.length) return;

    var now = Date.now();
    var nextRow = null;
    var minDiff = Infinity;

    rows.forEach(function (row) {
      row.classList.remove('next-prayer');
      var t = row.getAttribute('data-time');
      if (!t) return;
      var diff = new Date(t).getTime() - now;
      if (diff > 0 && diff < minDiff) {
        minDiff = diff;
        nextRow = row;
      }
    });

    if (nextRow) {
      nextRow.classList.add('next-prayer', 'focus-ring', 'active');
      if (prevNextPrayer && prevNextPrayer !== nextRow) {
        prevNextPrayer.classList.remove('next-prayer', 'focus-ring', 'active');
      }
      prevNextPrayer = nextRow;
    }
  }

  function highlightPhaseBadge() {
    var badge = document.querySelector('.phase-badge, [data-phase]');
    if (!badge) return;

    var phase = badge.getAttribute('data-phase') || '';
    badge.classList.remove('adhan-active', 'iqama-active');

    if (phase === 'adhan_active' || phase === 'adhan') {
      badge.classList.add('adhan-active');
    } else if (phase === 'iqama_countdown' || phase === 'iqama') {
      badge.classList.add('iqama-active');
    }
    return phase;
  }

  function applyTickerPause(phase) {
    var tickerText = document.querySelector('.ticker-text, .ticker > span');
    if (!tickerText) return;
    var shouldPause = phase === 'adhan_active' || phase === 'adhan' ||
                      phase === 'iqama_countdown' || phase === 'iqama';
    tickerText.style.animationPlayState = shouldPause ? 'paused' : 'running';
  }

  function watchTicker() {
    var ticker = document.querySelector('.ticker, .dhikr-ticker, [data-ticker]');
    if (!ticker) return;

    var text = ticker.textContent || '';
    if (text !== prevTickerText) {
      ticker.classList.add('ticker-focus', 'changing');
      requestAnimationFrame(function () {
        setTimeout(function () {
          ticker.classList.remove('changing');
        }, 500);
      });
      prevTickerText = text;
    }
  }

  function tick() {
    highlightNextPrayer();
    var phase = highlightPhaseBadge();
    applyTickerPause(phase || '');
    watchTicker();
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', function () {
      tick();
      setInterval(tick, 1000);
    });
  } else {
    tick();
    setInterval(tick, 1000);
  }
})();
