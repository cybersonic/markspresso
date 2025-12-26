component {

    /**
     * ConfigService
     * Handles loading, validation, and defaults for markspresso.json configuration.
     */

    function init() {
        return this;
    }

    /**
     * Load and parse markspresso.json from the site root.
     * Returns an empty struct if the file doesn't exist.
     */
    public struct function load(string siteRoot) {
        var configPath = siteRoot & "/markspresso.json";
        var config = {};

        if (fileExists(configPath)) {
            try {
                config = deserializeJson(fileRead(configPath, "UTF-8"));
            }
            catch (any e) {
                throw(
                    type    = "MarkspressoConfigError",
                    message = "Error reading markspresso.json: " & e.message
                );
            }
        }

        return applyDefaults(config);
    }

    /**
     * Apply default values to a config struct.
     */
    public struct function applyDefaults(struct cfg) {
        if (isNull(cfg)) cfg = {};

        // Paths
        if (!structKeyExists(cfg, "paths") or isNull(cfg.paths)) cfg.paths = {};
        if (!structKeyExists(cfg.paths, "content") or !len(cfg.paths.content)) cfg.paths.content = "content";
        if (!structKeyExists(cfg.paths, "layouts") or !len(cfg.paths.layouts)) cfg.paths.layouts = "layouts";
        if (!structKeyExists(cfg.paths, "assets") or !len(cfg.paths.assets)) cfg.paths.assets = "assets";
        if (!structKeyExists(cfg.paths, "output") or !len(cfg.paths.output)) cfg.paths.output = "public";

        // Build options
        if (!structKeyExists(cfg, "build") or isNull(cfg.build)) cfg.build = {};
        if (!structKeyExists(cfg.build, "defaultLayout")) cfg.build.defaultLayout = "page";
        if (!structKeyExists(cfg.build, "prettyUrls"))   cfg.build.prettyUrls   = true;
        if (!structKeyExists(cfg.build, "includeDrafts")) cfg.build.includeDrafts = false;

        // Collections
        if (!structKeyExists(cfg, "collections") or isNull(cfg.collections)) cfg.collections = {};

        return cfg;
    }

    /**
     * Get a default scaffold config with the given name and baseUrl.
     */
    public struct function getDefaultConfig(string name = "Markspresso Site", string baseUrl = "http://localhost:8080") {
        return {
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
    }

}
