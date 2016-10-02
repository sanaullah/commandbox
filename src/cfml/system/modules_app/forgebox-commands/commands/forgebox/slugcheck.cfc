/**
 * Verifies a slug against ForgeBox.
 * .
 * {code:bash}
 * forgebox slugcheck MyApp
 * {code}
 * .
 
 **/
component {
	
	// DI
	property name="forgeBox" inject="ForgeBox";
	
	/**
	* @slug.hint The slug to verify in ForgeBox
	*/
	function run( required slug ) {
		
		if( !len( arguments.slug ) ) {
			return error( "Slug cannot be an empty string" );
		}
		
		var exists = forgebox.isSlugAvailable( arguments.slug );

		if( exists ){
			print.greenBoldLine( "The slug '#arguments.slug#' does not exist in ForgeBox and can be used!" );
		} else {
			print.redBoldLine( "The slug '#arguments.slug#' already exists in ForgeBox!" );
		}
		
	}

}