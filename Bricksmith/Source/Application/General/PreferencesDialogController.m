//==============================================================================
//
// File:		PreferencesDialogController.m
//
// Purpose:		Handles the user interface between the application and its 
//				preferences file.
//
//  Created by Allen Smith on 2/14/05.
//  Copyright 2005. All rights reserved.
//==============================================================================
#import "PreferencesDialogController.h"

#import "MacLDraw.h"
#import "LDrawApplication.h"
#import "LDrawGLView.h"			//for ViewingAngleT
#import "PartLibrary.h"
#import "UserDefaultsCategory.h"
#import "WindowCategory.h"
#import <AMSProgressBar/AMSProgressBar.h>

@implementation PreferencesDialogController

//The shared preferences window. We need to store this reference here so that 
// we can simply bring the window to the front when it is already onscreen, 
// rather than accidentally creating a whole new one.
PreferencesDialogController *preferencesDialog = nil;


//========== awakeFromNib ======================================================
//
// Purpose:		Show the preferences window.
//
//==============================================================================
- (void) awakeFromNib{

	//Grab the current window content from the Nib (it should be blank). 
	// We will display this while changing panes.
	blankContent = [[preferencesWindow contentView] retain];

	NSToolbar *tabToolbar = [[[NSToolbar alloc] initWithIdentifier:@"Preferences"] autorelease];
	[tabToolbar setDelegate:self];
	[preferencesWindow setToolbar:tabToolbar];
	
	//Restore the last-seen tab.
	NSUserDefaults	*userDefaults = [NSUserDefaults standardUserDefaults];
	NSString		*lastIdentifier = [userDefaults stringForKey:PREFERENCES_LAST_TAB_DISPLAYED];
	if(lastIdentifier == nil)
		lastIdentifier = PREFS_LDRAW_TAB_IDENTFIER;
	[self selectPanelWithIdentifier:lastIdentifier];
	
}

#pragma mark -
#pragma mark INITIALIZATION
#pragma mark -

//========== doPreferences =====================================================
//
// Purpose:		Show the preferences window.
//
//==============================================================================
+ (void) doPreferences{

	if(preferencesDialog == nil)
		preferencesDialog = [[PreferencesDialogController alloc] init];
	
	[preferencesDialog showPreferencesWindow];
}

//========== init ==============================================================
//
// Purpose:		Make us an object. Load us our window.
//
//==============================================================================
- (id) init{
	self = [super init];
	[NSBundle loadNibNamed:@"Preferences" owner:self];
	return self;
}

//========== showPreferencesWindow =============================================
//
// Purpose:		Brings the window on screen.
//
//==============================================================================
- (void) showPreferencesWindow{
	[self setDialogValues];
	[preferencesWindow makeKeyAndOrderFront:nil];
}//end showPreferencesWindow


#pragma mark -

//========== setDialogValues ===================================================
//
// Purpose:		Brings the window on screen.
//
//==============================================================================
- (void) setDialogValues{
	
	//Make sure there are actually preferences to read before attempting to 
	// retrieve them.
	[PreferencesDialogController ensureDefaults];

	[self setStylesTabValues];
	[self setLDrawTabValues];
}


//========== setStylesTabValues ================================================
//
// Purpose:		Updates the data in the Styles tab to match what is on the disk.
//
//==============================================================================
- (void) setStylesTabValues{
	
	NSUserDefaults	*userDefaults		= [NSUserDefaults standardUserDefaults];
	
	NSColor			*modelsColor		= [userDefaults colorForKey:SYNTAX_COLOR_MODELS_KEY];
	NSColor			*stepsColor			= [userDefaults colorForKey:SYNTAX_COLOR_STEPS_KEY];
	NSColor			*partsColor			= [userDefaults colorForKey:SYNTAX_COLOR_PARTS_KEY];
	NSColor			*primitivesColor	= [userDefaults colorForKey:SYNTAX_COLOR_PRIMITIVES_KEY];
	NSColor			*commentsColor		= [userDefaults colorForKey:SYNTAX_COLOR_COMMENTS_KEY];
	NSColor			*unknownColor		= [userDefaults colorForKey:SYNTAX_COLOR_UNKNOWN_KEY];
	
	[modelsColorWell		setColor:modelsColor];
	[stepsColorWell			setColor:stepsColor];
	[partsColorWell			setColor:partsColor];
	[primitivesColorWell	setColor:primitivesColor];
	[commentsColorWell		setColor:commentsColor];
	[unknownColorWell		setColor:unknownColor];
}


