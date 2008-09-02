//==============================================================================
//
// File:		DocumentToolbarController.m
//
// Purpose:		Repository for methods relating to creating and maintaining the 
//				toolbar for the main document window. This class is conveniently 
//				instantiated in the Nib file of the document, which is also 
//				where all the button's custom views live.
//
//				This class basically exists to sweep any toolbar complexity 
//				under the carpet, so as to keep the LDrawDocument class as 
//				focused as possible.
//
//  Created by Allen Smith on 5/4/05.
//  Copyright 2005. All rights reserved.
//==============================================================================
#import "DocumentToolbarController.h"

#import "MatrixMath.h"


@implementation DocumentToolbarController

//========== awakeFromNib ======================================================
//
// Purpose:		Creates things!
//
//==============================================================================
- (void) awakeFromNib {
	gridSegmentedControl = [[self makeGridSegmentControl] retain];
	
	//Retain all our custom views for toolbar items. Why? Because all of these 
	// could be inserted into the toolbar's view hierarchy, thereby *removing* 
	// them from their current superview, which holds the ONLY retain on them!
	// The result is that without retains here, all these views would be 
	// deallocated once added then removed from the toolbar!
	[nudgeXToolView		retain];
	[nudgeYToolView		retain];
	[nudgeZToolView		retain];
	[zoomToolTextField	retain];
	
	[nudgeXToolView		removeFromSuperview];
	[nudgeYToolView		removeFromSuperview];
	[nudgeZToolView		removeFromSuperview];
	[zoomToolTextField	removeFromSuperview];
	
}//end awakeFromNib

#pragma mark -
#pragma mark TOOLBAR DELEGATE
#pragma mark -

//========== toolbarAllowedItemIdentifiers: ====================================
//
// Purpose:		Returns the list of all possible toolbar buttons.
//
//==============================================================================
- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
{
	return [NSArray arrayWithObjects:	TOOLBAR_ZOOM_IN,
										TOOLBAR_ZOOM_OUT,
										TOOLBAR_ZOOM_SPECIFY,
										TOOLBAR_NUDGE_X_IDENTIFIER,
										TOOLBAR_NUDGE_Y_IDENTIFIER,
										TOOLBAR_NUDGE_Z_IDENTIFIER,
										TOOLBAR_SNAP_TO_GRID,
										TOOLBAR_GRID_SPACING_IDENTIFIER,
										TOOLBAR_ROTATE_POSITIVE_X,
										TOOLBAR_ROTATE_NEGATIVE_X,
										TOOLBAR_ROTATE_POSITIVE_Y,
										TOOLBAR_ROTATE_NEGATIVE_Y,
										TOOLBAR_ROTATE_POSITIVE_Z,
										TOOLBAR_ROTATE_NEGATIVE_Z,

										//Cocoa doodads
										NSToolbarSeparatorItemIdentifier,
										NSToolbarSpaceItemIdentifier,
										NSToolbarFlexibleSpaceItemIdentifier,
										NSToolbarCustomizeToolbarItemIdentifier,
										nil ];
}

//========== toolbarDefaultItemIdentifiers: ====================================
//
// Purpose:		Returns the list of toolbar buttons in the default set. These 
//				will appear when the application is opened for the first time.
//
//==============================================================================
- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar
{
	return [NSArray arrayWithObjects:	TOOLBAR_ZOOM_IN,
										TOOLBAR_ZOOM_SPECIFY,
										TOOLBAR_ZOOM_OUT,
										NSToolbarSeparatorItemIdentifier,
										TOOLBAR_GRID_SPACING_IDENTIFIER,
										TOOLBAR_SNAP_TO_GRID,
										NSToolbarSeparatorItemIdentifier,
										TOOLBAR_ROTATE_POSITIVE_X,
										TOOLBAR_ROTATE_NEGATIVE_X,
										TOOLBAR_ROTATE_POSITIVE_Y,
										TOOLBAR_ROTATE_NEGATIVE_Y,
										TOOLBAR_ROTATE_POSITIVE_Z,
										TOOLBAR_ROTATE_NEGATIVE_Z,
										nil ];
}

