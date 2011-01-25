//==============================================================================
//
// File:		MacLDraw.h
//
// Purpose:		Keys, enumerations, constants, and build flags used in the 
//				Bricksmith project. 
//
// Notes:		Bricksmith was originally titled "Mac LDraw"; hence the name of 
//				this file. That name was dropped shortly before the 1.0 release 
//				because Tim Courtney said the LDraw name should be reserved for 
//				the Library itself, and I thought "Mac LDraw" was kinda boring. 
//
// Modified:	2/14/05 Allen Smith.
//
//==============================================================================


////////////////////////////////////////////////////////////////////////////////
//
#pragma mark		Build Flags
//					Special options to configure the program behavior.
//
////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////
//
#pragma mark		Preferences Keys
//
////////////////////////////////////////////////////////////////////////////////

#define DOCUMENT_WINDOW_SIZE						@"Document Window Size"
#define DONATION_SCREEN_SUPPRESS_THIS_VERSION		@"DonationRequestSuppressThisVersion"
#define DONATION_SCREEN_LAST_VERSION_DISPLAYED		@"DonationRequestLastVersion"
#define FAVORITE_PARTS_KEY							@"FavoriteParts"
#define FILE_CONTENTS_DRAWER_STATE					@"File Contents Drawer State" //obsolete
#define GRID_SPACING_COARSE							@"Grid Spacing: Coarse"
#define GRID_SPACING_FINE							@"Grid Spacing: Fine"
#define GRID_SPACING_MEDIUM							@"Grid Spacing: Medium"
#define LDRAW_GL_VIEW_ANGLE							@"LDrawGLView Viewing Angle"
#define LDRAW_GL_VIEW_PROJECTION					@"LDrawGLView Viewing Projection"
#define LDRAW_PATH_KEY								@"LDraw Path"
#define LDRAW_VIEWER_BACKGROUND_COLOR_KEY			@"LDraw Viewer Background Color"
#define MOUSE_DRAGGING_BEHAVIOR_KEY					@"Mouse Dragging Behavior"
#define PART_BROWSER_DRAWER_STATE					@"Part Browser Drawer State"
#define PART_BROWSER_PANEL_SHOW_AT_LAUNCH			@"Part Browser Panel Show at Launch"
#define PART_BROWSER_PREVIOUS_CATEGORY				@"Part Browser Previous Category"
#define PART_BROWSER_PREVIOUS_SELECTED_ROW			@"Part Browser Previous Selected Row"
#define PART_BROWSER_STYLE_KEY						@"Part Browser Style"
#define PREFERENCES_LAST_TAB_DISPLAYED				@"Preferences Tab"
#define SYNTAX_COLOR_COLORS_KEY						@"Syntak Color Colors"
#define SYNTAX_COLOR_COMMENTS_KEY					@"Syntax Color Comments"
#define SYNTAX_COLOR_MODELS_KEY						@"Syntax Color Models"
#define SYNTAX_COLOR_PARTS_KEY						@"Syntax Color Parts"
#define SYNTAX_COLOR_PRIMITIVES_KEY					@"Syntax Color Primitives"
#define SYNTAX_COLOR_STEPS_KEY						@"Syntax Color Steps"
#define SYNTAX_COLOR_UNKNOWN_KEY					@"Syntax Color Unknown"
#define TOOL_PALETTE_HIDDEN							@"Tool Palette Hidden"
#define VIEWPORTS_EXPAND_TO_AVAILABLE_SIZE			@"ViewportsExpandToAvailableSize"
#define COLUMNIZE_OUTPUT_KEY						@"ColumnizeOutput"

