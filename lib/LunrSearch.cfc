component {

    /**
     * LunrSearch
     * Builds client-side search data and makes Markspresso search scripts
     * available to layouts when enabled via markspresso.json.
     */

    public any function init(required any fileService) {
        variables.fileService = arguments.fileService;
        return this;
    }

    /**
     * Build search data file and ensure JS assets are present in the output dir.
     */
    public void function build(
        required struct config,
        required array  docs,
        required string outputDir
    ) {
        if (!isLunrEnabled(config)) {
            return;
        }

        var lunrCfg = config.search.lunr;

        buildDataFile(
            docs      = docs,
            outputDir = outputDir,
            dataRel   = lunrCfg.dataJs
        );

        ensureAssets(
            outputDir = outputDir,
            searchRel = lunrCfg.searchJs
        );
    }

    /**
     * Return HTML <script> tags for inclusion in layouts.
     * Intended to be exposed as {{ markspressoScripts }} in HTML layouts
     * and as the markspressoScripts variable in CFML layouts.
     */
    public string function getScriptHtml(required struct config) {
        if (!isLunrEnabled(config)) {
            return "";
        }

        var lunrCfg = config.search.lunr;

        // Paths are relative to the site root as seen by the browser.
        // We emit data first so search JS can immediately access MarkspressoSearchDocs.
        var scripts = [];
        arrayAppend(scripts, '<script src="/' & lunrCfg.dataJs & '"></script>');
        arrayAppend(scripts, '<script src="/' & lunrCfg.searchJs & '"></script>');

        return arrayToList(scripts, chr(10));
    }

    // --- Internal helpers ---

    private boolean function isLunrEnabled(required struct config) {
        if (!structKeyExists(config, "search") or isNull(config.search)) return false;
        if (!structKeyExists(config.search, "lunr") or isNull(config.search.lunr)) return false;
        return !!config.search.lunr.enabled;
    }

    /**
     * Build the JS data file that exposes window.MarkspressoSearchDocs.
     */
    private void function buildDataFile(
        required array  docs,
        required string outputDir,
        required string dataRel
    ) {
        var dataAbs = outputDir & "/" & dataRel;
        var searchDocs = [];

        for (var d in docs) {
            if (!structKeyExists(d, "canonicalUrl") or !len(d.canonicalUrl)) {
                continue;
            }

            var title = "";
            if (structKeyExists(d, "meta") and structKeyExists(d.meta, "title") and len(d.meta.title)) {
                title = d.meta.title;
            }
            else {
                var fileName = listLast(d.relPath, "/");
                title = reReplace(fileName, "\\.[^.]+$", "");
                title = replace(title, "-", " ", "all");
                title = replace(title, "_", " ", "all");
            }

            var body = d.html ?: "";
            body = reReplace(body, "<[^>]+>", " ", "all");
            body = reReplace(body, "\s+", " ", "all");
            body = trim(body);
            if (len(body) > 20000) body = left(body, 20000);

            // Use canonicalUrl directly; avoid a local variable named "url" to
            // prevent any interaction with the built-in URL scope.
            arrayAppend(searchDocs, {
                "url"   = d.canonicalUrl,
                "title" = title,
                "body"  = body
            });
        }

        var json = serializeJson(searchDocs, false);
        var jsContent = "window.MarkspressoSearchDocs = " & json & ";";

        variables.fileService.ensureDir( getDirectoryFromPath(dataAbs) );
        fileWrite(dataAbs, jsContent, "UTF-8");
    }

    /**
     * Ensure the Markspresso search JS is present in the output tree.
     * This JS is responsible for loading Lunr (via CDN) and wiring up the UI.
     */
    private void function ensureAssets(
        required string outputDir,
        required string searchRel
    ) {
        var moduleRoot = getDirectoryFromPath( getCurrentTemplatePath() );

        var srcSearch = moduleRoot & "/../resources/utility/markspresso-search.js";
        var destSearch = outputDir & "/" & searchRel;

        variables.fileService.ensureDir( getDirectoryFromPath(destSearch) );

        if (fileExists(srcSearch)) {
            fileCopy(srcSearch, destSearch);
        }
    }

}
