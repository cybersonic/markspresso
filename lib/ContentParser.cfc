component {

    /**
     * ContentParser
     * Pure parsing logic for Markdown content and front matter.
     * No file I/O - operates on strings.
     */

    function init() {
        return this;
    }

    /**
     * Parse a Markdown file: extract front matter and convert body to HTML.
     * Returns { meta, html } or null if the file is a draft and should be skipped.
     */
    public any function parseMarkdownFile(string filePath, boolean includeDrafts = false) {
        var raw = fileRead(filePath, "UTF-8");
        var parsed = parseFrontMatter(raw);

        // Skip drafts unless explicitly included
        if (structKeyExists(parsed.meta, "draft") 
            and isBoolean(parsed.meta.draft) 
            and parsed.meta.draft 
            and !includeDrafts) {
            return nullValue();
        }

        var html = renderMarkdown(parsed.body);
        return { meta = parsed.meta, html = html };
    }

    /**
     * Extract YAML-like front matter from content.
     * Returns { meta = {}, body = "" }.
     */
    public struct function parseFrontMatter(string contents) {
        var result = { meta = {}, body = contents };
        var newline    = chr(10);
        var startToken = "---" & newline;
        var endToken   = newline & "---" & newline;

        // Check if content starts with front matter delimiter
        if (left(contents, len(startToken)) != startToken) {
            return result;
        }

        var withoutStart = mid(contents, len(startToken) + 1);
        var endPos       = find(endToken, withoutStart);
        if (!endPos) {
            return result;
        }

        var fmBlock = left(withoutStart, endPos - 1);
        var body    = mid(withoutStart, endPos + len(endToken));

        var meta = {};
        var lines = listToArray(fmBlock, newline);

        for (var line in lines) {
            line = trim(line);
            
            // Skip empty lines and comments (lines starting with ##)
            if (!len(line) or left(line, 1) == "##") continue;

            var sepPos = find(":", line);
            if (!sepPos) continue;

            var key   = trim(left(line, sepPos - 1));
            var value = trim(mid(line, sepPos + 1));

            if (!len(key)) continue;

            // Type coercion: booleans and numbers
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

    /**
     * Convert Markdown text to HTML.
     * Uses CFML's built-in MarkdownToHTML function.
     */
    public string function renderMarkdown(string src) {
        return MarkDownToHTML(src);
    }

    /**
     * Apply layout template with token replacement.
     * Replaces {{ key }} and {{key}} with values from meta and content.
     * Supports conditional blocks: {{#if key}}...{{/if}} and {{#if key}}...{{else}}...{{/if}}
     */
    public string function applyLayout(string layoutHtml, struct meta, string contentHtml) {
        var data = duplicate(meta);
        
        // Ensure title exists
        if (!structKeyExists(data, "title")) {
            data.title = "";
        }
        
        // First, allow tokens/conditionals inside the rendered content itself.
        // This lets things like {{ latest_posts }} or {{ archives_list }} work
        // when they appear in Markdown bodies (e.g. content/index.md).
        var processedContent = contentHtml;
        
        // Process conditionals in content
        processedContent = processConditionals(processedContent, data);
        
        // Replace simple tokens in content
        for (var cKey in data) {
            var cVal = data[cKey];
            processedContent = replaceNoCase(processedContent, "{{ " & cKey & " }}", cVal, "all");
            processedContent = replaceNoCase(processedContent, "{{" & cKey & "}}", cVal, "all");
        }
        
        // Expose the processed content to the layout as {{ content }}
        data.content = processedContent;

        // Now process the layout HTML using the same data (including content)
        layoutHtml = processConditionals(layoutHtml, data);

        for (var key in data) {
            var value = data[key];
            layoutHtml = replaceNoCase(layoutHtml, "{{ " & key & " }}", value, "all");
            layoutHtml = replaceNoCase(layoutHtml, "{{" & key & "}}", value, "all");
        }

        return layoutHtml;
    }

    /**
     * Process conditional blocks: {{#if key}}...{{/if}} and {{#if key}}...{{else}}...{{/if}}
     * Evaluates truthiness and includes/excludes content accordingly.
     */
    private string function processConditionals(string template, struct data) {
        var result = template;
        
        // Match {{#if key}}...{{/if}} blocks (with optional {{else}})
        // Using regex to find blocks, then process them
        var ifPattern = "\{\{##if\s+(\w+)\s*\}\}";
        var elsePattern = "\{\{else\}\}";
        var endIfPattern = "\{\{/if\}\}";
        
        // Process all if blocks (including nested ones by processing from innermost to outermost)
        var maxIterations = 100; // Prevent infinite loops
        var iteration = 0;
        
        while (reFindNoCase(ifPattern, result) > 0 && iteration < maxIterations) {
            iteration++;
            
            var ifMatch = reFindNoCase(ifPattern, result, 1, true);
            if (ifMatch.pos[1] == 0) break;
            
            var ifStartPos = ifMatch.pos[1];
            var ifKey = mid(result, ifMatch.pos[2], ifMatch.len[2]);
            var ifEndPos = ifMatch.pos[1] + ifMatch.len[1] - 1;
            
            // Find the matching {{/if}}
            var endIfPos = findMatchingEndIf(result, ifEndPos + 1);
            if (endIfPos == 0) break; // No matching end tag found
            
            // Extract the content between {{#if}} and {{/if}}
            var blockContent = mid(result, ifEndPos + 1, endIfPos - ifEndPos - 1);
            
            // Check for {{else}} within this block
            var elseMatch = reFindNoCase(elsePattern, blockContent, 1, true);
            var trueContent = "";
            var falseContent = "";
            
            if (elseMatch.pos[1] > 0) {
                // Has else clause
                trueContent = left(blockContent, elseMatch.pos[1] - 1);
                falseContent = mid(blockContent, elseMatch.pos[1] + elseMatch.len[1]);
            } else {
                // No else clause
                trueContent = blockContent;
                falseContent = "";
            }
            
            // Evaluate the condition
            var conditionValue = structKeyExists(data, ifKey) ? data[ifKey] : "";
            var isTrue = isTruthy(conditionValue);
            
            // Replace the entire block with the appropriate content
            var replacement = isTrue ? trueContent : falseContent;
            var endIfEndPos = endIfPos + len("{{/if}}") - 1;
            
            result = left(result, ifStartPos - 1) & replacement & mid(result, endIfEndPos + 1);
        }
        
        return result;
    }

    /**
     * Find the matching {{/if}} for a given position after {{#if}}.
     * Handles nested if blocks by counting depth.
     */
    private numeric function findMatchingEndIf(string template, numeric startPos) {
        var depth = 1;
        var pos = startPos;
        var ifPattern = "\{\{##if\s+\w+\s*\}\}";
        var endIfPattern = "\{\{/if\}\}";
        
        while (depth > 0 && pos <= len(template)) {
            var nextIf = reFindNoCase(ifPattern, template, pos, true);
            var nextEndIf = reFindNoCase(endIfPattern, template, pos, true);
            
            if (nextEndIf.pos[1] == 0) {
                // No more {{/if}} found
                return 0;
            }
            
            // Check if there's a nested {{#if}} before the next {{/if}}
            if (nextIf.pos[1] > 0 && nextIf.pos[1] < nextEndIf.pos[1]) {
                // Found nested if, increase depth
                depth++;
                pos = nextIf.pos[1] + nextIf.len[1];
            } else {
                // Found closing endif
                depth--;
                if (depth == 0) {
                    return nextEndIf.pos[1];
                }
                pos = nextEndIf.pos[1] + nextEndIf.len[1];
            }
        }
        
        return 0;
    }

    /**
     * Determine if a value is truthy.
     * Empty strings, empty arrays, empty structs, false, 0, and null are falsy.
     */
    private boolean function isTruthy(any value) {
        if (isNull(value)) return false;
        if (isBoolean(value)) return value;
        if (isNumeric(value)) return value != 0;
        if (isSimpleValue(value)) return len(trim(value)) > 0;
        if (isArray(value)) return arrayLen(value) > 0;
        if (isStruct(value)) return structCount(value) > 0;
        return true;
    }

    /**
     * Rewrite Markdown links to use canonical URLs.
     * Currently disabled to avoid unintended content changes.
     */
    public string function rewriteLinks(string html, string currentRelPath, struct docUrlMap) {
        // Placeholder for future link rewriting logic
        return html;
    }

}
