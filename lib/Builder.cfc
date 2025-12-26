component {

    /**
     * Builder
     * Orchestrates site scaffolding, building, and watching.
     * Coordinates ConfigService, ContentParser, and FileService.
     */

    function init(
        required any configService,
        required any contentParser,
        required any fileService,
        required any navigationBuilder,
        string cwd = "",
        any timer = nullValue(),
        any outputCallback = nullValue()
    ) {
        variables.configService = arguments.configService;
        variables.contentParser = arguments.contentParser;
        variables.fileService   = arguments.fileService;
        variables.navigationBuilder = arguments.navigationBuilder;
        variables.cwd           = arguments.cwd;
        variables.timer         = arguments.timer ?: {};
        variables.outputCallback = arguments.outputCallback;
        
        return this;
    }

    // --- Public API ---

    /**
     * Scaffold a new Markspresso site in the site root.
     */
    public void function createSite(
        string  name    = "Markspresso Site",
        string  baseUrl = "http://localhost:8080",
        boolean force   = false
    ) {
        var rootDir    = siteRoot();
        var configPath = rootDir & "/markspresso.json";

        // Safety: don't overwrite an existing config unless --force
        if (fileExists(configPath) AND !force) {
            out("markspresso.json already exists. Use --force to overwrite.");
            return;
        }

        // Ensure directories
        var contentDir = rootDir & "/content";
        var layoutsDir = rootDir & "/layouts";
        var assetsDir  = rootDir & "/assets";
        var outputDir  = rootDir & "/public";
        var postsDir   = contentDir & "/posts";

        variables.fileService.ensureDir(contentDir);
        variables.fileService.ensureDir(layoutsDir);
        variables.fileService.ensureDir(assetsDir);
        variables.fileService.ensureDir(outputDir);
        variables.fileService.ensureDir(postsDir);

        // Write markspresso.json
        var config = variables.configService.getDefaultConfig(name, baseUrl);
        fileWrite(configPath, serializeJson(var = config, compact = false), "UTF-8");

        // Write lucee.json for LuCLI server
        var luceeConfigPath = rootDir & "/lucee.json";
        var luceeConfig = {
            "name": name,
            "webroot": "./" & config.paths.output,
            "openBrowser": true,
            "enableLucee": false
        };
        variables.fileService.writeFileIfMissing(luceeConfigPath, serializeJson(var = luceeConfig, compact = false), force);

        // Starter content/index.md
        var indexMd = "---" & chr(10) &
                      "title: Home" & chr(10) &
                      "layout: page" & chr(10) &
                      "---" & chr(10) & chr(10) &
                      "## Welcome to " & name & chr(10) & chr(10) &
                      "This site was brewed with Markspresso." & chr(10) & chr(10) &
                      "## Latest posts" & chr(10) & chr(10) &
                      "{{ latest_posts }}" & chr(10);
        variables.fileService.writeFileIfMissing(contentDir & "/index.md", indexMd, force);

        // Starter posts/hello-world.md
        var helloPost = "---" & chr(10) &
                        "title: Hello, world" & chr(10) &
                        "layout: post" & chr(10) &
                        "draft: true" & chr(10) &
                        "---" & chr(10) & chr(10) &
                        "This is your first Markspresso post." & chr(10);
        variables.fileService.writeFileIfMissing(postsDir & "/hello-world.md", helloPost, force);

        // Basic layouts
        var pageLayout = '<!doctype html>' & chr(10) &
                         '<html>' & chr(10) &
                         '  <head>' & chr(10) &
                         '    <meta charset="utf-8">' & chr(10) &
                         '    <title>{{ title }}</title>' & chr(10) &
                         '    <style>' & chr(10) &
                         '      body { display: flex; margin: 0; font-family: sans-serif; }' & chr(10) &
                         '      .docs-nav { width: 250px; padding: 1rem; background: ##f5f5f5; border-right: 1px solid ##ddd; }' & chr(10) &
                         '      .docs-nav ul { list-style: none; padding-left: 0; }' & chr(10) &
                         '      .docs-nav ul ul { padding-left: 1rem; }' & chr(10) &
                         '      .docs-nav li.active > a { font-weight: bold; color: ##0066cc; }' & chr(10) &
                         '      main { flex: 1; padding: 2rem; max-width: 900px; }' & chr(10) &
                         '    </style>' & chr(10) &
                         '  </head>' & chr(10) &
                         '  <body>' & chr(10) &
                         '    {{ navigation }}' & chr(10) &
                         '    <main>' & chr(10) &
                         '      {{ content }}' & chr(10) &
                         '    </main>' & chr(10) &
                         '  </body>' & chr(10) &
                         '</html>' & chr(10);
        variables.fileService.writeFileIfMissing(layoutsDir & "/page.html", pageLayout, force);

        var postLayout = '<!doctype html>' & chr(10) &
                         '<html>' & chr(10) &
                         '  <head>' & chr(10) &
                         '    <meta charset="utf-8">' & chr(10) &
                         '    <title>{{ title }}</title>' & chr(10) &
                         '    <style>' & chr(10) &
                         '      body { display: flex; margin: 0; font-family: sans-serif; }' & chr(10) &
                         '      .docs-nav { width: 250px; padding: 1rem; background: ##f5f5f5; border-right: 1px solid ##ddd; }' & chr(10) &
                         '      .docs-nav ul { list-style: none; padding-left: 0; }' & chr(10) &
                         '      .docs-nav ul ul { padding-left: 1rem; }' & chr(10) &
                         '      .docs-nav li.active > a { font-weight: bold; color: ##0066cc; }' & chr(10) &
                         '      article { flex: 1; padding: 2rem; max-width: 900px; }' & chr(10) &
                         '    </style>' & chr(10) &
                         '  </head>' & chr(10) &
                         '  <body>' & chr(10) &
                         '    {{ navigation }}' & chr(10) &
                         '    <article>' & chr(10) &
                         '      <h1>{{ title }}</h1>' & chr(10) &
                         '      {{ content }}' & chr(10) &
                         '    </article>' & chr(10) &
                         '  </body>' & chr(10) &
                         '</html>' & chr(10);
        variables.fileService.writeFileIfMissing(layoutsDir & "/post.html", postLayout, force);

        out("Markspresso site created in " & rootDir);
    }

    /**
     * Build the site into the output directory.
     */
    public void function buildSite(
        string src    = "",
        string outDir = "",
        boolean clean = false,
        boolean drafts = false,
        string onlyRelPath = ""
    ) {
        var onlyRelPathLower = lcase(onlyRelPath);
        
        out("Building site...");
        if (structKeyExists(variables.timer, "start")) {
            variables.timer.start("markspresso-build");
        }

        var rootDir = siteRoot();
        var config  = variables.configService.load(rootDir);

        // Resolve paths (CLI args override config.paths)
        var contentDir = rootDir & "/" & (len(src) ? src : config.paths.content);
        var outputDir  = rootDir & "/" & (len(outDir) ? outDir : config.paths.output);
        var layoutsDir = rootDir & "/" & config.paths.layouts;
        var assetsDir  = rootDir & "/" & config.paths.assets;

        var prettyUrls    = config.build.prettyUrls;
        var includeDrafts = drafts ? true : config.build.includeDrafts;

        out("Building site from " & contentDir & " -> " & outputDir);

        if (!directoryExists(contentDir)) {
            out("Content directory not found: " & contentDir);
            return;
        }

        // Clean output if requested
        if (clean AND directoryExists(outputDir)) {
            directoryDelete(outputDir, true);
        }
        variables.fileService.ensureDir(outputDir);

        // Copy assets (if any)
        if (directoryExists(assetsDir)) {
            variables.fileService.copyAssets(assetsDir, outputDir);
        }

        // First pass: parse all docs and collect metadata
        var files           = variables.fileService.discoverMarkdownFiles(contentDir);
        var docs            = [];
        var postsCollection = [];
        var docUrlMap       = {};
        var dirsWithIndex   = {};

        // Pre-scan for index.md per directory so we can treat README.md as index when needed
        for (var scanPath in files) {
            var scanName = lcase(getFileFromPath(scanPath));
            if (scanName != "index.md") {
                continue;
            }

            var scanRel       = replace(mid(scanPath, len(contentDir) + 2), "\\", "/", "all");
            var partsCount    = listLen(scanRel, "/");
            var scanRelDir    = (partsCount GT 1 ? listDeleteAt(scanRel, partsCount, "/") : "");
            var scanRelDirKey = lcase(scanRelDir);
            dirsWithIndex[scanRelDirKey] = true;
        }

        // Parse all markdown files
        for (var filePath in files) {
            var parsed = variables.contentParser.parseMarkdownFile(filePath, includeDrafts);
            if (isNull(parsed)) {
                continue; // skipped (likely draft)
            }

            var relPath = replace(mid(filePath, len(contentDir) + 2), "\\", "/", "all");

            // Treat README.md as index.md when there is no explicit index.md in that folder
            var fileNameLower = lcase(getFileFromPath(filePath));
            var dirPartsCount = listLen(relPath, "/");
            var relDir        = (dirPartsCount GT 1 ? listDeleteAt(relPath, dirPartsCount, "/") : "");
            var relDirKey     = lcase(relDir);

            if (fileNameLower == "readme.md" and !structKeyExists(dirsWithIndex, relDirKey)) {
                relPath = len(relDir) ? (relDir & "/index.md") : "index.md";
            }

            var collectionName = findCollectionNameForRelPath(config, relPath);

            var dateInfo = {};
            if (len(collectionName) and collectionName == "posts") {
                var relNoExt = reReplace(relPath, "\.[^.]+$", "");
                dateInfo = deriveDateSlugFromRelPath(relNoExt);

                if (structCount(dateInfo) and !structKeyExists(parsed.meta, "date")) {
                    parsed.meta.date = dateInfo.year & "-" & dateInfo.month & "-" & dateInfo.day;
                }
            }

            var layoutName = determineLayoutName(config, parsed.meta, collectionName);

            var doc = {
                filePath       = filePath,
                relPath        = relPath,
                collectionName = collectionName,
                dateInfo       = dateInfo,
                meta           = parsed.meta,
                html           = parsed.html,
                layoutName     = layoutName,
                canonicalUrl   = ""
            };

            var canonicalUrl = computeCanonicalUrl(outputDir, relPath, doc.meta, prettyUrls, collectionName, dateInfo);

            doc.canonicalUrl = canonicalUrl;
            if (len(canonicalUrl)) {
                docUrlMap[lcase(relPath)] = canonicalUrl;
            }

            arrayAppend(docs, doc);

            // Build posts collection
            if (len(collectionName) and collectionName == "posts") {
                var postDate = "";
                if (structKeyExists(doc.meta, "date")) {
                    postDate = doc.meta.date;
                }
                else if (structCount(dateInfo)) {
                    postDate = dateInfo.year & "-" & dateInfo.month & "-" & dateInfo.day;
                }

                if (len(canonicalUrl) and len(postDate)) {
                    var postTitle = (structKeyExists(doc.meta, "title") and len(doc.meta.title))
                        ? doc.meta.title
                        : (structCount(dateInfo) ? dateInfo.slug : relPath);

                    arrayAppend(postsCollection, {
                        title = postTitle,
                        date  = postDate,
                        url   = canonicalUrl
                    });
                }
            }
        }

        // Sort posts collection by date (newest first)
        if (arrayLen(postsCollection) GT 1) {
            arraySort(postsCollection, function(a, b) {
                if (a.date == b.date) {
                    return compare(a.title, b.title);
                }
                return compare(b.date, a.date);
            });
        }

        // Determine if index needs rebuilding for incremental builds
        var rebuildIndex = false;
        if (len(onlyRelPathLower)) {
            for (var d in docs) {
                if (lcase(d.relPath) == onlyRelPathLower and len(d.collectionName) and d.collectionName == "posts") {
                    rebuildIndex = true;
                    break;
                }
            }
        }

        // Second pass: render and write output files
        var builtCount = 0;

        for (var i = 1; i <= arrayLen(docs); i++) {
            var doc = docs[i];

            // Skip files not targeted for incremental builds
            if (len(onlyRelPathLower)) {
                var docRelLower = lcase(doc.relPath);
                if (docRelLower != onlyRelPathLower) {
                    if (!(rebuildIndex and docRelLower == "index.md")) {
                        continue;
                    }
                }
            }

            var effectiveMeta = duplicate(doc.meta);

            // Inject latest posts for index page
            if (lcase(doc.relPath) == "index.md" and arrayLen(postsCollection)) {
                effectiveMeta.latest_posts = renderLatestPostsHtml(postsCollection, 5);
            }

            // Inject navigation HTML
            var navRootPath = structKeyExists(config, "navigation") && structKeyExists(config.navigation, "rootPath") 
                ? config.navigation.rootPath 
                : "";
            effectiveMeta.navigation = variables.navigationBuilder.buildNavigation(
                docs = docs,
                currentRelPath = doc.relPath,
                rootPath = navRootPath
            );

            var layoutPath = layoutsDir & "/" & doc.layoutName & ".html";
            var layoutHtml = fileExists(layoutPath) ? fileRead(layoutPath, "UTF-8") : "{{ content }}";

            var rewrittenContent = variables.contentParser.rewriteLinks(doc.html, doc.relPath, docUrlMap);

            var finalHtml = variables.contentParser.applyLayout(layoutHtml, effectiveMeta, rewrittenContent);

            var outPaths = computeOutputPathsForFile(
                config,
                doc.relPath,
                effectiveMeta,
                outputDir,
                prettyUrls,
                doc.collectionName,
                doc.dateInfo
            );

            for (var outPath in outPaths) {
                variables.fileService.ensureDir(getDirectoryFromPath(outPath));
                fileWrite(outPath, finalHtml, "UTF-8");
            }

            builtCount++;
        }

        out("Built " & builtCount & " Markdown file(s) into " & outputDir);
        
        if (structKeyExists(variables.timer, "stop")) {
            variables.timer.stop("markspresso-build");
        }
    }

    /**
     * Watch content/layouts/assets and trigger incremental builds.
     */
    public void function watchSite(numeric numberOfSeconds = 1) {
        var rootDir = siteRoot();
        var config  = variables.configService.load(rootDir);

        var contentDir = rootDir & "/" & config.paths.content;
        var layoutsDir = rootDir & "/" & config.paths.layouts;
        var assetsDir  = rootDir & "/" & config.paths.assets;
        var outputDir  = rootDir & "/" & config.paths.output;

        out("Watching for changes in:");
        out("  content: " & contentDir);
        out("  layouts: " & layoutsDir);
        out("  assets : " & assetsDir);

        var prevContentSnapshot = variables.fileService.snapshotContentFiles(contentDir, layoutsDir, assetsDir);
        var prevLayoutSnapshot  = variables.fileService.snapshotFiles(layoutsDir);
        var prevAssetSnapshot   = variables.fileService.snapshotFiles(assetsDir);

        buildSite();

        while (true) {
            sleep(numberOfSeconds * 1000);

            var currentContentSnapshot = variables.fileService.snapshotContentFiles(contentDir, layoutsDir, assetsDir);
            var currentLayoutSnapshot  = variables.fileService.snapshotFiles(layoutsDir);
            var currentAssetSnapshot   = variables.fileService.snapshotFiles(assetsDir);

            var changedLayouts = variables.fileService.diffSnapshots(prevLayoutSnapshot, currentLayoutSnapshot);
            var changedContent = variables.fileService.diffSnapshots(prevContentSnapshot, currentContentSnapshot);
            var changedAssets  = variables.fileService.diffSnapshots(prevAssetSnapshot, currentAssetSnapshot);

            if (!arrayLen(changedLayouts) and !arrayLen(changedContent) and !arrayLen(changedAssets)) {
                continue;
            }

            if (arrayLen(changedLayouts)) {
                out(arrayLen(changedLayouts) & " layout change(s) detected – rebuilding full site...");
                buildSite();
            }
            else {
                if (arrayLen(changedAssets)) {
                    out(arrayLen(changedAssets) & " asset change(s) detected – copying assets...");
                    if (directoryExists(assetsDir)) {
                        variables.fileService.copyAssets(assetsDir, outputDir);
                    }
                }

                for (var changedPath in changedContent) {
                    var relPath = replace(mid(changedPath, len(contentDir) + 2), "\\", "/", "all");
                    out("Content change detected: " & relPath & " – rebuilding...");
                    buildSite(onlyRelPath = relPath);
                }
            }

            prevContentSnapshot = currentContentSnapshot;
            prevLayoutSnapshot  = currentLayoutSnapshot;
            prevAssetSnapshot   = currentAssetSnapshot;
        }
    }

    /**
     * Create new content (placeholder for future implementation).
     */
    public void function newContent(string type, string title = "", string slug = "") {
        // TODO: Implement content creation
        out("Creating new " & type & " is not yet implemented.");
    }

    // --- Private Helper Functions ---

    private string function siteRoot() {
        return variables.cwd.len() ? variables.cwd : getCurrentTemplatePath().reReplace("[/\\][^/\\]*$", "");
    }

    /**
     * Strip numeric prefixes from path segments.
     * Example: "010_getting-started/020_intro.md" -> "getting-started/intro.md"
     */
    private string function stripNumericPrefixes(string path) {
        var normalized = replace(path, "\\", "/", "all");
        var parts = listToArray(normalized, "/");
        var cleanedParts = [];

        for (var part in parts) {
            // Remove numeric prefix pattern: 1-4 digits followed by underscore
            var cleanPart = reReplace(part, "^\d{1,4}_", "");
            arrayAppend(cleanedParts, cleanPart);
        }

        return arrayToList(cleanedParts, "/");
    }

    private void function out(any message) {
        if (!isNull(variables.outputCallback)) {
            variables.outputCallback(message);
        }
        else {
            if (!isSimpleValue(message)) {
                message = serializeJson(var = message, compact = false);
            }
            systemOutput(message, true, false);
        }
    }

    private string function findCollectionNameForRelPath(struct config, string relPath) {
        if (!structKeyExists(config, "collections") or isNull(config.collections)) {
            return "";
        }

        var normalizedRel = replace(relPath, "\\", "/", "all");

        for (var name in config.collections) {
            var col = config.collections[name];
            if (!structKeyExists(col, "path") or !len(col.path)) {
                continue;
            }

            var colPath = replace(col.path, "\\", "/", "all");

            if (left(normalizedRel, len(colPath)) == colPath
                and (len(normalizedRel) == len(colPath) or mid(normalizedRel, len(colPath) + 1, 1) == "/")) {
                return name;
            }
        }

        return "";
    }

    private struct function deriveDateSlugFromRelPath(string relPathNoExt) {
        var result = {};

        var normalized = replace(relPathNoExt, "\\", "/", "all");
        var filenamePart = listLast(normalized, "/");

        if (listLen(filenamePart, "-") < 4) {
            return result;
        }

        var year  = listGetAt(filenamePart, 1, "-");
        var month = listGetAt(filenamePart, 2, "-");
        var day   = listGetAt(filenamePart, 3, "-");

        if (!isNumeric(year) or len(year) != 4 or !isNumeric(month) or len(month) != 2 or !isNumeric(day) or len(day) != 2) {
            return result;
        }

        var slugStart = len(year) + 1 + len(month) + 1 + len(day) + 1;
        if (slugStart GT len(filenamePart)) {
            return result;
        }

        var slug = mid(filenamePart, slugStart);
        if (!len(slug)) {
            return result;
        }

        result.year  = year;
        result.month = month;
        result.day   = day;
        result.slug  = slug;
        return result;
    }

    private string function determineLayoutName(struct config, struct meta, string collectionName) {
        if (structKeyExists(meta, "layout") and len(meta.layout)) {
            return meta.layout;
        }
        else if (len(collectionName)
                 and structKeyExists(config, "collections")
                 and structKeyExists(config.collections, collectionName)
                 and structKeyExists(config.collections[collectionName], "layout")
                 and len(config.collections[collectionName].layout)) {
            return config.collections[collectionName].layout;
        }
        else {
            return config.build.defaultLayout;
        }
    }

    private string function computeOutputPath(string outputDir, string relPath, boolean prettyUrls) {
        relPath = replace(relPath, "\\", "/", "all");
        
        // Strip numeric prefixes from path segments
        relPath = stripNumericPrefixes(relPath);
        
        var noExt = reReplace(relPath, "\.[^.]+$", "");
        var isIndex = listLast(noExt, "/") == "index";

        if (prettyUrls) {
            if (isIndex) {
                return outputDir & "/" & noExt & ".html";
            }
            return outputDir & "/" & noExt & "/index.html";
        }
        else {
            return outputDir & "/" & noExt & ".html";
        }
    }

    private array function computeOutputPathsForFile(
        struct config,
        string relPath,
        struct meta,
        string outputDir,
        boolean prettyUrls,
        string collectionName,
        struct dateInfo
    ) {
        var paths = [];
        var seen  = {};

        var basePath = computeOutputPath(outputDir, relPath, prettyUrls);
        seen[basePath] = true;
        arrayAppend(paths, basePath);

        if (len(collectionName) and collectionName == "posts" and structCount(dateInfo)) {
            var datePath = outputDir & "/" & dateInfo.year & "/" & dateInfo.month & "/" & dateInfo.day & "/" & dateInfo.slug & ".html";
            if (!structKeyExists(seen, datePath)) {
                seen[datePath] = true;
                arrayAppend(paths, datePath);
            }
        }

        if (structKeyExists(meta, "permalink") and len(trim(meta.permalink))) {
            var permalink = trim(meta.permalink);

            while (len(permalink) and left(permalink, 1) == "/") {
                permalink = mid(permalink, 2);
            }
            while (len(permalink) and right(permalink, 1) == "/") {
                permalink = left(permalink, len(permalink) - 1);
            }

            if (len(permalink)) {
                var permalinkPath = outputDir & "/" & permalink & "/index.html";
                if (!structKeyExists(seen, permalinkPath)) {
                    seen[permalinkPath] = true;
                    arrayAppend(paths, permalinkPath);
                }
            }
        }

        return paths;
    }

    private string function computeCanonicalUrl(
        string outputDir,
        string relPath,
        struct meta,
        boolean prettyUrls,
        string collectionName,
        struct dateInfo
    ) {
        if (structKeyExists(meta, "permalink") and len(trim(meta.permalink))) {
            var p = trim(meta.permalink);

            while (len(p) and left(p, 1) == "/") {
                p = mid(p, 2);
            }
            while (len(p) and right(p, 1) == "/") {
                p = left(p, len(p) - 1);
            }

            if (!len(p)) {
                return "/";
            }
            return "/" & p & "/";
        }

        if (len(collectionName) and collectionName == "posts" and structCount(dateInfo)) {
            return "/" & dateInfo.year & "/" & dateInfo.month & "/" & dateInfo.day & "/" & dateInfo.slug & ".html";
        }

        var path = computeOutputPath(outputDir, relPath, prettyUrls);
        path = replace(path, "\\", "/", "all");
        var outDirNorm = replace(outputDir, "\\", "/", "all");

        if (left(path, len(outDirNorm)) == outDirNorm) {
            path = mid(path, len(outDirNorm) + 1);
        }

        if (!len(path)) {
            return "/";
        }

        if (left(path, 1) != "/") {
            path = "/" & path;
        }

        if (right(path, 11) == "/index.html") {
            return left(path, len(path) - 10);
        }

        return path;
    }

    private string function renderLatestPostsHtml(array posts, numeric maxCount=5) {
        var html = '<ul>';

        var limit = min(maxCount, arrayLen(posts));
        for (var i = 1; i <= limit; i++) {
            var p = posts[i];
            var title = structKeyExists(p, 'title') ? p.title : '';
            var url   = structKeyExists(p, 'url')   ? p.url   : '';

            if (!len(url)) {
                continue;
            }

            html &= '<li><a href="' & htmlEditFormat(url) & '">' & htmlEditFormat(title) & '</a></li>';
        }

        html &= '</ul>';
        return html;
    }

}
