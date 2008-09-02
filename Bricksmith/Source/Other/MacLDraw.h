/*
 *  MacLDraw.h
 *  Bricksmith
 *
 *  Created by Allen Smith on 2/14/05.
 *  Copyright 2005 Allen M. Smith. All rights reserved.
 *
 */

////////////////////////////////////////////////////////////////////////////////
//
#pragma mark		Preferences Keys
//
////////////////////////////////////////////////////////////////////////////////

#define LDRAW_PATH_KEY							@"LDraw Path"
#define PART_BROWSER_DRAWER_STATE				@"Part Browser Drawer State"
#define PART_BROWSER_PREVIOUS_CATEGORY			@"Part Browser Previous Category"
#define FILE_CONTENTS_DRAWER_STATE				@"File Contents Drawer State"
#define PREFERENCES_LAST_TAB_DISPLAYED			@"Preferences Tab"
#define DOCUMENT_WINDOW_SIZE					@"Document Window Size"
#define SYNTAX_COLOR_MODELS_KEY					@"Syntax Color Models"
#define SYNTAX_COLOR_STEPS_KEY					@"Syntax Color Steps"
#define SYNTAX_COLOR_PARTS_KEY					@"Syntax Color Parts"
#define SYNTAX_COLOR_PRIMITIVES_KEY				@"Syntax Color Primitives"
#define SYNTAX_COLOR_COMMENTS_KEY				@"Syntax Color Comments"
#define SYNTAX_COLOR_UNKNOWN_KEY				@"Syntax Color Unknown"
#define GRID_SPACING_FINE						@"Grid Spacing: Fine"
#define GRID_SPACING_MEDIUM						@"Grid Spacing: Medium"
#define GRID_SPACING_COARSE						@"Grid Spacing: Coarse"


////////////////////////////////////////////////////////////////////////////////
//
#pragma mark		Dictionary Keys
//
////////////////////////////////////////////////////////////////////////////////


// The parts list file is stored at LDraw/PARTS_LIST_NAME.
// It contains a dictionary of parts. Each element in the dictionary 
// is an array of parts for a category; the key under which the array 
// is stored is the category name.
//
//The part catalog is a dictionary of parts filed by Category name.
#define PARTS_CATALOG_KEY						@"Part Catalog"
	//subdictionary keys.
	#define PART_NUMBER_KEY						@"Part Number"
	#define PART_NAME_KEY						@"Part Name"
	//#define PART_CATEGORY_KEY					@"Category"

//Raw dictionary containing each part filed by number.
#define PARTS_LIST_KEY							@"Part List"
	//subdictionary keys.
	//PART_NUMBER_KEY							(defined above)
	//PART_NAME_KEY								(defined above)


//Color Keys
#define LDRAW_COLOR_CODE						@"LDraw Color Code"		// NSNumber 0-512
#define COLOR_NAME								@"Color Name"			// NSString representing localized name

//Part Report keys
#define PART_QUANTITY							@"QuantityKey"			// NSNumber of how many of this part there are


////////////////////////////////////////////////////////////////////////////////
//
#pragma mark		File Names
//
////////////////////////////////////////////////////////////////////////////////

#define LDRAW_DIRECTORY_NAME					@"LDraw"

#define PRIMITIVES_DIRECTORY_NAME				@"p"
	#define PRIMITIVES_48_DIRECTORY_NAME		@"48"

#define PARTS_DIRECTORY_NAME					@"parts"
	#define SUBPARTS_DIRECTORY_NAME				@"s"

#define UNOFFICIAL_DIRECTORY_NAME				@"Unofficial"

#define PART_CATALOG_NAME						@"Bricksmith Parts.plist"


////////////////////////////////////////////////////////////////////////////////
//
#pragma mark		LDraw Syntax
//
// Strings which are absolute syntax of LDraw commands.
//
////////////////////////////////////////////////////////////////////////////////

#define LDRAW_MPD_FILE_START_MARKER				@"0 FILE"
#define LDRAW_MPD_FILE_END_MARKER				@"0 NOFILE"
#define LDRAW_STEP								@"0 STEP"

//Comment markers
#define LDRAW_COMMENT_WRITE						@"WRITE"
#define LDRAW_COMMENT_PRINT						@"PRINT"

