//==============================================================================
//
// File:		LDrawDocument.m
//
// Purpose:		Document controller for an LDraw document.
//
//				Opens the document and manages its editor and viewer.
//
//  Created by Allen Smith on 2/14/05.
//  Copyright (c) 2005. All rights reserved.
//==============================================================================
#import "LDrawDocument.h"

#import "LDrawFile.h"
#import "LDrawModel.h"
#import "LDrawMPDModel.h"
#import "LDrawStep.h"

#import "LDrawComment.h"
#import "LDrawConditionalLine.h"
#import "LDrawDirective.h"
#import "LDrawDrawableElement.h"
#import "LDrawLine.h"
#import "LDrawPart.h"
#import "LDrawQuadrilateral.h"
#import "LDrawTriangle.h"

#import "DocumentToolbarController.h"
#import "IconTextCell.h"
#import "Inspector.h"
#import "LDrawApplication.h"
#import "LDrawColorPanel.h"
#import "LDrawFileOutlineView.h"
#import "LDrawGLView.h"
#import "MacLDraw.h"
#import "PartBrowserDataSource.h"
#import "PartChooserPanel.h"
#import "UserDefaultsCategory.h"

@implementation LDrawDocument

//========== init ==============================================================
//
// Purpose:		Sets up a new untitled document.
//
//==============================================================================
- (id)init
{
    self = [super init];
    if (self) {
		
		[self setDocumentContents:[LDrawFile newFile]];
        insertionMode = insertAtEnd;
		[self setGridSpacingMode:gridModeMedium];
		
		// Add your subclass-specific initialization here.
        // If an error occurs here, send a [self release] message and return nil.
    
    }
    return self;
}

#pragma mark -
#pragma mark DOCUMENT
#pragma mark -

//========== windowNibName =====================================================
//
// Purpose:		Returns the name of the Nib file used to display this document.
//
//==============================================================================
- (NSString *)windowNibName
{
    // If you need to use a subclass of NSWindowController or if your document 
	// supports multiple NSWindowControllers, you should remove this method and 
	// override -makeWindowControllers instead.
    return @"LDrawDocument";
}//end windowNibName


//========== windowControllerDidLoadNib: =======================================
//
// Purpose:		awakeFromNib for document-based programs.
//
//==============================================================================
- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
	NSNotificationCenter	*notificationCenter	= [NSNotificationCenter defaultCenter];
	NSUserDefaults			*userDefaults		= [NSUserDefaults standardUserDefaults];
	NSWindow				*window				= [aController window];
	int						 drawerState		= 0;

    [super windowControllerDidLoadNib:aController];
	
	//Create the toolbar.
	NSToolbar *toolbar = [[[NSToolbar alloc] initWithIdentifier:@"LDrawDocumentToolbar"] autorelease];
	[toolbar setAutosavesConfiguration:YES];
	[toolbar setAllowsUserCustomization:YES];
	[toolbar setDelegate:self->toolbarController];
	[window setToolbar:toolbar];
	
	[fileContentsOutline setDoubleAction:@selector(showInspector:)];
	[fileContentsOutline setVerticalMotionCanBeginDrag:YES];
	[fileContentsOutline registerForDraggedTypes:[NSArray arrayWithObject:LDrawDirectivePboardType]];
	[fileContentsOutline reloadData];
	
	//Display our model.
	[fileGraphicView setLDrawDirective:[self documentContents]];
	
	//Set up the window state based on what is found in preferences.
	drawerState = [userDefaults integerForKey:PART_BROWSER_DRAWER_STATE];
	if(drawerState == NSDrawerOpenState)
		[partBrowserDrawer open];
	
	drawerState = [userDefaults integerForKey:FILE_CONTENTS_DRAWER_STATE];
	if(drawerState == NSDrawerOpenState)
		[fileContentsDrawer open];
		
	//Set our size to whatever it was last time. (We don't do the whole frame 
	// because we want the origin to be nicely staggered as documents open; that 
	// normally happens automatically.)
	NSString *savedSize = [userDefaults objectForKey:DOCUMENT_WINDOW_SIZE];
	if(savedSize != nil){
		NSRect frame = [window frame];
		frame.size = NSSizeFromString(savedSize);
		[window setFrame:frame display:YES];
	}
	
	
	//Notifications we want.
	[notificationCenter addObserver:self
						   selector:@selector(syntaxColorChanged:)
							   name:LDrawSyntaxColorsDidChangeNotification
							 object:nil ];
	
	[notificationCenter addObserver:self
						   selector:@selector(partChanged:)
							   name:LDrawDirectiveDidChangeNotification
							 object:nil ];
	
	[notificationCenter addObserver:self
						   selector:@selector(activeModelChanged:)
							   name:LDrawFileActiveModelDidChangeNotification
							 object:[self documentContents] ];
	
}//end windowControllerDidLoadNib:


//========== dataRepresentationOfType: =========================================
//
// Purpose:		Converts this document into a data object that can be written 
//				to disk. This is where a document gets saved.
//
// You can also choose to override -fileWrapperRepresentationOfType: or 
// -writeToFile:ofType: instead.
//==============================================================================
- (NSData *)dataRepresentationOfType:(NSString *)aType
{
    NSString *modelOutput = [[self documentContents] write];
	
	return [modelOutput dataUsingEncoding:NSUTF8StringEncoding];
}


//========== loadDataRepresentation:ofType: ====================================
//
// Purpose:		Read a logical document structure from data. This is the "open" 
//				method.
//
// You can also choose to override -loadFileWrapperRepresentation:ofType: 
// or -readFromFile:ofType: instead.
//==============================================================================
- (BOOL)loadDataRepresentation:(NSData *)data ofType:(NSString *)aType
{
	//LDraw files are plain text.
	NSString *fileContents = [[NSString alloc] initWithData:data
												   encoding:NSUTF8StringEncoding ];
	
	LDrawFile *newFile = [LDrawFile parseFromFileContents:fileContents];
	
	[self setDocumentContents:newFile];
	[fileContentsOutline reloadData];
	
    return YES;
}//end loadDataRepresentation:ofType:


#pragma mark -
#pragma mark ACCESSORS
#pragma mark -

//========== documentContents ==================================================
//
// Purpose:		Returns the logical representation of the LDraw file this 
//				document represents.
//
//==============================================================================
- (LDrawFile *) documentContents{
	return documentContents;
}


//========== foremostWindow ====================================================
//
// Purpose:		Returns the main editing window.
//
//==============================================================================
- (NSWindow *)foremostWindow {
	return [[[self windowControllers] objectAtIndex:0] window];
}


//========== gridSpacingMode ===================================================
//
// Purpose:		Returns the current granularity of the positioning grid being 
//				used in this document.
//
//==============================================================================
- (gridSpacingModeT) gridSpacingMode {
	return gridMode;
}


//========== setDocumentContents: ==============================================
//
// Purpose:		Sets the logical representation of the LDraw file this 
//				document represents to newContents. This method should be called 
//				when the document is first created.
//
//==============================================================================
- (void) setDocumentContents:(LDrawFile *)newContents{
	[newContents retain];
	[documentContents release];
	
	documentContents = newContents;
}


//========== setGridSpacingMode: ===============================================
//
// Purpose:		Returns the current granularity of the positioning grid being 
//				used in this document.
//
//==============================================================================
- (void) setGridSpacingMode:(gridSpacingModeT)newMode {
	self->gridMode = newMode;
	
	[self->toolbarController setGridSpacingMode:newMode];
}


//========== setLastSelectedPart: ==============================================
//
// Purpose:		The document keeps track of the part most recently selected in 
//				the file contents outline. This method is called each time a new 
//				part is selected. The transformation matrix of the previously 
//				selected part is then used when new parts are added.
//
//==============================================================================
- (void) setLastSelectedPart:(LDrawPart *)newPart
{
	[newPart retain];
	[lastSelectedPart release];
	
	lastSelectedPart = newPart;
}

#pragma mark -
#pragma mark ACTIONS
#pragma mark -


//========== changeLDrawColor: =================================================
//
// Purpose:		Responds to color-change messages sent down the responder chain 
//				by the LDrawColorPanel. Upon the receipt of this message, the 
//				window should change the color of all the selected objects to 
//				the new color specified in the panel.
//
//==============================================================================
- (void) changeLDrawColor:(id)sender{

	NSArray		*selectedObjects = [self selectedObjects];
	id			 currentObject;
	LDrawColorT	 newColor = [sender LDrawColor];
	int			 counter;
	
	for(counter = 0; counter < [selectedObjects count]; counter++){
	
		currentObject = [selectedObjects objectAtIndex:counter];
	
		if([currentObject conformsToProtocol:@protocol(LDrawColorable)]){
			[self setObject:currentObject toColor:newColor];
		}
	}
	if([selectedObjects count] > 0)
		[[self documentContents] setNeedsDisplay];
}


//========== nudgeSelectionBy: =================================================
//
// Purpose:		Nudges all selected (and nudgeable) directives in the direction 
//				indicated by nudgeVector, which should be normalized. The exact 
//				amount nudged is dependent on the directives themselves, but we 
//				give them our best estimate based on the grid granularity.
//
//==============================================================================
- (void) nudgeSelectionBy:(Vector3) nudgeVector {
	NSUserDefaults	*userDefaults		= [NSUserDefaults standardUserDefaults];
	NSArray			*selectedObjects	= [self selectedObjects];
	LDrawDirective	*currentObject		= nil;
	float			 nudgeMagnitude		= 0;
	int				 counter			= 0;
	
	//Determine magnitude of nudge.
	switch([self gridSpacingMode]) {
		case gridModeFine:
			nudgeMagnitude = [userDefaults floatForKey:GRID_SPACING_FINE];
			break;
		case gridModeMedium:
			nudgeMagnitude = [userDefaults floatForKey:GRID_SPACING_MEDIUM];
			break;
		case gridModeCoarse:
			nudgeMagnitude = [userDefaults floatForKey:GRID_SPACING_COARSE];
			break;
	}
	
	V3Normalize(&nudgeVector); //normalize just in case someone didn't get the message!
	nudgeVector.x *= nudgeMagnitude;
	nudgeVector.y *= nudgeMagnitude;
	nudgeVector.z *= nudgeMagnitude;
	
	//nudge everything that can be nudged.
	for(counter = 0; counter < [selectedObjects count]; counter++){
		currentObject = [selectedObjects objectAtIndex:counter];
		
		if([currentObject isKindOfClass:[LDrawDrawableElement class]])
			[self nudgeDirective: (LDrawDrawableElement*)currentObject
					 inDirection: nudgeVector];
	}
}