#define MINIFIGURE_HAS_HAT							@"Minifigure Has Hat"
#define MINIFIGURE_HAS_HEAD							@"Minifigure Has Head"
#define MINIFIGURE_HAS_NECK							@"Minifigure Has Neck"
#define MINIFIGURE_HAS_TORSO						@"Minifigure Has Torso"
#define MINIFIGURE_HAS_ARM_RIGHT					@"Minifigure Has Arm Right"
#define MINIFIGURE_HAS_ARM_LEFT						@"Minifigure Has Arm Left"
#define MINIFIGURE_HAS_HAND_RIGHT					@"Minifigure Has Hand Right"
#define MINIFIGURE_HAS_HAND_RIGHT_ACCESSORY			@"Minifigure Has Hand Right Accessory"
#define MINIFIGURE_HAS_HAND_LEFT					@"Minifigure Has Hand Left"
#define MINIFIGURE_HAS_HAND_LEFT_ACCESSORY			@"Minifigure Has Hand Left Accessory"
#define MINIFIGURE_HAS_HIPS							@"Minifigure Has Hips"
#define MINIFIGURE_HAS_LEG_RIGHT					@"Minifigure Has Leg Right"
#define MINIFIGURE_HAS_LEG_RIGHT_ACCESSORY			@"Minifigure Has Leg Right Accessory"
#define MINIFIGURE_HAS_LEG_LEFT						@"Minifigure Has Leg Left"
#define MINIFIGURE_HAS_LEG_LEFT_ACCESSORY			@"Minifigure Has Leg Left Accessory"

#define MINIFIGURE_PARTNAME_HAT						@"Minifigure Partname Hat"
#define MINIFIGURE_PARTNAME_HEAD					@"Minifigure Partname Head"
#define MINIFIGURE_PARTNAME_NECK					@"Minifigure Partname Neck"
#define MINIFIGURE_PARTNAME_TORSO					@"Minifigure Partname Torso"
#define MINIFIGURE_PARTNAME_ARM_RIGHT				@"Minifigure Partname Arm Right"
#define MINIFIGURE_PARTNAME_ARM_LEFT				@"Minifigure Partname Arm Left"
#define MINIFIGURE_PARTNAME_HAND_RIGHT				@"Minifigure Partname Hand Right"
#define MINIFIGURE_PARTNAME_HAND_RIGHT_ACCESSORY	@"Minifigure Partname Hand Right Accessory"
#define MINIFIGURE_PARTNAME_HAND_LEFT				@"Minifigure Partname Hand Left"
#define MINIFIGURE_PARTNAME_HAND_LEFT_ACCESSORY		@"Minifigure Partname Hand Left Accessory"
#define MINIFIGURE_PARTNAME_HIPS					@"Minifigure Partname Hips"
#define MINIFIGURE_PARTNAME_LEG_RIGHT				@"Minifigure Partname Leg Right"
#define MINIFIGURE_PARTNAME_LEG_RIGHT_ACCESSORY		@"Minifigure Partname Leg Right Accessory"
#define MINIFIGURE_PARTNAME_LEG_LEFT				@"Minifigure Partname Leg Left"
#define MINIFIGURE_PARTNAME_LEG_LEFT_ACCESSORY		@"Minifigure Partname Leg Left Accessory"

#define MINIFIGURE_ANGLE_HAT						@"Minifigure Angle Hat"
#define MINIFIGURE_ANGLE_HEAD						@"Minifigure Angle Head"
#define MINIFIGURE_ANGLE_NECK						@"Minifigure Angle Neck"
#define MINIFIGURE_ANGLE_TORSO						@"Minifigure Angle Torso"
#define MINIFIGURE_ANGLE_ARM_RIGHT					@"Minifigure Angle Arm Right"
#define MINIFIGURE_ANGLE_ARM_LEFT					@"Minifigure Angle Arm Left"
#define MINIFIGURE_ANGLE_HAND_RIGHT					@"Minifigure Angle Hand Right"
#define MINIFIGURE_ANGLE_HAND_RIGHT_ACCESSORY		@"Minifigure Angle Hand Right Accessory"
#define MINIFIGURE_ANGLE_HAND_LEFT					@"Minifigure Angle Hand Left"
#define MINIFIGURE_ANGLE_HAND_LEFT_ACCESSORY		@"Minifigure Angle Hand Left Accessory"
#define MINIFIGURE_ANGLE_HIPS						@"Minifigure Angle Hips"
#define MINIFIGURE_ANGLE_LEG_RIGHT					@"Minifigure Angle Leg Right"
#define MINIFIGURE_ANGLE_LEG_RIGHT_ACCESSORY		@"Minifigure Angle Leg Right Accessory"
#define MINIFIGURE_ANGLE_LEG_LEFT					@"Minifigure Angle Leg Left"
#define MINIFIGURE_ANGLE_LEG_LEFT_ACCESSORY			@"Minifigure Angle Leg Left Accessory"