//File header
#define LDRAW_HEADER_NAME						@"Name:"
#define LDRAW_HEADER_AUTHOR						@"Author:"
#define LDRAW_HEADER_OFFICIAL_MODEL				@"LDraw.org Official Model Repository"
#define LDRAW_HEADER_UNOFFICIAL_MODEL			@"Unofficial Model"


////////////////////////////////////////////////////////////////////////////////
//
#pragma mark		Drawing Mask bits and Constants
//
////////////////////////////////////////////////////////////////////////////////
#define DRAW_NO_OPTIONS							0
#define DRAW_BEGUN								1 << 0
#define DRAW_HIT_TEST_MODE						1 << 1
#define DRAW_REVERSE_NORMALS					1 << 2
#define DRAW_BOUNDS_ONLY						1 << 3

//The tags used for mouse-click hit-testing are formed by: 
// stepIndex * STEP_NAME_MULTIPLIER + partIndexInStep   (see LDrawDrawableElement)
#define STEP_NAME_MULTIPLIER					1000000

//Number of degrees to rotate in each grid mode.
#define GRID_ROTATION_FINE						15
#define GRID_ROTATION_MEDIUM					45
#define GRID_ROTATION_COARSE					90


////////////////////////////////////////////////////////////////////////////////
//
#pragma mark		Notifications
//
////////////////////////////////////////////////////////////////////////////////

//The part catalog was regenerated from disk. Object is the new catalog. No userInfo.
#define LDrawPartCatalogDidChangeNotification		@"LDrawPartCatalogDidChangeNotification"

//A directive was modified, either explicitly by the user or by undo/redo.
// Object is the LDrawDirective that changed. No userInfo.
#define LDrawDirectiveDidChangeNotification			@"LDrawDirectiveDidChangeNotification"

//Syntax coloring changed in preferences. Object is the application. No userInfo.
#define LDrawSyntaxColorsDidChangeNotification		@"LDrawSyntaxColorsDidChangeNotification"

//Active model changed. Object is the LDrawFile in which the model resides. No userInfo.
#define LDrawFileActiveModelDidChangeNotification	@"LDrawFileActiveModelDidChangeNotification"

//File has changed in some way that it should be redisplayed. Object is the LDrawFile that changed. No userInfo.
// Note: this should probably replace LDrawDirectiveDidChangeNotification in some places.
#define LDrawFileDidChangeNotification				@"LDrawFileDidChangeNotification"


////////////////////////////////////////////////////////////////////////////////
//
#pragma mark		Menu Tags
//
// Tags to look up menus with.
//
////////////////////////////////////////////////////////////////////////////////

typedef enum MenuTags {
	//Application Menu
	applicationMenuTag			= 0,
	
	//File Menu
	fileMenuTag					= 1,
	
	//Edit Menu
	editMenuTag					= 2,
	cutMenuTag					= 202,
	copyMenuTag					= 203,
	pasteMenuTag				= 204,
	deleteMenuTag				= 205,
	selectAllMenuTag			= 206,
	duplicateMenuTag			= 207,
	
	//Tools Menu
	toolsMenuTag				= 3,
	snapToGridMenuTag			= 304,
	gridFineMenuTag				= 305,
	gridMediumMenuTag			= 306,
	gridCoarseMenuTag			= 307,
	
	//Views Menu
	viewsMenuTag				= 4,
	stepDisplayMenuTag			= 404,
	nextStepMenuTag				= 405,
	previousStepMenuTag			= 406,
	
	//Models Menu
	modelsMenuTag				= 5,
	addModelMenuTag				= 501,
	modelsSeparatorMenuTag		= 502,
	insertReferenceMenuTag		= 503,
	submodelReferenceMenuTag	= 504, //used for all items in the Insert Reference menu.
	
	//Window Menu
	windowMenuTag				= 6
	
} menuTagsT;



////////////////////////////////////////////////////////////////////////////////
//
#pragma mark		Pasteboards
//
// Names of pasteboard types that Bricksmith uses to transfer data internally.
//
////////////////////////////////////////////////////////////////////////////////

//Contains an array of LDrawDirectives stored as NSData objects. There should 
// be no duplication of objects.
#define LDrawDirectivePboardType			@"LDrawDirectivePboardType"

//Contains an array of indexes for the original objects being drug.
// Since the objects are converted to data when placed on the 
// LDrawDirectivePboardType (effectively copying them), these source indexes 
// must be used to delete the original objects after the copies have been 
// deposited in their new destination.
#define LDrawDragSourceRowsPboardType		@"LDrawDragSourceRowsPboardType"