//========== rotateSelectionAround: ============================================
//
// Purpose:		Rotates all selected parts in a clockwise direction around the 
//				specified axis. The rotationAxis should be either 
//				+/- i, +/- j or +/- k.
//
//==============================================================================
- (void) rotateSelectionAround:(Vector3)rotationAxis {

	NSArray			*selectedObjects	= [self selectedObjects];
	LDrawDirective	*currentObject		= nil;
	float			 degreesToRotate	= 0;
	int				 counter			= 0;
	
	//Determine magnitude of nudge.
	switch([self gridSpacingMode]) {
		case gridModeFine:
			degreesToRotate = GRID_ROTATION_FINE;	//15 degrees
			break;
		case gridModeMedium:
			degreesToRotate = GRID_ROTATION_MEDIUM;	//45 degrees
			break;
		case gridModeCoarse:
			degreesToRotate = GRID_ROTATION_COARSE;	//90 degrees
			break;
	}
	
	V3Normalize(&rotationAxis); //normalize just in case someone didn't get the message!
	
	//nudge everything that can be rotated. That would be parts and only parts.
	for(counter = 0; counter < [selectedObjects count]; counter++){
		currentObject = [selectedObjects objectAtIndex:counter];
		
		if([currentObject isKindOfClass:[LDrawPart class]])
			[self rotatePart:(LDrawPart*)currentObject
					  onAxis:rotationAxis
				   byDegrees:degreesToRotate];
	}
}


//========== setZoomPercentage: ================================================
//
// Purpose:		Zooms the selected LDraw view to the specified percentage.
//
//==============================================================================
- (void) setZoomPercentage:(float)newPercentage {
	[mostRecentLDrawView setZoomPercentage:newPercentage];
}


#pragma mark -
#pragma mark File Menu

//========== exportSteps: ======================================================
//
// Purpose:		Presents a save dialog allowing the user to export his model 
//				as a series of files, one for each progressive step.
//
//==============================================================================
- (IBAction) exportSteps:(id)sender {
	
	NSSavePanel *exportPanel	= [NSSavePanel savePanel];
	NSString	*activeName		= [[[self documentContents] activeModel] modelName];
	NSString	*nameFormat		= NSLocalizedString(@"ExportedStepsFolderFormat", nil);
	
//	[exportPanel setRequiredFileType:@"ldr"];
//	[exportPanel setCanSelectHiddenExtension:YES];
	
	[exportPanel beginSheetForDirectory:nil
								   file:[NSString stringWithFormat:nameFormat, activeName]
						 modalForWindow:[self windowForSheet]
						  modalDelegate:self
						 didEndSelector:@selector(exportStepsPanelDidEnd:returnCode:contextInfo:)
							contextInfo:NULL ];
		

}//end exportSteps:


//========== exportStepsPanelDidEnd:returnCode:contextInfo: ====================
//
// Purpose:		The export steps dialog was closed. If OK was clicked, the 
//				filename specified is the name of the folder we should create 
//				to export the model.
//
//==============================================================================
- (void)exportStepsPanelDidEnd:(NSSavePanel *)savePanel
					returnCode:(int)returnCode
				   contextInfo:(void *)contextInfo
{
	NSFileManager	*fileManager	= [NSFileManager defaultManager];
	NSString		*folderName		= nil;
	NSString		*filenameFormat	= NSLocalizedString(@"ExportedStepsFileFormat", nil);
	NSString		*fileString		= nil;
	NSData			*fileOutputData	= nil;
	NSString		*outputName		= nil;
	NSString		*outputPath		= nil;
	LDrawFile		*fileCopy		= nil;
	int				 counter		= 0;
	
	if(returnCode == NSOKButton){
	
		fileCopy	= [[self documentContents] copy];
		folderName	= [savePanel filename];
		
		//If we got this far, we need to replace any prexisting file.
		if([fileManager fileExistsAtPath:folderName isDirectory:NULL])
			[fileManager removeFileAtPath:folderName handler:nil];
		
		[fileManager createDirectoryAtPath:folderName attributes:nil];
		
		fileCopy = [[self documentContents] copy];
		
		//Move the active model to the top of the file. That way L3P will know to 
		// render it!
		LDrawMPDModel *activeModel = [fileCopy activeModel];
		[activeModel retain];
		[fileCopy removeDirective:activeModel];
		[fileCopy insertDirective:activeModel atIndex:0];
		[fileCopy setActiveModel:activeModel];
		[activeModel release];
		
		//Write out each step!
		for(counter = [[activeModel steps] count]-1; counter >= 0; counter--){
			
			fileString		= [fileCopy write];
			fileOutputData	= [fileString dataUsingEncoding:NSUTF8StringEncoding];
			
			outputName = [NSString stringWithFormat: filenameFormat, 
													 [[fileCopy activeModel] modelName],
													 counter+1 ];
			outputPath = [folderName stringByAppendingPathComponent:outputName];
			[fileManager createFileAtPath:outputPath
								 contents:fileOutputData
							   attributes:nil ];
			
			//Remove the step we just wrote, so that the next cycle won't 
			// include it. We can safely do this because we are working with 
			// a copy of the file!
			[activeModel removeDirectiveAtIndex:counter];
		}
		
				
		[fileCopy release];
	}
}//end exportStepsPanelDidEnd:returnCode:contextInfo:

#pragma mark -
#pragma mark Edit Menu

//========== cut: ==============================================================
//
// Purpose:		Respond to an Edit->Cut action.
//
//==============================================================================
- (IBAction) cut:(id)sender {

	NSUndoManager	*undoManager		= [self undoManager];

	[self copy:sender];
	[self delete:sender]; //that was easy.

	[undoManager setActionName:NSLocalizedString(@"", nil)];
	
}//end cut:


//========== copy: =============================================================
//
// Purpose:		Respond to an Edit->Copy action.
//
//==============================================================================
- (IBAction) copy:(id)sender {

	NSPasteboard	*pasteboard			= [NSPasteboard generalPasteboard];
	NSArray			*selectedObjects	= [self selectedObjects];
	
	[self writeDirectives:selectedObjects
			 toPasteboard:pasteboard];
	
}//end copy:


//========== paste: ============================================================
//
// Purpose:		Respond to an Edit->Paste action, pasting the contents off the 
//				standard copy/paste pasteboard.
//
//==============================================================================
- (IBAction) paste:(id)sender {
	
	NSPasteboard	*pasteboard			= [NSPasteboard generalPasteboard];
	NSUndoManager	*undoManager		= [self undoManager];
	
	[self pasteFromPasteboard:pasteboard];
	
	[undoManager setActionName:NSLocalizedString(@"", nil)];
}//end paste:


//========== delete: ===========================================================
//
// Purpose:		A delete request has arrived from somplace--it could be the 
//				menus, the window, the outline view, etc. Our job is to delete
//				the current selection now.
//
// Notes:		This method conveniently has the same name as one in NSText; 
//				that allows us to use the same menu item for both textual and 
//				part delete.
//
//==============================================================================
- (IBAction) delete:(id)sender {
	NSArray			*selectedObjects	= [self selectedObjects];
	LDrawDirective	*currentObject		= nil;
	int				 counter;
	
	//We'll just try to delete everything. Count backwards so that if a 
	// deletion fails, it's the thing at the top rather than the bottom that 
	// remains.
	for(counter = [selectedObjects count]-1; counter >= 0; counter--) {
		currentObject = [selectedObjects objectAtIndex:counter];
		if([self canDeleteDirective:currentObject displayErrors:YES] == YES)
		{	//above method will display an error if the directive can't be deleted.
			[self deleteDirective:currentObject];
		}
	}
	
	[fileContentsOutline deselectAll:sender];
	[[self documentContents] setNeedsDisplay];
}//end delete:


//========== duplicate: ========================================================
//
// Purpose:		Makes a copy of the selected object.
//
//==============================================================================
- (IBAction) duplicate:(id)sender{
	
	//To take advantage of all the exceptionally cool copy/paste code we already 
	// have, -duplicate: simply "copies" the selection onto a private pasteboard 
	// then "pastes" it right back in. This avoids destroying the general 
	// pasteboard, but allows us some fabulous code reuse.
	// (In case you haven't noticed, I'm proud of this!)
	NSPasteboard	*pasteboard			= [NSPasteboard pasteboardWithName:@"MacLDrawDuplicationPboard"];
	NSArray			*selectedObjects	= [self selectedObjects];
	NSUndoManager	*undoManager		= [self undoManager];
	
	[self writeDirectives:selectedObjects
			 toPasteboard:pasteboard];
	[self pasteFromPasteboard:pasteboard];

	[undoManager setActionName:NSLocalizedString(@"UndoDuplicate", nil)];
}


#pragma mark -
#pragma mark Tools Menu

//========== showInspector: ====================================================
//
// Purpose:		Opens the inspector window. It may have something in it; it may 
//				not. That's up to the document.
//
//				I presume this method will take precedence over the one in 
//				LDrawApplication when a document is opened. This is not 
//				necessarily a good thing, but oh well.
//
//==============================================================================
- (IBAction) showInspector:(id)sender{
	[[LDrawApplication sharedInspector] show:sender];
}


//========== togglePartBrowserDrawer: ==========================================
//
// Purpose:		Either open or close the part browser.
//
//==============================================================================
- (IBAction) togglePartBrowserDrawer:(id)sender{
	
	int drawerState = [partBrowserDrawer state];
	[partBrowserDrawer toggle:sender];
	
	//We have a problem. When the window is resized while the drawer is closed, 
	// the OpenGLView moves, but the OpenGL drawing region doesn't! To fix this 
	// problem, we need to adjust the drawer's size while it is open; that 
	// causes the OpenGL to synchronize itself properly.
	//
	// This doesn't feel like the right solution to this problem, but it works.
	// Also listed are some other things I tried that didn't work.
	
	
	if(drawerState == NSDrawerClosedState){
		//Works, but animation is very chunky. (better than adjusting the window, though)
		NSSize contentSize = [partBrowserDrawer contentSize];
		contentSize.height += 1;
		[partBrowserDrawer setContentSize:contentSize];
		contentSize.height -= 1;
		[partBrowserDrawer setContentSize:contentSize];
	}
	
	//Fails.
//	[partsBrowser->partPreview reshape];
	
	//Uh-uh.
//	NSView *contentView = [partBrowserDrawer contentView];
//	[contentView resizeWithOldSuperviewSize:[partBrowserDrawer contentSize]];
	
	//Nope.
//	[contentView resizeSubviewsWithOldSize:[partBrowserDrawer contentSize]];
	
	//Ferget it.
//	[contentView setNeedsDisplay:YES];
	
	//Works, but ruins nice animation.
//	if(drawerState == NSDrawerClosedState){
//		NSWindow *parentWindow = [partBrowserDrawer parentWindow];
//		NSRect parentFrame = [parentWindow frame];
//		parentFrame.size.width += 1;
//		[parentWindow setFrame:parentFrame display:NO];
//		parentFrame.size.width -= 1;
//		[parentWindow setFrame:parentFrame display:NO];
//	}
}