//========== toolbar:itemForItemIdentifier:willBeInsertedIntoToolbar: ==========
//
// Purpose:		The toolbar buttons themselves are created here.
//
//==============================================================================
- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar
	 itemForItemIdentifier:(NSString *)itemIdentifier
 willBeInsertedIntoToolbar:(BOOL)flag
{
	NSToolbarItem *newItem = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
	
	if([itemIdentifier isEqualToString:TOOLBAR_NUDGE_X_IDENTIFIER]) {
		[newItem setLabel:NSLocalizedString(@"NudgeX", nil)];
		[newItem setPaletteLabel:NSLocalizedString(@"NudgeX", nil)];
		[newItem setView:nudgeXToolView];
		[newItem setMinSize:[nudgeXToolView frame].size];
	}
	
	else if([itemIdentifier isEqualToString:TOOLBAR_NUDGE_Y_IDENTIFIER]) {
		[newItem setLabel:NSLocalizedString(@"NudgeY", nil)];
		[newItem setPaletteLabel:NSLocalizedString(@"NudgeY", nil)];
		[newItem setView:nudgeYToolView];
		[newItem setMinSize:[nudgeYToolView frame].size];
	}
	
	else if([itemIdentifier isEqualToString:TOOLBAR_NUDGE_Z_IDENTIFIER]) {
		[newItem setLabel:NSLocalizedString(@"NudgeZ", nil)];
		[newItem setPaletteLabel:NSLocalizedString(@"NudgeZ", nil)];
		[newItem setView:nudgeZToolView];
		[newItem setMinSize:[nudgeZToolView frame].size];
	}
	else if([itemIdentifier isEqualToString:TOOLBAR_GRID_SPACING_IDENTIFIER]) {
		newItem = [self makeGridSpacingItem];
	}
	//Rotations
	else if([itemIdentifier isEqualToString:TOOLBAR_ROTATE_POSITIVE_X]) {
		newItem = [self makeRotationPlusXItem];
	}
	else if([itemIdentifier isEqualToString:TOOLBAR_ROTATE_NEGATIVE_X]) {
		newItem = [self makeRotationMinusXItem];
	}
	else if([itemIdentifier isEqualToString:TOOLBAR_ROTATE_POSITIVE_Y]) {
		newItem = [self makeRotationPlusYItem];
	}
	else if([itemIdentifier isEqualToString:TOOLBAR_ROTATE_NEGATIVE_Y]) {
		newItem = [self makeRotationMinusYItem];
	}
	else if([itemIdentifier isEqualToString:TOOLBAR_ROTATE_POSITIVE_Z]) {
		newItem = [self makeRotationPlusZItem];
	}
	else if([itemIdentifier isEqualToString:TOOLBAR_ROTATE_NEGATIVE_Z]) {
		newItem = [self makeRotationMinusZItem];
	}
	
	else if([itemIdentifier isEqualToString:TOOLBAR_SNAP_TO_GRID]) {
		newItem = [self makeSnapToGridItem];
	}
	
	else if([itemIdentifier isEqualToString:TOOLBAR_ZOOM_IN]) {
		newItem = [self makeZoomInItem];
	}
	else if([itemIdentifier isEqualToString:TOOLBAR_ZOOM_OUT]) {
		newItem = [self makeZoomOutItem];
	}
	else if([itemIdentifier isEqualToString:TOOLBAR_ZOOM_SPECIFY]) {
		newItem = [self makeZoomTextFieldItem];
	}
	


	return newItem;
}


#pragma mark -
#pragma mark ACCESSORS
#pragma mark -
//Methods to affect toolbar widgets.

//========== setGridSpacingMode: ===============================================
//
// Purpose:		Someone is telling us they changed the current granularity.
//				We need to update our indicator to this new state.
//
//==============================================================================
- (void) setGridSpacingMode:(gridSpacingModeT)newMode {
	//Blast. I wanted to do this with tags, but no...
	// They didn't bother writing that method until Tiger.
	[self->gridSegmentedControl setSelectedSegment:newMode];
}


#pragma mark -
#pragma mark BUTTON FACTORIES
#pragma mark -

