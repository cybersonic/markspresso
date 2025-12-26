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

        // Initialize services
        variables.configService = new lib.ConfigService();
        variables.contentParser = new lib.ContentParser();
        variables.fileService   = new lib.FileService();
        variables.navigationBuilder = new lib.NavigationBuilder();
        
        // Initialize builder with dependencies
        variables.builder = new lib.Builder(
            configService      = variables.configService,
            contentParser      = variables.contentParser,
            fileService        = variables.fileService,
            navigationBuilder  = variables.navigationBuilder,
            cwd                = variables.cwd,
            timer              = variables.timer,
            outputCallback     = nullValue()
        );

        return this;
    }

    // Called when you run just: lucli markspresso
    function main() {
        out("Markspresso – brew static sites from Markdown.");
        out("");
        out("Usage:");
        out("  lucli markspresso create      ## scaffold a new site in current dir");
        out("  lucli markspresso build       ## build Markdown -> HTML into public/");
        out("  lucli markspresso watch       ## watch for changes and auto-rebuild");
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
        string onlyRelPath = ""
    ) {
        return variables.builder.buildSite(
            src         = src,
            outDir      = outDir,
            clean       = clean,
            drafts      = drafts,
            onlyRelPath = onlyRelPath
        );
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
        return variables.builder.watchSite(numberOfSeconds = numberOfSeconds);
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
        return variables.builder.newContent(
            type  = type,
            title = title,
            slug  = slug
        );
    }

    // --- Helper Functions ---

    function out(any message) {
        if (!isSimpleValue(message)) {
            message = serializeJson(var = message, compact = false);
        }
        // Keep direct CLI output available from Module for top-level commands.
        systemOutput(message, true, false);
    }

    function verbose(any message) {
        if (variables.verboseEnabled) {
            out(message);
        }
    }

}
