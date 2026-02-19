component {

    /**
     * PdfBuilder
     * Generates PDF documents from Markdown content using cfdocument.
     * Handles document discovery, ordering, TOC generation, and PDF rendering.
     */

    function init(
        required any configService,
        required any contentParser,
        required any fileService,
        string cwd = ""
    ) {
        variables.configService = arguments.configService;
        variables.contentParser = arguments.contentParser;
        variables.fileService   = arguments.fileService;
        variables.cwd           = arguments.cwd;
        return this;
    }

    /**
     * Build a PDF from the docs collection.
     * @rootPath Optional subdirectory under content (e.g., "docs")
     * @outFile  Output filename (defaults to config or "output.pdf")
     * @drafts   Include draft content
     * @toc      Generate table of contents
     */
    public struct function buildPdf(
        string rootPath = "",
        string outFile  = "",
        boolean drafts  = false,
        boolean toc     = true
    ) {
        out("Building PDF...");

        var siteRoot = getSiteRoot();
        var config   = variables.configService.load(siteRoot);

        // Get PDF config with defaults
        var pdfConfig = getPdfConfig(config);

        // Determine content root (docs only, exclude posts)
        var contentDir = siteRoot & "/" & config.paths.content;
        if (len(rootPath)) {
            contentDir &= "/" & rootPath;
        } else if (structKeyExists(pdfConfig, "rootPath") && len(pdfConfig.rootPath)) {
            contentDir &= "/" & pdfConfig.rootPath;
        }

        // Discover and order markdown files
        var mdFiles = variables.fileService.discoverMarkdownFiles(contentDir);
        
        // Filter out posts directory
        var postsPath = siteRoot & "/" & config.paths.content & "/posts";
        mdFiles = mdFiles.filter(function(f) {
            return findNoCase(postsPath, f) == 0;
        });

        if (arrayLen(mdFiles) == 0) {
            out("No documents found for PDF generation.");
            return { success = false, message = "No documents found" };
        }

        out("Found #arrayLen(mdFiles)# document(s) for PDF.");

        // Parse and order documents
        var documents = [];
        for (var filePath in mdFiles) {
            var parsed = variables.contentParser.parseMarkdownFile(filePath, drafts);
            if (!isNull(parsed)) {
                var relPath = replace(filePath, contentDir & "/", "");
                arrayAppend(documents, {
                    filePath = filePath,
                    relPath  = relPath,
                    title    = structKeyExists(parsed.meta, "title") ? parsed.meta.title : getFileFromPath(filePath),
                    order    = extractOrder(relPath),
                    meta     = parsed.meta,
                    html     = parsed.html
                });
            }
        }

        // Sort by order (numeric prefix in filename)
        arraySort(documents, function(a, b) {
            return a.order - b.order;
        });

        // Build combined HTML with chapter markers
        var combinedHtml = buildCombinedHtml(documents, toc, pdfConfig, siteRoot, config);

        // Determine output path
        var outputFile = len(outFile) ? outFile : pdfConfig.output;
        if (!findNoCase(".pdf", outputFile)) {
            outputFile &= ".pdf";
        }
        var outputPath = siteRoot & "/" & outputFile;

        // Debug: write the combined HTML to see what we're generating
        fileWrite(siteRoot & "/debug-pdf-input.html", combinedHtml);
        out("Debug HTML written to: " & siteRoot & "/debug-pdf-input.html");

        // Generate PDF using external template
        var pdfBinary = generatePdfFromHtml(combinedHtml, pdfConfig);

        // Write to file
        fileWrite(outputPath, pdfBinary);

        out("PDF generated: #outputPath#");
        return { success = true, outputPath = outputPath, documentCount = arrayLen(documents) };
    }

    /**
     * Get PDF configuration with defaults applied.
     */
    private struct function getPdfConfig(struct config) {
        var defaults = {
            enabled     = true,
            output      = "output.pdf",
            rootPath    = "docs",
            title       = structKeyExists(config, "name") ? config.name : "Documentation",
            author      = "",
            pageSize    = "A4",
            orientation = "portrait",
            marginTop   = 1,
            marginBottom= 1,
            marginLeft  = 0.75,
            marginRight = 0.75,
            unit        = "in",
            tocEnabled  = true,
            headerHtml  = "",
            footerHtml  = ""
        };

        if (structKeyExists(config, "pdf")) {
            structAppend(defaults, config.pdf, true);
        }

        return defaults;
    }

    /**
     * Extract numeric order from filename (e.g., "01-intro.md" -> 1).
     */
    private numeric function extractOrder(string relPath) {
        var fileName = getFileFromPath(relPath);
        var match = reFind("^(\d+)", fileName, 1, true);
        if (match.pos[1] > 0) {
            return val(mid(fileName, match.pos[1], match.len[1]));
        }
        return 999; // Default for unordered files
    }

    /**
     * Build combined HTML content with TOC and chapter markers.
     * Returns struct with { styles, tocHtml, chaptersHtml } for template to assemble.
     */
    private string function buildCombinedHtml(
        array documents,
        boolean includeToc,
        struct pdfConfig,
        string siteRoot,
        struct config
    ) {
        var html = "";
        var assetsDir = siteRoot & "/" & config.paths.assets;

        // Add TOC if enabled
        if (includeToc && arrayLen(documents) > 0) {
            html &= '<!--TOC_START-->' & chr(10);
            html &= buildTableOfContents(documents, pdfConfig);
            html &= '<!--TOC_END-->' & chr(10);
        }

        // Add each document with chapter markers
        for (var doc in documents) {
            // Add chapter marker for per-section headers
            html &= '<!--CHAPTER:' & doc.title & '-->' & chr(10);

            // Add document content with resolved image paths
            var docHtml = resolveImagePaths(doc.html, siteRoot, assetsDir);
            html &= '<article class="chapter">' & chr(10);
            html &= '<h1>' & htmlEditFormat(doc.title) & '</h1>' & chr(10);
            html &= docHtml & chr(10);
            html &= '</article>' & chr(10);
        }

        // Store styles separately for template to use
        variables.pdfStyles = '
        body { font-family: Georgia, "Times New Roman", serif; font-size: 11pt; line-height: 1.5; color: ##333; }
        h1 { font-size: 24pt; margin-bottom: 0.5em; color: ##111; border-bottom: 2px solid ##333; padding-bottom: 0.3em; }
        h2 { font-size: 18pt; margin-top: 1.5em; color: ##222; }
        h3 { font-size: 14pt; margin-top: 1.2em; color: ##333; }
        p { margin: 0.8em 0; text-align: justify; }
        code { font-family: "Courier New", monospace; font-size: 10pt; background: ##f4f4f4; padding: 2px 2px; }
        pre { background: ##f4f4f4; padding: 6px 8px 6px 12px; overflow-x: auto; font-size: 9pt; border: 1px solid ##ddd; text-align: left; margin: 0.4em 0; line-height: 1.2; white-space: pre-wrap; }
        pre code { background: none; padding: 0; margin: 0; display: block; text-align: left; line-height: 1.2; white-space: pre-wrap; }
        ul, ol { margin: 0.8em 0; padding-left: 2em; }
        li { margin: 0.3em 0; }
        a { color: ##0066cc; text-decoration: none; }
        blockquote { margin: 1em 0; padding: 0.5em 1em; border-left: 4px solid ##ddd; color: ##666; font-style: italic; }
        table { border-collapse: collapse; width: 100%; margin: 1em 0; }
        th, td { border: 1px solid ##ddd; padding: 8px; text-align: left; }
        th { background: ##f4f4f4; }
        img { max-width: 100%; height: auto; }
        .toc { margin: 2em 0; }
        .toc h2 { border-bottom: 1px solid ##ccc; }
        .toc ul { list-style: none; padding-left: 0; }
        .toc li { margin: 0.5em 0; padding-left: 1em; }
        .toc a { color: ##333; }
        .chapter { margin-bottom: 2em; }
        ';

        return html;
    }

    /**
     * Build table of contents HTML.
     */
    private string function buildTableOfContents(array documents, struct pdfConfig) {
        var toc = '<div class="toc">' & chr(10);
        toc &= '<h2>Table of Contents</h2>' & chr(10);
        toc &= '<ul>' & chr(10);

        for (var doc in documents) {
            toc &= '<li><a href="##">' & htmlEditFormat(doc.title) & '</a></li>' & chr(10);
        }

        toc &= '</ul>' & chr(10);
        toc &= '</div>' & chr(10);

        return toc;
    }

    /**
     * Resolve relative image paths to absolute file:// paths for PDF rendering.
     */
    private string function resolveImagePaths(string html, string siteRoot, string assetsDir) {
        var result = html;

        // Replace src="assets/... or src="/assets/... with absolute paths
        result = reReplaceNoCase(result, 'src="/?assets/', 'src="file:///' & replace(assetsDir, "\", "/", "all") & '/', 'all');
        
        // Replace src="images/... or src="/images/... with absolute paths  
        result = reReplaceNoCase(result, 'src="/?images/', 'src="file:///' & replace(assetsDir, "\", "/", "all") & '/images/', 'all');

        // Handle relative paths that might exist
        result = reReplaceNoCase(result, 'src="\.\./', 'src="file:///' & replace(siteRoot, "\", "/", "all") & '/', 'all');

        return result;
    }

    /**
     * Generate PDF binary from HTML using cfdocument.
     */
    private binary function generatePdfFromHtml(string html, struct pdfConfig) {
        var result = "";
        
        // Prepare header/footer with token replacement
        var headerHtml = structKeyExists(pdfConfig, "headerHtml") ? pdfConfig.headerHtml : "";
        var footerHtml = structKeyExists(pdfConfig, "footerHtml") ? pdfConfig.footerHtml : "";
        
        // Check if we need per-chapter headers
        var hasChapterToken = (findNoCase("currentChapterTitle", headerHtml) > 0) 
                           || (findNoCase("currentChapterTitle", footerHtml) > 0);
        
        // Replace static tokens
        if (structKeyExists(pdfConfig, "title")) {
            headerHtml = replaceNoCase(headerHtml, "{{ title }}", pdfConfig.title, "all");
            headerHtml = replaceNoCase(headerHtml, "{{title}}", pdfConfig.title, "all");
            footerHtml = replaceNoCase(footerHtml, "{{ title }}", pdfConfig.title, "all");
            footerHtml = replaceNoCase(footerHtml, "{{title}}", pdfConfig.title, "all");
        }
        if (structKeyExists(pdfConfig, "author")) {
            headerHtml = replaceNoCase(headerHtml, "{{ author }}", pdfConfig.author, "all");
            headerHtml = replaceNoCase(headerHtml, "{{author}}", pdfConfig.author, "all");
            footerHtml = replaceNoCase(footerHtml, "{{ author }}", pdfConfig.author, "all");
            footerHtml = replaceNoCase(footerHtml, "{{author}}", pdfConfig.author, "all");
        }
        
        // Replace currentChapterTitle with placeholder for template
        headerHtml = replaceNoCase(headerHtml, "{{ currentChapterTitle }}", "__CHAPTERTITLE__", "all");
        headerHtml = replaceNoCase(headerHtml, "{{currentChapterTitle}}", "__CHAPTERTITLE__", "all");
        footerHtml = replaceNoCase(footerHtml, "{{ currentChapterTitle }}", "__CHAPTERTITLE__", "all");
        footerHtml = replaceNoCase(footerHtml, "{{currentChapterTitle}}", "__CHAPTERTITLE__", "all");
        
        // Use placeholders for page numbers (replaced at runtime in template)
        headerHtml = replaceNoCase(headerHtml, "{{ currentPage }}", "__CURRENTPAGE__", "all");
        headerHtml = replaceNoCase(headerHtml, "{{currentPage}}", "__CURRENTPAGE__", "all");
        headerHtml = replaceNoCase(headerHtml, "{{ totalPages }}", "__TOTALPAGES__", "all");
        headerHtml = replaceNoCase(headerHtml, "{{totalPages}}", "__TOTALPAGES__", "all");
        headerHtml = replaceNoCase(headerHtml, "{{ currentSectionPage }}", "__CURRENTSECTIONPAGE__", "all");
        headerHtml = replaceNoCase(headerHtml, "{{currentSectionPage}}", "__CURRENTSECTIONPAGE__", "all");
        headerHtml = replaceNoCase(headerHtml, "{{ totalSectionPages }}", "__TOTALSECTIONPAGES__", "all");
        headerHtml = replaceNoCase(headerHtml, "{{totalSectionPages}}", "__TOTALSECTIONPAGES__", "all");
        footerHtml = replaceNoCase(footerHtml, "{{ currentPage }}", "__CURRENTPAGE__", "all");
        footerHtml = replaceNoCase(footerHtml, "{{currentPage}}", "__CURRENTPAGE__", "all");
        footerHtml = replaceNoCase(footerHtml, "{{ totalPages }}", "__TOTALPAGES__", "all");
        footerHtml = replaceNoCase(footerHtml, "{{totalPages}}", "__TOTALPAGES__", "all");
        footerHtml = replaceNoCase(footerHtml, "{{ currentSectionPage }}", "__CURRENTSECTIONPAGE__", "all");
        footerHtml = replaceNoCase(footerHtml, "{{currentSectionPage}}", "__CURRENTSECTIONPAGE__", "all");
        footerHtml = replaceNoCase(footerHtml, "{{ totalSectionPages }}", "__TOTALSECTIONPAGES__", "all");
        footerHtml = replaceNoCase(footerHtml, "{{totalSectionPages}}", "__TOTALSECTIONPAGES__", "all");
        
        // Store config for template (keep chapter markers in HTML for template to parse)
        variables.pdfHtml = html;
        variables.pdfHeaderHtml = headerHtml;
        variables.pdfFooterHtml = footerHtml;
        variables.pdfPageConfig = pdfConfig;
        variables.pdfHasChapterToken = hasChapterToken;
        
        // Include external CFM template that uses tag syntax
        include template="templates/generatePdf.cfm";
        
        return result;
    }

    /**
     * Get the site root directory.
     */
    private string function getSiteRoot() {
        if (len(variables.cwd)) {
            return variables.cwd;
        }
        return getDirectoryFromPath(getCurrentTemplatePath()) & "../";
    }

    /**
     * Output helper.
     */
    private void function out(string message) {
        systemOutput(message, true, false);
    }

}
