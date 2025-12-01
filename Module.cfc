component extends="modules.BaseModule" {

    /**
     * markspresso Module
     * Subcommands:
     *   lucli markspresso create
     *   lucli markspresso build
     *   lucli markspresso serve
     *   lucli markspresso new
     */

    function init(
        boolean verboseEnabled = false,
        boolean timingEnabled = false,
        string cwd = "",
        any timer = nullValue()
    ) {
        variables.verboseEnabled = arguments.verboseEnabled;
        variables.timingEnabled = arguments.timingEnabled;
        variables.cwd           = arguments.cwd;
        variables.timer         = arguments.timer ?: {};
        return this;
    }

    // Called when you run just: lucli markspresso
    function main() {
        out("Markspresso – brew static sites from Markdown.");
        out("");
        out("Usage:");
        out("  lucli markspresso create      ## scaffold a new site in current dir");
        out("  lucli markspresso build       ## build Markdown -> HTML into public/");
        out("  lucli markspresso serve       ## serve public/ over HTTP");
        out("  lucli markspresso new post …  ## create new content");
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

        verbose("Scaffolding Markspresso site in " & rootDir);

        // Ensure directories
        var contentDir = rootDir & "/content";
        var layoutsDir = rootDir & "/layouts";
        var assetsDir  = rootDir & "/assets";
        var outputDir  = rootDir & "/public";
        var postsDir   = contentDir & "/posts";

        ensureDir(contentDir);
        ensureDir(layoutsDir);
        ensureDir(assetsDir);
        ensureDir(outputDir);
        ensureDir(postsDir);

        // Write markspresso.json
        var config = {
            "name"    : name,
            "baseUrl" : baseUrl,
            "paths"   : {
                "content" : "content",
                "layouts" : "layouts",
                "assets"  : "assets",
                "output"  : "public"
            },
            "build"   : {
                "defaultLayout" : "page",
                "prettyUrls"    : true,
                "includeDrafts" : false
            },
            "collections" : {
                "posts" : {
                    "path"      : "posts",
                    "layout"    : "post",
                    "permalink" : "/posts/:slug/"
                }
            }
        };

        fileWrite(configPath, serializeJson(var = config, compact = false), "UTF-8");

        // Starter content/index.md
        var indexMd = "---" & chr(10) &
                      "title: Home" & chr(10) &
                      "layout: page" & chr(10) &
                      "---" & chr(10) & chr(10) &
                      "## Welcome to " & name & chr(10) & chr(10) &
                      "This site was brewed with Markspresso." & chr(10) & chr(10) &
                      "## Latest posts" & chr(10) & chr(10) &
                      "{{ latest_posts }}" & chr(10);
        writeFileIfMissing(contentDir & "/index.md", indexMd, force);

        // Starter posts/hello-world.md
        var helloPost = "---" & chr(10) &
                        "title: Hello, world" & chr(10) &
                        "layout: post" & chr(10) &
                        "draft: true" & chr(10) &
                        "---" & chr(10) & chr(10) &
                        "This is your first Markspresso post." & chr(10);
        writeFileIfMissing(postsDir & "/hello-world.md", helloPost, force);

        // Basic layouts
        var pageLayout = "<!doctype html>" & chr(10) &
                         "<html>" & chr(10) &
                         "  <head>" & chr(10) &
                         "    <meta charset=""utf-8"">" & chr(10) &
                         "    <title>{{ title }}</title>" & chr(10) &
                         "  </head>" & chr(10) &
                         "  <body>" & chr(10) &
                         "    <main>" & chr(10) &
                         "      {{ content }}" & chr(10) &
                         "    </main>" & chr(10) &
                         "  </body>" & chr(10) &
                         "</html>" & chr(10);
        writeFileIfMissing(layoutsDir & "/page.html", pageLayout, force);

        var postLayout = "<!doctype html>" & chr(10) &
                         "<html>" & chr(10) &
                         "  <head>" & chr(10) &
                         "    <meta charset=""utf-8"">" & chr(10) &
                         "    <title>{{ title }}</title>" & chr(10) &
                         "  </head>" & chr(10) &
                         "  <body>" & chr(10) &
                         "    <article>" & chr(10) &
                         "      <h1>{{ title }}</h1>" & chr(10) &
                         "      {{ content }}" & chr(10) &
                         "    </article>" & chr(10) &
                         "  </body>" & chr(10) &
                         "</html>" & chr(10);
        writeFileIfMissing(layoutsDir & "/post.html", postLayout, force);

        out("Markspresso site created in " & rootDir);
        return;
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
        string onlyRelPath = ""
    ) {
    
        var onlyRelPathLower = lcase(onlyRelPath);
        var builtItems = 0;
        out("Building site...");
        variables.timer.start("markspresso-build");
        var rootDir    = siteRoot();
        var configPath = rootDir & "/markspresso.json";
        var config     = {};

        // Load config if present; otherwise use defaults
        if (fileExists(configPath)) {
            try {
                config = deserializeJson(fileRead(configPath, "UTF-8"));
            }
            catch (any e) {
                out("Error reading markspresso.json: " & e.message);
                return;
            }
        }

        config = applyConfigDefaults(config);

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
        ensureDir(outputDir);

        // Copy assets (if any)
        if (directoryExists(assetsDir)) {
            copyAssets(assetsDir, outputDir);
        }

        // First pass: parse all docs and collect metadata
        var files           = directoryList(contentDir, true, "path", "*.md");
        var docs            = [];
        var postsCollection = [];
        var docUrlMap       = {};
        var dirsWithIndex   = {};

        // Pre-scan for index.md per directory so we can treat README.md as index when needed
        for (var scanPath in files) {
            // Ignore any Markdown that lives under layouts/ or assets/ when those
            // directories are nested inside the content directory (common when
            // markspresso is embedded in a larger project).
            if (shouldIgnoreContentFile(scanPath, contentDir, layoutsDir, assetsDir)) {
                continue;
            }

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

        for (var filePath in files) {
            // Ignore any Markdown that lives under layouts/ or assets/ when those
            // directories are nested inside the content directory.
            if (shouldIgnoreContentFile(filePath, contentDir, layoutsDir, assetsDir)) {
                continue;
            }

            var parsed = parseMarkdownFile(filePath, includeDrafts);
            if (isNull(parsed)) {
                continue; // skipped (likely draft)
            }
            builtItems++;
            out("Building: #filePath#");
            // Relative path from content root, using forward slashes
            var relPath = replace(mid(filePath, len(contentDir) + 2), "\\", "/", "all");

            // Treat README.md as index.md when there is no explicit index.md in that folder
            var fileNameLower = lcase(getFileFromPath(filePath));
            var dirPartsCount = listLen(relPath, "/");
            var relDir        = (dirPartsCount GT 1 ? listDeleteAt(relPath, dirPartsCount, "/") : "");
            var relDirKey     = lcase(relDir);

            if (fileNameLower == "readme.md" and !structKeyExists(dirsWithIndex, relDirKey)) {
                relPath = len(relDir) ? (relDir & "/index.md") : "index.md";
            }

            // Identify collection (if any) by matching relPath against collection paths
            var collectionName = findCollectionNameForRelPath(config, relPath);

            // Derive date/slug info for posts-style entries, e.g.
            //   posts/2013/2013-02-18-give-me-5-please.md
            var dateInfo = {};
            if (len(collectionName) and collectionName == "posts") {
                var relNoExt = reReplace(relPath, "\.[^.]+$", "");
                dateInfo = deriveDateSlugFromRelPath(relNoExt);

                // If front matter has no date, populate it from the filename so layouts can use it.
                if (structCount(dateInfo) and !structKeyExists(parsed.meta, "date")) {
                    parsed.meta.date = dateInfo.year & "-" & dateInfo.month & "-" & dateInfo.day;
                }
            }

            // Determine layout: front matter > collection default > global default
            var layoutName = "";
            if (structKeyExists(parsed.meta, "layout") and len(parsed.meta.layout)) {
                layoutName = parsed.meta.layout;
            }
            else if (len(collectionName)
                     and structKeyExists(config, "collections")
                     and structKeyExists(config.collections, collectionName)
                     and structKeyExists(config.collections[collectionName], "layout")
                     and len(config.collections[collectionName].layout)) {
                layoutName = config.collections[collectionName].layout;
            }
            else {
                layoutName = config.build.defaultLayout;
            }

            // Stash doc for second pass
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

            // Compute canonical URL for this doc and register it for link rewriting
            var canonicalUrl = computeCanonicalUrl(outputDir, relPath, doc.meta, prettyUrls, collectionName, dateInfo);

            out(canonicalUrl);
            return;
            doc.canonicalUrl = canonicalUrl;
            if (len(canonicalUrl)) {
                docUrlMap[lcase(relPath)] = canonicalUrl;
            }

            arrayAppend(docs, doc);

            // Build posts collection for latest-posts listing
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

        // Sort posts by date desc (newest first), then title asc for stability
        if (arrayLen(postsCollection) GT 1) {
            arraySort(postsCollection, function(a, b) {
                if (a.date == b.date) {
                    return compare(a.title, b.title);
                }
                // Newest first
                return compare(b.date, a.date);
            });
        }

        // Determine whether we also need to rebuild index.md when doing a
        // single-file build (e.g., when a post changes and the home page
        // renders a list of latest posts).
        var rebuildIndex = false;
        if (len(onlyRelPathLower)) {
            for (var d in docs) {
                if (lcase(d.relPath) == onlyRelPathLower and len(d.collectionName) and d.collectionName == "posts") {
                    rebuildIndex = true;
                    break;
                }
            }
        }

        // Second pass: render and write all docs
        var builtCount = 0;

        for (var i = 1; i <= arrayLen(docs); i++) {
            var doc = docs[i];

            // When onlyRelPath is provided (e.g. from watch()), only rebuild the
            // matching file plus index.md (when it needs latest_posts updated).
            if (len(onlyRelPathLower)) {
                var docRelLower = lcase(doc.relPath);
                if (docRelLower != onlyRelPathLower) {
                    if (!(rebuildIndex and docRelLower == "index.md")) {
                        continue;
                    }
                }
            }

            var effectiveMeta = duplicate(doc.meta);

            // Inject latest posts into the home page
            if (lcase(doc.relPath) == "index.md" and arrayLen(postsCollection)) {
                effectiveMeta.latest_posts = renderLatestPostsHtml(postsCollection, 5);
            }

            var layoutPath = layoutsDir & "/" & doc.layoutName & ".html";
            var layoutHtml = fileExists(layoutPath) ? fileRead(layoutPath, "UTF-8") : "{{ content }}";

            // Rewrite links that still point at .md files to their built URLs
            var rewrittenContent = rewriteMarkdownLinks(doc.html, doc.relPath, docUrlMap);

            var finalHtml = applyLayout(layoutHtml, effectiveMeta, rewrittenContent);

            // Compute one or more output paths (default + date-based + permalink-based)
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
                ensureDir(getDirectoryFromPath(outPath));
                fileWrite(outPath, finalHtml, "UTF-8");
            }

            builtCount++;
        }

        
        out("Built " & builtCount & " Markdown file(s) into " & outputDir);
        variables.timer.stop("markspresso-build");
        return;
    }

    /**
     * lucli markspresso serve
     *   --port=8080 --watch
     */
    function serve(
        numeric port = 8080,
        boolean watch = false
    ) {

        // this can be done via executomeCommand("serve",  []);

        verbose("Serving site on http://localhost:" & port);

        // 1. Start a simple HTTP server rooted at public/
        // 2. If watch=true, monitor content/ and layouts/ and trigger build on changes

        return;
    }

    function watch(
        numeric numberOfSeconds = 1
    ) {
        var rootDir    = siteRoot();
        var configPath = rootDir & "/markspresso.json";
        var config     = {};

        if (fileExists(configPath)) {
            try {
                config = deserializeJson(fileRead(configPath, "UTF-8"));
            }
            catch (any e) {
                out("Error reading markspresso.json in watch(): " & e.message);
                return;
            }
        }

        
        config = applyConfigDefaults(config);

        var contentDir = rootDir & "/" & config.paths.content;
        var layoutsDir = rootDir & "/" & config.paths.layouts;
        var assetsDir  = rootDir & "/" & config.paths.assets;
        var outputDir  = rootDir & "/" & config.paths.output;

        out("Watching for changes in:");
        out("  content: " & contentDir);
        out("  layouts: " & layoutsDir);
        out("  assets : " & assetsDir);

        // Initial snapshots
        var prevContentSnapshot = snapshotContentFiles(contentDir, layoutsDir, assetsDir);
        var prevLayoutSnapshot  = snapshotFiles(layoutsDir);
        var prevAssetSnapshot   = snapshotFiles(assetsDir);

        // Perform an initial build so output exists
        build();

        while (true) {
            sleep(numberOfSeconds * 1000);

            var currentContentSnapshot = snapshotContentFiles(contentDir, layoutsDir, assetsDir);
            var currentLayoutSnapshot  = snapshotFiles(layoutsDir);
            var currentAssetSnapshot   = snapshotFiles(assetsDir);

            var changedLayouts = diffSnapshots(prevLayoutSnapshot, currentLayoutSnapshot);
            var changedContent = diffSnapshots(prevContentSnapshot, currentContentSnapshot);
            var changedAssets  = diffSnapshots(prevAssetSnapshot, currentAssetSnapshot);

            if (!arrayLen(changedLayouts) and !arrayLen(changedContent) and !arrayLen(changedAssets)) {
                continue; // no changes
            }

            if (arrayLen(changedLayouts)) {
                out(arrayLen(changedLayouts) & " layout change(s) detected – rebuilding full site...");
                build();
            }
            else {
                if (arrayLen(changedAssets)) {
                    out(arrayLen(changedAssets) & " asset change(s) detected – copying assets...");
                    if (directoryExists(assetsDir)) {
                        copyAssets(assetsDir, outputDir);
                    }
                }

                for (var changedPath in changedContent) {
                    var relPath = replace(mid(changedPath, len(contentDir) + 2), "\\", "/", "all");
                    out("Content change detected: " & relPath & " – rebuilding...");
                    build(onlyRelPath = relPath);
                }
            }

            prevContentSnapshot = currentContentSnapshot;
            prevLayoutSnapshot  = currentLayoutSnapshot;
            prevAssetSnapshot   = currentAssetSnapshot;
        }

        return;
    }

    /**
     * lucli markspresso new post "hello-world"
     * lucli markspresso new page about
     */
    function new(
        string type,
        string title = "",
        string slug = ""
    ) {
        // type: "post" or "page" (at first)
        // If slug is blank, derive from title.
        // 1. Decide target path e.g. content/posts/<slug>.md
        // 2. Create a stub file with front matter:
        //    ---
        //    title: <title>
        //    date: <now>
        //    draft: true
        //    ---
        //    Your content here.

        return;
    }

    // --- Helper Functions ---

    function out(any message) {
        if (!isSimpleValue(message)) {
            message = serializeJson(var = message, compact = false);
        }
        // Use systemOutput so watch() and other long-running commands stream
        // logs reliably through LuCLI's CLI environment.
        systemOutput(message, true, false);
    }

    function verbose(any message) {
        if (variables.verboseEnabled) {
            out(message);
        }
    }

    private string function siteRoot() {
        // Root directory for this command execution
        return variables.cwd.len() ? variables.cwd : getCurrentTemplatePath().reReplace("[/\\\\][^/\\\\]*$", "");
    }

    private void function ensureDir(string path) {
        if (!directoryExists(path)) {
            directoryCreate(path, true);
        }
    }

    private void function writeFileIfMissing(string path, string contents, boolean force) {
        if (fileExists(path) AND !force) {
            return;
        }
        fileWrite(path, contents, "UTF-8");
    }

    private struct function applyConfigDefaults(struct cfg) {
        if (isNull(cfg)) cfg = {};

        if (!structKeyExists(cfg, "paths") or isNull(cfg.paths)) cfg.paths = {};
        if (!structKeyExists(cfg.paths, "content") or !len(cfg.paths.content)) cfg.paths.content = "content";
        if (!structKeyExists(cfg.paths, "layouts") or !len(cfg.paths.layouts)) cfg.paths.layouts = "layouts";
        if (!structKeyExists(cfg.paths, "assets") or !len(cfg.paths.assets)) cfg.paths.assets = "assets";
        if (!structKeyExists(cfg.paths, "output") or !len(cfg.paths.output)) cfg.paths.output = "public";

        if (!structKeyExists(cfg, "build") or isNull(cfg.build)) cfg.build = {};
        if (!structKeyExists(cfg.build, "defaultLayout")) cfg.build.defaultLayout = "page";
        if (!structKeyExists(cfg.build, "prettyUrls"))   cfg.build.prettyUrls   = true;
        if (!structKeyExists(cfg.build, "includeDrafts")) cfg.build.includeDrafts = false;

        if (!structKeyExists(cfg, "collections") or isNull(cfg.collections)) cfg.collections = {};

        return cfg;
    }

    private any function parseMarkdownFile(string path, boolean includeDrafts=false) {
        var raw = fileRead(path, "UTF-8");
        var parsed = parseFrontMatter(raw);
        verbose("Parsed Markdown file: " & path);
        // Skip drafts unless explicitly included
        if (structKeyExists(parsed.meta, "draft") and isBoolean(parsed.meta.draft) and parsed.meta.draft and !includeDrafts) {
            return nullValue();
        }

        var html = renderMarkdown(parsed.body);
        return { meta = parsed.meta, html = html };
    }

    private struct function parseFrontMatter(string contents) {

        // out(contents);
        var result = { meta = {}, body = contents };
        var newline    = chr(10);
        var startToken = "---" & newline;
        var endToken   = newline & "---" & newline;

        if (left(contents, len(startToken)) != startToken) {
            return result; // no front matter
        }

        var withoutStart = mid(contents, len(startToken) + 1);
        var endPos       = find(endToken, withoutStart);
        if (!endPos) {
            return result; // malformed front matter
        }

        var fmBlock = left(withoutStart, endPos - 1);
        var body    = mid(withoutStart, endPos + len(endToken));

        var meta = {};
        var lines = listToArray(fmBlock, newline);

        for (var line in lines) {
            line = trim(line);
            if (!len(line) or left(line, 1) == "##") continue;

            var sepPos = find(":", line);
            if (!sepPos) continue;

            var key   = trim(left(line, sepPos - 1));
            var value = trim(mid(line, sepPos + 1));

            if (!len(key)) continue;

            var lower = lcase(value);
            if (lower == "true" or lower == "false") {
                meta[key] = (lower == "true");
            }
            else if (isNumeric(value)) {
                meta[key] = val(value);
            }
            else {
                meta[key] = value;
            }
        }

        

        result.meta = meta;
        result.body = body;
        return result;
    }

    private string function renderMarkdown(string src) {


        return MarkDownToHTML(src);

        // Very minimal markdown renderer: supports #, ##, ### headings and paragraphs.
        var newline = chr(10);
        var lines   = listToArray(src, newline);
        var html    = "";
        var paragraph = "";

        for (var line in lines) {
            var trimmed = trim(line);

            if (!len(trimmed)) {
                if (len(paragraph)) {
                    html &= "<p>" & paragraph & "</p>" & newline;
                    paragraph = "";
                }
                continue;
            }

            if (left(trimmed, 2) == "## ") {
                if (len(paragraph)) {
                    html &= "<p>" & paragraph & "</p>" & newline;
                    paragraph = "";
                }
                html &= "<h1>" & htmlEditFormat(trim(mid(trimmed, 3))) & "</h1>" & newline;
                continue;
            }
            if (left(trimmed, 3) == "#### ") {
                if (len(paragraph)) {
                    html &= "<p>" & paragraph & "</p>" & newline;
                    paragraph = "";
                }
                html &= "<h2>" & htmlEditFormat(trim(mid(trimmed, 4))) & "</h2>" & newline;
                continue;
            }
            if (left(trimmed, 4) == "###### ") {
                if (len(paragraph)) {
                    html &= "<p>" & paragraph & "</p>" & newline;
                    paragraph = "";
                }
                html &= "<h3>" & htmlEditFormat(trim(mid(trimmed, 5))) & "</h3>" & newline;
                continue;
            }

            // Paragraph text
            if (len(paragraph)) {
                paragraph &= " " & htmlEditFormat(trimmed);
            }
            else {
                paragraph = htmlEditFormat(trimmed);
            }
        }

        if (len(paragraph)) {
            html &= "<p>" & paragraph & "</p>" & newline;
        }

        return html;
    }

    private string function applyLayout(string layoutHtml, struct meta, string contentHtml) {
        var data = duplicate(meta);
        if (!structKeyExists(data, "title")) {
            data.title = "";
        }
        data.content = contentHtml;

        // Simple {{ key }} replacement
        for (var key in data) {
            var value = data[key];
            layoutHtml = replaceNoCase(layoutHtml, "{{ " & key & " }}", value, "all");
            layoutHtml = replaceNoCase(layoutHtml, "{{" & key & "}}", value, "all");
        }
        // out("Applied layout:");
        // out(data);
        // out(contentHtml);
        // out(layoutHtml);

        return layoutHtml;
    }

    private string function computeOutputPath(string outputDir, string relPath, boolean prettyUrls) {
        // Normalize separators
        relPath = replace(relPath, "\\", "/", "all");

        // Strip extension
        var noExt = reReplace(relPath, "\.[^.]+$", "");

        // Special-case index pages so that:
        //   content/index.md        -> outputDir/index.html
        //   content/blog/index.md   -> outputDir/blog/index.html
        // instead of introducing an extra "index" directory.
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

    /**
     * Determine which collection (if any) a relative content path belongs to.
     */
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

    /**
     * Given a posts-style relative path without extension (e.g.
     *   posts/2013/2013-02-18-give-me-5-please
     * derive { year, month, day, slug }.
     */
    private struct function deriveDateSlugFromRelPath(string relPathNoExt) {
        var result = {};

        var normalized = replace(relPathNoExt, "\\", "/", "all");
        var filenamePart = listLast(normalized, "/");

        // Expect filename like: YYYY-MM-DD-slug
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

    /**
     * Compute all output paths for a content file:
     * - Default path (pretty or flat)
     * - Date-based path for posts collection entries
     * - Front-matter permalink (if present)
     */
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

        // Always include the default path
        var basePath = computeOutputPath(outputDir, relPath, prettyUrls);
        seen[basePath] = true;
        arrayAppend(paths, basePath);

        // Date-based path for posts collection entries, e.g.
        //   content/posts/2013/2013-02-18-give-me-5-please.md
        if (len(collectionName) and collectionName == "posts" and structCount(dateInfo)) {
            var datePath = outputDir & "/" & dateInfo.year & "/" & dateInfo.month & "/" & dateInfo.day & "/" & dateInfo.slug & ".html";
            if (!structKeyExists(seen, datePath)) {
                seen[datePath] = true;
                arrayAppend(paths, datePath);
            }
        }

        // Front-matter permalink: `permalink: give-me-5-please` -> give-me-5-please/index.html
        if (structKeyExists(meta, "permalink") and len(trim(meta.permalink))) {
            var permalink = trim(meta.permalink);

            // Normalise: strip leading/trailing slashes
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

    /**
     * Compute a canonical site-relative URL ("/...") for a document.
     * Preference order:
     *   1. Front-matter permalink
     *   2. Date-based posts URL
     *   3. Default computed output path
     */
    private string function computeCanonicalUrl(
        string outputDir,
        string relPath,
        struct meta,
        boolean prettyUrls,
        string collectionName,
        struct dateInfo
    ) {
        // 1) Front-matter permalink
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

        // 2) Date-based URL for posts
        if (len(collectionName) and collectionName == "posts" and structCount(dateInfo)) {
            return "/" & dateInfo.year & "/" & dateInfo.month & "/" & dateInfo.day & "/" & dateInfo.slug & ".html";
        }

        // 3) Fallback: derive from default output path
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

        // Collapse "/foo/index.html" -> "/foo/"
        if (right(path, 11) == "/index.html") {
            return left(path, len(path) - 10);
        }

        return path;
    }

    /**
     * Render a simple HTML list of the latest posts for injection into layouts
     * via the {{ latest_posts }} placeholder.
     */
    private string function renderLatestPostsHtml(array posts, numeric maxCount=5) {
        var html = "<ul>";

        var limit = min(maxCount, arrayLen(posts));
        for (var i = 1; i <= limit; i++) {
            var p = posts[i];
            var title = structKeyExists(p, "title") ? p.title : "";
            var url   = structKeyExists(p, "url")   ? p.url   : "";

            if (!len(url)) {
                continue;
            }

            html &= "<li><a href=\"" & htmlEditFormat(url) & "\">" & htmlEditFormat(title) & "</a></li>";
        }

        html &= "</ul>";
        return html;
    }

    /**
     * Rewrite links in rendered HTML that still point at .md files so that they
     * point at the final built URLs, using the registry built in build().
     */
    private string function rewriteMarkdownLinks(string html, string currentRelPath, struct docUrlMap) {
        // Handle href="..." then href='...'
        html = rewriteMarkdownLinksForQuote(html, currentRelPath, docUrlMap, '"');
        html = rewriteMarkdownLinksForQuote(html, currentRelPath, docUrlMap, "'");
        return html;
    }

    private string function rewriteMarkdownLinksForQuote(
        string html,
        string currentRelPath,
        struct docUrlMap,
        string quote
    ) {
        var out      = "";
        var pos      = 1;
        var pattern  = "href=" & quote;
        var patLen   = len(pattern);
        var htmlLen  = len(html);

        // while (true) {
        //     var start = findNoCase(pattern, html, pos);
        //     if (!start) {
        //         out &= mid(html, pos);
        //         break;
        //     }

        //     var before = mid(html, pos, start - pos);
        //     var rest   = mid(html, start + patLen);
        //     var endPos = find(quote, rest);
        //     if (!endPos) {
        //         out &= mid(html, pos);
        //         break;
        //     }
        //     SystemOutput("ELVIS!!!:#rest#", true);
        //     var hrefValue = left(rest, endPos - 1);
        //     var newUrl    = rewriteSingleMarkdownHref(hrefValue, currentRelPath, docUrlMap);

        //     out &= before & "href=" & quote & newUrl & quote;
        //     pos  = start + patLen + endPos;
        // }

        return out;
    }

    /**
     * Rewrite a single href URL if it points at a known .md document.
     */
    private string function rewriteSingleMarkdownHref(string href, string currentRelPath, struct docUrlMap) {
        var trimmed = trim(href);
        if (!len(trimmed)) return href;

        var lower = lcase(trimmed);
        // Skip absolute URLs and mailto; fragment-only links will fall through and be left as-is.
        if (left(lower, 7) == "http://" or left(lower, 8) == "https://" or left(lower, 7) == "mailto:") {
            return href;
        }

        // Separate anchor if present
        var hashPos = find(chr(35), trimmed);
        var linkPath = trimmed;
        var anchor   = "";
        if (hashPos) {
            linkPath = left(trimmed, hashPos - 1);
            anchor   = mid(trimmed, hashPos);
        }

        if (!len(linkPath) or right(linkPath, 3) != ".md") {
            return href;
        }

        // Resolve relative to currentRelPath
        var curDir = "";
        var segCount = listLen(currentRelPath, "/");
        if (segCount GT 1) {
            curDir = listDeleteAt(currentRelPath, segCount, "/");
        }

        var combined = len(curDir) ? (curDir & "/" & linkPath) : linkPath;

        // Normalise ., .. components
        var parts = listToArray(combined, "/");
        var stack = [];
        for (var part in parts) {
            part = trim(part);
            if (!len(part) or part == ".") continue;
            if (part == "..") {
                if (arrayLen(stack)) arrayDeleteAt(stack, arrayLen(stack));
                continue;
            }
            arrayAppend(stack, part);
        }

        if (!arrayLen(stack)) {
            return href;
        }

        var normalized = arrayToList(stack, "/");
        var key        = lcase(normalized);

        if (!structKeyExists(docUrlMap, key)) {
            return href;
        }

        var target = docUrlMap[key]; // canonical site-relative URL, e.g. "/getting-started/installation/"

        // For non-root targets, prefer paths without leading slash for relative linking
        if (target != "/" and left(target, 1) == "/") {
            target = mid(target, 2);
        }

        return target & anchor;
    }

    private void function copyAssets(string fromDir, string toDir) {
        if (!directoryExists(fromDir)) {
            return;
        }

        var items = directoryList(fromDir, true, "path");

        for (var p in items) {
            if (directoryExists(p)) {
                continue; // we'll create dirs as needed for files
            }

            var rel  = replace(mid(p, len(fromDir) + 2), "\\", "/", "all");
            var dest = toDir & "/" & rel;
            ensureDir(getDirectoryFromPath(dest));
            fileCopy(p, dest);
        }
    }

    /**
     * Return true when childPath is inside rootPath (or equal to it), with
     * normalised separators and basic boundary checks.
     */
    private boolean function isPathUnder(string childPath, string rootPath) {
        if (!len(rootPath) or !len(childPath)) {
            return false;
        }

        var child = replace(childPath, "\\", "/", "all");
        var root  = replace(rootPath, "\\", "/", "all");

        // Ensure root ends with a separator so we don't mis-match on prefixes.
        if (right(root, 1) != "/") {
            root &= "/";
        }

        if (left(child, len(root)) != root) {
            return false;
        }

        return true;
    }

    /**
     * Decide whether a Markdown file under contentDir should be ignored
     * because it actually lives under layouts/ or assets when those
     * directories are nested inside the content tree.
     */
    private boolean function shouldIgnoreContentFile(
        string filePath,
        string contentDir,
        string layoutsDir,
        string assetsDir
    ) {
        // Only treat layouts/assets specially if they are inside the content
        // directory; when they are siblings, there is nothing to ignore.
        if (len(layoutsDir) and isPathUnder(layoutsDir, contentDir) and isPathUnder(filePath, layoutsDir)) {
            return true;
        }

        if (len(assetsDir) and isPathUnder(assetsDir, contentDir) and isPathUnder(filePath, assetsDir)) {
            return true;
        }

        return false;
    }

    /**
     * Snapshot all Markdown files under contentDir, skipping any that should
     * be ignored (e.g. when layouts/ or assets/ live inside content/).
     */
    private struct function snapshotContentFiles(string contentDir, string layoutsDir, string assetsDir) {
        var snapshot = {};
        if (!directoryExists(contentDir)) {
            return snapshot;
        }

        var items = directoryList(contentDir, true, "path", "*.md");
        for (var p in items) {
            if (directoryExists(p)) {
                continue;
            }

            if (shouldIgnoreContentFile(p, contentDir, layoutsDir, assetsDir)) {
                continue;
            }

            var info = getFileInfo(p);
            snapshot[p] = info.lastModified;
        }

        return snapshot;
    }

    /**
     * Snapshot all files (non-directories) under a directory.
     */
    private struct function snapshotFiles(string dir) {
        var snapshot = {};
        if (!len(dir) or !directoryExists(dir)) {
            return snapshot;
        }

        var items = directoryList(dir, true, "path");
        for (var p in items) {
            if (directoryExists(p)) {
                continue;
            }

            var info = getFileInfo(p);
            snapshot[p] = info.lastModified;
        }

        return snapshot;
    }

    /**
     * Simple snapshot diff: return files that are new or have a different
     * lastModified timestamp. Deletions are ignored for now.
     */
    private array function diffSnapshots(struct before, struct after) {
        var changed = [];

        for (var path in after) {
            if (!structKeyExists(before, path) or before[path] != after[path]) {
                arrayAppend(changed, path);
            }
        }

        return changed;
    }

}