#define MINIFIGURE_COLOR_HAT						@"Minifigure Color Hat"
#define MINIFIGURE_COLOR_HEAD						@"Minifigure Color Head"
#define MINIFIGURE_COLOR_NECK						@"Minifigure Color Neck"
#define MINIFIGURE_COLOR_TORSO						@"Minifigure Color Torso"
#define MINIFIGURE_COLOR_ARM_RIGHT					@"Minifigure Color Arm Right"
#define MINIFIGURE_COLOR_ARM_LEFT					@"Minifigure Color Arm Left"
#define MINIFIGURE_COLOR_HAND_RIGHT					@"Minifigure Color Hand Right"
#define MINIFIGURE_COLOR_HAND_RIGHT_ACCESSORY		@"Minifigure Color Hand Right Accessory"
#define MINIFIGURE_COLOR_HAND_LEFT					@"Minifigure Color Hand Left"
#define MINIFIGURE_COLOR_HAND_LEFT_ACCESSORY		@"Minifigure Color Hand Left Accessory"
#define MINIFIGURE_COLOR_HIPS						@"Minifigure Color Hips"
#define MINIFIGURE_COLOR_LEG_RIGHT					@"Minifigure Color Leg Right"
#define MINIFIGURE_COLOR_LEG_RIGHT_ACCESSORY		@"Minifigure Color Leg Right Accessory"
#define MINIFIGURE_COLOR_LEG_LEFT					@"Minifigure Color Leg Left"
#define MINIFIGURE_COLOR_LEG_LEFT_ACCESSORY			@"Minifigure Color Leg Left Accessory"

#define MINIFIGURE_HEAD_ELEVATION					@"Minifigure Head Elevation"

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
#define LDRAW_COLOR								@"LDraw Color"		// NSNumber 0-512
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

#define PARTS_DIRECTORY_NAME					@"parts" //match case of LDraw.org complete distribution zip package.
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
#define LDRAW_COMMENT_SLASH						@"//"

// Color definition
#define LDRAW_COLOR_DEFINITION					@"!COLOUR"
#define LDRAW_COLOR_DEF_CODE					@"CODE"
#define LDRAW_COLOR_DEF_VALUE					@"VALUE"
#define LDRAW_COLOR_DEF_EDGE					@"EDGE"
#define LDRAW_COLOR_DEF_ALPHA					@"ALPHA"
#define LDRAW_COLOR_DEF_LUMINANCE				@"LUMINANCE"
#define LDRAW_COLOR_DEF_MATERIAL_CHROME			@"CHROME"
#define LDRAW_COLOR_DEF_MATERIAL_PEARLESCENT	@"PEARLESCENT"
#define LDRAW_COLOR_DEF_MATERIAL_RUBBER			@"RUBBER"
#define LDRAW_COLOR_DEF_MATERIAL_MATTE_METALLIC	@"MATTE_METALLIC"
#define LDRAW_COLOR_DEF_MATERIAL_METAL			@"METAL"
#define LDRAW_COLOR_DEF_MATERIAL_CUSTOM			@"MATERIAL"

//File header
#define LDRAW_HEADER_NAME						@"Name:"
#define LDRAW_HEADER_AUTHOR						@"Author:"
#define LDRAW_HEADER_OFFICIAL_MODEL				@"LDraw.org Official Model Repository"
#define LDRAW_HEADER_UNOFFICIAL_MODEL			@"Unofficial Model"

