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
                      "This site was brewed with Markspresso." & chr(10);
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
        string src    = "content",
        string outDir = "public",
        boolean clean = false,
        boolean drafts = false
    ) {
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

        // Walk content directory for .md files
        var files = directoryList(contentDir, true, "path", "*.md");
        var builtCount = 0;

        for (var filePath in files) {
            var parsed = parseMarkdownFile(filePath, includeDrafts);
            if (isNull(parsed)) {
                continue; // skipped (likely draft)
            }

            var relPath = replace(mid(filePath, len(contentDir) + 2), "\\", "/", "all");
            var outPath = computeOutputPath(outputDir, relPath, prettyUrls);

            ensureDir(getDirectoryFromPath(outPath));

            // Determine layout
            var layoutName = structKeyExists(parsed.meta, "layout") && len(parsed.meta.layout) ? parsed.meta.layout : config.build.defaultLayout;
            var layoutPath = layoutsDir & "/" & layoutName & ".html";
            var layoutHtml = fileExists(layoutPath) ? fileRead(layoutPath, "UTF-8") : "{{ content }}";

            var finalHtml = applyLayout(layoutHtml, parsed.meta, parsed.html);
            fileWrite(outPath, finalHtml, "UTF-8");
            builtCount++;
        }

        out("Built " & builtCount & " Markdown file(s) into " & outputDir);
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
        verbose("Serving site on http://localhost:" & port);

        // 1. Start a simple HTTP server rooted at public/
        // 2. If watch=true, monitor content/ and layouts/ and trigger build on changes

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
        writeOutput(message & chr(10));
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

        out(contents);
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
        out("Applied layout:");
        out(data);
        out(contentHtml);
        out(layoutHtml);

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

    private void function copyAssets(string fromDir, string toDir) {
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

}
