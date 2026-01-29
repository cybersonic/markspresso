component {

    /**
     * NavigationBuilder
     * Builds hierarchical navigation from documentation files using numeric prefix convention.
     * 
     * Convention:
     *   - Files: 010_filename.md -> sorted numerically, prefix stripped from display
     *   - Folders: become sections in navigation
     *   - Titles: derived from filename (snake_case/kebab-case -> Title Case)
     *   - Front matter title: overrides derived title
     */

    function init() {
        return this;
    }

    /**
     * Build navigation tree from parsed documents.
     * 
     * @param docs Array of document structs with relPath, meta, canonicalUrl
     * @param currentRelPath Current page's relative path (for active highlighting)
     * @param rootPath Optional root path to filter navigation (e.g., "docs")
     * @return HTML string for navigation
     */
    public string function buildNavigation(
        required array docs,
        string currentRelPath = "",
        string rootPath = ""
    ) {
        // Filter docs to root path if specified and strip the rootPath prefix
        var filteredDocs = [];
        var rootPathPrefix = "";
        
        if (len(arguments.rootPath)) {
            rootPathPrefix = replace(arguments.rootPath, "\", "/", "all");
            if (right(rootPathPrefix, 1) != "/") {
                rootPathPrefix &= "/";
            }
        }
        
        for (var doc in arguments.docs) {
            var normalizedRel = replace(doc.relPath, "\", "/", "all");
            
            if (len(rootPathPrefix)) {
                // Check if doc is under rootPath
                if (left(normalizedRel, len(rootPathPrefix)) != rootPathPrefix) {
                    continue;
                }
                
                // Create modified doc with rootPath stripped from relPath
                var modifiedDoc = duplicate(doc);
                modifiedDoc.relPath = mid(normalizedRel, len(rootPathPrefix) + 1);
                arrayAppend(filteredDocs, modifiedDoc);
            }
            else {
                arrayAppend(filteredDocs, doc);
            }
        }

        if (!arrayLen(filteredDocs)) {
            return "";
        }

        // Normalize current path for active-state comparison: when rootPath is set,
        // nav items use stripped paths (e.g. "010_getting-started.md"); currentRelPath
        // from Builder is the full path (e.g. "docs/010_getting-started.md"). Strip
        // the same prefix so the active check matches.
        var currentForActive = arguments.currentRelPath;
        if (len(rootPathPrefix)) {
            var normalizedCurrent = replace(arguments.currentRelPath, "\", "/", "all");
            if (left(normalizedCurrent, len(rootPathPrefix)) == rootPathPrefix) {
                currentForActive = mid(normalizedCurrent, len(rootPathPrefix) + 1);
            }
        }

        // Build tree structure
        var tree = buildNavigationTree(filteredDocs);

        // Render HTML
        return renderNavigationHtml(tree, currentForActive);
    }

    /**
     * Build hierarchical tree structure from flat document list.
     * Returns: { sections: [...], rootItems: [...] }
     */
    private struct function buildNavigationTree(required array docs) {
        var sections = {};    // folder -> { title, order, items: [] }
        var rootItems = [];   // top-level items

        for (var doc in arguments.docs) {
            var relPath = replace(doc.relPath, "\", "/", "all");
            var parts = listToArray(relPath, "/");

            if (arrayLen(parts) == 1) {
                // Top-level file
                var item = createNavItem(doc, parts[1]);
                if (!isNull(item)) {
                    arrayAppend(rootItems, item);
                }
            }
            else if (arrayLen(parts) == 2) {
                // File in a folder (section)
                var folderName = parts[1];
                var fileName = parts[2];

                if (!structKeyExists(sections, folderName)) {
                    sections[folderName] = {
                        title = deriveTitleFromName(folderName),
                        order = extractNumericPrefix(folderName),
                        items = []
                    };
                }

                var item = createNavItem(doc, fileName);
                if (!isNull(item)) {
                    arrayAppend(sections[folderName].items, item);
                }
            }
            // Deeper levels ignored (2-level hierarchy only)
        }

        // Sort root items
        if (arrayLen(rootItems) > 1) {
            arraySort(rootItems, function(a, b) {
                return compare(a.order, b.order);
            });
        }

        // Sort sections and their items
        var sortedSections = [];
        for (var folderName in sections) {
            var section = sections[folderName];
            section.folderName = folderName;

            if (arrayLen(section.items) > 1) {
                arraySort(section.items, function(a, b) {
                    return compare(a.order, b.order);
                });
            }

            arrayAppend(sortedSections, section);
        }

        if (arrayLen(sortedSections) > 1) {
            arraySort(sortedSections, function(a, b) {
                return compare(a.order, b.order);
            });
        }

        return {
            rootItems = rootItems,
            sections = sortedSections
        };
    }

    /**
     * Create a navigation item from a document.
     * Returns null if item should be hidden.
     */
    private any function createNavItem(required struct doc, required string fileName) {
        // Skip files starting with underscore only (no number)
        if (left(fileName, 1) == "_") {
            return nullValue();
        }

        // Check if hidden via front matter
        if (structKeyExists(doc.meta, "nav_hidden") && doc.meta.nav_hidden) {
            return nullValue();
        }

        var title = "";
        if (structKeyExists(doc.meta, "title") && len(doc.meta.title)) {
            title = doc.meta.title;
        }
        else {
            title = deriveTitleFromName(fileName);
        }

        return {
            title = title,
            url = doc.canonicalUrl,
            relPath = doc.relPath,
            order = extractNumericPrefix(fileName)
        };
    }

    /**
     * Extract numeric prefix for sorting.
     * Returns string with zero-padding preserved for correct string sorting.
     */
    private string function extractNumericPrefix(required string name) {
        var matches = reMatch("^(\d{1,4})_", arguments.name);
        if (arrayLen(matches)) {
            // Return the matched prefix with padding intact
            return reReplace(matches[1], "^(\d+).*", "\1");
        }
        // No prefix: sort after all prefixed items
        return "9999";
    }

    /**
     * Derive human-readable title from filename.
     * Examples:
     *   010_introduction.md -> Introduction
     *   020_server-management.md -> Server Management
     *   ServerManagement.md -> Server Management
     */
    private string function deriveTitleFromName(required string name) {
        var clean = arguments.name;

        // Remove numeric prefix (e.g., 010_)
        clean = reReplace(clean, "^(\d{1,4})_", "");

        // Remove file extension
        clean = reReplace(clean, "\.[^.]+$", "");

        // Convert separators to spaces
        clean = replace(clean, "-", " ", "all");
        clean = replace(clean, "_", " ", "all");

        // Title case each word
        var words = listToArray(clean, " ");
        var titleWords = [];
        for (var word in words) {
            if (len(word)) {
                var titleWord = uCase(left(word, 1)) & lCase(mid(word, 2));
                arrayAppend(titleWords, titleWord);
            }
        }

        return arrayToList(titleWords, " ");
    }

    /**
     * Render navigation tree as HTML.
     */
    private string function renderNavigationHtml(
        required struct tree,
        string currentRelPath = ""
    ) {
        var html = '<nav class="docs-nav">' & chr(10);
        html &= '  <ul>' & chr(10);

        // Render root items
        for (var item in tree.rootItems) {
            html &= renderNavItem(item, arguments.currentRelPath, 2);
        }

        // Render sections
        for (var section in tree.sections) {
            html &= '    <li>' & chr(10);
            html &= '      <strong>' & htmlEditFormat(section.title) & '</strong>' & chr(10);
            html &= '      <ul>' & chr(10);

            for (var item in section.items) {
                html &= renderNavItem(item, arguments.currentRelPath, 4);
            }

            html &= '      </ul>' & chr(10);
            html &= '    </li>' & chr(10);
        }

        html &= '  </ul>' & chr(10);
        html &= '</nav>' & chr(10);

        return html;
    }

    /**
     * Render a single navigation item as <li>.
     * 
     * @param indentLevel Number of spaces for indentation
     */
    private string function renderNavItem(
        required struct item,
        string currentRelPath = "",
        numeric indentLevel = 2
    ) {
        var indent = repeatString(" ", arguments.indentLevel);
        var isActive = (len(arguments.currentRelPath) && lcase(item.relPath) == lcase(arguments.currentRelPath));
        var activeClass = isActive ? ' class="active"' : '';

        var html = indent & '<li' & activeClass & '>';
        html &= '<a href="' & htmlEditFormat(item.url) & '">';
        html &= htmlEditFormat(item.title);
        html &= '</a></li>' & chr(10);

        return html;
    }

}
