/**
 * Execute an operating system level command in the native shell.  The binary must be in the PATH, or you can specify the full
 * path to it.  This command will wait for the OS exectuable to complete but will flush the output as it is received.
 * .
 * {code:bash}
 * run myApp.exe
 * run /path/to/myApp
 * {code}
 * .
 * A shortcut for running OS binaries is to prefix the binary with "!".  In this mode, any other params need to be positional.
 * There is no CommandBox parsing applied to the command's arguments.  They are passed straight to the native shell.
 * .
 * {code:bash}
 * !myApp.exe
 * !/path/to/myApp
 * !dir
 * !npm ll
 * !ipconfig
 * !ping google.com -c 4
 * {code}
 * .
 * Executing Java would look like this
 * .
 * {code:bash}
 * !java -version
 * !java -jar myLib.jar
 * {code}
 * .
 * You can even call other CLIs
 * .
 * {code:bash}
 * !git init
 * touch index.cfm
 * !git add .
 * !git commit -m "Initial Commit"
 * {code}
 *
 **/
component{
	property name="fileSystemUtil" inject="fileSystem"; 
	property name="configService" inject="configService";

	/**
	* @command.hint The full operating system command to execute including the binary and any parameters
	**/
	function run(
		required command
	){
		if( !arguments.keyExists( 'interactive' ) ) {
			arguments.interactive = true;
		}
		
        var terminal = shell.getReader().getTerminal();
		// Prep the command to run in the OS-specific shell
		if( fileSystemUtil.isWindows() ) {
			// Pass through Windows' command shell, /a outputs ANSI formatting, /c runs as a command
			var commandArray = [ 'cmd','/a','/c', arguments.command ];
		} else {
			// Pass through bash in interactive mode with -i to expand aliases like "ll".
			// -c runs input as a command, "&& exits" cleanly from the shell as long as the original command ran successfully
			var nativeShell = configService.getSetting( 'nativeShell', '/bin/bash' );
			commandArray = [ nativeShell, '-i', '-c', arguments.command & ' 2>&1 && ( exit $? > /dev/null )' ];
		}
		
		var exitCode = 1;
        // grab the current working directory
        var CWDFile = createObject( 'java', 'java.io.File' ).init( resolvePath( '' ) );
				
		try{
            
            // This unbinds JLine from our input and output so it's not fighting over the keyboard
            terminal.pause();
            
			if( interactive ) {
				
				var exitCode = createObject( "java", "java.lang.ProcessBuilder" )
					.init( commandArray )
					// Do you believe in magic
					// This works great on Mac/Windows.
					// On Linux, the standard input (keyboard) is not being piped to the background process.
					.inheritIO()
					// Sets current working directory for the process
					.directory( CWDFile )
					// Fires process async
					.start()
					// waits for it to exit, returning the exit code
					.waitFor();
	
			} else {
		            
	            // Static reference to inner class
	            var redirect = createObject( 'java', 'java.lang.ProcessBuilder$Redirect' );
	            // A string builder to collect the output that we're also streaming to the console so it can be captured and piped to another command as well.
	            var processOutputStringBuilder = createObject( 'java', 'java.lang.StringBuilder' ).init( '' );
				var process = createObject( 'java', 'java.lang.ProcessBuilder' )
					.init( commandArray )
					// Keyboard pipes through to the input of the process
					.redirectInput( redirect.INHERIT )
					.redirectErrorStream(fileSystemUtil.isWindows())
					// Sets current working directory for the process
					.directory( CWDFile );
	
				if(!fileSystemUtil.isWIndows()) {
					process=process.redirectError(redirect.INHERIT);
				}
				// Fires process async
				process=process.start();
				
				// Despite the name, this is the stream that the *output* of the external process is in.
				var inputStream = process.getInputStream();
				// I convert the byte array in the piped input stream to a character array
				var inputStreamReader = createObject( 'java', 'java.io.InputStreamReader' ).init( inputStream );
				
				// This will block/loop until the input stream closes, which means this loops until the process ends.
				while( ( var char = inputStreamReader.read() ) != -1 ) {
					checkInterrupted();
					// if running non-interactive, gather the output of the command
					processOutputStringBuilder.append( javaCast( 'char', char ) );
				} 
				
				// make sure it's dead
				process.waitFor();
	
				// Get the exit code
				exitCode = process.exitValue();
			
				// This was non-interactive, print out the text output all at once.
				print.text( processOutputStringBuilder.toString() );
			}

			
			// As you were, JLine
            terminal.resume();
            
		} finally {
			
			// Clean up the streams
			if( !isNull( inputStream ) ) {
				inputStream.close();
			}
			
			// Clean up the streams
			if( !isNull( inputStreamReader ) ) {
				inputStreamReader.close();
			} 
			
			// I had issues with Ctrl-C not fully existing cmd on Windows.  This should make sure it's dead.
			if( !isNull( process ) ) {
				process.destroy();	
			}
			
			// As you were, JLine
			if( terminal.paused() ) {
				terminal.resume();
			}
			
			checkInterrupted();
		}

		if( exitCode != 0 ) {
			error( message='Command returned failing exit code [#exitCode#]', exitCode=exitCode );
		}

	}

}