//========== makeGridSpacingItem ===============================================
//
// Purpose:		Creates the toolbar widget used to toggle the grid mode. 
//				Currently, this is implemented as a segmented control.
//
//==============================================================================
- (NSToolbarItem *) makeGridSpacingItem {
	NSToolbarItem		*newItem		= [[NSToolbarItem alloc] initWithItemIdentifier:TOOLBAR_GRID_SPACING_IDENTIFIER];
	gridSpacingModeT	gridMode		= [self->document gridSpacingMode];
	
	//And then the whole tag thing came crashing down when I discovered there 
	// is no segmentForTag: method. Oops. Addendum: They managed to squeeze it 
	// into Tiger. But I'm not developing for Tiger. Shoot!
	[self->gridSegmentedControl setSelectedSegment:gridMode];
	
	[newItem setView:gridSegmentedControl];
	[newItem setMinSize:[[gridSegmentedControl cell] cellSize]];
	[newItem setLabel:NSLocalizedString(@"GridSpacing",nil)];
	[newItem setPaletteLabel:NSLocalizedString(@"GridSpacing",nil)];
	
	return [newItem autorelease];
}//end makeGridSpacingItem

//========== makeRotationPlusXItem =============================================
//
// Purpose:		Button that rotates counterclockwise around the X axis
//
//==============================================================================
- (NSToolbarItem *) makeRotationPlusXItem {
	NSToolbarItem *newItem = [[NSToolbarItem alloc]
									initWithItemIdentifier:TOOLBAR_ROTATE_POSITIVE_X];

	[newItem setLabel:NSLocalizedString(TOOLBAR_ROTATE_POSITIVE_X, nil)];
	[newItem setPaletteLabel:NSLocalizedString(TOOLBAR_ROTATE_POSITIVE_X, nil)];
	[newItem setImage:[NSImage imageNamed:TOOLBAR_ROTATE_POSITIVE_X]];

	[newItem setTarget:self];
	[newItem setAction:@selector(rotatePositiveXClicked:)];
	
	return [newItem autorelease];
}

//========== makeRotationMinusXItem ============================================
//
// Purpose:		Button that rotates clockwise around the X axis
//
//==============================================================================
- (NSToolbarItem *) makeRotationMinusXItem {
	NSToolbarItem *newItem = [[NSToolbarItem alloc]
									initWithItemIdentifier:TOOLBAR_ROTATE_NEGATIVE_X];
	
	[newItem setLabel:NSLocalizedString(TOOLBAR_ROTATE_NEGATIVE_X, nil)];
	[newItem setPaletteLabel:NSLocalizedString(TOOLBAR_ROTATE_NEGATIVE_X, nil)];
	[newItem setImage:[NSImage imageNamed:TOOLBAR_ROTATE_NEGATIVE_X]];
	
	[newItem setTarget:self];
	[newItem setAction:@selector(rotateNegativeXClicked:)];
	
	return [newItem autorelease];
}

//========== makeRotationPlusYItem =============================================
//
// Purpose:		Button that rotates counterclockwise around the Y axis
//
//==============================================================================
- (NSToolbarItem *) makeRotationPlusYItem {
	NSToolbarItem *newItem = [[NSToolbarItem alloc]
									initWithItemIdentifier:TOOLBAR_ROTATE_POSITIVE_Y];
	
	[newItem setLabel:NSLocalizedString(TOOLBAR_ROTATE_POSITIVE_Y, nil)];
	[newItem setPaletteLabel:NSLocalizedString(TOOLBAR_ROTATE_POSITIVE_Y, nil)];
	[newItem setImage:[NSImage imageNamed:TOOLBAR_ROTATE_POSITIVE_Y]];
	
	[newItem setTarget:self];
	[newItem setAction:@selector(rotatePositiveYClicked:)];
	
	return [newItem autorelease];
}

//========== makeRotationMinusYItem ============================================
//
// Purpose:		Button that rotates clockwise around the Y axis
//
//==============================================================================
- (NSToolbarItem *) makeRotationMinusYItem {
	NSToolbarItem *newItem = [[NSToolbarItem alloc]
									initWithItemIdentifier:TOOLBAR_ROTATE_NEGATIVE_Y];
	
	[newItem setLabel:NSLocalizedString(TOOLBAR_ROTATE_NEGATIVE_Y, nil)];
	[newItem setPaletteLabel:NSLocalizedString(TOOLBAR_ROTATE_NEGATIVE_Y, nil)];
	[newItem setImage:[NSImage imageNamed:TOOLBAR_ROTATE_NEGATIVE_Y]];
	
	[newItem setTarget:self];
	[newItem setAction:@selector(rotateNegativeYClicked:)];
	
	return [newItem autorelease];
}