//========== setLDrawTabValues =================================================
//
// Purpose:		Updates the data in the LDraw tab to match what is on the disk.
//
//==============================================================================
- (void) setLDrawTabValues{
	PartLibrary		*partLibrary	= [LDrawApplication sharedPartLibrary];
	NSUserDefaults	*userDefaults	= [NSUserDefaults standardUserDefaults];
	NSFileManager	*fileManager	= [NSFileManager defaultManager];
	NSString		*ldrawPath		= [userDefaults stringForKey:LDRAW_PATH_KEY];
	
	if(ldrawPath != nil){
		[LDrawPathTextField setStringValue:ldrawPath];
	}//end if we have a folder.
	//No folder selected yet.
	else
		[self chooseLDrawFolder:self];
	
	//Grid Spacing.
	float gridFine		= [userDefaults floatForKey:GRID_SPACING_FINE];
	float gridMedium	= [userDefaults floatForKey:GRID_SPACING_MEDIUM];
	float gridCoarse	= [userDefaults floatForKey:GRID_SPACING_COARSE];
	[[gridSpacingForm cellAtIndex:0] setFloatValue:gridFine];
	[[gridSpacingForm cellAtIndex:1] setFloatValue:gridMedium];
	[[gridSpacingForm cellAtIndex:2] setFloatValue:gridCoarse];
	
}//end showPreferencesWindow


#pragma mark -
#pragma mark ACTIONS
#pragma mark -

//========== changeTab =========================================================
//
// Purpose:		Sent by the toolbar "tabs" to indicate the preferences pane 
//				should change.
//
//==============================================================================
- (void)changeTab:(id)sender{
	
	NSString	*itemIdentifier	= [sender itemIdentifier];
	
	[self selectPanelWithIdentifier:itemIdentifier];
}


#pragma mark -
#pragma mark Styles Tab

//========== modelsColorWellChanged: ===========================================
//
// Purpose:		This syntax-color well changed. Update the value in preferences.
//
//==============================================================================
- (IBAction) modelsColorWellChanged:(id)sender{
	NSColor			*newColor		= [sender color];
	NSUserDefaults	*userDefaults	= [NSUserDefaults standardUserDefaults];
	
	[userDefaults setColor:newColor forKey:SYNTAX_COLOR_MODELS_KEY];
	
	[[NSNotificationCenter defaultCenter] 
			postNotificationName:LDrawSyntaxColorsDidChangeNotification
						  object:NSApp ];
}


//========== stepsColorWellChanged: ============================================
//
// Purpose:		This syntax-color well changed. Update the value in preferences.
//
//==============================================================================
- (IBAction) stepsColorWellChanged:(id)sender{
	NSColor			*newColor		= [sender color];
	NSUserDefaults	*userDefaults	= [NSUserDefaults standardUserDefaults];
	
	[userDefaults setColor:newColor forKey:SYNTAX_COLOR_STEPS_KEY];
	
	[[NSNotificationCenter defaultCenter] 
			postNotificationName:LDrawSyntaxColorsDidChangeNotification
						  object:NSApp ];
}

//========== partsColorWellChanged: ============================================
//
// Purpose:		This syntax-color well changed. Update the value in preferences.
//
//==============================================================================
- (IBAction) partsColorWellChanged:(id)sender{
	NSColor			*newColor		= [sender color];
	NSUserDefaults	*userDefaults	= [NSUserDefaults standardUserDefaults];
	
	[userDefaults setColor:newColor forKey:SYNTAX_COLOR_PARTS_KEY];

	[[NSNotificationCenter defaultCenter] 
			postNotificationName:LDrawSyntaxColorsDidChangeNotification
						  object:NSApp ];
}

