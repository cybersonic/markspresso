component {

    /**
     * SocialImageBuilder
     * Generates simple per-page PNG images using Java2D.
     * These images can be reused as og:image and on-page hero/header images.
     */

    function init(required any fileService) {
        variables.fileService = arguments.fileService;
        return this;
    }

    /**
     * Generate a social image for a document and return a web path (e.g. /social-images/docs/intro.png).
     */
    public string function generateForDocument(
        required struct config,
        required string outputDir,
        required struct doc,
        required struct meta
    ) {
        var socialConfig = structKeyExists(config, "socialImages") and isStruct(config.socialImages)
            ? config.socialImages
            : {};

        if (!structKeyExists(socialConfig, "enabled") or !socialConfig.enabled) {
            return "";
        }

        // Allow per-page opt-out in front matter: social_image: false
        if (structKeyExists(meta, "social_image") and !toBoolean(meta.social_image, true)) {
            return "";
        }

        var width  = max(600, int(val(structKeyExists(socialConfig, "width") ? socialConfig.width : 1200)));
        var height = max(315, int(val(structKeyExists(socialConfig, "height") ? socialConfig.height : 630)));
        var titleMaxLines = max(1, int(val(structKeyExists(socialConfig, "titleMaxLines") ? socialConfig.titleMaxLines : 3)));
        var descMaxLines  = max(1, int(val(structKeyExists(socialConfig, "descriptionMaxLines") ? socialConfig.descriptionMaxLines : 3)));

        var title = resolveTitle(meta, doc);
        var description = resolveDescription(meta, doc);
        var siteName = structKeyExists(config, "name") and len(trim("" & config.name)) ? trim("" & config.name) : "Markspresso";

        var relPath = buildImageRelativePath(
            doc       = doc,
            outputDir = (structKeyExists(socialConfig, "outputDir") ? socialConfig.outputDir : "social-images")
        );
        var fullPath = normalizeFsPath(outputDir & "/" & relPath);

        variables.fileService.ensureDir(getDirectoryFromPath(fullPath));

        renderImage(
            outputPath      = fullPath,
            width           = width,
            height          = height,
            siteName        = siteName,
            title           = title,
            description     = description,
            titleMaxLines   = titleMaxLines,
            descMaxLines    = descMaxLines,
            startColorHex   = (structKeyExists(socialConfig, "backgroundStartColor") ? socialConfig.backgroundStartColor : "##0f172a"),
            endColorHex     = (structKeyExists(socialConfig, "backgroundEndColor") ? socialConfig.backgroundEndColor : "##1d4ed8"),
            accentColorHex  = (structKeyExists(socialConfig, "accentColor") ? socialConfig.accentColor : "##60a5fa")
        );

        return "/" & replace(relPath, "\", "/", "all");
    }

    private void function renderImage(
        required string outputPath,
        required numeric width,
        required numeric height,
        required string siteName,
        required string title,
        required string description,
        required numeric titleMaxLines,
        required numeric descMaxLines,
        required string startColorHex,
        required string endColorHex,
        required string accentColorHex
    ) {
        var BufferedImage = createObject("java", "java.awt.image.BufferedImage");
        var image = BufferedImage.init(width, height, BufferedImage.TYPE_INT_ARGB);
        var g = image.createGraphics();

        try {
            var RenderingHints = createObject("java", "java.awt.RenderingHints");
            g.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
            g.setRenderingHint(RenderingHints.KEY_TEXT_ANTIALIASING, RenderingHints.VALUE_TEXT_ANTIALIAS_ON);
            g.setRenderingHint(RenderingHints.KEY_RENDERING, RenderingHints.VALUE_RENDER_QUALITY);

            var bgStart = parseHexColor(startColorHex, "0f172a");
            var bgEnd   = parseHexColor(endColorHex, "1d4ed8");
            var accent  = parseHexColor(accentColorHex, "60a5fa");
            var overlay = createColor(0, 0, 0, 135);

            var GradientPaint = createObject("java", "java.awt.GradientPaint");
            var gradient = GradientPaint.init(
                javacast("float", 0),
                javacast("float", 0),
                bgStart,
                javacast("float", width),
                javacast("float", height),
                bgEnd,
                false
            );
            g.setPaint(gradient);
            g.fillRect(0, 0, width, height);

            // Decorative accent bar
            g.setColor(accent);
            g.fillRoundRect(56, 48, 160, 10, 10, 10);

            // Text backing for contrast
            g.setColor(overlay);
            g.fillRoundRect(40, int(height * 0.30), width - 80, int(height * 0.62), 24, 24);

            var Font = createObject("java", "java.awt.Font");

            // Site label
            g.setFont(Font.init("SansSerif", Font.PLAIN, max(20, int(width / 42))));
            g.setColor(createColor(220, 235, 255));
            g.drawString(siteName, 56, 92);

            // Title
            g.setFont(Font.init("SansSerif", Font.BOLD, max(44, int(width / 16))));
            g.setColor(createColor(255, 255, 255));
            var titleStartY = int(height * 0.44);
            drawWrappedText(g, title, 56, titleStartY, width - 112, titleMaxLines, true);

            // Description
            g.setFont(Font.init("SansSerif", Font.PLAIN, max(24, int(width / 38))));
            g.setColor(createColor(233, 240, 248));
            var descStartY = int(height * 0.73);
            drawWrappedText(g, description, 56, descStartY, width - 112, descMaxLines, false);

            var ImageIO = createObject("java", "javax.imageio.ImageIO");
            var File = createObject("java", "java.io.File");
            ImageIO.write(image, "png", File.init(outputPath));
        }
        finally {
            g.dispose();
        }
    }

    private void function drawWrappedText(
        required any g,
        required string text,
        required numeric x,
        required numeric y,
        required numeric maxWidth,
        required numeric maxLines,
        boolean ellipsize = true
    ) {
        var wrapped = wrapLines(g, text, maxWidth, maxLines);
        var lines = wrapped.lines;
        var truncated = wrapped.truncated;
        var fm = g.getFontMetrics();
        var baseline = y;
        var lineHeight = fm.getHeight() + 4;

        if (truncated and ellipsize and arrayLen(lines)) {
            lines[arrayLen(lines)] = appendEllipsis(g, lines[arrayLen(lines)], maxWidth);
        }

        for (var line in lines) {
            g.drawString(line, x, baseline);
            baseline += lineHeight;
        }
    }

    private struct function wrapLines(
        required any g,
        required string text,
        required numeric maxWidth,
        required numeric maxLines
    ) {
        var cleanText = trim(reReplace(text ?: "", "\s+", " ", "all"));
        var lines = [];
        var truncated = false;

        if (!len(cleanText)) {
            return { lines = lines, truncated = false };
        }

        var words = listToArray(cleanText, " ");
        var currentLine = "";
        var consumedWords = 0;

        for (var i = 1; i <= arrayLen(words); i++) {
            var word = words[i];
            var candidate = len(currentLine) ? (currentLine & " " & word) : word;

            if (len(currentLine) and g.getFontMetrics().stringWidth(candidate) > maxWidth) {
                arrayAppend(lines, currentLine);
                if (arrayLen(lines) >= maxLines) {
                    truncated = true;
                    break;
                }
                currentLine = trimToWidth(g, word, maxWidth);
            }
            else {
                currentLine = trimToWidth(g, candidate, maxWidth);
            }

            consumedWords = i;
        }

        if (!truncated and len(currentLine)) {
            if (arrayLen(lines) < maxLines) {
                arrayAppend(lines, currentLine);
            }
            else {
                truncated = true;
            }
        }

        if (consumedWords < arrayLen(words)) {
            truncated = true;
        }

        return {
            lines = lines,
            truncated = truncated
        };
    }

    private string function appendEllipsis(required any g, required string value, required numeric maxWidth) {
        var base = trim(value ?: "");
        if (!len(base)) {
            return "...";
        }

        var withDots = base & "...";
        if (g.getFontMetrics().stringWidth(withDots) <= maxWidth) {
            return withDots;
        }

        var trimmed = trimToWidth(g, base, maxWidth);
        while (len(trimmed) and g.getFontMetrics().stringWidth(trimmed & "...") > maxWidth) {
            trimmed = left(trimmed, len(trimmed) - 1);
        }

        return len(trimmed) ? (trimmed & "...") : "...";
    }

    private string function trimToWidth(required any g, required string value, required numeric maxWidth) {
        var text = trim(value ?: "");
        if (!len(text)) {
            return "";
        }

        if (g.getFontMetrics().stringWidth(text) <= maxWidth) {
            return text;
        }

        var output = text;
        while (len(output) and g.getFontMetrics().stringWidth(output) > maxWidth) {
            output = left(output, len(output) - 1);
        }
        return len(output) ? output : left(text, 1);
    }

    private string function resolveTitle(required struct meta, required struct doc) {
        if (structKeyExists(meta, "social_title") and len(trim("" & meta.social_title))) {
            return trim("" & meta.social_title);
        }
        if (structKeyExists(meta, "og_title") and len(trim("" & meta.og_title))) {
            return trim("" & meta.og_title);
        }
        if (structKeyExists(meta, "title") and len(trim("" & meta.title))) {
            return trim("" & meta.title);
        }
        if (structKeyExists(doc, "relPath") and len(trim("" & doc.relPath))) {
            return trim("" & doc.relPath);
        }
        return "Untitled";
    }

    private string function resolveDescription(required struct meta, required struct doc) {
        if (structKeyExists(meta, "social_description") and len(trim("" & meta.social_description))) {
            return trim("" & meta.social_description);
        }
        if (structKeyExists(meta, "og_description") and len(trim("" & meta.og_description))) {
            return trim("" & meta.og_description);
        }
        if (structKeyExists(meta, "description") and len(trim("" & meta.description))) {
            return trim("" & meta.description);
        }
        if (structKeyExists(meta, "subtitle") and len(trim("" & meta.subtitle))) {
            return trim("" & meta.subtitle);
        }

        if (structKeyExists(doc, "html") and len(trim("" & doc.html))) {
            var html = "" & doc.html;
            var paragraph = reFindNoCase("(?is)<p[^>]*>(.*?)</p>", html, 1, true);
            if (isStruct(paragraph) and arrayLen(paragraph.pos) >= 2 and paragraph.pos[2] GT 0 and paragraph.len[2] GT 0) {
                var paragraphText = mid(html, paragraph.pos[2], paragraph.len[2]);
                paragraphText = reReplace(paragraphText, "<[^>]+>", "", "all");
                paragraphText = reReplace(paragraphText, "\s+", " ", "all");
                paragraphText = trim(paragraphText);
                if (len(paragraphText) > 240) {
                    paragraphText = left(paragraphText, 237) & "...";
                }
                if (len(paragraphText)) {
                    return paragraphText;
                }
            }
        }

        return "Built with Markspresso";
    }

    private string function buildImageRelativePath(required struct doc, required string outputDir) {
        var base = trim("" & outputDir);
        if (!len(base)) {
            base = "social-images";
        }
        base = replace(base, "\", "/", "all");
        while (len(base) and left(base, 1) == "/") {
            base = mid(base, 2);
        }
        while (len(base) and right(base, 1) == "/") {
            base = left(base, len(base) - 1);
        }

        var documentPath = "";
        if (structKeyExists(doc, "canonicalUrl") and len(trim("" & doc.canonicalUrl))) {
            documentPath = canonicalToPath("" & doc.canonicalUrl);
        }
        if (!len(documentPath) and structKeyExists(doc, "relPath") and len(trim("" & doc.relPath))) {
            documentPath = reReplace(replace(trim("" & doc.relPath), "\", "/", "all"), "\.[^.]+$", "");
        }
        if (!len(documentPath)) {
            documentPath = "index";
        }

        var pathSegments = listToArray(documentPath, "/");
        var cleanSegments = [];
        for (var segment in pathSegments) {
            var clean = sanitizePathSegment(segment);
            if (len(clean)) {
                arrayAppend(cleanSegments, clean);
            }
        }
        if (!arrayLen(cleanSegments)) {
            arrayAppend(cleanSegments, "index");
        }

        return base & "/" & arrayToList(cleanSegments, "/") & ".png";
    }

    private string function canonicalToPath(required string canonicalUrl) {
        var value = trim(canonicalUrl ?: "");
        if (!len(value)) {
            return "";
        }

        // Support full URLs and path-only canonical values.
        if (findNoCase("://", value)) {
            try {
                value = createObject("java", "java.net.URI").init(value).getPath();
            }
            catch (any _ignore) {
                // keep original for path cleanup below
            }
        }

        value = replace(value, "\", "/", "all");
        if (find("?", value)) {
            value = listFirst(value, "?");
        }
        if (find("##", value)) {
            value = listFirst(value, "##");
        }
        while (len(value) and left(value, 1) == "/") {
            value = mid(value, 2);
        }
        while (len(value) and right(value, 1) == "/") {
            value = left(value, len(value) - 1);
        }
        if (!len(value)) {
            return "index";
        }
        value = reReplace(value, "\.html$", "");
        return value;
    }

    private string function sanitizePathSegment(required string value) {
        var output = lcase(trim(value ?: ""));
        output = reReplace(output, "[^a-z0-9._-]+", "-", "all");
        output = reReplace(output, "^-+|-+$", "", "all");
        return output;
    }

    private any function parseHexColor(required string value, string fallback = "0f172a") {
        var hex = trim(value ?: "");
        if (!len(hex)) {
            hex = fallback;
        }
        if (left(hex, 1) == "##") {
            hex = mid(hex, 2);
        }
        hex = lcase(hex);
        if (!reFind("^[0-9a-f]{6}$", hex)) {
            hex = lcase(fallback);
        }

        var r = inputBaseN(mid(hex, 1, 2), 16);
        var g = inputBaseN(mid(hex, 3, 2), 16);
        var b = inputBaseN(mid(hex, 5, 2), 16);
        return createColor(r, g, b);
    }

    private any function createColor(required numeric r, required numeric g, required numeric b, numeric a = 255) {
        var Color = createObject("java", "java.awt.Color");
        return Color.init(
            javacast("int", r),
            javacast("int", g),
            javacast("int", b),
            javacast("int", a)
        );
    }

    private string function normalizeFsPath(required string inputPath) {
        return replace(inputPath, "\", "/", "all");
    }

    private boolean function toBoolean(any value, boolean defaultValue = false) {
        if (isBoolean(value)) {
            return value;
        }
        if (isSimpleValue(value)) {
            var text = lcase(trim("" & value));
            if (text == "true" or text == "1" or text == "yes" or text == "on") {
                return true;
            }
            if (text == "false" or text == "0" or text == "no" or text == "off") {
                return false;
            }
        }
        return defaultValue;
    }

}
