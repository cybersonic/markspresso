component {

    /**
     * FeedGenerator
     * Generates RSS 2.0 and Atom feeds for collections.
     */

    function init(required any fileService) {
        variables.fileService = arguments.fileService;
        return this;
    }

    /**
     * Generate feeds for a collection.
     *
     * @param config        Full site config
     * @param collectionName Name of the collection (e.g. "posts")
     * @param items         Array of items with: title, date, url, description (optional), content (optional)
     * @param outputDir     Absolute path to output directory
     */
    public void function generateFeeds(
        required struct config,
        required string collectionName,
        required array items,
        required string outputDir
    ) {
        if (!structKeyExists(config, "collections") or !structKeyExists(config.collections, collectionName)) {
            return;
        }

        var colConfig = config.collections[collectionName];

        if (!structKeyExists(colConfig, "feed") or !colConfig.feed.enabled) {
            return;
        }

        var feedConfig = colConfig.feed;
        var formats    = feedConfig.formats;
        var limit      = feedConfig.limit;

        // Limit items
        var feedItems = [];
        var maxItems  = min(limit, arrayLen(items));
        for (var i = 1; i <= maxItems; i++) {
            arrayAppend(feedItems, items[i]);
        }

        // Resolve feed metadata
        var siteTitle = structKeyExists(config, "name") ? config.name : "Markspresso Site";
        var baseUrl   = structKeyExists(config, "baseUrl") ? config.baseUrl : "";

        // Normalize baseUrl (remove trailing slash)
        while (len(baseUrl) and right(baseUrl, 1) == "/") {
            baseUrl = left(baseUrl, len(baseUrl) - 1);
        }

        var feedTitle = len(feedConfig.title) ? feedConfig.title : (siteTitle & " - " & collectionName);
        var feedDescription = len(feedConfig.description) ? feedConfig.description : ("Latest " & collectionName & " from " & siteTitle);
        var feedLink  = baseUrl & "/" & collectionName & "/";

        // Generate requested formats
        for (var format in formats) {
            if (format == "rss") {
                var rssXml = generateRss(
                    title       = feedTitle,
                    description = feedDescription,
                    link        = feedLink,
                    baseUrl     = baseUrl,
                    items       = feedItems
                );
                var rssPath = outputDir & "/" & collectionName & "/feed.xml";
                variables.fileService.ensureDir(getDirectoryFromPath(rssPath));
                fileWrite(rssPath, rssXml, "UTF-8");
            }
            else if (format == "atom") {
                var atomXml = generateAtom(
                    title   = feedTitle,
                    subtitle = feedDescription,
                    link    = feedLink,
                    baseUrl = baseUrl,
                    items   = feedItems
                );
                var atomPath = outputDir & "/" & collectionName & "/atom.xml";
                variables.fileService.ensureDir(getDirectoryFromPath(atomPath));
                fileWrite(atomPath, atomXml, "UTF-8");
            }
        }
    }

    /**
     * Generate RSS 2.0 XML.
     */
    private string function generateRss(
        required string title,
        required string description,
        required string link,
        required string baseUrl,
        required array items
    ) {
        var xml = '<?xml version="1.0" encoding="UTF-8"?>' & chr(10);
        xml &= '<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">' & chr(10);
        xml &= '  <channel>' & chr(10);
        xml &= '    <title>' & xmlFormat(title) & '</title>' & chr(10);
        xml &= '    <link>' & xmlFormat(link) & '</link>' & chr(10);
        xml &= '    <description>' & xmlFormat(description) & '</description>' & chr(10);
        xml &= '    <language>en-us</language>' & chr(10);
        xml &= '    <lastBuildDate>' & formatRfc822Date(now()) & '</lastBuildDate>' & chr(10);
        xml &= '    <atom:link href="' & xmlFormat(link & "feed.xml") & '" rel="self" type="application/rss+xml"/>' & chr(10);

        for (var item in items) {
            var itemTitle = structKeyExists(item, "title") ? item.title : "Untitled";
            var itemUrl   = structKeyExists(item, "url") ? item.url : "";
            var itemDate  = structKeyExists(item, "date") ? item.date : "";
            var itemDesc  = structKeyExists(item, "description") ? item.description : "";
            var itemContent = structKeyExists(item, "content") ? item.content : "";

            // Build full URL
            var fullUrl = itemUrl;
            if (len(itemUrl) and left(itemUrl, 1) == "/") {
                fullUrl = baseUrl & itemUrl;
            }

            xml &= '    <item>' & chr(10);
            xml &= '      <title>' & xmlFormat(itemTitle) & '</title>' & chr(10);
            xml &= '      <link>' & xmlFormat(fullUrl) & '</link>' & chr(10);
            xml &= '      <guid isPermaLink="true">' & xmlFormat(fullUrl) & '</guid>' & chr(10);

            if (len(itemDate)) {
                xml &= '      <pubDate>' & formatRfc822Date(parseDate(itemDate)) & '</pubDate>' & chr(10);
            }

            if (len(itemDesc)) {
                xml &= '      <description>' & xmlFormat(itemDesc) & '</description>' & chr(10);
            }
            else if (len(itemContent)) {
                // Use content snippet as description (first 200 chars, strip tags)
                var snippet = left(reReplace(itemContent, "<[^>]*>", "", "all"), 200);
                if (len(itemContent) > 200) snippet &= "...";
                xml &= '      <description>' & xmlFormat(snippet) & '</description>' & chr(10);
            }

            xml &= '    </item>' & chr(10);
        }

        xml &= '  </channel>' & chr(10);
        xml &= '</rss>';

        return xml;
    }

    /**
     * Generate Atom 1.0 XML.
     */
    private string function generateAtom(
        required string title,
        required string subtitle,
        required string link,
        required string baseUrl,
        required array items
    ) {
        var xml = '<?xml version="1.0" encoding="UTF-8"?>' & chr(10);
        xml &= '<feed xmlns="http://www.w3.org/2005/Atom">' & chr(10);
        xml &= '  <title>' & xmlFormat(title) & '</title>' & chr(10);
        xml &= '  <subtitle>' & xmlFormat(subtitle) & '</subtitle>' & chr(10);
        xml &= '  <link href="' & xmlFormat(link & "atom.xml") & '" rel="self" type="application/atom+xml"/>' & chr(10);
        xml &= '  <link href="' & xmlFormat(link) & '" rel="alternate" type="text/html"/>' & chr(10);
        xml &= '  <id>' & xmlFormat(link) & '</id>' & chr(10);
        xml &= '  <updated>' & formatIso8601Date(now()) & '</updated>' & chr(10);

        for (var item in items) {
            var itemTitle = structKeyExists(item, "title") ? item.title : "Untitled";
            var itemUrl   = structKeyExists(item, "url") ? item.url : "";
            var itemDate  = structKeyExists(item, "date") ? item.date : "";
            var itemDesc  = structKeyExists(item, "description") ? item.description : "";
            var itemContent = structKeyExists(item, "content") ? item.content : "";

            // Build full URL
            var fullUrl = itemUrl;
            if (len(itemUrl) and left(itemUrl, 1) == "/") {
                fullUrl = baseUrl & itemUrl;
            }

            xml &= '  <entry>' & chr(10);
            xml &= '    <title>' & xmlFormat(itemTitle) & '</title>' & chr(10);
            xml &= '    <link href="' & xmlFormat(fullUrl) & '" rel="alternate" type="text/html"/>' & chr(10);
            xml &= '    <id>' & xmlFormat(fullUrl) & '</id>' & chr(10);

            if (len(itemDate)) {
                xml &= '    <published>' & formatIso8601Date(parseDate(itemDate)) & '</published>' & chr(10);
                xml &= '    <updated>' & formatIso8601Date(parseDate(itemDate)) & '</updated>' & chr(10);
            }
            else {
                xml &= '    <updated>' & formatIso8601Date(now()) & '</updated>' & chr(10);
            }

            if (len(itemDesc)) {
                xml &= '    <summary type="text">' & xmlFormat(itemDesc) & '</summary>' & chr(10);
            }

            if (len(itemContent)) {
                xml &= '    <content type="html"><![CDATA[' & itemContent & ']]></content>' & chr(10);
            }

            xml &= '  </entry>' & chr(10);
        }

        xml &= '</feed>';

        return xml;
    }

    /**
     * Format a date as RFC 822 (for RSS).
     * Example: "Tue, 10 Jun 2003 04:00:00 GMT"
     */
    private string function formatRfc822Date(required date d) {
        return dateTimeFormat(d, "EEE, dd MMM yyyy HH:nn:ss") & " GMT";
    }

    /**
     * Format a date as ISO 8601 (for Atom).
     * Example: "2003-06-10T04:00:00Z"
     */
    private string function formatIso8601Date(required date d) {
        return dateTimeFormat(d, "yyyy-MM-dd'T'HH:nn:ss'Z'");
    }

    /**
     * Parse a date string (supports YYYY-MM-DD and common formats).
     */
    private date function parseDate(required string dateStr) {
        try {
            // Handle YYYY-MM-DD format
            if (reFind("^\d{4}-\d{2}-\d{2}$", dateStr)) {
                return createDate(
                    val(left(dateStr, 4)),
                    val(mid(dateStr, 6, 2)),
                    val(mid(dateStr, 9, 2))
                );
            }
            return parseDateTime(dateStr);
        }
        catch (any e) {
            return now();
        }
    }

}
