component extends="modules.BaseModule" {

    /**
     * markspresso Module
     * Subcommands:
     *   lucli markspresso create
     *   lucli markspresso build
     *   lucli markspresso watch
     *   lucli markspresso serve
     *   lucli markspresso new
     *   lucli markspresso pdf
     *   lucli markspresso geturl
     *   lucli markspresso previewtheme
     *   lucli markspresso previewallthemes
     */

    function init(
        boolean verboseEnabled = false,
        boolean timingEnabled = false,
        string cwd = "",
        any timer = nullValue()
    ) {
        super.init(argumentCollection=arguments);
        
        variables.verboseEnabled = arguments.verboseEnabled;
        variables.timingEnabled = arguments.timingEnabled;
        variables.cwd           = arguments.cwd;
        variables.timer         = arguments.timer ?: {};

        // Initialize services
        variables.configService     = new lib.ConfigService();
        variables.contentParser     = new lib.ContentParser();
        variables.fileService       = new lib.FileService();
        variables.navigationBuilder = new lib.NavigationBuilder();
        variables.lunrSearch        = new lib.LunrSearch(fileService = variables.fileService);
        variables.socialImageBuilder = new lib.SocialImageBuilder(fileService = variables.fileService);
        
        // Initialize builder with dependencies
        variables.builder = new lib.Builder(
            configService      = variables.configService,
            contentParser      = variables.contentParser,
            fileService        = variables.fileService,
            navigationBuilder  = variables.navigationBuilder,
            lunrSearch         = variables.lunrSearch,
            socialImageBuilder = variables.socialImageBuilder,
            cwd                = variables.cwd,
            timer              = variables.timer,
            outputCallback     = nullValue()
        );

        // Initialize PDF builder
        variables.pdfBuilder = new lib.PdfBuilder(
            configService = variables.configService,
            contentParser = variables.contentParser,
            fileService   = variables.fileService,
            cwd           = variables.cwd
        );

        return this;
    }

    // Called when you run just: lucli markspresso
    function main() {
        var fullCommand = getFullCommand();
        out("Markspresso – brew static sites from Markdown.");
        out("");
        out("Usage:");
        out("  #fullCommand# create        ## scaffold a new site in current dir");
        out("  #fullCommand# build         ## build Markdown -> HTML into public/");
        out("  #fullCommand# watch         ## watch for changes and auto-rebuild");
        out("  #fullCommand# serve         ## serve public/ over HTTP");
        out("  #fullCommand# new <type>    ## create new content (post, page, or configured collection)");
        out("  #fullCommand# pdf           ## generate PDF from docs collection");
        out("  #fullCommand# geturl        ## resolve the URL for a content file");
        out("  #fullCommand# previewtheme  ## switch theme in markspresso.json and optionally build");
        out("  #fullCommand# previewallthemes ## build all themes into comparison previews");
        return;
    }

    /**
     * lucli markspresso create
     *
     * Scaffolds a Markspresso site in the current working directory.
     *
     * Arguments (mapped from CLI flags):
     *   --name      -> name
     *   --baseUrl   -> baseUrl
     *   --force     -> force
     */
    function create(
        string  name    = "Markspresso Site",
        string  baseUrl = "http://localhost:3456",
        boolean force   = false
    ) {
        return variables.builder.createSite(
            name    = name,
            baseUrl = baseUrl,
            force   = force
        );
    }

/**
     * lucli markspresso build
     *   --src=content --out=public --clean --drafts
     */
    function build(
        string src    = "",
        string outDir = "",
        boolean clean = false,
        boolean drafts = false,
        string onlyRelPath = "",
        boolean dev = false
    ) {
        return variables.builder.buildSite(
            src         = src,
            outDir      = outDir,
            clean       = clean,
            drafts      = drafts,
            onlyRelPath = onlyRelPath,
            dev         = dev
        );
    }

    /**
     * lucli markspresso serve
     *   --port=3456 --watch
     */
    function serve(
        numeric port = 3456
    ) {

        
        out("Serving site on http://localhost:" & port);
        executeCommand("server", ["start", "--port=" & port]);
        // this can be done via executomeCommand("serve",  []);
        // 1. Start a simple HTTP server rooted at public/
        // 2. If watch=true, monitor content/ and layouts/ and trigger build on changes

        return;
    }

    function watch(
        numeric numberOfSeconds = 1,
        boolean dev=false
    ) {
        return variables.builder.watchSite(numberOfSeconds = arguments.numberOfSeconds, dev=arguments.dev);
    }

    /**
     * lucli markspresso new post "hello-world"
     * lucli markspresso new page about
     * lucli markspresso new doc "getting-started"
     *
     * The type can be "post", "page", or any collection key (singular form)
     * defined in markspresso.json (e.g. "doc" if a "docs" collection is configured).
     */
    function new(
        string type = "",
        string title = "",
        string slug = ""
    ) {
        return variables.builder.newContent(
            type  = type,
            title = title,
            slug  = slug
        );
    }

    /**
     * lucli markspresso pdf
     *   --rootPath=docs --outFile=mysite.pdf --drafts --toc
     *
     * Generates a PDF from the docs collection (excludes posts).
     */
    function pdf(
        string rootPath = "",
        string outFile  = "",
        boolean drafts  = false,
        boolean toc     = true
    ) {
        return variables.pdfBuilder.buildPdf(
            rootPath = arguments.rootPath,
            outFile  = arguments.outFile,
            drafts   = arguments.drafts,
            toc      = arguments.toc
        );
    }
    /**
     * lucli markspresso geturl content=posts/2025-12-30-managing-servers-with-lucli.md [pathOnly=true]
     *
     * Resolves the URL for a given content file relative to the configured
     * content directory.
     *
     * When pathOnly=true, prints just the canonical path (e.g. "/posts/foo/").
     * Otherwise prints baseUrl + canonical path when baseUrl is configured.
    */
    public void function geturl(string content = "", boolean pathOnly = false) {
        if (!len(arguments.content)) {
            out("Error: content path is required, e.g. content=posts/2025-12-30-managing-servers-with-lucli.md");
            return;
        }

        var url = variables.builder.getUrlForContent(
            relContentPath = content,
            pathOnly       = arguments.pathOnly
        );
        if (!len(url)) {
            out("Could not resolve URL for " & content);
            return;
        }

        out(url);
    }

    /**
     * lucli markspresso previewtheme [theme=retro-wave] [build=true]
     *
     * Updates markspresso.json with the selected theme. If theme is empty,
     * prints all available themes from site + module theme directories.
    */
    public void function previewtheme(string theme = "", boolean build = true) {
        var siteRootPath = getSiteRoot();
        var configPath = siteRootPath & "/markspresso.json";

        if (!fileExists(configPath)) {
            out("markspresso.json not found in " & siteRootPath);
            return;
        }

        var themes = listAvailableThemes(siteRootPath);
        if (!len(trim(arguments.theme))) {
            out("Available themes:");
            for (var themeName in themes) {
                out("  - " & themeName);
            }
            out("Usage: " & getFullCommand() & " previewtheme theme=<name> [build=true|false]");
            return;
        }

        var selectedTheme = trim(arguments.theme);
        if (!arrayContains(themes, selectedTheme)) {
            out("Theme '" & selectedTheme & "' not found.");
            out("Available themes:");
            for (var themeName in themes) {
                out("  - " & themeName);
            }
            return;
        }

        var config = {};
        try {
            config = deserializeJson(fileRead(configPath, "UTF-8"));
        }
        catch (any e) {
            out("Error reading markspresso.json: " & e.message);
            return;
        }

        config.theme = selectedTheme;
        fileWrite(configPath, serializeJson(var = config, compact = false), "UTF-8");
        out("Theme set to '" & selectedTheme & "' in markspresso.json");

        if (arguments.build) {
            variables.builder.buildSite();
        }
    }

    /**
     * lucli markspresso previewallthemes [baseOutDir=docs/_previews]
     *
     * Builds all available themes into isolated output paths and writes a
     * side-by-side iframe comparison index page.
    */
    public void function previewallthemes(string baseOutDir = "docs/_previews") {
        var siteRootPath = getSiteRoot();
        var configPath = siteRootPath & "/markspresso.json";

        if (!fileExists(configPath)) {
            out("markspresso.json not found in " & siteRootPath);
            return;
        }

        var themes = listAvailableThemes(siteRootPath);
        if (!arrayLen(themes)) {
            out("No themes found.");
            return;
        }

        var normalizedBaseOutDir = normalizePreviewOutDir(arguments.baseOutDir);
        var rawConfig = "";
        var config = {};

        try {
            rawConfig = fileRead(configPath, "UTF-8");
            config = deserializeJson(rawConfig);
        }
        catch (any e) {
            out("Error reading markspresso.json: " & e.message);
            return;
        }

        try {
            for (var themeName in themes) {
                var themeOutDir = normalizedBaseOutDir & "/" & themeName;
                out("Building preview for '" & themeName & "' -> " & themeOutDir);

                config.theme = themeName;
                if (!structKeyExists(config, "paths") or isNull(config.paths)) {
                    config.paths = {};
                }
                // Disable site layout overrides so preview uses theme layouts.
                config.paths.layouts = "__markspresso_theme_preview_no_site_layouts__";
                fileWrite(configPath, serializeJson(var = config, compact = false), "UTF-8");

                variables.builder.buildSite(
                    outDir = themeOutDir,
                    clean  = true
                );

                rewriteAbsoluteUrlsForThemePreview(
                    previewRootPath = siteRootPath & "/" & themeOutDir
                );
            }

            var previewIndexPath = siteRootPath & "/" & normalizedBaseOutDir & "/index.html";
            var previewIndexHtml = buildThemeComparisonIndexHtml(themes);
            fileWrite(previewIndexPath, previewIndexHtml, "UTF-8");

            out("Theme comparison index generated: " & normalizedBaseOutDir & "/index.html");
            out("Serve your docs output and open /_previews/index.html to compare themes.");
        }
        catch (any e) {
            out("Error generating theme previews: " & e.message);
        }
        finally {
            if (len(rawConfig)) {
                fileWrite(configPath, rawConfig, "UTF-8");
            }
        }
    }

    // --- Helper Functions ---

    function out(any message) {
        if (!isSimpleValue(arguments.message)) {
            arguments.message = serializeJson(var = arguments.message, compact = false);
        }
        // Keep direct CLI output available from Module for top-level commands.
        systemOutput(arguments.message, true, false);
    }

    function verbose(any message) {
        if (variables.verboseEnabled) {
            out(arguments.message);
        }
    }

    private string function getFullCommand() {
        var binaryName = "";
        if (structKeyExists(server, "system") && isStruct(server.system)) {
            if (structKeyExists(server.system, "lucli.binary.name")) {
                binaryName = lCase(trim(server.system["lucli.binary.name"]));
            } else if (
                structKeyExists(server.system, "properties")
                && isStruct(server.system.properties)
                && structKeyExists(server.system.properties, "lucli.binary.name")
            ) {
                binaryName = lCase(trim(server.system.properties["lucli.binary.name"]));
            }
        }
        if (!len(binaryName)) {
            binaryName = lCase(trim(createObject("java", "java.lang.System").getProperty("lucli.binary.name", "")));
        }

        if (binaryName == "markspresso") {
            return "markspresso";
        }

        return "lucli markspresso";
    }

    private string function getSiteRoot() {
        if (len(trim(variables.cwd ?: ""))) {
            return variables.cwd;
        }

        return getCurrentTemplatePath().reReplace("[/\\][^/\\]*$", "");
    }

    private string function getModuleRoot() {
        var modulePath = replace(getDirectoryFromPath(getCurrentTemplatePath()), "\\", "/", "all");
        return reReplace(modulePath, "/?$", "");
    }

    private array function listAvailableThemes(required string siteRootPath) {
        var seen = {};
        var names = [];
        var siteThemesDir = siteRootPath & "/themes";
        var moduleThemesDir = getModuleRoot() & "/themes";

        if (directoryExists(siteThemesDir)) {
            var siteDirs = directoryList(siteThemesDir, false, "name", "", "dir");
            for (var d in siteDirs) {
                if (!structKeyExists(seen, d)) {
                    seen[d] = true;
                    arrayAppend(names, d);
                }
            }
        }

        if (directoryExists(moduleThemesDir)) {
            var moduleDirs = directoryList(moduleThemesDir, false, "name", "", "dir");
            for (var d in moduleDirs) {
                if (!structKeyExists(seen, d)) {
                    seen[d] = true;
                    arrayAppend(names, d);
                }
            }
        }

        arraySort(names, "textnocase", "asc");
        return names;
    }

    private string function normalizePreviewOutDir(string p) {
        var outDir = trim(replace("" & (arguments.p ?: ""), "\\", "/", "all"));
        if (!len(outDir)) {
            return "docs/_previews";
        }

        while (left(outDir, 1) == "/") {
            outDir = mid(outDir, 2);
        }
        while (right(outDir, 1) == "/") {
            outDir = left(outDir, len(outDir) - 1);
        }

        if (!len(outDir)) {
            return "docs/_previews";
        }

        return outDir;
    }

    private void function rewriteAbsoluteUrlsForThemePreview(required string previewRootPath) {
        if (!directoryExists(previewRootPath)) {
            return;
        }

        var htmlFiles = directoryList(previewRootPath, true, "path", "*.html");
        for (var htmlPath in htmlFiles) {
            if (directoryExists(htmlPath)) {
                continue;
            }

            var html = fileRead(htmlPath, "UTF-8");
            var relPath = replace(mid(htmlPath, len(previewRootPath) + 2), "\\", "/", "all");
            var relDir = listLen(relPath, "/") > 1 ? listDeleteAt(relPath, listLen(relPath, "/"), "/") : "";
            var depth = len(relDir) ? listLen(relDir, "/") : 0;
            var rootPrefix = depth > 0 ? repeatString("../", depth) : "./";

            html = replace(html, 'href="/', 'href="' & rootPrefix, "all");
            html = replace(html, "href='/", "href='" & rootPrefix, "all");
            html = replace(html, 'src="/', 'src="' & rootPrefix, "all");
            html = replace(html, "src='/", "src='" & rootPrefix, "all");
            html = replace(html, 'action="/', 'action="' & rootPrefix, "all");
            html = replace(html, "action='/", "action='" & rootPrefix, "all");
            html = replace(html, 'poster="/', 'poster="' & rootPrefix, "all");
            html = replace(html, "poster='/", "poster='" & rootPrefix, "all");
            html = replace(html, 'url("/', 'url("' & rootPrefix, "all");
            html = replace(html, "url('/", "url('" & rootPrefix, "all");

            fileWrite(htmlPath, html, "UTF-8");
        }
    }

    private string function buildThemeComparisonIndexHtml(required array themes) {
        var cards = "";

        for (var themeName in themes) {
            var safeTheme = htmlEditFormat(themeName);
            cards &= '<article class="theme-card">' & chr(10)
                & '  <header class="theme-card-header">' & chr(10)
                & '    <h2>' & safeTheme & '</h2>' & chr(10)
                & '    <a href="./' & safeTheme & '/" target="_blank" rel="noreferrer">Open full preview ↗</a>' & chr(10)
                & '  </header>' & chr(10)
                & '  <iframe src="./' & safeTheme & '/" loading="lazy" title="Preview ' & safeTheme & '"></iframe>' & chr(10)
                & '</article>' & chr(10);
        }

        return '<!doctype html>' & chr(10)
            & '<html lang="en">' & chr(10)
            & '<head>' & chr(10)
            & '  <meta charset="utf-8">' & chr(10)
            & '  <meta name="viewport" content="width=device-width, initial-scale=1">' & chr(10)
            & '  <title>Markspresso Theme Previews</title>' & chr(10)
            & '  <style>' & chr(10)
            & '    :root { color-scheme: dark; }' & chr(10)
            & '    body { margin: 0; font-family: Inter, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; background: ##0b1020; color: ##d9e1f2; }' & chr(10)
            & '    .page { max-width: 1600px; margin: 0 auto; padding: 1.2rem; }' & chr(10)
            & '    h1 { margin: 0 0 0.5rem; font-size: 1.5rem; }' & chr(10)
            & '    p { margin: 0 0 1rem; color: ##95a3c5; }' & chr(10)
            & '    .grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(480px, 1fr)); gap: 1rem; }' & chr(10)
            & '    .theme-card { border: 1px solid ##223158; border-radius: 0.75rem; overflow: hidden; background: ##101833; }' & chr(10)
            & '    .theme-card-header { display: flex; justify-content: space-between; align-items: center; gap: 0.8rem; padding: 0.7rem 0.9rem; border-bottom: 1px solid ##223158; background: ##121d3d; }' & chr(10)
            & '    .theme-card-header h2 { margin: 0; font-size: 0.95rem; font-weight: 600; }' & chr(10)
            & '    .theme-card-header a { color: ##9ec0ff; text-decoration: none; font-size: 0.82rem; }' & chr(10)
            & '    .theme-card-header a:hover { text-decoration: underline; }' & chr(10)
            & '    iframe { display: block; width: 100%; height: 620px; border: 0; background: ##fff; }' & chr(10)
            & '    @media (max-width: 560px) { .grid { grid-template-columns: 1fr; } iframe { height: 480px; } }' & chr(10)
            & '  </style>' & chr(10)
            & '</head>' & chr(10)
            & '<body>' & chr(10)
            & '  <main class="page">' & chr(10)
            & '    <h1>Markspresso Theme Comparison</h1>' & chr(10)
            & '    <p>Each preview is rendered from the same content with a different theme.</p>' & chr(10)
            & '    <section class="grid">' & chr(10)
            & cards
            & '    </section>' & chr(10)
            & '  </main>' & chr(10)
            & '</body>' & chr(10)
            & '</html>';
    }

}
