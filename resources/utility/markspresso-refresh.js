(function () {
  const POLL_INTERVAL = 1000; // ms
  let lastBuildId = null;

  async function checkReload() {
    try {
      const res = await fetch('/__markspresso_reload.json?cb=' + Date.now(), {
        cache: 'no-store'
      });
      if (!res.ok) {
        setTimeout(checkReload, POLL_INTERVAL);
        return;
      }

      const data = await res.json();
      if (lastBuildId === null) {
        lastBuildId = data.buildId;
      } else if (data.buildId !== lastBuildId) {
        console.info("Content changed. Reloading")
        location.reload();
        return;
      }
    } catch (e) {
      // ignore in dev, just keep polling
    }
    setTimeout(checkReload, POLL_INTERVAL);
  }

  checkReload();
})();