//Important Categories
#define LDRAW_MOVED_CATEGORY					@"Moved"
#define LDRAW_MOVED_DESCRIPTION_PREFIX			@"~Moved to"

// Rotation Steps
#define LDRAW_ROTATION_STEP						@"0 ROTSTEP"
#define LDRAW_ROTATION_END						@"END"
#define LDRAW_ROTATION_RELATIVE					@"REL"
#define LDRAW_ROTATION_ABSOLUTE					@"ABS"
#define LDRAW_ROTATION_ADDITIVE					@"ADD"


////////////////////////////////////////////////////////////////////////////////
//
#pragma mark		Drawing Mask bits and Constants
//
////////////////////////////////////////////////////////////////////////////////
#define DRAW_NO_OPTIONS							0
#define DRAW_HIT_TEST_MODE						1 << 1
#define DRAW_BOUNDS_ONLY						1 << 3

//Number of degrees to rotate in each grid mode.
#define GRID_ROTATION_FINE						15
#define GRID_ROTATION_MEDIUM					45
#define GRID_ROTATION_COARSE					90


////////////////////////////////////////////////////////////////////////////////
//
#pragma mark		Notifications
//
////////////////////////////////////////////////////////////////////////////////

//A directive was modified, either explicitly by the user or by undo/redo.
// Object is the LDrawDirective that changed. No userInfo.
#define LDrawDirectiveDidChangeNotification				@"LDrawDirectiveDidChangeNotification"

//The color which will be assigned to new parts has changed.
// Object is the new LDrawColorT, as an NSNumber. No userInfo.
#define LDrawColorDidChangeNotification					@"LDrawColorDidChangeNotification"

//Active model changed.
// Object is the LDrawFile in which the model resides. No userInfo.
#define LDrawFileActiveModelDidChangeNotification		@"LDrawFileActiveModelDidChangeNotification"

//File has changed in some way that it should be redisplayed. Object is the LDrawFile that changed. No userInfo.
// Note: this should probably replace LDrawDirectiveDidChangeNotification in some places.
#define LDrawFileDidChangeNotification					@"LDrawFileDidChangeNotification"

//the keys on the keyboard which were depressed just changed.
// Object is an NSEvent: keyUp, keyDown, or flagsChanged.
#define LDrawKeyboardDidChangeNotification				@"LDrawKeyboardDidChangeNotification"

//tool mode changed.
// Object is an NSNumber containing the new ToolModeT.
#define LDrawMouseToolDidChangeNotification				@"LDrawMouseToolDidChangeNotification"

//tablet pointing device changed.
// Object is an NSEvent: NSTabletProximity.
#define LDrawPointingDeviceDidChangeNotification		@"LDrawPointingDeviceDidChangeNotification"

//The part catalog was regenerated from disk.
// Object is the new catalog. No userInfo.
#define LDrawPartLibraryDidChangeNotification			@"LDrawPartLibraryDidChangeNotification"

//Part Browser should be shown a different way.
// Object is NSNumber of new style. No userInfo.
#define LDrawPartBrowserStyleDidChangeNotification		@"LDrawPartBrowserStyleDidChangeNotification"

//Syntax coloring changed in preferences.
// Object is the application. No userInfo.
#define LDrawSyntaxColorsDidChangeNotification			@"LDrawSyntaxColorsDidChangeNotification"

//Syntax coloring changed in preferences.
// Object is the new color. No userInfo.
#define LDrawViewBackgroundColorDidChangeNotification	@"LDrawViewBackgroundColorDidChangeNotification"


////////////////////////////////////////////////////////////////////////////////
//
#pragma mark		Menu Tags
//
// Tags to look up menus with.
//
////////////////////////////////////////////////////////////////////////////////

