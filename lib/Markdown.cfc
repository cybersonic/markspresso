component
	javaSettings='{
		"maven": [
			"org.commonmark:commonmark:0.24.0"
			, "org.commonmark:commonmark-ext-gfm-strikethrough:0.24.0"
			, "org.commonmark:commonmark-ext-gfm-tables:0.24.0"
			, "org.commonmark:commonmark-ext-ins:0.24.0"
			, "org.commonmark:commonmark-ext-autolink:0.24.0"
			, "org.commonmark:commonmark-ext-image-attributes:0.24.0"
			, "org.nibor.autolink:autolink:0.11.0"
		]
	}'
{

	/**
	 * Render Markdown to HTML via commonmark-java.
	 *
	 * Uses createObject("java", FQCN) instead of import + Class::static() so Lucee
	 * resolves classes through this component's javaSettings classloader. The
	 * import/:: form can look for a CFML component named AutolinkExtension and fail
	 * with "could not find component or class with name [AutolinkExtension]".
	 */
	function render( string markdown, boolean safemode=false ){
		var AutolinkExtension = createObject( "java", "org.commonmark.ext.autolink.AutolinkExtension" );
		var ImageAttributesExtension = createObject( "java", "org.commonmark.ext.image.attributes.ImageAttributesExtension" );
		var InsExtension = createObject( "java", "org.commonmark.ext.ins.InsExtension" );
		var StrikethroughExtension = createObject( "java", "org.commonmark.ext.gfm.strikethrough.StrikethroughExtension" );
		var TablesExtension = createObject( "java", "org.commonmark.ext.gfm.tables.TablesExtension" );
		var Parser = createObject( "java", "org.commonmark.parser.Parser" );
		var HtmlRenderer = createObject( "java", "org.commonmark.renderer.html.HtmlRenderer" );

		var extensions = [
			AutolinkExtension.create(),
			ImageAttributesExtension.create(),
			InsExtension.create(),
			StrikethroughExtension.create(),
			TablesExtension.create()
		];

		var parser = Parser.builder().extensions( extensions ).build();
		var document = parser.parse( arguments.markdown );
		var renderer = HtmlRenderer.builder().extensions( extensions ).escapeHtml( arguments.safemode ).build();
		return renderer.render( document );
	}

}
