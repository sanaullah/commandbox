/**
 * Delete a file or directory from the filesystem.  Path may be absolute or relative to the current working directory.
 * .
 * {code:bash}
 * delete sample.html
 * {code}
 * .
 * Use the "force" param to supress the confirmation dialog.
 * .
 * {code:bash}
 * delete sample.html --force
 * {code}
 * .
 * Use the "recurse" param to remove a directory which is not empty.  Trying to remove a non-empty
 * directory will throw an error.  This a safetly check to make sure you know what you are getting into.
 * .
 * {code:bash}
 * delete myFolder/ --recurse
 * {code}
 **/	
component aliases="rm,del" {

	/**
	 * @path.hint file or directory to delete
	 * @force.hint Force deletion without asking
	 * @recurse.hint Delete sub directories
	 **/
	function run( required path, Boolean force=false, Boolean recurse=false )  {
		
		// Make path canonical and absolute
		arguments.path = fileSystemUtil.resolvePath( arguments.path );
			
		// It's a directory
		if( directoryExists( arguments.path ) ) {
								
				var subMessage = arguments.recurse ? ' and all its subdirectories' : '';
				
				if( arguments.force || confirm( "Delete #path##subMessage#? [y/n]" ) ) {
					
					if( directoryList( arguments.path ).len() && !arguments.recurse ) {
						return error( 'Directory [#arguments.path#] is not empty! Use the "recurse" parameter to override' );
					}
					// Catch this to gracefully handle where the OS or another program 
					// has the folder locked.
					try {
						directoryDelete( arguments.path, recurse );
						print.greenLine( "Deleted #arguments.path#" );				
					} catch( any e ) {
						error( '#e.message##CR#The folder is possibly locked by another program.'  );
						logger.error( '#e.message# #e.detail#' , e.stackTrace );
					}
				} else {
					print.redLine( "Cancelled!" );					
				}
				
			
		// It's a file
		} else if( fileExists( arguments.path ) ){
						
			if( arguments.force || confirm( "Delete #path#? [y/n]" ) ) {
				
					// Catch this to gracefully handle where the OS or another program 
					// has the file locked.
					try {
						fileDelete( arguments.path );
						print.greenLine( "Deleted #arguments.path#" );				
					} catch( any e ) {
						error( '#e.message##CR#The file is possibly locked by another program.'  );
						logger.error( '#e.message# #e.detail#' , e.stackTrace );
					}
			} else {
				print.redLine( "Cancelled!" );					
			}
			
		} else {	
			return error( "File/directory does not exist: #arguments.path#" );
		}
	}
	
}