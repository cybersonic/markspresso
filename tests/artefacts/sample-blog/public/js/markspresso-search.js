(function () {
  // Simple loader for external scripts (used to pull in Lunr from CDN)
  function loadScript(src, callback) {
    var s = document.createElement('script');
    s.src = src;
    s.async = true;
    s.onload = function () { callback && callback(); };
    s.onerror = function () {
      console.error('Markspresso search: failed to load script', src);
    };
    document.head.appendChild(s);
  }

  function initSearch() {
    if (typeof window === 'undefined') return;

    var docs = window.MarkspressoSearchDocs || [];
    if (!docs.length) {
      // No search documents available for this site/build
      return;
    }

    if (typeof lunr === 'undefined') {
      console.error('Markspresso search: lunr is not available');
      return;
    }

    var idx = lunr(function () {
      this.ref('url');
      this.field('title', { boost: 10 });
      this.field('body');

      docs.forEach(function (doc) {
        this.add(doc);
      }, this);
    });

    var input = document.getElementById('markspresso-search-input');
    var resultsEl = document.getElementById('markspresso-search-results');

    if (!input || !resultsEl) {
      // Page does not provide a search UI; nothing to wire up.
      return;
    }

    function renderResults(results) {
      if (!results.length) {
        resultsEl.innerHTML = '';
        return;
      }

      var html = '';
      results.slice(0, 20).forEach(function (res) {
        var doc = docs.find(function (d) { return d.url === res.ref; });
        if (!doc) return;

        html += '<div class="markspresso-search-result">';
        html +=   '<a href="' + doc.url + '">';
        html +=     (doc.title || doc.url);
        html +=   '</a>';
        html += '</div>';
      });

      resultsEl.innerHTML = html;
    }

    input.addEventListener('input', function (e) {
      var q = (e.target.value || '').trim();
      if (!q) {
        resultsEl.innerHTML = '';
        return;
      }

      try {
        var results = idx.search(q);
        renderResults(results);
      } catch (err) {
        console.error('Markspresso search: error executing search', err);
      }
    });
  }

  function ensureLunrAndInit() {
    if (typeof lunr !== 'undefined') {
      initSearch();
      return;
    }

    // Load Lunr from a CDN if it is not already present on the page.
    loadScript('https://unpkg.com/lunr/lunr.js', function () {
      if (typeof lunr === 'undefined') {
        console.error('Markspresso search: lunr failed to load');
        return;
      }
      initSearch();
    });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', ensureLunrAndInit);
  } else {
    ensureLunrAndInit();
  }
})();