//========== toggleFileContentsDrawer: =========================================
//
// Purpose:		Either open or close the file contents outline.
//
//==============================================================================
- (IBAction) toggleFileContentsDrawer:(id)sender{
	[fileContentsDrawer toggle:sender];
}


//========== snapSelectionToGrid: ==============================================
//
// Purpose:		Aligns all selected parts to the current grid setting.
//
//==============================================================================
- (void) snapSelectionToGrid:(id)sender {
	
	NSUserDefaults	*userDefaults		= [NSUserDefaults standardUserDefaults];
	NSArray			*selectedObjects	= [self selectedObjects];
	id				 currentObject		= nil;
	float			 gridSpacing		= 0;
	float			 degreesToRotate	= 0;
	int				 counter			= 0;
	
	TransformationComponents snappedComponents;
	
	//Determine granularity of grid.
	switch([self gridSpacingMode]) {
		case gridModeFine:
			gridSpacing = [userDefaults floatForKey:GRID_SPACING_FINE];
			degreesToRotate = GRID_ROTATION_FINE;	//15 degrees
			break;
		case gridModeMedium:
			gridSpacing = [userDefaults floatForKey:GRID_SPACING_MEDIUM];
			degreesToRotate = GRID_ROTATION_MEDIUM;	//45 degrees
			break;
		case gridModeCoarse:
			gridSpacing = [userDefaults floatForKey:GRID_SPACING_COARSE];
			degreesToRotate = GRID_ROTATION_COARSE;	//90 degrees
			break;
	}
	
	//nudge everything that can be rotated. That would be parts and only parts.
	for(counter = 0; counter < [selectedObjects count]; counter++){
		currentObject = [selectedObjects objectAtIndex:counter];
		
		if([currentObject isKindOfClass:[LDrawPart class]]){
			snappedComponents = [currentObject 
										componentsSnappedToGrid:gridSpacing
												   minimumAngle:degreesToRotate];
			[self setTransformation:snappedComponents
							forPart:currentObject];
		}
		
	}//end update loop
	
	[[self documentContents] setNeedsDisplay];
}//end snapSelectionToGrid


//========== gridGranularityMenuChanged: =======================================
//
// Purpose:		We just used the menubar to change the granularity of the grid. 
//				This is rather irritating because we need to manage the other 
//				visual indicators of the selection:
//				1) the checkmark in the menu itself
//				2) the selection in the toolbar's grid widget.
//				The menu we will handle in -validateMenuItem:.
//				The toolbar is trickier.
//
//==============================================================================
- (IBAction) gridGranularityMenuChanged:(id)sender {
	int					menuTag		= [sender tag];
	gridSpacingModeT	newGridMode;
	
	
	switch(menuTag) {
		case gridFineMenuTag:
			newGridMode = gridModeFine;
			break;
		case gridMediumMenuTag:
			newGridMode = gridModeMedium;
			break;
		case gridCoarseMenuTag:
			newGridMode = gridModeCoarse;
			break;
	}
	
	[self setGridSpacingMode:newGridMode];
}

#pragma mark -
#pragma mark View Menu

//========== zoomActual: =======================================================
//
// Purpose:		Zoom to 100%.
//
//==============================================================================
- (IBAction) zoomActual:(id)sender {
	[mostRecentLDrawView setZoomPercentage:100];
	[self->toolbarController setZoom:100];
}


//========== zoomIn: ===========================================================
//
// Purpose:		Enlarge the scale of the current LDraw view.
//
//==============================================================================
- (IBAction) zoomIn:(id)sender {
	float currentZoom = [mostRecentLDrawView zoomPercentage];
	float newZoom = currentZoom * 2;
	[mostRecentLDrawView setZoomPercentage:newZoom];
	[self->toolbarController setZoom:newZoom];
}


//========== zoomOut: ==========================================================
//
// Purpose:		Shrink the scale of the current LDraw view.
//
//==============================================================================
- (IBAction) zoomOut:(id)sender {
	float currentZoom = [mostRecentLDrawView zoomPercentage];
	float newZoom = currentZoom / 2;
	[mostRecentLDrawView setZoomPercentage:newZoom];
	[self->toolbarController setZoom:newZoom];
}


//========== toggleStepDisplay: ================================================
//
// Purpose:		Turns step display (like Lego instructions) on or off for the 
//				active model.
//
//==============================================================================
- (IBAction) toggleStepDisplay:(id)sender {
	LDrawMPDModel	*activeModel	= [[self documentContents] activeModel];
	BOOL			 stepDisplay	= [activeModel stepDisplay];
	
	if(stepDisplay == NO) //was off; so turn it on.
		[activeModel setMaximumStepDisplayed:0];
	else //on; turn it off now
		[activeModel setStepDisplay:NO];
	
	[[self documentContents] setNeedsDisplay];
}


//========== advanceOneStep: ===================================================
//
// Purpose:		Moves the step display forward one step.
//
//==============================================================================
- (IBAction) advanceOneStep:(id)sender {
	LDrawMPDModel	*activeModel	= [[self documentContents] activeModel];
	int				currentStep		= [activeModel maximumStepDisplayed];
	int				numberSteps		= [[activeModel steps] count];
	
	[activeModel setMaximumStepDisplayed: (currentStep+1) % numberSteps ];
	[[self documentContents] setNeedsDisplay];
}


//========== backOneStep: ======================================================
//
// Purpose:		Displays the previous step.
//
//==============================================================================
- (IBAction) backOneStep:(id)sender {
	LDrawMPDModel	*activeModel	= [[self documentContents] activeModel];
	int				currentStep		= [activeModel maximumStepDisplayed];
	int				numberSteps		= [[activeModel steps] count];
	
	if(currentStep == 0)
		currentStep = numberSteps;
	
	[activeModel setMaximumStepDisplayed: (currentStep-1) % numberSteps ];
	[[self documentContents] setNeedsDisplay];
}


#pragma mark -
#pragma mark Models Menu

//========== addModelClicked: ==================================================
//
// Purpose:		Create a new model and add it to the current file.
//
//==============================================================================
- (IBAction) addModelClicked:(id)sender {
	
	LDrawMPDModel	*newModel		= [LDrawMPDModel newModel];

	[self addModel:newModel];
	[[self documentContents] setActiveModel:newModel];
	[[self documentContents] setNeedsDisplay];
	
}//end modelSelected


//========== addStepClicked: ===================================================
//
// Purpose:		Adds a new step wherever it belongs.
//
//==============================================================================
- (IBAction) addStepClicked:(id)sender {

	LDrawStep		*newStep		= [LDrawStep emptyStep];

	[self addStep:newStep];
}


//========== addPartClicked: ===================================================
//
// Purpose:		Adds a new step to the currently-displayed model. If a part of 
//				the model is already selected, the step will be added after 
//				selection. Otherwise, the step appears at the end of the list.
//
//==============================================================================
- (IBAction) addPartClicked:(id)sender {
	
	LDrawPart		*newPart		= [[[LDrawPart alloc] init] autorelease];
	NSUndoManager	*undoManager	= [self undoManager];
	NSString		*partName		= nil;
	LDrawColorT		 selectedColor	= [[LDrawColorPanel sharedColorPanel] LDrawColor];
	
	//Find out what part should be inserted.
	// If the parts browser drawer is open, we will read the selection out 
	// of it.
	if([partBrowserDrawer state] == NSDrawerOpenState) {
		partName = [partsBrowser selectedPart];
	}
	//But if the drawer is closed, we'll display a dialog prompting for the 
	// part.
	else {
		PartChooserPanel *partChooser = [PartChooserPanel partChooserPanel];
		if([partChooser runModal] == NSOKButton){
			partName = [partChooser selectedPart];
		}
	}

	//We got a part; let's add it!
	if(partName != nil){
		//Set up the part attributes
		[newPart setLDrawColor:selectedColor];
		[newPart setDisplayName:partName];
		if(lastSelectedPart != nil){
			//Collect the transformation from the previous part and apply it to the 
			// new one.
			TransformationComponents transformation = [lastSelectedPart transformationComponents];
			[newPart setTransformationComponents:transformation];

		}
		
		[self addStepComponent:newPart];
		
		[undoManager setActionName:NSLocalizedString(@"UndoAddPart", nil)];
		[[self documentContents] setNeedsDisplay];
	}
}//end addPartClicked:


//========== addLineClicked: ===================================================
//
// Purpose:		Adds a new line primitive to the currently-displayed model.
//
//==============================================================================
- (IBAction) addLineClicked:(id)sender {
	
	LDrawLine		*newLine		= [[[LDrawLine alloc] init] autorelease];
	NSUndoManager	*undoManager	= [self undoManager];
	LDrawColorT		 selectedColor	= [[LDrawColorPanel sharedColorPanel] LDrawColor];
	
	[newLine setLDrawColor:selectedColor];
	
	[self addStepComponent:newLine];
	
	[undoManager setActionName:NSLocalizedString(@"UndoAddLine", nil)];
	[[self documentContents] setNeedsDisplay];
}//end addLineClicked:


//========== addTriangleClicked: ===============================================
//
// Purpose:		Adds a new triangle primitive to the currently-displayed model.
//
//==============================================================================
- (IBAction) addTriangleClicked:(id)sender {
	
	LDrawTriangle	*newTriangle	= [[[LDrawTriangle alloc] init] autorelease];
	NSUndoManager	*undoManager	= [self undoManager];
	LDrawColorT		 selectedColor	= [[LDrawColorPanel sharedColorPanel] LDrawColor];
	
	[newTriangle setLDrawColor:selectedColor];
	
	[self addStepComponent:newTriangle];
	
	[undoManager setActionName:NSLocalizedString(@"UndoAddTriangle", nil)];
	[[self documentContents] setNeedsDisplay];
}//end addTriangleClicked:


//========== addQuadrilateralClicked: ==========================================
//
// Purpose:		Adds a new quadrilateral primitive to the currently-displayed 
//				model.
//
//==============================================================================
- (IBAction) addQuadrilateralClicked:(id)sender {
	
	LDrawQuadrilateral	*newQuadrilateral	= [[[LDrawQuadrilateral alloc] init] autorelease];
	NSUndoManager		*undoManager		= [self undoManager];
	LDrawColorT			 selectedColor		= [[LDrawColorPanel sharedColorPanel] LDrawColor];
	
	[newQuadrilateral setLDrawColor:selectedColor];
	
	[self addStepComponent:newQuadrilateral];
	
	[undoManager setActionName:NSLocalizedString(@"UndoAddQuadrilateral", nil)];
	[[self documentContents] setNeedsDisplay];
}//end addQuadrilateralClicked:


//========== addConditionalClicked: ============================================
//
// Purpose:		Adds a new conditional-line primitive to the currently-displayed 
//				model.
//
//==============================================================================
- (IBAction) addConditionalClicked:(id)sender {
	
	LDrawConditionalLine	*newConditional	= [[[LDrawConditionalLine alloc] init] autorelease];
	NSUndoManager			*undoManager	= [self undoManager];
	LDrawColorT				selectedColor	= [[LDrawColorPanel sharedColorPanel] LDrawColor];
	
	[newConditional setLDrawColor:selectedColor];
	
	[self addStepComponent:newConditional];
	
	[undoManager setActionName:NSLocalizedString(@"UndoAddConditionalLine", nil)];
	[[self documentContents] setNeedsDisplay];
}//end addConditionalClicked:


//========== addCommentClicked: ================================================
//
// Purpose:		Adds a new comment primitive to the currently-displayed model.
//
//==============================================================================
- (IBAction) addCommentClicked:(id)sender {
	
	LDrawComment	*newComment		= [[[LDrawComment alloc] init] autorelease];
	NSUndoManager	*undoManager	= [self undoManager];
	
	[self addStepComponent:newComment];
	
	[undoManager setActionName:NSLocalizedString(@"UndoAddComment", nil)];
}//end addCommentClicked:


//========== modelSelected: ====================================================
//
// Purpose:		A new model from the Models menu was chosen to be the active 
//				model.
//
//==============================================================================
- (void) modelSelected:(id)sender {
	LDrawMPDModel *newActiveModel = [sender representedObject];
	[[self documentContents] setActiveModel:newActiveModel];
	
	//A notification will be generated that updates the models menu.
	
}//end modelSelected



#pragma mark -
#pragma mark UNDOABLE ACTIVITIES
#pragma mark -

//========== addDirective:toParent: ============================================
//
// Purpose:		Undo-aware call to add a directive to the specified parent.
//
//==============================================================================
- (void) addDirective:(LDrawDirective *)newDirective
			 toParent:(LDrawContainer * )parent
{
	int index;
	if(self->insertionMode == insertAtEnd)
		index = [[parent subdirectives] count];
	else
		index = 0;
		
	[self addDirective:newDirective
			  toParent:parent
			   atIndex:index];
}

//========== addDirective:toParent:atIndex: ====================================
//
// Purpose:		Undo-aware call to add a directive to the specified parent.
//
//==============================================================================
- (void) addDirective:(LDrawDirective *)newDirective
			 toParent:(LDrawContainer * )parent
			  atIndex:(int)index
{
	NSUndoManager	*undoManager	= [self undoManager];
	NSString		*undoString		= nil;
	
	[[undoManager prepareWithInvocationTarget:self]
		deleteDirective:newDirective ];
	
	[parent insertDirective:newDirective atIndex:index];
	[self updateInspector];
}


//========== deleteDirective: ==================================================
//
// Purpose:		Removes the specified doomDirective from its enclosing 
//				container.
//
//==============================================================================
- (void) deleteDirective:(LDrawDirective *)doomedDirective
{
	NSUndoManager	*undoManager	= [self undoManager];
	NSString		*undoString		= nil;
	LDrawContainer	*parent			= [doomedDirective enclosingDirective];
	int				 index			= [[parent subdirectives] indexOfObject:doomedDirective];
	
	[[undoManager prepareWithInvocationTarget:self]
			addDirective:doomedDirective
				toParent:parent
				 atIndex:index ];
	
	[parent removeDirective:doomedDirective];
	[self updateInspector];
}

//========== nudgeDirective:inDirection: =======================================
//
// Purpose:		Undo-aware call to move the object in the direction indicated. 
//				The vector here should indicated the rough amount to move 
//				(that is, it should be adjusted to the grid mode already).
//
//==============================================================================
- (void) nudgeDirective:(LDrawDrawableElement *)object
			inDirection:(Vector3)nudgeVector
{
	NSUndoManager	*undoManager	= [self undoManager];
	Vector3			 opposite		= {0};
	
	opposite.x = -(nudgeVector.x);
	opposite.y = -(nudgeVector.y);
	opposite.z = -(nudgeVector.z);
	
	[[undoManager prepareWithInvocationTarget:self]
			nudgeDirective: object
			   inDirection: opposite ];
	[undoManager setActionName:NSLocalizedString(@"UndoMove", nil)];
	
	[object nudge:nudgeVector];
	
	[self updateInspector];
	[[NSNotificationCenter defaultCenter]
					postNotificationName:LDrawDirectiveDidChangeNotification
								  object:object];
}


//========== rotatePart:onAxis:byDegrees: ======================================
//
// Purpose:		Undo-aware call to rotate the object in the direction indicated. 
//
// Notes:		This gets a little tricky because there is more than one way 
//				to represent a single rotation when using three rotation angles. 
//				Since we don't really know which one was intended, we can't just 
//				blithely manipulate the rotation components.
//
//				Instead, we must generate a new transformation matrix that 
//				rotates by degreesToRotate in the desired direction. Then we 
//				multiply that matrix by the part's current transformation. This 
//				way, we can rest assured that we rotated the part exactly the 
//				direction the user intended, no matter what goofy representation
//				the components came up with.
//
//				Caveat: We have to zero out the translation components of the 
//				part's transformation before we append our new rotation. Thus 
//				the part will be rotated in place.
//
//==============================================================================
- (void) rotatePart:(LDrawPart *)part
			 onAxis:(Vector3)rotationAxis
		  byDegrees:(float)degreesToRotate
{

	NSUndoManager				*undoManager	= [self undoManager];
	
	[[undoManager prepareWithInvocationTarget:self]
			rotatePart: part
				onAxis: rotationAxis
			 byDegrees: -degreesToRotate ]; //undo: rotate backwards
	[undoManager setActionName:NSLocalizedString(@"UndoRotate", nil)];
	
	Tuple3		rotation	= {0};
	
	rotation.x = rotationAxis.x * degreesToRotate;
	rotation.y = rotationAxis.y * degreesToRotate;
	rotation.z = rotationAxis.z * degreesToRotate;
	
	[part rotateByDegrees:rotation];

	
	[self updateInspector];
	[[NSNotificationCenter defaultCenter]
					postNotificationName:LDrawDirectiveDidChangeNotification
								  object:part];
	


//	NSUndoManager				*undoManager	= [self undoManager];
//	
//	[[undoManager prepareWithInvocationTarget:self]
//			rotatePart: part
//				onAxis: rotationAxis
//			 byDegrees: -degreesToRotate ]; //undo: rotate backwards
//	[undoManager setActionName:NSLocalizedString(@"UndoRotate", nil)];
//	
//	
//	TransformationComponents	originalComponents	= [part transformationComponents];
//	TransformationComponents	currentComponents	= originalComponents;
//	TransformationComponents	rotateComponents	= {0};
//	Matrix4						initialRotation		= {0}; //we'll remove the translation.
//	Matrix4						addedRotation		= {0};
//	Matrix4						newMatrix			= {0};
//	TransformationComponents	newComponents		= {0};
//	
//	//Zero out the translation on the current matrix. This leaves us with 
//	// only transformations at the origin, so we can rotate as we please.
//	currentComponents.translate_X = 0;
//	currentComponents.translate_Y = 0;
//	currentComponents.translate_Z = 0;
//	initialRotation = createTransformationMatrix(&currentComponents);
//	
//	//Create a new matrix that causes the rotation we want.
//	rotateComponents.scale_X = 1; //
//	rotateComponents.scale_Y = 1; // (start with identity matrix)
//	rotateComponents.scale_Z = 1; //
//	rotateComponents.rotate_X = rotationAxis.x * radians(degreesToRotate);
//	rotateComponents.rotate_Y = rotationAxis.y * radians(degreesToRotate);
//	rotateComponents.rotate_Z = rotationAxis.z * radians(degreesToRotate);
//	addedRotation = createTransformationMatrix(&rotateComponents);
//	
//	//Concatenate this new rotation onto the old one. (Our part is now rotated!)
//	// Then restore the original translation. Our part thereby has been rotated 
//	// in place.
//	V3MatMul(&initialRotation, &addedRotation, &newMatrix);
//	newMatrix.element[3][0] = originalComponents.translate_X; //applied directly to 
//	newMatrix.element[3][1] = originalComponents.translate_Y; //the matrix because 
//	newMatrix.element[3][2] = originalComponents.translate_Z; //that's easier here.
//
//	
//	[part setTransformationMatrix:&newMatrix];
//	
//	[self updateInspector];
//	[[NSNotificationCenter defaultCenter]
//					postNotificationName:LDrawDirectiveDidChangeNotification
//								  object:part];
} //rotatePart:onAxis:byDegrees:


//========== setObject:toColor: ================================================
//
// Purpose:		Undo-aware call to change the color of an object.
//
//==============================================================================
- (void) setObject:(id <LDrawColorable> )object toColor:(LDrawColorT)newColor
{
	NSUndoManager *undoManager = [self undoManager];
	[[undoManager prepareWithInvocationTarget:self]
		setObject:object
		  toColor:[object LDrawColor] ];
	[undoManager setActionName:NSLocalizedString(@"UndoColor", nil)];
	
	[object setLDrawColor:newColor];
	[self updateInspector];
	[[NSNotificationCenter defaultCenter]
					postNotificationName:LDrawDirectiveDidChangeNotification
								  object:object];
}


//========== setTransformation:forPart: ========================================
//
// Purpose:		Undo-aware call to set the entire transformation for a part. 
//				This is an important step in snapping a part to the grid.
//
//==============================================================================
- (void) setTransformation:(TransformationComponents) newComponents
				   forPart:(LDrawPart *)part
{
	NSUndoManager *undoManager = [self undoManager];
	TransformationComponents currentComponents = [part transformationComponents];
	
	[part setTransformationComponents:newComponents];
	
	//Be ready to restore the old components.
	[[undoManager prepareWithInvocationTarget:self]
			setTransformation:currentComponents
					  forPart:part ];
	
	[undoManager setActionName:NSLocalizedString(@"UndoSnapToGrid", nil)];
	[self updateInspector];
}

#pragma mark -
#pragma mark OUTLINE VIEW
#pragma mark -

#pragma mark Data Source

//**** NSOutlineViewDataSource ****
//========== outlineView:numberOfChildrenOfItem: ===============================
//
// Purpose:		Returns the number of items which should be displayed under an 
//				expanded item.
//
//==============================================================================
- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	int numberOfChildren = 0;
	
	//root object; return the number of submodels
	if(item == nil)
		numberOfChildren = [[documentContents submodels] count];
	
	//a step or model (or something); return the nth directives command
	else if([item isKindOfClass:[LDrawContainer class]])
		numberOfChildren = [[item subdirectives] count];
		
	return numberOfChildren;
	
}//end outlineView:numberOfChildrenOfItem:


