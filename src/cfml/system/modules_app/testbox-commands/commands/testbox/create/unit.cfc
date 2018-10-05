/**
* Create a new xUnit test in an existing application.  By default, your new test will be created in the current working
* directory but you can override that with the directory param.
* .
* {code:bash}
* testbox create unit myTest
* {code}
*
**/
component {

	/**
	* @name.hint Name of the xUnit bundle to create without the .cfc. For packages, specify name as 'myPackage/MyTest'
	* @open.hint Open the file once it is created
	* @directory.hint The base directory to create your CFC in and creates the directory if it does not exist.
	 **/
	function run( required name, boolean open=false, directory=getCWD() ){
		// Allow dot-delimited paths
		arguments.name = replace( arguments.name, '.', '/', 'all' );

		// Check if the name is actually a path
		var nameArray = arguments.name.listToArray( '/' );
		var nameArrayLength = nameArray.len();
		if (nameArrayLength > 1) {
			// If it is a path, split the path from the name
			arguments.name = nameArray[nameArrayLength];
			var extendedPath = nameArray.slice(1, nameArrayLength - 1).toList('/');
			arguments.directory &= '/#extendedPath#';
		}

		// This will make each directory canonical and absolute
		arguments.directory = resolvePath( arguments.directory );

		// Validate directory
		if( !directoryExists( arguments.directory ) ) {
			directoryCreate( arguments.directory );
		}

		// This help readability so the success messages aren't up against the previous command line
		print.line();

		// Read in Templates
		var content = fileRead( '/testbox-commands/templates/testbox/unit.txt' );

		// Write out BDD Spec
		var thisPath = '#directory#/#name#.cfc';
		file action='write' file='#thisPath#' mode ='777' output='#content#';
		print.greenLine( 'Created #thisPath#' );

		// Open file?
		if( arguments.open ){ openPath( thisPath ); }
	}

}