//========== makeRotationPlusZItem =============================================
//
// Purpose:		Button that rotates counterclockwise around the Z axis
//
//==============================================================================
- (NSToolbarItem *) makeRotationPlusZItem {
	NSToolbarItem *newItem = [[NSToolbarItem alloc]
									initWithItemIdentifier:TOOLBAR_ROTATE_POSITIVE_Z];
	
	[newItem setLabel:NSLocalizedString(TOOLBAR_ROTATE_POSITIVE_Z, nil)];
	[newItem setPaletteLabel:NSLocalizedString(TOOLBAR_ROTATE_POSITIVE_Z, nil)];
	[newItem setImage:[NSImage imageNamed:TOOLBAR_ROTATE_POSITIVE_Z]];
	
	[newItem setTarget:self];
	[newItem setAction:@selector(rotatePositiveZClicked:)];
	
	return [newItem autorelease];
}

//========== makeRotationMinusZItem ============================================
//
// Purpose:		Button that rotates clockwise around the Z axis
//
//==============================================================================
- (NSToolbarItem *) makeRotationMinusZItem {
	NSToolbarItem *newItem = [[NSToolbarItem alloc]
									initWithItemIdentifier:TOOLBAR_ROTATE_NEGATIVE_Z];
	
	[newItem setLabel:NSLocalizedString(TOOLBAR_ROTATE_NEGATIVE_Z, nil)];
	[newItem setPaletteLabel:NSLocalizedString(TOOLBAR_ROTATE_NEGATIVE_Z, nil)];
	[newItem setImage:[NSImage imageNamed:TOOLBAR_ROTATE_NEGATIVE_Z]];
	
	[newItem setTarget:self];
	[newItem setAction:@selector(rotateNegativeZClicked:)];
	
	return [newItem autorelease];
}

//========== makeSnapToGridItem ================================================
//
// Purpose:		Button that aligns a part to the grid.
//
//==============================================================================
- (NSToolbarItem *) makeSnapToGridItem {
	NSToolbarItem *newItem = [[NSToolbarItem alloc]
									initWithItemIdentifier:TOOLBAR_SNAP_TO_GRID];
	
	[newItem setLabel:NSLocalizedString(@"SnapToGrid", nil)];
	[newItem setPaletteLabel:NSLocalizedString(@"SnapToGrid", nil)];
	[newItem setImage:[NSImage imageNamed:@"Snap To Grid"]];
	
	[newItem setTarget:self->document];
	[newItem setAction:@selector(snapSelectionToGrid:)];
	
	return [newItem autorelease];
}

//========== makeZoomInItem ====================================================
//
// Purpose:		Button that enlarges the object being viewed
//
//==============================================================================
- (NSToolbarItem *) makeZoomInItem {
	NSToolbarItem *newItem = [[NSToolbarItem alloc]
									initWithItemIdentifier:TOOLBAR_ZOOM_IN];
	
	[newItem setLabel:NSLocalizedString(@"ZoomIn", nil)];
	[newItem setPaletteLabel:NSLocalizedString(@"ZoomIn", nil)];
	[newItem setImage:[NSImage imageNamed:@"ZoomIn"]];
	
	[newItem setTarget:self->document];
	[newItem setAction:@selector(zoomIn:)];
	
	return [newItem autorelease];
}


//========== makeZoomOutItem ===================================================
//
// Purpose:		Button that shrinks the object being viewed
//
//==============================================================================
- (NSToolbarItem *) makeZoomOutItem {
	NSToolbarItem *newItem = [[NSToolbarItem alloc]
									initWithItemIdentifier:TOOLBAR_ZOOM_OUT];
	
	[newItem setLabel:NSLocalizedString(@"ZoomOut", nil)];
	[newItem setPaletteLabel:NSLocalizedString(@"ZoomOut", nil)];
	[newItem setImage:[NSImage imageNamed:@"ZoomOut"]];
	
	[newItem setTarget:self->document];
	[newItem setAction:@selector(zoomOut:)];
	
	return [newItem autorelease];
}


//========== makeZoomTextFieldItem =============================================
//
// Purpose:		Hooks up the text entry field which is used to specify an 
//				exact zoom percentage.
//
//==============================================================================
- (NSToolbarItem *) makeZoomTextFieldItem {
	NSToolbarItem *newItem = [[NSToolbarItem alloc]
									initWithItemIdentifier:TOOLBAR_ZOOM_SPECIFY];
	
	[newItem setLabel:NSLocalizedString(@"ZoomScale", nil)];
	[newItem setPaletteLabel:NSLocalizedString(@"ZoomScale", nil)];
	[newItem setView:zoomToolTextField];
	[newItem setMinSize:[zoomToolTextField frame].size];
	
	return [newItem autorelease];
}