//**** NSOutlineViewDataSource ****
//========== outlineView:isItemExpandable: =====================================
//
// Purpose:		Returns the number of items which should be displayed under an 
//				expanded item.
//
//==============================================================================
- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	Class itemClass = [item class];
	
	//You can expand models and steps.
	if([item isKindOfClass:[LDrawContainer class]] )
		return YES;
	else
		return NO;
	
}//end outlineView:isItemExpandable:


//**** NSOutlineViewDataSource ****
//========== outlineView:child:ofItem: =========================================
//
// Purpose:		Returns the child of item at the position index.
//
//==============================================================================
- (id)outlineView:(NSOutlineView *)outlineView
			child:(int)index
		   ofItem:(id)item
{
	NSArray *children = nil;
	
	//children of the root object; the nth of models.
	if(item == nil)
		children = [documentContents submodels];
		
	//a container; return the nth subdirective.	
	else if([item isKindOfClass:[LDrawContainer class]])
		children = [item subdirectives];
	
	return [children objectAtIndex:index];
	
}//end outlineView:child:ofItem:


//**** NSOutlineViewDataSource ****
//========== outlineView:objectValueForTableColumn:byItem: =====================
//
// Purpose:		Returns the representation of item given for the given table 
//				column.
//
//==============================================================================
- (id)			outlineView:(NSOutlineView *)outlineView
  objectValueForTableColumn:(NSTableColumn *)tableColumn
					 byItem:(id)item
{
	//Start off with a simple error message. Hopefully we won't see it.
	id representation = @"<Something went wrong here.>";
	
	//an LDraw directive; thank goodness! It knows how to describe itself.
	// The description will form the basis of the attributed text for the cell.
	if([item isKindOfClass:[LDrawDirective class]]){
		representation = [item browsingDescription];
		
		//Apply formatting to our little string.
		representation = [self formatDirective:item
					  withStringRepresentation:representation];
	}
		
	return representation;

}//end outlineView:objectValueForTableColumn:byItem:


#pragma mark -
#pragma mark Drag and Drop

//**** NSOutlineViewDataSource ****
//========== outlineView:willDisplayCell:forTableColumn:item: ==================
//
// Purpose:		Initiates a drag. We drag directives by copying them at the 
//				outset. Upon the successful completion of the drag, we "paste" 
//				the copied directives wherever they landed, then delete the 
//				original objects.
//
//				We also drag a string representation of the objects for the 
//				benefit of other applications.
//
//==============================================================================
- (BOOL)outlineView:(NSOutlineView *)outlineView
		 writeItems:(NSArray *)items
	   toPasteboard:(NSPasteboard *)pboard
{
	int				 numberItems	= [items count];
	NSMutableArray	*rowIndexes		= [NSMutableArray arrayWithCapacity:numberItems];
	int				 itemIndex		= 0;
	int				 counter		= 0;
	
	//Write the objects as data.
	[self writeDirectives:items toPasteboard:pboard];
	
	//Now write the row indexes out. We'll use them to delete the original 
	// objects in the event of a successful drag.
	for(counter = 0; counter < numberItems; counter++){
		itemIndex = [outlineView rowForItem:[items objectAtIndex:counter]];
		[rowIndexes addObject:[NSNumber numberWithInt:itemIndex]];
	}
	[pboard addTypes:[NSArray arrayWithObject:LDrawDragSourceRowsPboardType]
			   owner:nil];
	[pboard setPropertyList:rowIndexes forType:LDrawDragSourceRowsPboardType];
	
	return YES;
}

//**** NSOutlineViewDataSource ****
//========== outlineView:validateDrop:proposedItem:proposedChildIndex: =========
//
// Purpose:		Returns the representation of item given for the given table 
//				column.
//
//==============================================================================
- (NSDragOperation) outlineView:(NSOutlineView *)outlineView
				   validateDrop:(id <NSDraggingInfo>)info
				   proposedItem:(id)newParent
			 proposedChildIndex:(int)index
{
	NSPasteboard		*pasteboard		= [info draggingPasteboard];
	NSOutlineView		*sourceView		= [info draggingSource];
	NSDragOperation		 dragOperation	= NSDragOperationNone;
	
	//Fix our logic for handling drags to the root of the outline.
	if(newParent == nil)
		newParent = [self documentContents];
	
	//We must make sure we have the proper pasteboard type available.
	if(		index != NSOutlineViewDropOnItemIndex //not a "drop-on" operation.
	   &&	[[pasteboard types] containsObject:LDrawDirectivePboardType]) {
		
		//This drag is acceptable. Now figure out the operation.
		if(sourceView == outlineView)
			dragOperation = NSDragOperationMove;
		else
			dragOperation = NSDragOperationCopy;
		
		//Read the first object off the pasteboard so we can figure 
		// out where this drop is allowed to happen.
		NSArray			*objects		= [pasteboard propertyListForType:LDrawDirectivePboardType];
		NSData			*data			= nil;
		id				 currentObject	= nil;
		
		//Unarchive.
		data			= [objects objectAtIndex:0];
		currentObject	= [NSKeyedUnarchiver unarchiveObjectWithData:data];
			
	if([currentObject isKindOfClass:[LDrawStep class]])
//		NSLog(@"step drag to %@ : %d", [newParent class], index);
		
		//Now pop the data into our file.
		if(		[currentObject	isKindOfClass:[LDrawModel class]] == YES
		   &&	[newParent		isKindOfClass:[LDrawFile class]] == NO)
		{
//			NSLog(@"killing model-not-in-file drag");
			dragOperation	= NSDragOperationNone;
		}
			
		else if(	[currentObject	isKindOfClass:[LDrawStep class]] == YES
				&&	[newParent		isKindOfClass:[LDrawModel class]] == NO)
		{
//			if([newParent isKindOfClass:[LDrawStep class]])
//				[outlineView setDropItem:[newParent enclosingDirective]
//							dropChildIndex:0];
//			NSLog(@"rejecting step drag to %@", [newParent class]);
			dragOperation	= NSDragOperationNone;
		}
		
		else if(	[currentObject	isKindOfClass:[LDrawContainer class]] == NO
				&&	[newParent		isKindOfClass:[LDrawStep class]] == NO)
		{
//			NSLog(@"killing thingy-not-in-step");
			dragOperation	= NSDragOperationNone;
		}
		
		
	}
	return dragOperation;

	return NSDragOperationMove;
}//end outlineView:validateDrop:proposedItem:proposedChildIndex:


//**** NSOutlineViewDataSource ****
//========== outlineView:acceptDrop:item:childIndex: ===========================
//
// Purpose:		Finishes the current drop, depositing as near as possible to 
//				the specified item.
//
// Notes:		Complexities lie within. Note them carefully.
//
//==============================================================================
- (BOOL)outlineView:(NSOutlineView *)outlineView
		 acceptDrop:(id <NSDraggingInfo>)info
			   item:(id)newParent
		 childIndex:(int)dropIndex
{
	//Identify the root object if needed.
	if(newParent == nil)
		newParent = [self documentContents];
	
	LDrawDirective		*selectionTarget	= nil;
	NSArray				*newSiblings		= [newParent subdirectives];
	NSPasteboard		*pasteboard			= [info draggingPasteboard];
	NSUndoManager		*undoManager		= [self undoManager];
	NSOutlineView		*sourceView			= [info draggingSource];
	int					 selectionIndex		= 0;
	NSMutableArray		*doomedObjects		= [NSMutableArray array];
	NSArray				*pastedObjects		= nil;
	int					 counter			= 0;
	
	//Due to an unfortunate lack of foresight in the design, the main pasting 
	// code determines the paste location by looking at the current selection.
	// So if we want to use the pasting code (and we do!), we must create a 
	// selection before pasting.
	//We select the item below which we are dropping this drag.
	if(dropIndex > 0){
		//get the sibling *above* the drop location.
		selectionTarget = [newSiblings objectAtIndex:dropIndex-1]; 
	}
	else{
		//a drop at the top of the container; get the container itself.
		selectionTarget = newParent;
	}
	
	//Select the item. Watch out--drops at the very top of the file will be 
	// asking to select the LDrawFile itself, which is impossible. So we 
	// deselect all; that conveys the concept implicitly.
	selectionIndex = [outlineView rowForItem:selectionTarget];
	if(selectionIndex < 0) //selectionTarget not displayed in outline. That means the root object--the File.
		[outlineView deselectAll:self];
	else
		[outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:selectionIndex]
				 byExtendingSelection:NO ];
	
	//The standard pasting code will now automatically insert the dragged 
	// objects *directly below* the selection--effectively doing the drag.
	
	
	if(sourceView == outlineView) {
		//We dragged within the same table. That means we expect the original 
		// objects dragged to "mave" to the new position. Well, we can't 
		// actually *move* them, since our drag is implemented as a copy-and-paste.
		// However, we can simply delete the original objects, which will 
		// look the same anyway.
		//
		// Note we're doing this *before* moving, so that the indexes are 
		// still correct.
		NSArray			*rowsToDelete	= nil;
		int				 doomedIndex	= 0;
		LDrawDirective	*objectToDelete	= nil;
		
		//Gather up the objects we'll be removing.
		rowsToDelete = [pasteboard propertyListForType:LDrawDragSourceRowsPboardType];
		for(counter = 0; counter < [rowsToDelete count]; counter++) {
			doomedIndex = [[rowsToDelete objectAtIndex:counter] intValue];
			objectToDelete = [outlineView itemAtRow:doomedIndex];
			[doomedObjects addObject:objectToDelete];
		}
	}
	
	
	//     Do The Move.
	//
	//Due to more lack of foresight, we need to include a special flag if the 
	// move is happening at position 0 in newParent. The trouble is: in a 
	// normal copy/paste or new-part operation, we want to insert the new 
	// element at the *bottom* of the list in the absence of a different 
	// selection. But in a drag, we want to add the  items in the explicit 
	// position indicated by the user. If that position happens to be at the 
	// top of the list, then we are in a pickle. So we set up the insertionMode
	// flag to change the behavior of the -addDirective:toParent: method just 
	// for this drag.
	self->insertionMode = insertAtBeginning;
	pastedObjects = [self pasteFromPasteboard:pasteboard];
	self->insertionMode = insertAtEnd; //revert back to normal behavior.
	
	
	if(sourceView == outlineView) {
		//Now that we've inserted the new objects, we need to delete the 
		// old ones.
		for(counter = 0; counter < [doomedObjects count]; counter++)
			[self deleteDirective:[doomedObjects objectAtIndex:counter]];
		
		[undoManager setActionName:NSLocalizedString(@"UndoReorder", nil)];
	}
	
	//And lastly, select the dragged objects.
	[(LDrawFileOutlineView*)outlineView selectObjects:pastedObjects];

	return YES;
}



