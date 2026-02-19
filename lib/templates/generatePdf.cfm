<!---
    generatePdf.cfm
    Generates PDF binary from HTML content using cfdocument.
    Uses variables passed from PdfBuilder.cfc:
        - variables.pdfHtml (with <!--CHAPTER:title--> and <!--TOC_START/END--> markers)
        - variables.pdfHeaderHtml (with __CURRENTPAGE__, __TOTALPAGES__, __CHAPTERTITLE__ placeholders)
        - variables.pdfFooterHtml (with __CURRENTPAGE__, __TOTALPAGES__, __CHAPTERTITLE__ placeholders)
        - variables.pdfPageConfig
        - variables.pdfHasChapterToken (boolean)
        - variables.pdfStyles (CSS styles)
--->
<cfsilent>
<!--- Extract chapter markers --->
<cfset chapters = []>
<cfset chapterPattern = "<!--CHAPTER:([^>]+)-->">
<cfset currentPos = 1>
<cfloop condition="true">
    <cfset match = reFind(chapterPattern, variables.pdfHtml, currentPos, true)>
    <cfif match.pos[1] EQ 0>
        <cfbreak>
    </cfif>
    <cfset chapterTitle = mid(variables.pdfHtml, match.pos[2], match.len[2])>
    <cfset arrayAppend(chapters, { pos = match.pos[1], len = match.len[1], title = chapterTitle })>
    <cfset currentPos = match.pos[1] + match.len[1]>
</cfloop>

<!--- Extract TOC content if present --->
<cfset tocContent = "">
<cfset tocMatch = reFind("<!--TOC_START-->([\s\S]*?)<!--TOC_END-->", variables.pdfHtml, 1, true)>
<cfif tocMatch.pos[1] GT 0>
    <cfset tocContent = mid(variables.pdfHtml, tocMatch.pos[2], tocMatch.len[2])>
</cfif>
</cfsilent>
<cfdocument
    format="pdf"
    pagetype="#variables.pdfPageConfig.pageSize#"
    orientation="#variables.pdfPageConfig.orientation#"
    margintop="#variables.pdfPageConfig.marginTop#"
    marginbottom="#variables.pdfPageConfig.marginBottom#"
    marginleft="#variables.pdfPageConfig.marginLeft#"
    marginright="#variables.pdfPageConfig.marginRight#"
    unit="#variables.pdfPageConfig.unit#"
    localurl="true"
    variable="result">
<cfif variables.pdfHasChapterToken AND arrayLen(chapters) GT 0>
<!--- TOC section --->
<cfif len(trim(tocContent))>
<cfdocumentsection>
<cfdocumentitem type="header">
<cfoutput>
<cfset hdr = replaceNoCase(variables.pdfHeaderHtml, "__CHAPTERTITLE__", "Table of Contents", "all")>
<cfset hdr = replaceNoCase(hdr, "__CURRENTPAGE__", cfdocument.currentpagenumber, "all")>
<cfset hdr = replaceNoCase(hdr, "__TOTALPAGES__", cfdocument.totalpagecount, "all")>
<cfset hdr = replaceNoCase(hdr, "__CURRENTSECTIONPAGE__", cfdocument.currentsectionpagenumber, "all")>
<cfset hdr = replaceNoCase(hdr, "__TOTALSECTIONPAGES__", cfdocument.totalsectionpagecount, "all")>
#hdr#
</cfoutput>
</cfdocumentitem>
<cfdocumentitem type="footer">
<cfoutput>
<cfset ftr = replaceNoCase(variables.pdfFooterHtml, "__CHAPTERTITLE__", "Table of Contents", "all")>
<cfset ftr = replaceNoCase(ftr, "__CURRENTPAGE__", cfdocument.currentpagenumber, "all")>
<cfset ftr = replaceNoCase(ftr, "__TOTALPAGES__", cfdocument.totalpagecount, "all")>
<cfset ftr = replaceNoCase(ftr, "__CURRENTSECTIONPAGE__", cfdocument.currentsectionpagenumber, "all")>
<cfset ftr = replaceNoCase(ftr, "__TOTALSECTIONPAGES__", cfdocument.totalsectionpagecount, "all")>
#ftr#
</cfoutput>
</cfdocumentitem>
<cfoutput>
<html><head><style>#variables.pdfStyles#</style></head><body>
#tocContent#
</body></html>
</cfoutput>
</cfdocumentsection>
</cfif>
<!--- Chapter sections --->
<cfloop index="i" from="1" to="#arrayLen(chapters)#">
<cfset chapter = chapters[i]>
<cfset chapterEnd = len(variables.pdfHtml) + 1>
<cfif i LT arrayLen(chapters)>
    <cfset chapterEnd = chapters[i + 1].pos>
