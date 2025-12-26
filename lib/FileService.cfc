component {

    /**
     * FileService
     * Centralized file I/O operations for Markspresso.
     */

    function init() {
        return this;
    }

    /**
     * Ensure a directory exists, creating it if necessary.
     */
    public void function ensureDir(string path) {
        if (!directoryExists(path)) {
            directoryCreate(path, true);
        }
    }

    /**
     * Write a file only if it doesn't exist or force is true.
     */
    public void function writeFileIfMissing(string path, string contents, boolean force = false) {
        if (fileExists(path) AND !force) {
            return;
        }
        fileWrite(path, contents, "UTF-8");
    }

    /**
     * Recursively discover Markdown files in a directory.
     */
    public array function discoverMarkdownFiles(string contentDir) {
        if (!directoryExists(contentDir)) {
            return [];
        }
        return directoryList(contentDir, true, "path", "*.md");
    }

    /**
     * Copy all files from one directory to another recursively.
     */
    public void function copyAssets(string fromDir, string toDir) {
        if (!directoryExists(fromDir)) {
            return;
        }

        var items = directoryList(fromDir, true, "path");

        for (var p in items) {
            if (directoryExists(p)) {
                continue;
            }

            var rel  = replace(mid(p, len(fromDir) + 2), "\\", "/", "all");
            var dest = toDir & "/" & rel;
            ensureDir(getDirectoryFromPath(dest));
            fileCopy(p, dest);
        }
    }

    /**
     * Create a snapshot of file modification times for change detection.
     */
    public struct function snapshotFiles(string dir) {
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
     * Create a snapshot of content files (Markdown only), excluding specified directories.
     */
    public struct function snapshotContentFiles(
        string contentDir,
        string layoutsDir,
        string assetsDir
    ) {
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
     * Compare two snapshots and return changed file paths.
     */
    public array function diffSnapshots(struct before, struct after) {
        var changed = [];

        for (var path in after) {
            if (!structKeyExists(before, path) or before[path] != after[path]) {
                arrayAppend(changed, path);
            }
        }

        return changed;
    }

    // --- Private Helpers ---

    private boolean function isPathUnder(string childPath, string rootPath) {
        if (!len(rootPath) or !len(childPath)) {
            return false;
        }

        var child = replace(childPath, "\\", "/", "all");
        var root  = replace(rootPath, "\\", "/", "all");

        if (right(root, 1) != "/") {
            root &= "/";
        }

        if (left(child, len(root)) != root) {
            return false;
        }

        return true;
    }

    private boolean function shouldIgnoreContentFile(
        string filePath,
        string contentDir,
        string layoutsDir,
        string assetsDir
    ) {
        if (len(layoutsDir) and isPathUnder(layoutsDir, contentDir) and isPathUnder(filePath, layoutsDir)) {
            return true;
        }

        if (len(assetsDir) and isPathUnder(assetsDir, contentDir) and isPathUnder(filePath, assetsDir)) {
            return true;
        }

        return false;
    }

}