#pragma mark -
#pragma mark Delegate

//**** NSOutlineView ****
//========== outlineView:willDisplayCell:forTableColumn:item: ==================
//
// Purpose:		Returns the representation of item given for the given table 
//				column.
//
//==============================================================================
- (void) outlineView:(NSOutlineView *)outlineView
	 willDisplayCell:(id)cell
	  forTableColumn:(NSTableColumn *)tableColumn
				item:(id)item
{
	NSString	*imageName = nil;
	NSImage		*theImage;
	
	if([item isKindOfClass:[LDrawDirective class]])
		imageName = [item iconName];
		
	if(imageName == nil || [imageName isEqualToString:@""])
		theImage = nil;
	else
		theImage = [NSImage imageNamed:imageName];
		
	[(IconTextCell *)cell setImage:theImage];
}

//**** NSOutlineView ****
//========== outlineViewSelectionDidChange: ====================================
//
// Purpose:		We have selected a different something in the file contents.
//				We need to show it as selected in the OpenGL viewing area.
//				This means we may have to change the active model or step in 
//				order to display the selection.
//
//==============================================================================
- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
	NSOutlineView	*outlineView		= [notification object];
	NSArray			*selectedObjects	= [self selectedObjects];
	id				 lastSelectedItem	= [outlineView itemAtRow:[outlineView selectedRow]];
	LDrawMPDModel	*selectedModel		= [self selectedModel];
	LDrawStep		*selectedStep		= [self selectedStep];
	int				 counter			= 0;
	
	//Deselect all the previously-selected directives
	// (clears the internal directive flag used for drawing)
	for(counter = 0; counter < [self->selectedDirectives count]; counter++)
		[[selectedDirectives objectAtIndex:counter] setSelected:NO];
	
	//Tell the newly-selected directives that they just got selected.
	[selectedDirectives release];
	selectedDirectives = [selectedObjects retain];
	for(counter = 0; counter < [self->selectedDirectives count]; counter++)
		[[selectedDirectives objectAtIndex:counter] setSelected:YES];
	
	//Update things which need to take into account the entire selection.
	[[LDrawApplication sharedInspector] inspectObjects:selectedObjects];
	[[LDrawColorPanel sharedColorPanel] updateSelectionWithObjects:selectedObjects];
	if(selectedModel != nil){
		//put the selection on screen
		[[self documentContents] setActiveModel:selectedModel];
		[selectedModel makeStepVisible:selectedStep];
	}
	[[self documentContents] setNeedsDisplay];
	
	//See if we just selected a new part; if so, we must remember it.
	if([lastSelectedItem isKindOfClass:[LDrawPart class]])
		[self setLastSelectedPart:lastSelectedItem];

}


#pragma mark -
#pragma mark LDRAW GL VIEW
#pragma mark -

//========== LDrawGLViewBecameFirstResponder: ==================================
//
// Purpose:		One of our model views just became active, so we need to update 
//				our display to represent that view's characteristics.
//
//==============================================================================
- (void) LDrawGLViewBecameFirstResponder:(LDrawGLView *)glView {
	
	float zoomPercentage = [glView zoomPercentage];
	
	[self->toolbarController setZoom:zoomPercentage];
	self->mostRecentLDrawView = glView;
}


//========== LDrawGLView:wantsToSelectDirective:byExtendingSelection: ==========
//
// Purpose:		The file we are displaying has changed its active model.
//				Pass nil to mean deselect.
//
//==============================================================================
- (void)	LDrawGLView:(LDrawGLView *)glView
 wantsToSelectDirective:(LDrawDirective *)directiveToSelect
   byExtendingSelection:(BOOL) shouldExtend
{
	NSArray			*ancestors			= [directiveToSelect ancestors];
	LDrawDirective	*currentAncestor	= nil;
	int				 indexToSelect		= 0;
	int				 counter			= 0;
	
	if(directiveToSelect == nil)
		[fileContentsOutline deselectAll:glView];
	else {
		//Expand the hierarchy all the way down to the directive we are about to 
		// select.
		for(counter = 0; counter < [ancestors count]; counter++)
			[fileContentsOutline expandItem:[ancestors objectAtIndex:counter]];
		
		//Now we can safely select the directive. It is guaranteed to be visible, 
		// since we expanded all its ancestors.
		indexToSelect = [fileContentsOutline rowForItem:directiveToSelect];
		[fileContentsOutline selectRowIndexes:[NSIndexSet indexSetWithIndex:indexToSelect]
						 byExtendingSelection:shouldExtend];
		[fileContentsOutline scrollRowToVisible:indexToSelect];
	}
	
}//end LDrawGLView:wantsToSelectDirective:byExtendingSelection:

#pragma mark -
#pragma mark NOTIFICATIONS
#pragma mark -

//========== activeModelChanged: ===============================================
//
// Purpose:		The file we are displaying has changed its active model.
//
//==============================================================================
- (void)activeModelChanged:(NSNotification *)notification
{
	//[fileContentsOutline reloadData];
	
	//Update the models menu.
	[self addModelsToMenu];
}


//========== partChanged: ======================================================
//
// Purpose:		Somewhere, somehow, a part was changed. There is some 
//				possibility that our data could be stale now.
//
//==============================================================================
- (void)partChanged:(NSNotification *)notification
{
	LDrawDirective *changedDirective = [notification object];
	if([[changedDirective ancestors] containsObject:[self documentContents]]) {
		[[self documentContents] setNeedsDisplay];
		[fileContentsOutline reloadData];
		
		//Model menu needs to change if:
		//	*model list changes (in the file)
		//	*model name changes (in the model)
		if([[notification object] isKindOfClass:[LDrawFile class]] || 
		   [[notification object] isKindOfClass:[LDrawModel class]])
			[self addModelsToMenu];
	}
}

//========== syntaxColorChanged: ===============================================
//
// Purpose:		The preferences have been updated; we need to refresh our data 
//				display.
//
//==============================================================================
- (void)syntaxColorChanged:(NSNotification *)notification
{
	[fileContentsOutline reloadData];
}


//**** NSWindow ****
//========== windowDidBecomeMain: ==============================================
//
// Purpose:		The window has come to the foreground.
//
//==============================================================================
- (void)windowDidBecomeMain:(NSNotification *)aNotification {
	[self updateInspector];
	
	[self addModelsToMenu];
}


//**** NSWindow ****
//========== windowWillClose: ==================================================
//
// Purpose:		The window is about to close; let's save some state info.
//
//==============================================================================
- (void)windowWillClose:(NSNotification *)notification
{
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	NSWindow *window = [notification object];
	
	[userDefaults setInteger:[partBrowserDrawer state]	forKey:PART_BROWSER_DRAWER_STATE];
	[userDefaults setInteger:[fileContentsDrawer state]	forKey:FILE_CONTENTS_DRAWER_STATE];
	
	[userDefaults setObject:NSStringFromSize([window frame].size) forKey:DOCUMENT_WINDOW_SIZE];
	
	//Un-inspect everything
	[[LDrawApplication sharedInspector] inspectObjects:nil];

	[self clearModelsMenu];
}

#pragma mark -
#pragma mark MENUS
#pragma mark -

//========== validateMenuItem: =================================================
//
// Purpose:		Determines whether the given menu item should be available.
//				This method is called automatically each time a menu is opened.
//				We identify the menu item by its tag, which is defined in 
//				MacLDraw.h.
//
//==============================================================================
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	int				 tag			= [menuItem tag];
	NSArray			*selectedItems	= [self selectedObjects];
	LDrawPart		*selectedPart	= [self selectedPart];
	NSPasteboard	*pasteboard		= [NSPasteboard generalPasteboard];
	LDrawMPDModel	*activeModel	= [[self documentContents] activeModel];
	BOOL			 enable			= NO;
	
	switch(tag) {

		////////////////////////////////////////
		//
		// Edit Menu
		//
		////////////////////////////////////////

		case cutMenuTag:
		case copyMenuTag:
		case deleteMenuTag:
		case duplicateMenuTag:
			if([selectedItems count] > 0)
				enable = YES;
			break;
		
		case pasteMenuTag:
			if([[pasteboard types] containsObject:LDrawDirectivePboardType])
				enable = YES;
			break;
		
		
		////////////////////////////////////////
		//
		// Tools Menu
		//
		////////////////////////////////////////
		
		case snapToGridMenuTag:
			enable = (selectedPart != nil);
			break;
		
		//The grid menus are always enabled, but this is a fine place to keep 
		// track of their state.
		case gridFineMenuTag:
			[menuItem setState:(self->gridMode == gridModeFine)];
			enable = YES;
			break;
		case gridMediumMenuTag:
			[menuItem setState:(self->gridMode == gridModeMedium)];
			enable = YES;
			break;
		case gridCoarseMenuTag:
			[menuItem setState:(self->gridMode == gridModeCoarse)];
			enable = YES;
			break;
			
			
		////////////////////////////////////////
		//
		// View Menu
		//
		////////////////////////////////////////
		
		case stepDisplayMenuTag:
			[menuItem setState:([activeModel stepDisplay])];
			enable = YES;
			break;
			
		case nextStepMenuTag:
			enable = ([activeModel stepDisplay] == YES);
			break;
		case previousStepMenuTag:
			enable = ([activeModel stepDisplay] == YES);
			break;
			
		default:
			//We are an NSDocument; it has its own validator to track certain 
			// items.
			enable = [super validateMenuItem:menuItem];
			break;
	}
	
	return enable;
}

//========== validateToolbarItem: ==============================================
//
// Purpose:		Toolbar validation: eye candy that probably slows everything to 
//				a crawl.
//
//==============================================================================
- (BOOL)validateToolbarItem:(NSToolbarItem *)item
{
	LDrawPart		*selectedPart	= [self selectedPart];
//	NSArray			*selectedItems	= [self selectedObjects];
	NSString		*identifier		= [item itemIdentifier];
	BOOL			 enabled		= NO;
	
	//Must have something selected.
	//Must have a part selected.
	if([identifier isEqualToString:TOOLBAR_SNAP_TO_GRID]  )
	{
		if(selectedPart != nil)
			enabled = YES;
	}
	
	//We don't have special conditions for it; give it a pass.
	else
		enabled = YES;

	return enabled;
}

#pragma mark -
#pragma mark UTILITIES
#pragma mark -

