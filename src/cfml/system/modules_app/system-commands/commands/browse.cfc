/**
 * Open a browser to the passed URI.
 * .
 * Concatenate two files and output them to the screen
 * {code:bash}
 * browse localhost:8116
 * {code}
 *
 **/
component {

	/**
	 * @URI.hint The URI to open as you would type it into your browser's address bar
 	 **/
	function run( required URI )  {

		if( fileSystemUtil.openBrowser( arguments.URI ) ){
			print.line( "Browser opened!" );
		} else {
			error( "Unsopported OS" );
		};
	}

}