#pragma mark -

//========== makeGridSegmentControl ============================================
//
// Purpose:		Initializes the segmented cell to track the grid mode. Under 
//				System 10.4, this is all available in Interface Builder.
//
//==============================================================================
- (NSSegmentedControl *) makeGridSegmentControl {
	NSRect				segmentFrame	= NSMakeRect(0,0, 32, 32);
	NSSegmentedControl	*gridSegments	= [[NSSegmentedControl alloc] initWithFrame:segmentFrame];
	NSSegmentedCell		*segmentsCell	= [gridSegments cell];
	
	//We are going to be very rigorous here and use tags for identifying the 
	// grid mode. This is total overkill; we could use indices. But I just got 
	// done fixing a "simplification" like that at work today, so I'm wary.
	[gridSegments setSegmentCount:3];
	[segmentsCell setTag:gridModeFine							forSegment:0];
	[segmentsCell setImage:[NSImage imageNamed:@"GridFine"]		forSegment:0];
	[segmentsCell setWidth:24.0									forSegment:0];
	
	[segmentsCell setTag:gridModeMedium							forSegment:1];
	[segmentsCell setImage:[NSImage imageNamed:@"GridMedium"]	forSegment:1];
	[segmentsCell setWidth:24.0									forSegment:1];
	
	[segmentsCell setTag:gridModeCoarse							forSegment:2];
	[segmentsCell setImage:[NSImage imageNamed:@"GridCoarse"]	forSegment:2];
	[segmentsCell setWidth:24.0									forSegment:2];
	
	//And then the whole tag thing came crashing down when I discovered there 
	// is no segmentForTag: method. Oops. Addendum: They managed to squeeze it 
	// into Tiger. But I'm not developing for Tiger. Shoot!
	
	[gridSegments setTarget:self];
	[gridSegments setAction:@selector(gridSpacingSegmentedControlClicked:)];
	
	return [gridSegments autorelease];
}//end makeGridSegmentControl


#pragma mark -
#pragma mark ACTIONS
#pragma mark -


//========== gridSpacingSegmentedControlClicked: ===============================
//
// Purpose:		We clicked on the toolbar's segmented control for changing the 
//				grid spacing.
//
//==============================================================================
- (void) gridSpacingSegmentedControlClicked:(id)sender {
	int					selectedSegment	= [sender selectedSegment];
	gridSpacingModeT	newGridMode		= [[sender cell] tagForSegment:selectedSegment];
	
	[self->document setGridSpacingMode:newGridMode];
}


//========== nudgeXClicked: ====================================================
//
// Purpose:		The toolbar button indicating movement along the axis has been 
//				clicked. The direction to move can be determined by the tag of 
//				the button clicked: -1 for negative movement; +1 for positive 
//				movement.
//
//==============================================================================
- (IBAction) nudgeXClicked:(id)sender {
	Vector3	nudgeVector = {1,0,0};
	nudgeVector.x *= [[sender selectedCell] tag];
	
	[document nudgeSelectionBy:nudgeVector];
}


//========== nudgeYClicked: ====================================================
//
// Purpose:		The toolbar button indicating movement along the axis has been 
//				clicked. The direction to move can be determined by the tag of 
//				the button clicked: -1 for negative movement; +1 for positive 
//				movement.
//
//==============================================================================
- (IBAction) nudgeYClicked:(id)sender {
	Vector3	nudgeVector = {0,1,0};
	nudgeVector.y *= [[sender selectedCell] tag];
	
	[document nudgeSelectionBy:nudgeVector];
}

//========== nudgeZClicked: ====================================================
//
// Purpose:		The toolbar button indicating movement along the axis has been 
//				clicked. The direction to move can be determined by the tag of 
//				the button clicked: -1 for negative movement; +1 for positive 
//				movement.
//
//==============================================================================
- (IBAction) nudgeZClicked:(id)sender {
	Vector3	nudgeVector = {0,0,1};
	nudgeVector.z *= [[sender selectedCell] tag];
	
	[document nudgeSelectionBy:nudgeVector];
}

