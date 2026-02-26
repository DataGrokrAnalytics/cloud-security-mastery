/**
 * Cloud Security Mastery Program — csm-core.js
 * Shared behaviour module for all day-NN.html pages.
 *
 * Each page must call initPage(config) with:
 * {
 *   storageKey : 'csm-day01',
 *   total      : 5,           // number of panes (lessons + lab)
 *   quizCount  : 4,           // number of quiz questions
 *   checkTotal : 8,           // number of checklist items
 *   titles     : [...],       // pane titles (length === total)
 *   fb         : {            // quiz feedback strings
 *     0: { good: '...', bad: '...' },
 *     ...
 *   }
 * }
 */

(function () {
  'use strict';

  let _cfg = {};
  let _state = {};

  /* ── State persistence ── */
  function loadState() {
    try {
      const s = localStorage.getItem(_cfg.storageKey);
      if (s) return JSON.parse(s);
    } catch (e) {}
    return { current: 0, done: [], correct: [], answered: [], checks: [] };
  }

  function saveState() {
    try { localStorage.setItem(_cfg.storageKey, JSON.stringify(_state)); } catch (e) {}
  }

  /* ── Navigation ── */
  function goTo(n) {
    document.querySelectorAll('.lesson-pane').forEach(p => p.classList.remove('active'));
    document.querySelectorAll('.nav-item').forEach(i => i.classList.remove('active'));
    _state.current = n;
    const paneId = n === _cfg.total ? 'pane-complete' : 'pane-' + n;
    const pane = document.getElementById(paneId);
    if (pane) pane.classList.add('active');
    const items = document.querySelectorAll('.nav-item');
    if (items[n]) items[n].classList.add('active');
    const topbarTitle = document.getElementById('topbar-title');
    if (topbarTitle) topbarTitle.textContent = _cfg.titles[n] || 'Complete';
    const btnPrev = document.getElementById('btn-prev');
    const btnNext = document.getElementById('btn-next');
    if (btnPrev) btnPrev.disabled = (n === 0);
    if (btnNext) btnNext.disabled = (n >= _cfg.total - 1);
    window.scrollTo(0, 0);
    saveState();
    updateProgress();
  }

  function next() { if (_state.current < _cfg.total - 1) goTo(_state.current + 1); }
  function prev() { if (_state.current > 0) goTo(_state.current - 1); }

  /* ── Completion ── */
  function finish() {
    markDone(_state.current);
    document.querySelectorAll('.lesson-pane').forEach(p => p.classList.remove('active'));
    document.querySelectorAll('.nav-item').forEach(i => i.classList.remove('active'));
    const pct = Math.round(_state.correct.length / _cfg.quizCount * 100);
    const scoreEl = document.getElementById('score-val');
    if (scoreEl) scoreEl.textContent = _state.correct.length + ' / ' + _cfg.quizCount + ' (' + pct + '%)';
    const checked = _state.checks.filter(Boolean).length;
    const labEl = document.getElementById('lab-score-val');
    if (labEl) labEl.textContent = checked + ' / ' + _cfg.checkTotal;
    const completePt = document.getElementById('pane-complete');
    if (completePt) completePt.classList.add('active');
    const topbarTitle = document.getElementById('topbar-title');
    if (topbarTitle) topbarTitle.textContent = 'Complete';
    const btnPrev = document.getElementById('btn-prev');
    const btnNext = document.getElementById('btn-next');
    if (btnPrev) btnPrev.disabled = true;
    if (btnNext) btnNext.disabled = true;
    saveState();
  }

  /* ── Progress ── */
  function markDone(n) {
    if (!_state.done.includes(n)) _state.done.push(n);
    const items = document.querySelectorAll('.nav-item');
    if (items[n]) items[n].classList.add('done');
    updateProgress();
  }

  function updateProgress() {
    const count = _state.done.length;
    const pctEl = document.getElementById('progress-pct');
    const fillEl = document.getElementById('progress-fill');
    if (pctEl) pctEl.textContent = count + ' / ' + _cfg.total;
    if (fillEl) fillEl.style.width = (count / _cfg.total * 100) + '%';
  }

  /* ── Quiz ── */
  function check(btn, isCorrect, idx) {
    if (_state.answered.includes(idx)) return;
    _state.answered.push(idx);
    const opts = btn.closest('.kcheck-options').querySelectorAll('.kcheck-opt');
    opts.forEach(o => { o.classList.add('disabled'); o.style.pointerEvents = 'none'; });
    const fbEl = document.getElementById('fb-' + idx);
    if (isCorrect) {
      btn.classList.add('correct');
      if (fbEl) { fbEl.className = 'kcheck-feedback show good'; fbEl.textContent = '✓ ' + _cfg.fb[idx].good; }
      if (!_state.correct.includes(idx)) _state.correct.push(idx);
    } else {
      btn.classList.add('wrong');
      if (fbEl) { fbEl.className = 'kcheck-feedback show bad'; fbEl.textContent = '✗ ' + _cfg.fb[idx].bad; }
      opts.forEach(o => {
        if (o.getAttribute('onclick') && o.getAttribute('onclick').includes('true'))
          o.classList.add('reveal-correct');
      });
    }
    markDone(idx);
    saveState();
  }

  /* ── Checklist ── */
  function toggleCheck(el, idx) {
    if (!_state.checks[idx]) _state.checks[idx] = false;
    _state.checks[idx] = !_state.checks[idx];
    el.classList.toggle('checked', _state.checks[idx]);
    updateChecklist();
    saveState();
  }

  function updateChecklist() {
    const checked = _state.checks.filter(Boolean).length;
    const fillEl = document.getElementById('cl-fill');
    const labelEl = document.getElementById('cl-label');
    if (fillEl) fillEl.style.width = (checked / _cfg.checkTotal * 100) + '%';
    if (labelEl) labelEl.textContent = checked + ' / ' + _cfg.checkTotal;
    if (checked === _cfg.checkTotal && !_state.done.includes(_cfg.total - 1))
      markDone(_cfg.total - 1);
  }

  /* ── Code copy ── */
  function copyCode(btn) {
    const pre = btn.closest('.code-block').querySelector('pre');
    navigator.clipboard.writeText(pre.innerText).then(() => {
      btn.textContent = 'copied!';
      setTimeout(() => btn.textContent = 'copy', 1500);
    });
  }

  /* ── Reset ── */
  function resetAll() {
    _state = { current: 0, done: [], correct: [], answered: [], checks: [] };
    saveState();
    document.querySelectorAll('.nav-item').forEach(i => i.classList.remove('done'));
    document.querySelectorAll('.kcheck-opt').forEach(o => {
      o.classList.remove('correct', 'wrong', 'reveal-correct', 'disabled');
      o.style.pointerEvents = '';
    });
    document.querySelectorAll('.kcheck-feedback').forEach(f => { f.className = 'kcheck-feedback'; f.textContent = ''; });
    document.querySelectorAll('.check-item').forEach(i => i.classList.remove('checked'));
    updateChecklist();
    updateProgress();
    goTo(0);
  }

  /* ── Restore persisted state on load ── */
  function restoreState() {
    _state.done.forEach(n => {
      const items = document.querySelectorAll('.nav-item');
      if (items[n]) items[n].classList.add('done');
    });
    _state.answered.forEach(idx => {
      const paneEl = document.getElementById('pane-' + idx);
      if (!paneEl) return;
      const opts = paneEl.querySelectorAll('.kcheck-opt');
      opts.forEach(o => { o.classList.add('disabled'); o.style.pointerEvents = 'none'; });
      const fbEl = document.getElementById('fb-' + idx);
      if (_state.correct.includes(idx)) {
        const co = Array.from(opts).find(o => o.getAttribute('onclick') && o.getAttribute('onclick').includes('true'));
        if (co) co.classList.add('correct');
        if (fbEl) { fbEl.className = 'kcheck-feedback show good'; fbEl.textContent = '✓ ' + _cfg.fb[idx].good; }
      } else {
        opts.forEach(o => {
          if (o.getAttribute('onclick') && o.getAttribute('onclick').includes('true'))
            o.classList.add('reveal-correct');
        });
        if (fbEl) { fbEl.className = 'kcheck-feedback show bad'; fbEl.textContent = '✗ ' + _cfg.fb[idx].bad; }
      }
    });
    _state.checks.forEach((v, i) => {
      if (v) {
        const items = document.querySelectorAll('.check-item');
        if (items[i]) items[i].classList.add('checked');
      }
    });
    updateChecklist();
    updateProgress();
    goTo(_state.current || 0);
  }

  /* ── Public API ── */
  window.initPage = function (config) {
    _cfg = config;
    _state = loadState();
    restoreState();
  };

  /* Expose functions called from inline HTML attributes */
  window.goTo       = function (n)              { goTo(n); };
  window.next       = function ()               { next(); };
  window.prev       = function ()               { prev(); };
  window.finish     = function ()               { finish(); };
  window.check      = function (btn, ok, idx)   { check(btn, ok, idx); };
  window.toggleCheck= function (el, idx)        { toggleCheck(el, idx); };
  window.copyCode   = function (btn)            { copyCode(btn); };
  window.resetAll   = function ()               { resetAll(); };

})();