//========== primitivesColorWellChanged: =======================================
//
// Purpose:		This syntax-color well changed. Update the value in preferences.
//
//==============================================================================
- (IBAction) primitivesColorWellChanged:(id)sender{
	NSColor			*newColor		= [sender color];
	NSUserDefaults	*userDefaults	= [NSUserDefaults standardUserDefaults];
	
	[userDefaults setColor:newColor forKey:SYNTAX_COLOR_PRIMITIVES_KEY];
	
	[[NSNotificationCenter defaultCenter] 
			postNotificationName:LDrawSyntaxColorsDidChangeNotification
						  object:NSApp ];
}


//========== commentsColorWellChanged: =========================================
//
// Purpose:		This syntax-color well changed. Update the value in preferences.
//
//==============================================================================
- (IBAction) commentsColorWellChanged:(id)sender{
	NSColor			*newColor		= [sender color];
	NSUserDefaults	*userDefaults	= [NSUserDefaults standardUserDefaults];
	
	[userDefaults setColor:newColor forKey:SYNTAX_COLOR_COMMENTS_KEY];
	
	[[NSNotificationCenter defaultCenter] 
			postNotificationName:LDrawSyntaxColorsDidChangeNotification
						  object:NSApp ];
}


//========== unknownColorWellChanged: ==========================================
//
// Purpose:		This syntax-color well changed. Update the value in preferences.
//
//==============================================================================
- (IBAction) unknownColorWellChanged:(id)sender{
	NSColor			*newColor		= [sender color];
	NSUserDefaults	*userDefaults	= [NSUserDefaults standardUserDefaults];
	
	[userDefaults setColor:newColor forKey:SYNTAX_COLOR_UNKNOWN_KEY];
	
	[[NSNotificationCenter defaultCenter] 
			postNotificationName:LDrawSyntaxColorsDidChangeNotification
						  object:NSApp ];
}



#pragma mark -
#pragma mark LDraw Tab

//========== chooseLDrawFolder =================================================
//
// Purpose:		Present a folder choose dialog to find the LDraw folder.
//
//==============================================================================
- (IBAction)chooseLDrawFolder:(id)sender
{
	//Create a standard "Choose" dialog.
	NSOpenPanel *folderChooser = [NSOpenPanel openPanel];
	[folderChooser setCanChooseFiles:NO];
	[folderChooser setCanChooseDirectories:YES];
	
	//Tell the poor user what this dialog does!
	[folderChooser setTitle:NSLocalizedString(@"Choose LDraw Folder", nil)];
	[folderChooser setMessage:NSLocalizedString(@"LDrawFolderChooserMessage", nil)];
	[folderChooser setAccessoryView:folderChooserAccessoryView];
	[folderChooser setPrompt:NSLocalizedString(@"Choose", nil)];
	
	//Run the dialog.
	if([folderChooser runModalForTypes:nil] == NSOKButton){
		//Get the folder selected.
		NSString		*folderPath		= [[folderChooser filenames] objectAtIndex:0];
		
		[self changeLDrawFolderPath:folderPath];
	}
	
}

//========== pathTextFieldChanged: =============================================
//
// Purpose:		The user has gone all geek on us and manually typed in a new 
//				LDraw folder path.
//
//==============================================================================
- (IBAction) pathTextFieldChanged:(id)sender{
	NSString *newPath = [LDrawPathTextField stringValue];
	
	[self changeLDrawFolderPath:newPath];
}


