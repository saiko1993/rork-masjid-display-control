(function () {
  function clearAll() {
    document.querySelectorAll('.focus-ring').forEach((el) => el.classList.remove('focus-ring'));
  }

  function highlight(phaseBadge, prayerRow) {
    clearAll();
    if (phaseBadge) phaseBadge.classList.add('focus-ring');
    if (prayerRow) prayerRow.classList.add('focus-ring');
  }

  window.FocusRing = { highlight };
})();