//========== rotatePositiveXClicked ============================================
//
// Purpose:		Rotate counterclockwise around the X axis.
//
//==============================================================================
- (void) rotatePositiveXClicked:(id)sender {
	Vector3 rotation = {1,0,0};
	[self->document rotateSelectionAround:rotation];
}

//========== rotateNegativeXClicked ============================================
//
// Purpose:		Rotate clockwise around the X axis.
//
//==============================================================================
- (void) rotateNegativeXClicked:(id)sender {
	Vector3 rotation = {-1,0,0};
	[self->document rotateSelectionAround:rotation];
}

//========== rotatePositiveYClicked ============================================
//
// Purpose:		Rotate counterclockwise around the Y axis.
//
//==============================================================================
- (void) rotatePositiveYClicked:(id)sender {
	Vector3 rotation = {0,1,0};
	[self->document rotateSelectionAround:rotation];
}

//========== rotateNegativeYClicked ============================================
//
// Purpose:		Rotate clockwise around the Y axis.
//
//==============================================================================
- (void) rotateNegativeYClicked:(id)sender {
	Vector3 rotation = {0,-1,0};
	[self->document rotateSelectionAround:rotation];
}

//========== rotatePositiveZClicked ============================================
//
// Purpose:		Rotate counterclockwise around the Z axis.
//
//==============================================================================
- (void) rotatePositiveZClicked:(id)sender {
	Vector3 rotation = {0,0,1};
	[self->document rotateSelectionAround:rotation];
}

//========== rotateNegativeZClicked ============================================
//
// Purpose:		Rotate clockwise around the Z axis.
//
//==============================================================================
- (void) rotateNegativeZClicked:(id)sender {
	Vector3 rotation = {0,0,-1};
	[self->document rotateSelectionAround:rotation];
}

//========== zoomScaleChanged: =================================================
//
// Purpose:		The user has typed a new percentage into the scaling text field.
//				The document needs to update something with that.
//
//==============================================================================
- (IBAction) zoomScaleChanged:(id)sender {
	float newZoom = [sender floatValue];
	[self->document setZoomPercentage:newZoom];
}

#pragma mark -
#pragma mark VALIDATION
#pragma mark -


//========== validateToolbarItem: ==============================================
//
// Purpose:		Toolbar validation: eye candy that probably slows everything to 
//				a crawl.
//
//==============================================================================
- (BOOL)validateToolbarItem:(NSToolbarItem *)item
{
	LDrawPart		*selectedPart	= [self->document selectedPart];
	NSArray			*selectedItems	= [self->document selectedObjects];
	NSString		*identifier		= [item itemIdentifier];
	BOOL			 enabled		= NO;
	
	//Must have something selected.
	if(			[identifier isEqualToString:TOOLBAR_NUDGE_X_IDENTIFIER]
			||	[identifier isEqualToString:TOOLBAR_NUDGE_Y_IDENTIFIER]
			||	[identifier isEqualToString:TOOLBAR_NUDGE_Z_IDENTIFIER]  )
	{
		if([selectedItems count] > 0)
			enabled = YES;
	}
	
	//Must have a part selected.
	else if(	[identifier isEqualToString:TOOLBAR_ROTATE_POSITIVE_X]
			||	[identifier isEqualToString:TOOLBAR_ROTATE_NEGATIVE_X]
			||	[identifier isEqualToString:TOOLBAR_ROTATE_POSITIVE_Y]
			||	[identifier isEqualToString:TOOLBAR_ROTATE_NEGATIVE_Y]
			||	[identifier isEqualToString:TOOLBAR_ROTATE_POSITIVE_Z]
			||	[identifier isEqualToString:TOOLBAR_ROTATE_NEGATIVE_Z]  )
	{
		if(selectedPart != nil)
			enabled = YES;
	}
	
	//We don't have special conditions for it; give it a pass.
	else
		enabled = YES;
	
}


#pragma mark -
#pragma mark DESTRUCTOR
#pragma mark -

//========== dealloc ===========================================================
//
// Purpose:		My heart will go on...
//
// Note:		We DO NOT RELEASE TOP-LEVEL NIB OBJECTS HERE! NSWindowController 
//				(which comes with our NSDocument) does that automagically.
//
//==============================================================================
- (void) dealloc {

	[nudgeXToolView			release];
	[nudgeYToolView			release];
	[nudgeZToolView			release];
	[zoomToolTextField		release];

	[gridSegmentedControl	release];
	
	[super dealloc];
}

@end