//========== reloadParts: ======================================================
//
// Purpose:		Scans the contents of the LDraw/Parts folder and produces a 
//				Mac-friendly index of parts.
//
//				Is it fast? No. Is it easy to code? Yes.
//
//==============================================================================
- (IBAction)reloadParts:(id)sender
{
	PartLibrary			*partLibrary		= [LDrawApplication sharedPartLibrary];
	
	[partLibrary reloadParts:sender];
			
}//end reloadParts:


//========== gridSpacingChanged: ===============================================
//
// Purpose:		User updated the amounts by which parts are shifted in different 
//				grid modes.
//
//==============================================================================
- (IBAction) gridSpacingChanged:(id)sender {
	NSUserDefaults	*userDefaults		= [NSUserDefaults standardUserDefaults];

	//Grid Spacing.
	float gridFine	= [[gridSpacingForm cellAtIndex:0] floatValue];
	float gridMedium	= [[gridSpacingForm cellAtIndex:1] floatValue];
	float gridCoarse	= [[gridSpacingForm cellAtIndex:2] floatValue];
	
	[userDefaults setFloat:gridFine		forKey:GRID_SPACING_FINE];
	[userDefaults setFloat:gridMedium	forKey:GRID_SPACING_MEDIUM];
	[userDefaults setFloat:gridCoarse	forKey:GRID_SPACING_COARSE];
}


#pragma mark -
#pragma mark TOOLBAR DELEGATE
#pragma mark -

//**** NSToolbar ****
//========== toolbarAllowedItemIdentifiers: ====================================
//
// Purpose:		The tabs allowed in the preferences window.
//
//==============================================================================
- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
{
	return [NSArray arrayWithObjects:
						PREFS_STYLE_TAB_IDENTFIER,
						PREFS_LDRAW_TAB_IDENTFIER,
						nil
			];
}


//**** NSToolbar ****
//========== toolbarDefaultItemIdentifiers: ====================================
//
// Purpose:		The tabs shown by default in the preferences window.
//
//==============================================================================
- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar
{
	return [self toolbarAllowedItemIdentifiers:toolbar];
}


//**** NSToolbar ****
//========== toolbarSelectableItemIdentifiers: =================================
//
// Purpose:		The tabs selectable in the preferences window.
//
//==============================================================================
- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar
{
	return [self toolbarAllowedItemIdentifiers:toolbar];
}


//**** NSToolbar ****
//========== toolbar:itemForItemIdentifier:willBeInsertedIntoToolbar:: =========
//
// Purpose:		Creates the "tabs" used in the preferences window.
//
//==============================================================================
- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar
	 itemForItemIdentifier:(NSString *)itemIdentifier
 willBeInsertedIntoToolbar:(BOOL)flag
{
	NSToolbarItem *newItem = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
	
	[newItem setLabel:NSLocalizedString(itemIdentifier, nil)];
	
	if([itemIdentifier isEqualToString:PREFS_LDRAW_TAB_IDENTFIER])
		[newItem setImage:[NSImage imageNamed:@"LDrawLogo"]];
	else if([itemIdentifier isEqualToString:PREFS_STYLE_TAB_IDENTFIER])
		[newItem setImage:[NSImage imageNamed:@"SyntaxColoring"]];
	
	[newItem setTarget:self];
	[newItem setAction:@selector(changeTab:)];
	
	return [newItem autorelease];
}

#pragma mark -
#pragma mark WINDOW DELEGATE
#pragma mark -

//**** NSWindow ****
//========== windowShouldClose: ================================================
//
// Purpose:		Used to release the preferences controller.
//
//==============================================================================
- (BOOL)windowShouldClose:(id)sender
{
	//Save out the last tab view.
	NSUserDefaults	*userDefaults = [NSUserDefaults standardUserDefaults];
	NSString		*lastIdentifier = [[preferencesWindow toolbar] selectedItemIdentifier];
	
	[userDefaults setObject:lastIdentifier
					 forKey:PREFERENCES_LAST_TAB_DISPLAYED];
	
	//Make sure our memory is all released.
	[preferencesDialog autorelease];
	return YES;
}


#pragma mark -
#pragma mark UTILITIES
#pragma mark -