//========== addModelClicked: ==================================================
//
// Purpose:		Add newModel it to the current file.
//
//==============================================================================
- (void) addModel:(LDrawMPDModel *)newModel {

	LDrawModel		*selectedModel	= [self selectedModel];
	NSUndoManager	*undoManager	= [self undoManager];
	
	if(selectedModel != nil){
		int indexOfModel = [[self documentContents] indexOfDirective:selectedModel];
		[self addDirective:newModel
				  toParent:[self documentContents]
				   atIndex:indexOfModel+1 ];
	}
	else
		[self addDirective:newModel
				  toParent:[self documentContents] ];
	
	//Select the new model.
	[fileContentsOutline expandItem:newModel];
	int rowForItem = [fileContentsOutline rowForItem:newModel];
	[fileContentsOutline selectRowIndexes:[NSIndexSet indexSetWithIndex:rowForItem]
					 byExtendingSelection:NO];
	
	[undoManager setActionName:NSLocalizedString(@"UndoAddModel", nil)];
	
}


//========== addStep: ==========================================================
//
// Purpose:		Adds newStep to the currently-displayed model. If a part of 
//				the model is already selected, the step will be added after 
//				selection. Otherwise, the step appears at the end of the list.
//
//==============================================================================
- (void) addStep:(LDrawStep *)newStep {
	LDrawStep		*selectedStep	= [self selectedStep];
	LDrawMPDModel	*selectedModel	= [self selectedModel];
	NSUndoManager	*undoManager	= [self undoManager];
	
	//We need to synchronize our addition with the model currently active.
	if(selectedModel == nil)
		selectedModel = [[self documentContents] activeModel];
	else
		[[self documentContents] setActiveModel:selectedModel];
	
	if(selectedStep != nil){
		int indexOfStep = [selectedModel indexOfDirective:selectedStep];
		[self addDirective:newStep
				  toParent:selectedModel
				   atIndex:indexOfStep+1 ];
	}
	else
		[self addDirective:newStep
				  toParent:selectedModel ];
	
	//Select the new step.
	[fileContentsOutline expandItem:selectedModel];
	[fileContentsOutline expandItem:newStep];
	int rowForItem = [fileContentsOutline rowForItem:newStep];
	[fileContentsOutline selectRowIndexes:[NSIndexSet indexSetWithIndex:rowForItem]
					 byExtendingSelection:NO];
	
	[undoManager setActionName:NSLocalizedString(@"UndoAddStep", nil)];
	
}

//========== addStepComponent: =================================================
//
// Purpose:		Adds newDirective to the bottom of the current step, or after 
//				the currently-selected element in the step if there is one.
//
// Parameters:	newDirective: a directive which can be added to a step. These 
//						include parts, geometric primitives, and comments.
//
//==============================================================================
- (void) addStepComponent:(LDrawDirective *)newDirective {
	
	LDrawDirective	*selectedComponent	= [self selectedStepComponent];
	LDrawStep		*selectedStep		= [self selectedStep];
	LDrawMPDModel	*selectedModel		= [self selectedModel];
	NSUndoManager	*undoManager		= [self undoManager];
	
	//We need to synchronize our addition with the model currently active.
	if(selectedModel == nil)
		selectedModel = [[self documentContents] activeModel];
	else
		[[self documentContents] setActiveModel:selectedModel];
	
	//We may have the model itself selected, in which case we will add this new 
	// element to the very bottom of the model.
	if(selectedStep == nil)
		selectedStep = [selectedModel visibleStep];
		
	//It is also possible we have the step itself selected, in which case the 
	// new coponent will be added to the bottom of the step.
	if(selectedComponent == nil)
		[self addDirective:newDirective
				  toParent:selectedStep ];
	//Otherwise, we add the new element right after the selected element.
	else {
		int indexOfElement = [selectedStep indexOfDirective:selectedComponent];
		[self addDirective:newDirective
				  toParent:selectedStep
				   atIndex:indexOfElement+1 ];
	}

	//Select the new element.
	[fileContentsOutline expandItem:selectedModel];
	[fileContentsOutline expandItem:selectedStep];
	int rowForItem = [fileContentsOutline rowForItem:newDirective];
	[fileContentsOutline selectRowIndexes:[NSIndexSet indexSetWithIndex:rowForItem]
					 byExtendingSelection:NO];
	[[self foremostWindow] makeFirstResponder:mostRecentLDrawView]; //so we can move it immediately.
	
}//end addStepComponent:

#pragma mark -

//========== addModelsToMenu ===================================================
//
// Purpose:		Creates a menu used to switch the active model. A list of all 
//				the models in the document is inserted into the Models menu in 
//				the application's menu bar; the active model gets a check next 
//				to it.
//
//==============================================================================
- (void) addModelsToMenu {
	
	NSMenu			*mainMenu		= [NSApp mainMenu];
	NSMenu			*modelMenu		= [[mainMenu itemWithTag:modelsMenuTag] submenu];
	int				 separatorIndex	= [modelMenu indexOfItemWithTag:modelsSeparatorMenuTag];
	NSMenuItem		*modelItem		= nil;
	NSArray			*models			= [[self documentContents] submodels];
	LDrawMPDModel	*currentModel	= nil;
	int				 counter		= 0;
	
	[self clearModelsMenu];
	
	//Create menu items for each model.
	for(counter = 0; counter < [models count]; counter++){
		
		currentModel = [models objectAtIndex:counter];
		
		modelItem = [[[NSMenuItem alloc] init] autorelease];
		[modelItem setTitle:[currentModel modelName]];
		[modelItem setRepresentedObject:currentModel];
		[modelItem setTarget:self];
		[modelItem setAction:@selector(modelSelected:)];
		if([[self documentContents] activeModel] == currentModel)
			[modelItem setState:NSOnState];
		
		//Insert the new item at the end.
		[modelMenu insertItem:modelItem atIndex:separatorIndex+counter+1];
	}
	
}//end addModelsToMenu


//========== canDeleteDirective:displayErrors: =================================
//
// Purpose:		Tests whether the specified directive should be allowed to be 
//				deleted. If errorFlag is YES, also displays an appropriate error 
//				sheet explaining the reasons why directive cannot be deleted.
//
//==============================================================================
- (BOOL) canDeleteDirective:(LDrawDirective *)directive
			  displayErrors:(BOOL)errorFlag
{
	LDrawContainer	*parentDirective	= [directive enclosingDirective];
	BOOL			 isLastDirective	= ([[parentDirective subdirectives] count] <= 1);
	NSAlert			*alert				= [NSAlert new];
	NSString		*message			= nil;
	NSString		*informative		= nil;
	BOOL			 canDelete			= YES;
	
	if([directive isKindOfClass:[LDrawModel class]] && isLastDirective == YES)
	{
		canDelete = NO;
		informative = NSLocalizedString(@"DeleteLastModelInformative", nil);
	}
	else if([directive isKindOfClass:[LDrawStep class]] && isLastDirective == YES)
	{
		canDelete = NO;
		informative = NSLocalizedString(@"DeleteLastStepInformative", nil);
	}
	
	if(canDelete == NO && errorFlag == YES)
	{
		message = NSLocalizedString(@"DeleteDirectiveError", nil);
		message = [NSString stringWithFormat:message, [directive browsingDescription]];
		
		[alert setMessageText:message];
		[alert setInformativeText:informative];
		
		[alert addButtonWithTitle:NSLocalizedString(@"OKButtonName", nil)];
		
		[alert beginSheetModalForWindow:[self windowForSheet]
						  modalDelegate:nil
						 didEndSelector:NULL
							contextInfo:NULL ];
		
	}
	
	return canDelete;
	
}//end canDeleteDirective:displayErrors:


//========== clearModelsMenu ===================================================
//
// Purpose:		Removes all models from the menu.
//
//==============================================================================
- (void) clearModelsMenu {
	NSMenu			*mainMenu		= [NSApp mainMenu];
	NSMenu			*modelMenu		= [[mainMenu itemWithTag:modelsMenuTag] submenu];
	int				 separatorIndex	= [modelMenu indexOfItemWithTag:modelsSeparatorMenuTag];
	NSMenuItem		*modelItem		= nil;
	NSArray			*models			= [[self documentContents] submodels];
	LDrawMPDModel	*currentModel	= nil;
	int				 counter		= 0;
	
	//Create menu items for each model.
	for(counter = [modelMenu numberOfItems]-1; counter > separatorIndex; counter--){
		
		[modelMenu removeItemAtIndex: counter];
	}
	
}


//========== formatDirective:withStringRepresentation: =========================
//
// Purpose:		Applies syntax coloring to the specified directive, which will 
//				be displayed with the text representation.
//
//==============================================================================
- (NSAttributedString *) formatDirective:(LDrawDirective *)item
				withStringRepresentation:(NSString *)representation
{
	NSUserDefaults			*userDefaults	= [NSUserDefaults standardUserDefaults];
	NSString				*colorKey		= nil; //preference key for object's syntax color.
	NSColor					*syntaxColor	= nil;
	NSAttributedString		*styledString	= nil;
	NSMutableDictionary		*attributes		= [NSMutableDictionary dictionary];
	NSMutableParagraphStyle	*paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	
	//We want the text to appear nicely truncated in its column.
	// By setting the column to wrap and then setting the paragraph wrapping to 
	// truncate, we achieve the desired effect.
	[paragraphStyle setLineBreakMode:NSLineBreakByTruncatingTail];
	
	
	//Find the specified syntax color for the directive.
	if([item isKindOfClass:[LDrawModel class]])
		colorKey = SYNTAX_COLOR_MODELS_KEY;
	
	else if([item isKindOfClass:[LDrawStep class]])
		colorKey = SYNTAX_COLOR_STEPS_KEY;
	
	else if([item isKindOfClass:[LDrawComment class]])
		colorKey = SYNTAX_COLOR_COMMENTS_KEY;
		
	else if([item isKindOfClass:[LDrawPart class]])
		colorKey = SYNTAX_COLOR_PARTS_KEY;
	
	else if([item isKindOfClass:[LDrawLine				class]] ||
	        [item isKindOfClass:[LDrawTriangle			class]] ||
			[item isKindOfClass:[LDrawQuadrilateral		class]] ||
			[item isKindOfClass:[LDrawConditionalLine	class]]    )
		colorKey = SYNTAX_COLOR_PRIMITIVES_KEY;
	
	else
		colorKey = SYNTAX_COLOR_UNKNOWN_KEY;
	
	//We have the syntax coloring we want.
	syntaxColor = [userDefaults colorForKey:colorKey];
	
	
	//Assemble the attributes dictionary.
	[attributes setObject:paragraphStyle	forKey:NSParagraphStyleAttributeName];
	[attributes setObject:syntaxColor		forKey:NSForegroundColorAttributeName];
	
	//Create the attributed string.
	styledString = [[NSAttributedString alloc]
							initWithString:representation
								attributes:attributes ];
	
	//Release stuff we created or copied.
	[paragraphStyle release];
	
	return [styledString autorelease];

}//end formatDirective:withStringRepresentation:


//========== updateInspector ===================================================
//
// Purpose:		Updates the Inspector to display the currently-selected objects.
//				This should be called in response to any potentially state-
//				changing actions on a directive.
//
//==============================================================================
- (void) updateInspector{
	NSArray *selectedObjects = [self selectedObjects];
	
	[[LDrawApplication sharedInspector] inspectObjects:selectedObjects];
	[[LDrawColorPanel sharedColorPanel] updateSelectionWithObjects:selectedObjects];
}

//========== selectedObjects ===================================================
//
// Purpose:		Returns the LDraw objects currently selected in the file.
//
//==============================================================================
- (NSArray *) selectedObjects {

	NSIndexSet		*selectedIndexes	= [fileContentsOutline selectedRowIndexes];
	unsigned int	 currentIndex		= [selectedIndexes firstIndex];
	NSMutableArray	*selectedObjects	= [NSMutableArray arrayWithCapacity:[selectedIndexes count]];
	id				 currentObject		= nil;
	
	//Search through all the indexes and get the objects associated with them.
	while(currentIndex != NSNotFound){
	
		currentObject = [fileContentsOutline itemAtRow:currentIndex];
		[selectedObjects addObject:currentObject];
		
		currentIndex = [selectedIndexes indexGreaterThanIndex:currentIndex];
	}
	
	return selectedObjects;
}

//========== selectedModel =====================================================
//
// Purpose:		Returns the model that encloses the current selection, or nil 
//				if there is no selection.
//
// Note:		If you intend to use this method's output to figure out which 
//				model to display, then you need to convert a nil case into the 
//				active model.
//
//==============================================================================
- (LDrawMPDModel *) selectedModel {
	int	selectedRow		= [fileContentsOutline selectedRow];
	id	selectedItem	= [fileContentsOutline itemAtRow:selectedRow];
	
	if(selectedItem == nil || [selectedItem isKindOfClass:[LDrawFile class]])
		return nil;
		
	else if([selectedItem isKindOfClass:[LDrawModel class]])
		return selectedItem;
		
	else if([selectedItem isKindOfClass:[LDrawStep class]])
		return (LDrawMPDModel *)[selectedItem enclosingModel];
		
	else { //some kind of basic element.
		LDrawStep *enclosingStep = (LDrawStep*)[selectedItem enclosingDirective];
		return (LDrawMPDModel *)[enclosingStep enclosingModel];
		
	}
}

//========== selectedModel =====================================================
//
// Purpose:		Returns the step that encloses (or is) the current selection, or  
//				nil if there is no step in the selection chain.
//
//==============================================================================
- (LDrawStep *) selectedStep {
	int	selectedRow		= [fileContentsOutline selectedRow];
	id	selectedItem	= [fileContentsOutline itemAtRow:selectedRow];
	
	//If a model is selected, a step can't be!
	if(		selectedItem == nil
	   ||	[selectedItem isKindOfClass:[LDrawFile class]]
	   ||	[selectedItem isKindOfClass:[LDrawModel class]])
		return nil;
	
	//The step itself is selected.
	else if([selectedItem isKindOfClass:[LDrawStep class]])
		return selectedItem;
	
	else { //some kind of basic element.
		return (LDrawStep*)[selectedItem enclosingDirective];
	}
}//end selectedStep:


//========== selectedStepComponent =============================================
//
// Purpose:		Returns the drawable LDraw element that is currently selected.
//				(e.g., Part, Quadrilateral, Triangle, etc.)
//
//				Returns nil if the selection is not one of these atomic LDraw
//				commands.
//
//==============================================================================
- (LDrawDirective *) selectedStepComponent {
	int	selectedRow		= [fileContentsOutline selectedRow];
	id	selectedItem	= [fileContentsOutline itemAtRow:selectedRow];
	
	//If a model is selected, a step can't be!
	if(		selectedItem == nil
       ||	[selectedItem isKindOfClass:[LDrawFile class]]
	   ||	[selectedItem isKindOfClass:[LDrawModel class]]
	   ||	[selectedItem isKindOfClass:[LDrawStep class]] )
		return nil;
	
	else { //it's not a file, model, or step; whatever it is, it's what we are 
			// looking for.
		return selectedItem;
	}
}//end selectedStep:


//========== selectedPart ======================================================
//
// Purpose:		Returns the first part that is currently selected, or nil if no 
//				part is selected.
//
//==============================================================================
- (LDrawPart *) selectedPart {
	NSArray	*selectedObjects	= [self selectedObjects];
	id		 currentObject		= nil;
	int		 counter			= 0;
	
	while(counter < [selectedObjects count]){
		currentObject = [selectedObjects objectAtIndex:counter];
		if([currentObject isKindOfClass:[LDrawPart class]])
			break;
		else
			counter++;
	}
	
	//Either we just found one, on we found nothing.
	return currentObject;
}


//========== writeDirectives:toPasteboard: =====================================
//
// Purpose:		Writes objects to the given pasteboard, ensuring that each 
//				directive is written only once.
//
//				This method places two arrays on the pasteboard for these types:
//				* LDrawDirectivePboardType: array of LDrawDirectives converted 
//							to NSData objects.
//				* NSStringPboardType: array of strings representing the objects 
//							in the format written to an LDraw file.
//
// Notes:		This method will clear the contents of the pasteboard.
//
//==============================================================================
- (void) writeDirectives:(NSArray *)directives
			toPasteboard:(NSPasteboard *)pasteboard
{
	//Pasteboard types.
	NSArray			*pboardTypes		= [NSArray arrayWithObjects:
												LDrawDirectivePboardType, //Bricksmith's preferred type.
												NSStringPboardType, //representation for other applications.
												nil ];
	LDrawDirective	*currentObject		= nil;
	NSMutableArray	*objectsToCopy		= [NSMutableArray array];
	//list of containers we've already archived. We don't want to re-archive any 
	// of their children.
	NSMutableArray	*archivedContainers	= [NSMutableArray array];
	NSData			*data				= nil;
	NSString		*string				= nil;
	//list of LDrawDirectives which have been converted to data.
	NSMutableArray	*archivedObjects	= [NSMutableArray array];
	//list of LDrawDirectives which have been converted to strings.
	NSMutableString	*stringedObjects	= [NSMutableString stringWithCapacity:256];
	int				 counter			= 0;
	
	//Write out the selected objects, but only once for each object. 
	// Don't write out items whose parent is selected; the parent will 
	// automatically write its children.
	for(counter = 0; counter < [directives count]; counter++) {
		
		currentObject = [directives objectAtIndex:counter];
		//If we haven't already run into this object (via its parent container)
		// then we want to write it out. Otherwise, it will be copied implicitly 
		// along with its parent rather than copied explicitly.
		if([currentObject isAncestorInList:archivedContainers] == NO){
			[objectsToCopy addObject:currentObject];
		}
		//If this object is a container, we must record that it has been 
		// archived. Either it was archived just now, or it was archived 
		// earlier when its parent was archived.
		if([currentObject isKindOfClass:[LDrawContainer class]]){
			[archivedContainers addObject:currentObject];
		}
	}
	
	
	//Now that we have figured out *what* to copy, convert it into the 
	// *representations* we will use to copy.
	for(counter = 0; counter < [objectsToCopy count]; counter++) {
		currentObject = [objectsToCopy objectAtIndex:counter];
		
		//Convert the object into the two representations we know how to write.
		data	= [NSKeyedArchiver archivedDataWithRootObject:currentObject];
		string	= [currentObject write];
		
		//Save the representations into the arrays we'll write to the pasteboard.
		[archivedObjects addObject:data];
		[stringedObjects appendFormat:@"%@\n", string];
								//not using CRLF here because any Mac program that 
								// knows enough to do DOS line-endings will automatically
								// add them to pasted content.
	}
	
	
	//Set up our pasteboard.
	[pasteboard declareTypes:pboardTypes owner:nil];
	
	//Internally, Bricksmith uses archived LDrawDirectives to copy/paste.
	[pasteboard setPropertyList:archivedObjects forType:LDrawDirectivePboardType];
	
	//For other applications, however, we provide the LDraw file contents for 
	// the objects. Note that these strings cannot be pasted back into the 
	// program.
	[pasteboard setString:stringedObjects forType:NSStringPboardType];
	
}//end writeDirectives:toPasteboard:


//========== pasteFromPasteboard: ==============================================
//
// Purpose:		Paste the directives on the given pasteboard into the document.
//				The pasteboard must contain LDrawDirectivePboardType.
//
//				By generalizing the method in this way, we allow pasting off 
//				private internal pasteboards too. This method is used by 
//				-duplicate: in order to leverage the existing copy/paste code 
//				without wantonly destroying the contents of the General 
//				Pasteboard.
//
// Returns:		The objects added, or nil if nothing was on the pasteboard.
//
//==============================================================================
- (NSArray *) pasteFromPasteboard:(NSPasteboard *) pasteboard
{
	NSArray			*objects		= nil;
	id				 currentObject	= nil; //some kind of unarchived LDrawDirective
	NSData			*data			= nil;
	NSMutableArray	*addedObjects	= [NSMutableArray array];
	int				 counter		= 0;
	
	//We must make sure we have the proper pasteboard type available.
	if([[pasteboard types] containsObject:LDrawDirectivePboardType]) {
		
		//Unarchived everything and dump it into our file.
		objects = [pasteboard propertyListForType:LDrawDirectivePboardType];
		for(counter = 0; counter < [objects count]; counter++) {
			data			= [objects objectAtIndex:counter];
			currentObject	= [NSKeyedUnarchiver unarchiveObjectWithData:data];
			
			//Now pop the data into our file.
			if([currentObject isKindOfClass:[LDrawModel class]])
				[self addModel:currentObject];
			else if([currentObject isKindOfClass:[LDrawStep class]])
				[self addStep:currentObject];
			else
				[self addStepComponent:currentObject];
			
			[addedObjects addObject:currentObject];
		}
		
		//Select all the objects which have been added.
		[fileContentsOutline selectObjects:addedObjects];
	}

	//As this is the centralized conduit through which all "pasting" operations 
	// flow, this is where we refresh.
	[[self documentContents] setNeedsDisplay];
	
	return addedObjects;
	
}//end pasteFromPasteboard:


#pragma mark -
#pragma mark DESTRUCTOR
#pragma mark -

//========== dealloc ===========================================================
//
// Purpose:		We're crossing over Jordan; we're heading to that mansion just 
//				over the hilltop (the gold one that's silver-lined).
//
//==============================================================================
- (void) dealloc{

	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[documentContents release];
	[lastSelectedPart release];

	[super dealloc];
}

@end