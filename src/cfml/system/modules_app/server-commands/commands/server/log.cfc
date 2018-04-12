/**
 * Show log for embedded server.  Run command from the web root of the server, or use the short name.
 * .
 * {code:bash}
 * server log
 * server log name=serverName
 * {code}
 **/
component {

	property name="serverService" inject="ServerService";

	/**
	 * Show server log
	 *
	 * @name.hint the short name of the server
	 * @name.optionsUDF serverNameComplete
	 * @directory.hint web root for the server
	 * @serverConfigFile The path to the server's JSON file.
	 * @follow Tail the log file with the "follow" flag. Press Ctrl-C to quit.
	 * @access Set this flag to view/tail the access log
	 * @rewrites Set this flag to view/tail the rewrites log
	 **/
	function run(
		string name,
		string directory,
		String serverConfigFile,
		Boolean follow=false,
		Boolean access=false,
		Boolean rewrites=false
		 ){
		if( !isNull( arguments.directory ) ) {
			arguments.directory = fileSystemUtil.resolvePath( arguments.directory );
		}
		if( !isNull( arguments.serverConfigFile ) ) {
			arguments.serverConfigFile = fileSystemUtil.resolvePath( arguments.serverConfigFile );
		}
		var serverDetails = serverService.resolveServerDetails( arguments );
		var serverInfo = serverDetails.serverInfo;

		// Verify server info
		if( serverDetails.serverIsNew ){
			error( "The server you requested was not found.", "You can use the 'server list' command to get all the available servers." );
		}

		var logfile = serverInfo.logdir & "/server.out.txt";
		if( access ) {
			logfile = serverInfo.accessLogPath;
		}
		if( rewrites ) {
			logfile = serverInfo.rewritesLogPath;
		}
		if( fileExists( logfile) ){

			if( follow ) {
				command( 'tail' )
					.params( logfile, 50 )
					.flags( 'follow' )
					.run();
			} else {
				return fileRead( logfile );
			}

		} else {
			print.boldRedLine( "No log file found for '#serverInfo.webroot#'!" )
				.line( "#logFile#" );
			if( access ) {
				print.yellowLine( 'Enable accesss logging with [server set web.acessLogEnable=true]' );
			}
		}
	}


	function serverNameComplete() {
		return serverService.getServerNames();
	}

}
