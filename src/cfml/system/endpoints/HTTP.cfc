/**
*********************************************************************************
* Copyright Since 2014 CommandBox by Ortus Solutions, Corp
* www.coldbox.org | www.ortussolutions.com
********************************************************************************
* @author Brad Wood, Luis Majano, Denny Valliant
*
* I am the HTTP endpoint.  I get packages from an HTTP URL.
*/
component accessors=true implements="IEndpoint" singleton {

	// DI
	property name="consoleLogger"			inject="logbox:logger:console";
	property name="tempDir" 				inject="tempDir@constants";
	property name="artifactService" 		inject="ArtifactService";
	property name="fileEndpoint"			inject="commandbox.system.endpoints.File";
	property name="progressableDownloader" 	inject="ProgressableDownloader";
	property name="progressBar" 			inject="ProgressBar";
	property name="CR" 						inject="CR@constants";
	property name='wirebox'					inject='wirebox';
	property name="semanticVersion"			inject="provider:semanticVersion@semver";
	property name='semverRegex'				inject='semverRegex@constants';

	// Properties
	property name="namePrefixes" type="string";

	function init() {
		setNamePrefixes( 'HTTP' );
		return this;
	}

	public string function resolvePackage( required string package, boolean verbose=false ) {
		var job = wirebox.getInstance( 'interactiveJob' );

		var fileName = 'temp#randRange( 1, 1000 )#.zip';
		var fullPath = tempDir & '/' & fileName;

		job.addLog( "Downloading [#getNamePrefixes() & ':' & package#]" );

		try {
			// Download File
			var result = progressableDownloader.download(
				getNamePrefixes() & ':' & package, // URL to package
				fullPath, // Place to store it locally
				function( status ) {
					progressBar.update( argumentCollection = status );
				},
				function( newURL ) {
					job.addLog( "Redirecting to: '#arguments.newURL#'..." );
				}
			);
		} catch( UserInterruptException var e ) {
			if( fileExists( fullPath ) ) { fileDelete( fullPath ); }
			rethrow;
		} catch( Any var e ) {
			if( fileExists( fullPath ) ) { fileDelete( fullPath ); }
			throw( '#e.message##CR##e.detail#', 'endpointException' );
		};

		// Defer to file endpoint
		return fileEndpoint.resolvePackage( fullPath, arguments.verbose );

	}

	public function getDefaultName( required string package ) {

		// strip query string
		var baseURL = listFirst( arguments.package, '?' );

		// Github zip downloads tend to be called useless things like "master"
		// https://github.com/Ortus-Solutions/commandbox-docs/archive/master.zip
		if( baseURL contains 'github.com' ) {
			// Ortus-Solutions/commandbox-docs/archive/master.zip
			var path = mid( baseURL, findNoCase( 'github.com', baseURL ) + 10, len( baseURL ) );
			if( listLen( path, '/' ) >= 2 ) {
				// commandbox-docs
				return listGetAt( path, 2, '/' );
			}
		}

		// Find last segment of URL (may or may not be a file)
		var fileName = listLast( baseURL, '/' );

		// Check for file extension in URL
		var fileNameListLen = listLen( fileName, '.' );
		if( fileNameListLen > 1 && listLast( fileName, '.' ) == 'zip' ) {
			return listDeleteAt( fileName, fileNameListLen, '.' );
		}
		return reReplaceNoCase( arguments.package, '[^a-zA-Z0-9]', '', 'all' );
	}

	public function getUpdate( required string package, required string version, boolean verbose = false ) {
		// Check to see if a semver exists in the URL and if so use that
		var versionMatch = reMatch( semverRegex, package.reReplaceNoCase( '(https?:)?//', '' ).listRest( '/\' ) );

		if ( versionMatch.len() ) {
			return {
				isOutdated: semanticVersion.isNew( current = arguments.version, target = versionMatch.last() ),
				version: versionMatch.last()
			};
		}

		// Did not find a version in the URL so assume package is outdated
		return {
			isOutdated: true,
			version: 'unknown'
		};
	}

}
