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
     *
     * IMPORTANT: we must NOT evaluate template syntax that appears inside
     * code examples (e.g. fenced ``` blocks rendered as <pre><code>...</code></pre>
     * or inline <code>...</code> spans). To preserve those, we temporarily
     * replace every <pre>/<code> block with a placeholder, run our
     * conditional + token passes, then restore the original code blocks.
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
        // We explicitly avoid touching anything inside <pre> or <code> blocks
        // so that code samples showing template syntax are not executed.
        var processedContent = contentHtml;

        var contentProtection = protectCodeBlocks(processedContent);
        var contentWorking    = contentProtection.template;

        // Process conditionals in content (outside code blocks)
        contentWorking = processConditionals(contentWorking, data);
        
        // Replace simple tokens in content (outside code blocks)
        for (var cKey in data) {
            var cVal = data[cKey];
            contentWorking = replaceNoCase(contentWorking, "{{ " & cKey & " }}", cVal, "all");
            contentWorking = replaceNoCase(contentWorking, "{{" & cKey & "}}", cVal, "all");
        }

        processedContent = restoreCodeBlocks(contentWorking, contentProtection.blocks);
        
        // Expose the processed content to the layout as {{ content }}
        data.content = processedContent;

        // Now process the layout HTML using the same data (including content),
        // again skipping anything inside <pre>/<code> blocks.
        var layoutProtection = protectCodeBlocks(layoutHtml);
        var layoutWorking    = layoutProtection.template;

        layoutWorking = processConditionals(layoutWorking, data);

        for (var key in data) {
            var value = data[key];
            layoutWorking = replaceNoCase(layoutWorking, "{{ " & key & " }}", value, "all");
            layoutWorking = replaceNoCase(layoutWorking, "{{" & key & "}}", value, "all");
        }

        layoutWorking = restoreCodeBlocks(layoutWorking, layoutProtection.blocks);

        return layoutWorking;
    }

    /**
     * Protect <pre> and <code> blocks from token/conditional processing by
     * replacing them with unique placeholders and returning the mapping.
     */
    private struct function protectCodeBlocks(string html) {
        var result = {
            template = html,
            blocks   = []
        };

        // We scan for <pre>...</pre> and <code>...</code> blocks using
        // simple string searches instead of multi-line regex so that
        // we reliably catch fenced code blocks rendered by MarkdownToHTML.
        var tags = ["pre", "code"];

        for (var tag in tags) {
            var searchFrom = 1;
            var openTag    = "<" & tag;
            var closeTag   = "</" & tag & ">";

            while (true) {
                var openPos = findNoCase(openTag, result.template, searchFrom);
                if (!openPos) {
                    break;
                }

                var closePos = findNoCase(closeTag, result.template, openPos);
                if (!closePos) {
                    break;
                }

                var blockLen  = closePos + len(closeTag) - openPos;
                var blockHtml = mid(result.template, openPos, blockLen);
                var placeholder = "__MSP_CODE_BLOCK_" & (arrayLen(result.blocks) + 1) & "__";

                arrayAppend(result.blocks, {
                    placeholder = placeholder,
                    html        = blockHtml
                });

                result.template = left(result.template, openPos - 1) & placeholder & mid(result.template, openPos + blockLen);
                searchFrom = openPos + len(placeholder);
            }
        }

        return result;
    }

    /**
     * Restore original <pre>/<code> blocks back into the template.
     */
    private string function restoreCodeBlocks(string template, array blocks) {
        var result = template;

        for (var block in blocks) {
            result = replace(result, block.placeholder, block.html, "all");
        }

        return result;
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
