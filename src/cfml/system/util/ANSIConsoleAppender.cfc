/**
********************************************************************************
Copyright Since 2005 ColdBox Framework by Luis Majano and Ortus Solutions, Corp
www.coldbox.org | www.luismajano.com | www.ortussolutions.com
********************************************************************************

Author     :	Brad Wood, Luis Majano
Date        :	07/22/2014
Description :
	A logger for outputting ANSI-formmatted text to the console
	for use with CommandBox.

Properties:
- none
*/
component extends="wirebox.system.logging.AbstractAppender" {

	/**
	* @name.hint The unique name for this appender.
	* @properties.hint A map of configuration properties for the appender
	* @layout.hint The layout class to use in this appender for custom message rendering.
	* @levelMin.hint The default log level for this appender, by default it is 0. Optional. ex: LogBox.logLevels.WARN
	* @levelMax.hint The default log level for this appender, by default it is 5. Optional. ex: LogBox.logLevels.WARN
	*/
	ANSIConsoleAppender function init( required name, properties={}, layout, levelMin=0, leveMax=4 ) {
		// Init supertype
		super.init(argumentCollection=arguments);
		// The log levels enum as a public property
		variables.logLevels = createObject("component","wirebox.system.logging.LogLevels");
		return this;
	}

	function logMessage( required logEvent ) {

		// Check for Ctrl-C
		application.wirebox.getInstance( 'shell' ).checkInterrupted();

		var loge = arguments.logEvent;
		var entry = "";

		if( hasCustomLayout() ){
			entry = getCustomLayout().format( loge );
		} else {
			entry = loge.getmessage();
			if( entry == '.' ) {
				entry = '';
			}
		}

		// Log message
		switch( loge.getseverity() ) {
		    case logLevels.FATAL: case logLevels.ERROR:
				print().boldRedLine( entry );
		         break;
		    case logLevels.WARN:
				print().yellowLine( entry );
		         break;
		    case logLevels.INFO:
				print().greenLine( entry );
		         break;
		    default:
				print().line( entry );
		}

		// Log Extra Info as a string
		var extraInfo = loge.getExtraInfoAsString();
		if( len( extraInfo ) ){
			print().line( loge.getExtraInfo().toString() );
		}
		
		// If we're inside of an active job...
		if( job().isActive() ) {
			// Redirect out output into that current job's log
			job().addLog( print().getResult() );
			print().clear();
		} else {
			// Otherwise, just send it straight to the console
			print().toConsole();
		}
		
	}

	function print() {
		if( !structKeyExists( variables, 'printBuffer' ) ){
			// Appenders are created by WireBox, so we can't DI.
			variables.printBuffer = application.wireBox.getInstance( 'PrintBuffer' );
		}
		return variables.printBuffer;
	}

	function job() {
		if( !structKeyExists( variables, 'InteractiveJob' ) ){
			// Appenders are created by WireBox, so we can't DI.
			variables.InteractiveJob = application.wireBox.getInstance( 'InteractiveJob' );
		}
		return variables.InteractiveJob;
	}

}