</cfif>
<cfset chapterContent = mid(variables.pdfHtml, chapter.pos + chapter.len, chapterEnd - chapter.pos - chapter.len)>
<cfdocumentsection>
<cfdocumentitem type="header">
<cfoutput>
<cfset hdr = replaceNoCase(variables.pdfHeaderHtml, "__CHAPTERTITLE__", chapter.title, "all")>
<cfset hdr = replaceNoCase(hdr, "__CURRENTPAGE__", cfdocument.currentpagenumber, "all")>
<cfset hdr = replaceNoCase(hdr, "__TOTALPAGES__", cfdocument.totalpagecount, "all")>
<cfset hdr = replaceNoCase(hdr, "__CURRENTSECTIONPAGE__", cfdocument.currentsectionpagenumber, "all")>
<cfset hdr = replaceNoCase(hdr, "__TOTALSECTIONPAGES__", cfdocument.totalsectionpagecount, "all")>
#hdr#
</cfoutput>
</cfdocumentitem>
<cfdocumentitem type="footer">
<cfoutput>
<cfset ftr = replaceNoCase(variables.pdfFooterHtml, "__CHAPTERTITLE__", chapter.title, "all")>
<cfset ftr = replaceNoCase(ftr, "__CURRENTPAGE__", cfdocument.currentpagenumber, "all")>
<cfset ftr = replaceNoCase(ftr, "__TOTALPAGES__", cfdocument.totalpagecount, "all")>
<cfset ftr = replaceNoCase(ftr, "__CURRENTSECTIONPAGE__", cfdocument.currentsectionpagenumber, "all")>
<cfset ftr = replaceNoCase(ftr, "__TOTALSECTIONPAGES__", cfdocument.totalsectionpagecount, "all")>
#ftr#
</cfoutput>
</cfdocumentitem>
<cfoutput>
<html><head><style>#variables.pdfStyles#</style></head><body>
#chapterContent#
</body></html>
</cfoutput>
</cfdocumentsection>
</cfloop>
<cfelse>
<!--- Simple mode: single header/footer for all pages --->
<cfdocumentitem type="header">
<cfoutput>
<cfset hdrOut = replaceNoCase(variables.pdfHeaderHtml, "__CHAPTERTITLE__", "", "all")>
<cfset hdrOut = replaceNoCase(hdrOut, "__CURRENTPAGE__", cfdocument.currentpagenumber, "all")>
<cfset hdrOut = replaceNoCase(hdrOut, "__TOTALPAGES__", cfdocument.totalpagecount, "all")>
<cfset hdrOut = replaceNoCase(hdrOut, "__CURRENTSECTIONPAGE__", cfdocument.currentsectionpagenumber, "all")>
<cfset hdrOut = replaceNoCase(hdrOut, "__TOTALSECTIONPAGES__", cfdocument.totalsectionpagecount, "all")>
#hdrOut#
</cfoutput>
</cfdocumentitem>
<cfdocumentitem type="footer">
<cfoutput>
<cfset ftrOut = replaceNoCase(variables.pdfFooterHtml, "__CHAPTERTITLE__", "", "all")>
<cfset ftrOut = replaceNoCase(ftrOut, "__CURRENTPAGE__", cfdocument.currentpagenumber, "all")>
<cfset ftrOut = replaceNoCase(ftrOut, "__TOTALPAGES__", cfdocument.totalpagecount, "all")>
<cfset ftrOut = replaceNoCase(ftrOut, "__CURRENTSECTIONPAGE__", cfdocument.currentsectionpagenumber, "all")>
<cfset ftrOut = replaceNoCase(ftrOut, "__TOTALSECTIONPAGES__", cfdocument.totalsectionpagecount, "all")>
#ftrOut#
</cfoutput>
</cfdocumentitem>
<cfset cleanHtml = reReplace(variables.pdfHtml, "<!--CHAPTER:[^>]+-->", "", "all")>
<cfset cleanHtml = reReplace(cleanHtml, "<!--TOC_START-->", "", "all")>
<cfset cleanHtml = reReplace(cleanHtml, "<!--TOC_END-->", "", "all")>
<cfoutput>
<html><head><style>#variables.pdfStyles#</style></head><body>
#cleanHtml#
</body></html>
</cfoutput>
</cfif>
</cfdocument>
