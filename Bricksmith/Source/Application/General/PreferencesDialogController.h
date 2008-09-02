//==============================================================================
//
// File:		PreferencesDialogController.h
//
// Purpose:		Handles the user interface between the application and its 
//				preferences file.
//
//  Created by Allen Smith on 2/14/05.
//  Copyright 2005. All rights reserved.
//==============================================================================
#import <Cocoa/Cocoa.h>

//Toolbar Tab Identifiers
#define PREFS_STYLE_TAB_IDENTFIER	@"PreferencesTabStyles"
#define PREFS_LDRAW_TAB_IDENTFIER	@"PreferencesTabLDraw"



@interface PreferencesDialogController : NSObject
{
    IBOutlet NSWindow		*preferencesWindow;
	         NSView			*blankContent; //the initial, empty content of the window in the Nib.
	IBOutlet NSView			*stylesContentView;
	IBOutlet NSView			*ldrawContentView;
	
    IBOutlet NSTextField	*LDrawPathTextField;
	IBOutlet NSForm			*gridSpacingForm;
	
	IBOutlet NSColorWell	*modelsColorWell;
	IBOutlet NSColorWell	*stepsColorWell;
	IBOutlet NSColorWell	*partsColorWell;
	IBOutlet NSColorWell	*primitivesColorWell;
	IBOutlet NSColorWell	*commentsColorWell;
	IBOutlet NSColorWell	*unknownColorWell;
	
	IBOutlet NSView			*folderChooserAccessoryView;
	
}
//Initialization
+ (void) doPreferences;
- (void) showPreferencesWindow;
- (void) setDialogValues;
- (void) setStylesTabValues;
- (void) setLDrawTabValues;

//Actions
- (void)changeTab:(id)sender;

- (IBAction) modelsColorWellChanged:(id)sender;
- (IBAction) stepsColorWellChanged:(id)sender;
- (IBAction) partsColorWellChanged:(id)sender;
- (IBAction) primitivesColorWellChanged:(id)sender;
- (IBAction) commentsColorWellChanged:(id)sender;
- (IBAction) unknownColorWellChanged:(id)sender;

- (IBAction) chooseLDrawFolder:(id)sender;
- (IBAction) pathTextFieldChanged:(id)sender;
- (IBAction) reloadParts:(id)sender;
- (IBAction) gridSpacingChanged:(id)sender;

//Utilities
+ (void) ensureDefaults;
- (void) changeLDrawFolderPath:(NSString *) folderPath;
- (void)selectPanelWithIdentifier:(NSString *)itemIdentifier;

@end
