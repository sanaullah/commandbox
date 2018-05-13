/**
* Play a fun, retro-style snake game.  The "snake" is on the loose and you need to gobble up as many juicy apples as you can. 
* Use the up, down, left, and right keys on your keyboard to move.  
* But be careful- if you run into a wall or into your own tail, the game is over!  The snake will grow every time he eats and apple, and once you 
* clear all the apples, more will appear for your chomping pleasure.
* .
* Press Q to quit the game at any time.
* Press R to restart the game after it's over
 * .
 * {code:bash}
 * snake
 * {code}

**/
component aliases="snake" {
	
	processingdirective pageEncoding='UTF-8';
	
	property name='p' inject='print';

	function run()  {
		// Static reference to the class so we can create instances later
		aStr = createObject( 'java', 'org.jline.utils.AttributedString' );
		terminal = shell.getReader().getTerminal();
		display = createObject( 'java', 'org.jline.utils.Display' ).init( terminal, false );
		display.resize( terminal.getHeight(), terminal.getWidth() );
		
		variables.directionOpposites = {
			'up' = 'down',
			'down' = 'up',
			'left' = 'right',
			'right' = 'left'
		};
		//	╚ ╔ ╩ ╦ ╠ ═ ╬ ╣ ║ ╗  ╝ 
	
	
		variables.height = 17;
		variables.width = 53;
		//variables.height = shell.getTermHeight()-13;
		//variables.width = shell.getTermWidth()-3;
		variables.centerX = round( variables.width / 2 );
		variables.centerY = round( variables.height / 2 );
		
		resetGame();
	
		
		variables.gameHeader = [
			aStr.fromAnsi( '╔═════════════════════════════════════════════════════╗' ), 
			aStr.fromAnsi( '║                   ' & p.boldGreen( 'CommandBox Snake' ) & '                  ║' ),
			aStr.fromAnsi( '║                     by Brad Wood                    ║░' ),
			aStr.fromAnsi( '╠═════════════════════════════════════════════════════╣░' )
		];
		
		// Initialize an array with an index for each row
		variables.gameSurface = arrayNew( 2 );
		var i = 0;
		// For each row...
		while( ++i <= variables.height ) {
			// Initialize it as an array of characters for each column
			//variables.gameSurface[ i ] = []; 
			loop from=1 to=variables.width index='j' {
				variables.gameSurface[ i ][ j ] = ' ';
			}			
		}
		
		variables.gameFooter = [
			aStr.fromAnsi( '╠═════════════════════════════════════════════════════╣░' ),
			aStr.fromAnsi( '║                                                     ║░' ),
			aStr.fromAnsi( '║     Use arrow keys to move up/down/left/right       ║░' ),
			aStr.fromAnsi( '║                                                     ║░' ),
			aStr.fromAnsi( '║                   Press ' & p.bold( 'Q' ) & ' to quit                   ║░' ),
			aStr.fromAnsi( '╚═════════════════════════════════════════════════════╝░' ),
			aStr.fromAnsi( ' ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░' )
		];
		
		
		var h = p.bold( '═' );
		var v = p.bold( '║' );
		var ul = p.bold( '╔' );
		var ur = p.bold( '╗' );
		var bl = p.bold( '╚' );
		var br = p.bold( '╝' );
		var sh = p.bold( '░' );
		var s = ' ';

		// These characters much be formatted individually since they are output one at a time.
		variables.gameOverMessage =  [
			[ ul, h, h, h, h, h, h, h, h, h, h, h, h, h, h, h, h, h, h, h, h, h, h, h, h, ur, s ],
			[ v, s, s, s, s, s, s, s,  p.boldRed( 'G' ), p.boldRed( 'A' ), p.boldRed( 'M' ), p.boldRed( 'E' ), s, p.boldRed( 'O' ), p.boldRed( 'V' ), p.boldRed( 'E' ), p.boldRed( 'R' ), p.boldRed( '!' ), s, s, s, s, s, s, s, v, sh ],
			[ v, s, s, s, p.bold( 'P' ), p.bold( 'r' ), p.bold( 'e' ), p.bold( 's' ), p.bold( 's' ), s, p.bold( '"' ), p.bold( 'R' ), p.bold( '"' ), s, p.bold( 't' ), p.bold( 'o' ), s, p.bold( 'r' ), p.bold( 'e' ), p.bold( 't' ), p.bold( 'r' ), p.bold( 'y' ), s, s, s, v, sh ],
			[ v, s, s, s, s, s, s, s, s, s, p.bold( 'S' ), p.bold( 'c' ), p.bold( 'o' ), p.bold( 'r' ), p.bold( 'e' ), p.bold( ':' ),  s, s, s, s, s, s, s, s, s, v, sh ],
			[ bl, h, h, h, h, h, h, h, h, h, h, h, h, h, h, h, h, h, h, h, h, h, h, h, h, br, sh ],
			[ s, sh, sh, sh, sh, sh, sh, sh, sh, sh, sh, sh, sh, sh, sh, sh, sh, sh, sh, sh, sh, sh, sh, sh, sh, sh, sh ]
		];
		
		// Flush out anything stored up
		print.toConsole();
		// Start with a blank slate
		shell.clearScreen();
		
		
		// This lets the thread know we're still running'
		variables.snakeRun = true;
				
		try {
			// This thread will keep redrawing the screen while the main thread waits for user input
			threadName = 'snakeDrawer#createUUID()#';
			thread action="run" name=threadName priority="HIGH" {
				try{
					// Only keep drawing as long as the main thread is active
					while( variables.snakeRun ) {
						// Move and re-draw if not in an invalid state
						if( !variables.collision ) {
							variables.collision = !move( getNextDirection() );			
							printGame();
						}
						// Decrease this to speed up the game
						sleep( 300 );
					}	
				} catch( any e ) {
					logger.error( e.message & ' ' & e.detail, e.stacktrace );
				}
				
			}   // End thread
			
			var key = '';
			while( true ) {
						
				// Detect user input
				key = shell.waitForKey();
				
				if( isQuit( key ) ) {
					break;
				} else if( isLeft( key ) ) {
					go( 'left' );
				} else if( isRight( key ) ) {
					go( 'right' );
				} else if( isUp( key ) ) {
					go( 'up' );
				} else if( isDown( key ) ) {
					go( 'down' );
				} else if( isRetry( key ) ) {
					resetGame();
				}
								
			}

		} catch ( any e ) {
			// If anything bad happens, make sure the thread exits
			variables.snakeRun = false;
			// Wait until the thread finishes its last draw
			thread action="join" name=threadName;
			rethrow;
		}
		
		// We're done with the game, clean up.
		variables.snakeRun = false;
		// Wait until the thread finishes its last draw
		thread action="join" name=threadName;
		
		// Push the prompt down below the game box.
		var lines = 29;
		while( lines-- > 0 ) {
			print.line();
		}
				
	}

	/* *************************************************************************************
	* Private methods
	************************************************************************************* */

	private function printGame() {
			var gameLines = [];
			
			gameLines.append( gameHeader, true );
			
			var thisGameSurface = duplicate( variables.gameSurface );
			
			// Overlay the snake
			for( var part in variables.body ) {
				thisGameSurface[ part.y ][ part.x ] = p.green( '0' );
			}
			
			// Overlay the apples
			for( var apple in variables.apples ) {
				thisGameSurface[ apple.y ][ apple.x ] = p.redBold( '@' );
			}
			
			
			// If boom-booms happened, overlay message
			if( variables.collision ) {
				
				// Add in score
				thisScore = NumberFormat( variables.biteCount, "000" );
				gameOverMessage[ 4 ][ 18 ] = mid( thisScore, 1, 1 );
				gameOverMessage[ 4 ][ 19 ] = mid( thisScore, 2, 1 );
				gameOverMessage[ 4 ][ 20 ] = mid( thisScore, 3, 1 );
				
				// Find the offset of the upper left corner
				var startX = variables.centerX - ( round( gameOverMessage[1].len() / 2 ) );
				var startY = variables.centerY - ( round( gameOverMessage.len() / 2 ) ); 

				var YOffset = 0;
				for( var line in gameOverMessage ) {
					var XOffset = 0;
					while( ++XOffset <= line.len() ) {
						thisGameSurface[ startY + YOffset ][ startX + XOffset-1 ] = line[ XOffset];
					}
					YOffset++;
				}
								
			}
			
			// Now that we've build up the array of characters, spit them out to the console
			for( var row in thisGameSurface ) {
				var thisLine = '║';
				for( var col in row ) {
					thisLine &= col;
				}
				thisLine &= '║░';
				
				gameLines.append( aStr.fromAnsi( thisLine ) );
			}
			
			gameLines.append( gameFooter, true );
						
			display.update(
				gameLines,
				0
			);
			
	}



	// This needs to be synchronized with getNextDirection()
	private function go( newDirection ) {
		lock name='snake_direction' type='exclusive' timeout=2 {
			
			// Figure out where we'll be going right before this direction is used
			if( variables.direction.len() ) {
				var preceedingDirection = variables.direction.first();
			} else {
				var preceedingDirection = variables.lastDirection;				
			}
			
			// Firstly, don't add additional directions that are the same as where we're already headed
			// so we don't stack up redundant junk in the queue that makes the snake appear unresponsive.
			// Secondly, only obey if the new direction isn't in the opposite (since that's an annoying instant "game over") 
			// UNLESS the snake is stil a baby-- then it can go anywhere it wants 
			if( arguments.newDirection != preceedingDirection &&
				( arguments.newDirection != variables.directionOpposites[ preceedingDirection ] || isBaby() )
			) {
				variables.direction.prepend( newDirection );				
			}
		}
	}
	
	// This needs to be synchronized with go()
	private function getNextDirection() {
		lock name='snake_direction' type='exclusive' timeout=2 {
			// Has the user told us to go somewhere?
			if( variables.direction.len() ) {
				// What's next in the queue of directions?
				var nextDirection = variables.direction.last();
				// Then remove it
				variables.direction.deleteAt( variables.direction.len() );
			} else {
				// Otherwise, just go the last place we went for lack of something better
				nextDirection = variables.lastDirection;
			}
			
			// Remember where we are going
			variables.lastDirection = nextDirection;
			return nextDirection;
		}
	}
	
	private function move( required direction ) {
		var head = variables.body[1];
		var newHead = duplicate( head );
		
		// Move the head
		switch( arguments.direction ) {
			case 'up':
				newHead.y--;
				break;
			case 'down':
				newHead.y++;
				break;
			case 'left':
				newHead.x--;
				break;
			case 'right':
				newHead.x++;
				break;
				
		}
		
		// If the snake bites an apple, it grows by one
		if( !bite( newHead ) ) {
			// Move tail
			variables.body.deleteAt( variables.body.len() );
		}
			
		// If we hit something, the move failed
		if( isWallCollision( newHead ) || isSnakeCollision( newHead ) ) {
			return false;
		}
		
		// Move the snakes head
		variables.body.prepend( newHead );
		
		// Move successful
		return true;
	}

	// This is a baby snake? i.e. Only 1 body segment.
	private function isBaby() {
		return variables.body.len() == 1; 
	}


	private function resetGame() {
		
		// An array of coordinates that represent where the snake is
		// He starts in the bottom center with a lenth of "1"
		variables.body = [
			{
				x : variables.centerX,
				y : variables.height-1
			}
		];
		
		// Number of apples to start the game with
		variables.appleCount = 6;
		variables.biteCount = 0;
		
		// An array of apples
		variables.apples = [];
		
		seedApples();
			
		// Direction is an array to capture multiple key strokes that are
		// pressed between screen refreshes
		variables.direction = [ 'up' ];
		// This is the last direction we went in case the user is just coasting
		variables.lastDirection = 'up';
		variables.collision = false;
	}
	
	private function seedApples() {
		
		// Randomly seed our apples
		while( variables.apples.len() < variables.appleCount ) {
			var newApple = {
				x : randRange( 1, variables.width ),
				y : randRange( 1, variables.height )
			};
			
			// Make sure we don't double-stack our apples, or put them on the snake
			if( !isSnakeCollision( newApple ) && !isAppleCollision( newApple ) ) {
				variables.apples.append( newApple );	
			}
		}
		
	}
			
	private function isWallCollision( location ) {
		
		// Check collision with outside of play area
		if(
			   location.x < 1
			|| location.y < 1
			|| location.x > variables.width
			|| location.y > variables.height
		) {
			return true;
		}
				
		return false;
	}
	
			
	private function isSnakeCollision( location ) {
				
		// Check collision with snake
		for( piece in variables.body ) {
			if( piece.x == location.x && piece.y == location.y ) {				
				return true;
			}
		}
		
		return false;
	}
	
	private function bite( location ) {
		
		// Check to see if we reached an apple
		for( apple in variables.apples ) {
			if( apple.x == location.x && apple.y == location.y ) {
				// Add 1 to the score
				variables.biteCount++;
				// Remove that apple from the game area
				variables.apples.delete( apple );
				
				// If that was the last apple
				if( !variables.apples.len() ) {
					// Add some more!
					variables.appleCount += 6;
					seedApples();	
				}
				
				return true;
			}
		}
		
		return false;
		
	}
	
	private function isAppleCollision( location ) {
		
		// Check to see if this location is an an apple
		for( apple in variables.apples ) {
			if( apple.x == location.x && apple.y == location.y ) {
				return true;
			}
		}
		
		return false;
		
	}
		
	private function isQuit( key ) {
		// q or Q
		return ( key == 'q' );
	}
		
	private function isRetry( key ) {
		// r or R
		return ( key == 'r' );
	}

	private function isUp( key ) { 
		return ( key == 'key_up' );
	}
		
	private function isDown( key ) {
		return ( key == 'key_down' );
	}
		
	private function isLeft( key ) {
		return ( key == 'key_left' );
	}
		
	private function isRight( key ) {
		return ( key == 'key_right' );
	}


}