//========== ensureDefaults ====================================================
//
// Purpose:		Verifies that all expected settings exist in preferences. If a 
//				setting is not found, it is restored to its default value.
//
//				This method should be called upon program launch, so that the 
//				rest of the program need not worry about preference 
//				error-checking.
//
//==============================================================================
+ (void) ensureDefaults{
	NSUserDefaults		*userDefaults		= [NSUserDefaults standardUserDefaults];
	NSMutableDictionary	*initialDefaults	= [NSMutableDictionary dictionary];
	
	NSColor			*modelsColor		= [NSColor blackColor];
	NSColor			*stepsColor			= [NSColor blackColor];
	NSColor			*partsColor			= [NSColor blackColor];
	NSColor			*primitivesColor	= [NSColor blueColor];
	NSColor			*commentsColor		= [NSColor colorWithDeviceRed:(float) 35 / 255
																green:(float)110 / 255
																 blue:(float) 37 / 255
																alpha:1.0 ];
	NSColor			*unknownColor		= [NSColor lightGrayColor];
	
	//
	// Syntax Colors
	//
	[initialDefaults setObject:[NSArchiver archivedDataWithRootObject:modelsColor]		forKey:SYNTAX_COLOR_MODELS_KEY];
	[initialDefaults setObject:[NSArchiver archivedDataWithRootObject:stepsColor]		forKey:SYNTAX_COLOR_STEPS_KEY];
	[initialDefaults setObject:[NSArchiver archivedDataWithRootObject:partsColor]		forKey:SYNTAX_COLOR_PARTS_KEY];
	[initialDefaults setObject:[NSArchiver archivedDataWithRootObject:primitivesColor]	forKey:SYNTAX_COLOR_PRIMITIVES_KEY];
	[initialDefaults setObject:[NSArchiver archivedDataWithRootObject:commentsColor]	forKey:SYNTAX_COLOR_COMMENTS_KEY];
	[initialDefaults setObject:[NSArchiver archivedDataWithRootObject:unknownColor]		forKey:SYNTAX_COLOR_UNKNOWN_KEY];
	
	//
	// Grid Spacing
	//
	[initialDefaults setObject:[NSNumber numberWithFloat: 1]	forKey:GRID_SPACING_FINE];
	[initialDefaults setObject:[NSNumber numberWithFloat:10]	forKey:GRID_SPACING_MEDIUM];
	[initialDefaults setObject:[NSNumber numberWithFloat:20]	forKey:GRID_SPACING_COARSE];
	
	//
	// Initial Window State
	//
	[initialDefaults setObject:[NSNumber numberWithInt:NSDrawerOpenState]	forKey:PART_BROWSER_DRAWER_STATE];
	[initialDefaults setObject:[NSNumber numberWithInt:NSDrawerOpenState]	forKey:FILE_CONTENTS_DRAWER_STATE];
	
	//OpenGL viewer settings -- see -restoreConfiguration in LDrawGLView.
	[initialDefaults setObject:[NSNumber numberWithInt:ViewingAngle3D]				forKey:[LDRAW_GL_VIEW_ANGLE			stringByAppendingString:@" fileGraphicsView"]];
	[initialDefaults setObject:[NSNumber numberWithInt:ProjectionModePerspective]	forKey:[LDRAW_GL_VIEW_PROJECTION	stringByAppendingString:@" fileGraphicsView"]];
	
	[initialDefaults setObject:[NSNumber numberWithInt:ViewingAngleFront]			forKey:[LDRAW_GL_VIEW_ANGLE			stringByAppendingString:@" fileDetailView1"]];
	[initialDefaults setObject:[NSNumber numberWithInt:ProjectionModeOrthographic]	forKey:[LDRAW_GL_VIEW_PROJECTION	stringByAppendingString:@" fileDetailView1"]];
	
	[initialDefaults setObject:[NSNumber numberWithInt:ViewingAngleLeft]			forKey:[LDRAW_GL_VIEW_ANGLE			stringByAppendingString:@" fileDetailView2"]];
	[initialDefaults setObject:[NSNumber numberWithInt:ProjectionModeOrthographic]	forKey:[LDRAW_GL_VIEW_PROJECTION	stringByAppendingString:@" fileDetailView2"]];

	[initialDefaults setObject:[NSNumber numberWithInt:ViewingAngleTop]				forKey:[LDRAW_GL_VIEW_ANGLE			stringByAppendingString:@" fileDetailView3"]];
	[initialDefaults setObject:[NSNumber numberWithInt:ProjectionModeOrthographic]	forKey:[LDRAW_GL_VIEW_PROJECTION	stringByAppendingString:@" fileDetailView3"]];
	
	//
	// Part Browser
	//
	[initialDefaults setObject:NSLocalizedString(@"All Categories", nil)	forKey:PART_BROWSER_PREVIOUS_CATEGORY];
	[initialDefaults setObject:[NSNumber numberWithInt:0]					forKey:PART_BROWSER_PREVIOUS_SELECTED_ROW];
	
	//
	// Tool Palette
	//
	[initialDefaults setObject:[NSNumber numberWithBool:NO]					forKey:TOOL_PALETTE_HIDDEN];
	
	[userDefaults registerDefaults:initialDefaults];
	
}//end ensureDefaults


