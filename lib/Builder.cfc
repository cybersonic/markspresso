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
        // Ensure a partials directory exists for shared header/footer/nav templates
        variables.fileService.ensureDir(layoutsDir & "/partials");
        variables.fileService.ensureDir(assetsDir);
        variables.fileService.ensureDir(outputDir);
        variables.fileService.ensureDir(postsDir);

        // Starter partials
        var headerPartial = '<header>' & chr(10) &
                            '  {{ navigation }}' & chr(10) &
                            '</header>' & chr(10);
        variables.fileService.writeFileIfMissing(layoutsDir & "/partials/header.html", headerPartial, force);

        var footerPartial = '<footer style="margin-top: 2rem; padding: 1rem; border-top: 1px solid ##ddd; font-size: 0.9rem; color: ##666;">' & chr(10) &
                            '  <p>Powered by Markspresso.</p>' & chr(10) &
                            '</footer>' & chr(10);
        variables.fileService.writeFileIfMissing(layoutsDir & "/partials/footer.html", footerPartial, force);

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
                         '    {{ include "partials/header.html" }}' & chr(10) &
                         '    <main>' & chr(10) &
                         '      {{ content }}' & chr(10) &
                         '    </main>' & chr(10) &
                         '    {{ include "partials/footer.html" }}' & chr(10) &
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
                         '    {{ include "partials/header.html" }}' & chr(10) &
                         '    <article>' & chr(10) &
                         '      <h1>{{ title }}</h1>' & chr(10) &
                         '      {{ content }}' & chr(10) &
                         '    </article>' & chr(10) &
                         '    {{ include "partials/footer.html" }}' & chr(10) &
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

        // Tagging and archives indexes
        // tagsIndex: tagKey -> { name = originalTagLabel, posts = [ { title, date, url } ] }
        // archivesIndex: "YYYY-MM" -> [ { title, date, url } ]
        var tagsIndex      = {};
        var archivesIndex  = {};

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

            // Build posts collection and tagging/archives indexes
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

                    var postEntry = {
                        title = postTitle,
                        date  = postDate,
                        url   = canonicalUrl
                    };

                    arrayAppend(postsCollection, postEntry);

                    // --- Tags index ---
                    if (structKeyExists(doc.meta, "tags") and len(doc.meta.tags)) {
                        // Treat tags as a comma-separated string; split and trim.
                        var tagsString = "" & doc.meta.tags;
                        var tagsArray  = listToArray(tagsString, ",");

                        for (var t in tagsArray) {
                            var tagLabel = trim(t);
                            if (!len(tagLabel)) {
                                continue;
                            }

                            var tagKey = lcase(tagLabel);
                            if (!structKeyExists(tagsIndex, tagKey)) {
                                tagsIndex[tagKey] = {
                                    name  = tagLabel,
                                    posts = []
                                };
                            }

                            arrayAppend(tagsIndex[tagKey].posts, postEntry);
                        }
                    }

                    // --- Archives index (by YYYY-MM) ---
                    if (len(postDate) GTE 7) {
                        var archiveKey = left(postDate, 7); // e.g. 2025-01
                        if (!structKeyExists(archivesIndex, archiveKey)) {
                            archivesIndex[archiveKey] = [];
                        }
                        arrayAppend(archivesIndex[archiveKey], postEntry);
                    }
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

        // Determine latest post document (for home page featured post tokens)
        var latestPostDoc = nullValue();
        if (arrayLen(postsCollection)) {
            var latestPostUrl = postsCollection[1].url;
            if (len(latestPostUrl)) {
                for (var dDoc in docs) {
                    if (structKeyExists(dDoc, "canonicalUrl") and dDoc.canonicalUrl == latestPostUrl) {
                        latestPostDoc = dDoc;
                        break;
                    }
                }
            }
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

            // Inject global variables from config under a namespaced key like {{ globals.blogName }}
            if (structKeyExists(config, "globals") and isStruct(config.globals)) {
                for (var gKey in config.globals) {
                    var gVal = config.globals[gKey];
                    if (isSimpleValue(gVal)) {
                        effectiveMeta["globals." & gKey] = gVal;
                    }
                }
            }

            var relLower = lcase(doc.relPath);

            // Inject latest posts and featured post tokens for index page
            // TODO: maybe we can have a global which is latest_post.content (for example)
            if (relLower == "index.md") {
                var maxPosts = config.build.latestPostsCount;
                effectiveMeta.latest_posts = arrayLen(postsCollection) ? renderLatestPostsHtml(postsCollection, maxPosts) : "";

                // Expose the most recent post's front matter and content as post.* tokens
                // e.g. {{ post.title }}, {{ post.date }}, {{ post.content }}, {{ post.url }}
                if (!isNull(latestPostDoc)) {
                    // Copy all front matter keys under a post.* namespace
                    if (structKeyExists(latestPostDoc, "meta") and isStruct(latestPostDoc.meta)) {
                        for (var pKey in latestPostDoc.meta) {
                            var pVal = latestPostDoc.meta[pKey];
                            if (isSimpleValue(pVal)) {
                                effectiveMeta["post." & pKey] = pVal;
                            }
                        }
                    }

                    // Always expose content and URL
                    if (structKeyExists(latestPostDoc, "html")) {
                        effectiveMeta["post.content"] = latestPostDoc.html;
                    }
                    if (structKeyExists(latestPostDoc, "canonicalUrl") and len(latestPostDoc.canonicalUrl)) {
                        effectiveMeta["post.url"] = latestPostDoc.canonicalUrl;
                    }
                }
            }

            // Make tags/archives/posts lists globally available so they can be used in any layout
            effectiveMeta.tags_list = structCount(tagsIndex) ? renderTagsListHtml(tagsIndex, layoutsDir) : "";
            effectiveMeta.archives_list = structCount(archivesIndex) ? renderArchivesListHtml(archivesIndex, layoutsDir) : "";
            effectiveMeta.posts_list = arrayLen(postsCollection) ? renderPostsListHtml(postsCollection, layoutsDir) : "";

            // Inject navigation HTML
            var navRootPath = structKeyExists(config, "navigation") && structKeyExists(config.navigation, "rootPath") 
                ? config.navigation.rootPath 
                : "";
            effectiveMeta.navigation = variables.navigationBuilder.buildNavigation(
                docs = docs,
                currentRelPath = doc.relPath,
                rootPath = navRootPath
            );

            // Make tags/archives/posts lists globally available so they can be used in any layout.
            // These support CFML overrides in the active site's layouts directory.
            effectiveMeta.tags_list = structCount(tagsIndex)
                ? renderTagsListHtml(tagsIndex, layoutsDir)
                : "";

            effectiveMeta.archives_list = structCount(archivesIndex)
                ? renderArchivesListHtml(archivesIndex, layoutsDir)
                : "";

            effectiveMeta.posts_list = arrayLen(postsCollection)
                ? renderPostsListHtml(postsCollection, layoutsDir)
                : "";

            // Determine layout base path and CFML/HTML variants
            var layoutBasePath = layoutsDir & "/" & doc.layoutName;
            var layoutCfmPath  = layoutBasePath & ".cfm";
            var layoutHtmlPath = layoutBasePath & ".html";

            var rewrittenContent = variables.contentParser.rewriteLinks(doc.html, doc.relPath, docUrlMap);
            var finalHtml = "";

            if (fileExists(layoutCfmPath)) {
                // Use CFML layout override when present.
                // First, process tokens/conditionals inside the content HTML itself
                // so things like {{ latest_posts }} work when written in Markdown.
                var processedContentOnly = variables.contentParser.applyLayout("{{ content }}", effectiveMeta, rewrittenContent);

                finalHtml = renderWithCfmlLayout(
                    overrideFilePath = layoutCfmPath,
                    meta             = effectiveMeta,
                    contentHtml      = processedContentOnly,
                    config           = config,
                    doc              = doc,
                    postsCollection  = postsCollection,
                    tagsIndex        = tagsIndex,
                    archivesIndex    = archivesIndex,
                    latestPostDoc    = latestPostDoc
                );
            }
            else {
                // Fallback to HTML layout with Markspresso token replacement
                var layoutHtml = fileExists(layoutHtmlPath) ? fileRead(layoutHtmlPath, "UTF-8") : "{{ content }}";

                // Resolve layout partial includes such as {{ include "partials/header.html" }}.
                // Include paths are resolved relative to the layouts directory.
                layoutHtml = resolveLayoutIncludes(layoutHtml, layoutsDir);

                finalHtml = variables.contentParser.applyLayout(layoutHtml, effectiveMeta, rewrittenContent);
            }

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
     * Create new content (post, page, or other collection type).
     */
    public void function newContent(string type = "", string title = "", string slug = "") {
        if (!len(type)) {
            out("Error: content type is required (e.g., 'post' or 'page')");
            return;
        }
        
        var rootDir = siteRoot();
        var config  = variables.configService.load(rootDir);
        var contentDir = rootDir & "/" & config.paths.content;
        
        // Determine collection config
        var collectionConfig = {};
        var targetDir = contentDir;
        var layout = config.build.defaultLayout;
        
        if (structKeyExists(config.collections, type)) {
            collectionConfig = config.collections[type];
            if (structKeyExists(collectionConfig, "path") and len(collectionConfig.path)) {
                targetDir = contentDir & "/" & collectionConfig.path;
            }
            if (structKeyExists(collectionConfig, "layout") and len(collectionConfig.layout)) {
                layout = collectionConfig.layout;
            }
        }
        
        // Generate slug from title if not provided
        if (!len(slug) and len(title)) {
            slug = lcase(trim(title));
            // Replace spaces and special chars with dashes
            slug = reReplace(slug, "[^a-z0-9]+", "-", "all");
            // Remove leading/trailing dashes
            slug = reReplace(slug, "^-+|-+$", "", "all");
        }
        
        if (!len(slug)) {
            out("Error: title or slug is required");
            return;
        }
        
        // For posts, use date prefix in filename
        var filename = slug & ".md";
        if (type == "posts") {
            var now = now();
            var datePart = dateFormat(now, "yyyy-mm-dd");
            filename = datePart & "-" & slug & ".md";
        }
        
        var filePath = targetDir & "/" & filename;
        
        if (fileExists(filePath)) {
            out("Error: file already exists at " & filePath);
            return;
        }
        
        // Ensure target directory exists
        variables.fileService.ensureDir(targetDir);
        
        // Build front matter
        var frontMatter = "---" & chr(10);
        if (len(title)) {
            frontMatter &= "title: " & title & chr(10);
        }
        frontMatter &= "layout: " & layout & chr(10);
        
        if (type == "posts") {
            var now = now();
            frontMatter &= "date: " & dateFormat(now, "yyyy-mm-dd") & chr(10);
            frontMatter &= "draft: true" & chr(10);
        }
        
        frontMatter &= "---" & chr(10) & chr(10);
        
        // Add starter content
        var content = frontMatter;
        if (len(title)) {
            content &= "Write your content here for " & title & "." & chr(10);
        } else {
            content &= "Write your content here." & chr(10);
        }
        
        // Write the file
        fileWrite(filePath, content, "UTF-8");
        
        out("Created " & type & ": " & filePath);
    }

    // --- Private Helper Functions ---

    private string function siteRoot() {
        return variables.cwd.len() ? variables.cwd : getCurrentTemplatePath().reReplace("[/\\][^/\\]*$", "");
    }

    /**
     * Resolve {{ include "partials/header.html" }}-style directives in layout HTML.
     * Include paths are resolved relative to the layouts directory (e.g. layouts/partials/header.html).
     */
    private string function resolveLayoutIncludes(
        required string layoutHtml,
        required string layoutsDir,
        struct visited = {}
    ) {
        var result        = layoutHtml;
        var searchStart   = 1;
        var maxIterations = 1000;
        var iteration     = 0;

        // Normalize layoutsDir once
        var baseDir = replace(layoutsDir, "\\", "/", "all");

        while (true) {
            iteration++;
            if (iteration GT maxIterations) {
                break;
            }

            // Look for the next include directive
            var tokenStart = findNoCase("{{ include", result, searchStart);
            if (!tokenStart) {
                break;
            }

            // Find the first quote after the include keyword
            var firstQuote = find('"', result, tokenStart);
            if (!firstQuote) {
                searchStart = tokenStart + len("{{ include");
                continue;
            }

            // Find the closing quote
            var secondQuote = find('"', result, firstQuote + 1);
            if (!secondQuote) {
                searchStart = firstQuote + 1;
                continue;
            }

            // Extract the relative include path
            var includeRelPath = mid(result, firstQuote + 1, secondQuote - firstQuote - 1);

            // Find the closing }} for this include directive
            var endToken = find("}}", result, secondQuote + 1);
            if (!endToken) {
                searchStart = secondQuote + 1;
                continue;
            }

            var fullStart = tokenStart;
            var fullEnd   = endToken + 1; // include both } characters

            // Basic validation on the path
            if (!len(trim(includeRelPath))) {
                // Remove malformed include
                result = left(result, fullStart - 1) & mid(result, fullEnd + 1);
                searchStart = fullStart;
                continue;
            }

            // Normalize path separators
            includeRelPath = replace(includeRelPath, "\\", "/", "all");

            // Prevent escaping layoutsDir via ../ segments
            if (reFindNoCase("(^|/)\.\.(?:/|$)", includeRelPath)) {
                result = left(result, fullStart - 1) & mid(result, fullEnd + 1);
                searchStart = fullStart;
                continue;
            }

            var fullPath = baseDir & "/" & includeRelPath;

            // Detect recursive includes using the resolved full path
            if (structKeyExists(visited, fullPath)) {
                // Strip recursive include to avoid infinite loop
                result = left(result, fullStart - 1) & mid(result, fullEnd + 1);
                searchStart = fullStart;
                continue;
            }

            var partialHtml = "";
            if (fileExists(fullPath)) {
                visited[fullPath] = true;
                partialHtml = fileRead(fullPath, "UTF-8");
                // Recursively resolve includes inside the partial
                partialHtml = resolveLayoutIncludes(partialHtml, layoutsDir, visited);
                structDelete(visited, fullPath);
            }

            // Replace the include directive with the resolved partial HTML (or empty string)
            result = left(result, fullStart - 1) & partialHtml & mid(result, fullEnd + 1);

            // Continue searching after the inserted content
            searchStart = fullStart + len(partialHtml);
        }

        return result;
    }

    /**
     * Render a CFML layout (e.g. layouts/post.cfm, layouts/page.cfm).
     * Exposes content/meta/globals/doc/post/etc as local variables.
     */
    private string function renderWithCfmlLayout(
        required string overrideFilePath,
        required struct meta,
        required string contentHtml,
        required struct config,
        required struct doc,
        required array  postsCollection,
        required struct tagsIndex,
        required struct archivesIndex,
        any latestPostDoc = nullValue()
    ) {
        var html = "";

        // Primary data structures
        var content = contentHtml;      // rendered Markdown for this document
        var data    = meta;             // effective meta (front matter + injected fields)
        var page    = doc;              // filePath, relPath, collectionName, etc.

        // Optional convenience aliases
        var globals = structKeyExists(config, "globals") && isStruct(config.globals)
            ? duplicate(config.globals)
            : {};

        // Always expose config.baseUrl to layouts via globals.baseUrl
        if (structKeyExists(config, "baseUrl") and isSimpleValue(config.baseUrl)) {
            globals.baseUrl = config.baseUrl;
        }

        var posts    = postsCollection;
        var tags     = tagsIndex;
        var archives = archivesIndex;

        // For posts collection items, expose a "post" struct
        var post = {};
        if (len(doc.collectionName) and doc.collectionName == "posts") {
            post = duplicate(doc.meta);
            post.content = contentHtml;
            if (structKeyExists(doc, "canonicalUrl")) {
                post.url = doc.canonicalUrl;
            }
        }

        // Expose a full latestPost struct (front matter + content + url) when available
        var latestPost = {};
        if (!isNull(latestPostDoc)
            and structKeyExists(latestPostDoc, "meta")
            and isStruct(latestPostDoc.meta)) {

            latestPost = duplicate(latestPostDoc.meta);

            if (structKeyExists(latestPostDoc, "html")) {
                latestPost.content = latestPostDoc.html;
            }
            if (structKeyExists(latestPostDoc, "canonicalUrl")) {
                latestPost.url = latestPostDoc.canonicalUrl;
            }
        }

        savecontent variable="html" {
            include template="#contractPath(overrideFilePath)#";
        }

        return html;
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

        var slugStart = len(year) + 1 + len(month) + 1 + len(day) + 1 + 1;
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
                // If the permalink ends with an extension (e.g. ".xml"), treat it as a file path.
                // Otherwise, use the existing /permalink/index.html convention.
                var hasExt = listLen(listLast(permalink, "/"), ".") GT 1;
                var permalinkPath = hasExt
                    ? (outputDir & "/" & permalink)
                    : (outputDir & "/" & permalink & "/index.html");

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

            // If the permalink looks like a file (has an extension), return "/file.ext".
            // Otherwise, treat it as a directory-style URL with trailing slash.
            var hasExt = listLen(listLast(p, "/"), ".") GT 1;
            if (hasExt) {
                return "/" & p;
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
            var postTitle = structKeyExists(p, "title") ? p["title"] : "";
            var postUrl   = structKeyExists(p, "url") ? p["url"] : "";

            if (!len(postUrl)) {
                continue;
            }

            html &= '<li><a href="' & htmlEditFormat(postUrl) & '">' & htmlEditFormat(postTitle) & '</a></li>';
        }

        html &= '</ul>';
        return html;
    }

    /**
     * Render a site-wide tags list as HTML.
     * tagsIndex: tagKey -> { name, posts = [ { title, date, url } ] }
     * If layouts/tags_list.cfm exists in the active site, that CFML template
     * is used instead and receives a single argument: tagsIndex.
     */
    private string function renderTagsListHtml(struct tagsIndex, string layoutsDir) {
        var overrideFilePath = layoutsDir & "/lists/tags_list.cfm";

        if (fileExists(overrideFilePath)) {
            savecontent variable="html" {
                include template="#contractPath(overrideFilePath)#";
            }
            return html;
        }

        var html = '<ul class="tags-list">';

        var tagKeys = structKeyArray(tagsIndex);
        // Sort tag keys alphabetically, case-insensitive
        arraySort(tagKeys, "textNoCase", "asc");

        for (var i = 1; i <= arrayLen(tagKeys); i++) {
            var key    = tagKeys[i];
            var entry  = tagsIndex[key];
            var label  = structKeyExists(entry, "name") ? entry.name : key;
            var posts  = structKeyExists(entry, "posts") ? entry.posts : [];
            var count  = arrayLen(posts);

            html &= '<li class="tags-list__item">' & htmlEditFormat(label) & ' (' & count & ')</li>';
        }

        html &= '</ul>';
        return html;
    }

    /**
     * Render a date archives list as HTML.
     * archivesIndex: "YYYY-MM" -> [ { title, date, url } ]
     * If layouts/archives_list.cfm exists in the active site, that CFML
     * template is used instead and receives a single argument: archivesIndex.
     */
    private string function renderArchivesListHtml(struct archivesIndex, string layoutsDir) {
        var overrideFilePath = layoutsDir & "/lists/archives_list.cfm";

        if (fileExists(overrideFilePath)) {
            savecontent variable="html" {
                include template="#contractPath(overrideFilePath)#";
            }
            return html;
        }

        var html = '<ul class="archives-list">';

        var keys = structKeyArray(archivesIndex);
        // Sort archive keys (e.g. YYYY-MM) so newest month appears first
        arraySort(keys, "textNoCase", "desc");

        for (var i = 1; i <= arrayLen(keys); i++) {
            var key   = keys[i];
            var posts = archivesIndex[key];
            var count = arrayLen(posts);

            html &= '<li class="archives-list__item">' & htmlEditFormat(key) & ' (' & count & ')</li>';
        }

        html &= '</ul>';
        return html;
    }

/**
     * Render a full posts list, e.g. for /posts index pages.
     * If layouts/posts_list.cfm exists in the active site, that CFML template
     * is used instead and receives a single argument: posts (array).
     */
    private string function renderPostsListHtml(array posts, string layoutsDir) {
        var overrideFilePath = layoutsDir & "/lists/posts_list.cfm";

        if (fileExists(overrideFilePath)) {
            savecontent variable="html" {
                include template="#contractPath(overrideFilePath)#";
            }
            return html;
        }

        var html = '<ul class="posts-list">';

        for (var i = 1; i <= arrayLen(posts); i++) {
            var p = posts[i];
            var postTitle = structKeyExists(p, "title") ? p["title"] : "";
            var postUrl   = structKeyExists(p, "url") ? p["url"] : "";
            var postDate  = structKeyExists(p, "date") ? p["date"] : "";

            if (!len(postUrl)) {
                continue;
            }

            html &= '<li class="posts-list__item">';
            html &= '<a href="' & htmlEditFormat(postUrl) & '">' & htmlEditFormat(postTitle) & '</a>';
            if (len(postDate)) {
                html &= ' <span class="post-date">' & htmlEditFormat(postDate) & '</span>';
            }
            html &= '</li>';
        }

        html &= '</ul>';
        return html;
    }

}