typedef enum MenuTags
{
	// Application Menu
	applicationMenuTag				= 0,
	
	// File Menu
	fileMenuTag						= 1,
	
	// Edit Menu
	editMenuTag						= 2,
	cutMenuTag						= 202,
	copyMenuTag						= 203,
	pasteMenuTag					= 204,
	deleteMenuTag					= 205,
	selectAllMenuTag				= 206,
	duplicateMenuTag				= 207,
	rotatePositiveXTag				= 220,
	rotateNegativeXTag				= 221,
	rotatePositiveYTag				= 222,
	rotateNegativeYTag				= 223,
	rotatePositiveZTag				= 224,
	rotateNegativeZTag				= 225,
	
	// Tools Menu
	toolsMenuTag					= 3,
	fileContentsMenuTag				= 302,
	gridFineMenuTag					= 305,
	gridMediumMenuTag				= 306,
	gridCoarseMenuTag				= 307,
	
	// Views Menu
	viewsMenuTag					= 4,
	stepDisplayMenuTag				= 404,
	nextStepMenuTag					= 405,
	previousStepMenuTag				= 406,
	orientationMenuTag				= 407,
	
	// Piece Menu
	pieceMenuTag					= 5,
	hidePieceMenuTag				= 501,
	showPieceMenuTag				= 502,
	snapToGridMenuTag				= 503,
	
	// Models Menu
	modelsMenuTag					= 6,
	addModelMenuTag					= 601,
	modelsSeparatorMenuTag			= 602,
	insertReferenceMenuTag			= 603,
	submodelReferenceMenuTag		= 604, //used for all items in the Insert Reference menu.
	
	// Window Menu
	windowMenuTag					= 7,
	
	// Contextual Menus
	partBrowserAddFavoriteTag		= 4001,
	partBrowserRemoveFavoriteTag	= 4002
	
} menuTagsT;


////////////////////////////////////////////////////////////////////////////////
//
#pragma mark		Shared Datatypes
//
// Data types which would otherwise be homeless
//
////////////////////////////////////////////////////////////////////////////////

typedef enum MouseDragBehavior
{
	MouseDraggingOff									= 0,
	MouseDraggingBeginImmediately						= 1,
	MouseDraggingBeginAfterDelay						= 2,
	MouseDraggingImmediatelyInOrthoNeverInPerspective	= 3
	

} MouseDragBehaviorT;


typedef enum PartBrowserStyle
{
	PartBrowserShowAsDrawer	= 0,
	PartBrowserShowAsPanel	= 1

} PartBrowserStyleT;


////////////////////////////////////////////////////////////////////////////////
//
#pragma mark		Pasteboards
//
// Names of pasteboard types that Bricksmith uses to transfer data internally.
//
////////////////////////////////////////////////////////////////////////////////

//Used for dragging within the File Contents outline. Contains an array of 
// LDrawDirectives stored as NSData objects. There should be no duplication of 
// objects.
#define LDrawDirectivePboardType				@"LDrawDirectivePboardType"

//Used for dragging parts around in or between viewports. Contains an array of 
// LDrawDirectives stored as NSData objects. There should be no duplication of 
// objects.
#define LDrawDraggingPboardType					@"LDrawDraggingPboardType"

// Contains a Vector3 as NSData indicating the offset between the click location 
// which originated the drag and the position of the first dragged directive. 
#define LDrawDraggingInitialOffsetPboardType	@"LDrawDraggingInitialOffsetPboardType"

// Contains a BOOL indicating the dragging directive has never been part of a 
// model before.  
#define LDrawDraggingIsUninitializedPboardType	@"LDrawDraggingIsUninitializedPboardType"

//Contains an array of indexes for the original objects being drug.
// Since the objects are converted to data when placed on the 
// LDrawDirectivePboardType (effectively copying them), these source indexes 
// must be used to delete the original objects after the copies have been 
// deposited in their new destination.
#define LDrawDragSourceRowsPboardType			@"LDrawDragSourceRowsPboardType"