//========== changeLDrawFolderPath: ============================================
//
// Purpose:		A new folder path has been chose as the LDraw folder. We need to 
//				check it out and reload the parts from it.
//
//==============================================================================
- (void) changeLDrawFolderPath:(NSString *) folderPath{

	PartLibrary		*partLibrary	= [LDrawApplication sharedPartLibrary];
	NSUserDefaults	*userDefaults	= [NSUserDefaults standardUserDefaults];
	
	//Record this new folder in preferences whether it's right or not. We'll let 
	// them sink their own ship here.
	[userDefaults setObject:folderPath
					 forKey:LDRAW_PATH_KEY];
	[LDrawPathTextField setStringValue:folderPath];
	
	if([partLibrary validateLDrawFolderWithMessage:folderPath] == YES){
		[self reloadParts:self];
	}
	//else we displayed an error message already.
}

//========== selectPanelWithIdentifier: ========================================
//
// Purpose:		Changes the the preferences dialog to display the panel/tab 
//				represented by itemIdentifier.
//
//==============================================================================
- (void)selectPanelWithIdentifier:(NSString *)itemIdentifier{
	
	NSView		*newContentView	= nil;
	NSRect		 newFrameRect	= NSZeroRect;
	
	//Make sure the corresponding toolbar tab is selected too.
	[[preferencesWindow toolbar] setSelectedItemIdentifier:itemIdentifier];
	
	if([itemIdentifier isEqualToString:PREFS_LDRAW_TAB_IDENTFIER])
		newContentView = ldrawContentView;
	
	else if([itemIdentifier isEqualToString:PREFS_STYLE_TAB_IDENTFIER])
		newContentView = stylesContentView;
	
	//need content rect in screen coordinates
	//Need find window frame with new content view.
	newFrameRect = [preferencesWindow frameRectForContentSize:[newContentView frame].size];
	
	//Do a smooth transition to the new panel.
	[preferencesWindow setContentView:blankContent]; //so we don't see artifacts during resize.
	[preferencesWindow setFrame:newFrameRect
						display:YES
						animate:YES ];
	[preferencesWindow setContentView:newContentView];
	
}//end selectPanelWithIdentifier


#pragma mark -
#pragma mark DESTRUCTOR
#pragma mark -

//========== dealloc ===========================================================
//
// Purpose:		It's time to get fitted for a halo.
//
//==============================================================================
- (void)dealloc
{
	[preferencesWindow	release];
	[blankContent		release];
	
	//clear out our global preferences controller. 
	// It will be reinitialized when needed.
	preferencesDialog = nil;
	
	[super dealloc];
}


@end
