//==============================================================================
//
// File:		LDrawDocument.m
//
// Purpose:		Document controller for an LDraw document.
//
//				Opens the document and manages its editor and viewer. This is 
//				the central class of the application's user interface.
//
// Threading:	The LDrawFile encapsulated in this class is a shared resource. 
//				We must take care not to edit it while it is being drawn in 
//				another thread. As such, all the calls in the "Undoable 
//				Activities" section are bracketed with the approriate locking 
//				calls. (ANY edit of the document should be undoable.)
//
//  Created by Allen Smith on 2/14/05.
//  Copyright (c) 2005. All rights reserved.
//==============================================================================
#import "LDrawDocument.h"

#import "LDrawFile.h"
#import "LDrawModel.h"
#import "LDrawMPDModel.h"
#import "LDrawStep.h"

#import "LDrawColor.h"
#import "LDrawComment.h"
#import "LDrawConditionalLine.h"
#import "LDrawDirective.h"
#import "LDrawDrawableElement.h"
#import "LDrawLine.h"
#import "LDrawPart.h"
#import "LDrawQuadrilateral.h"
#import "LDrawTriangle.h"

#import <AMSProgressBar/AMSProgressBar.h>
#import "DimensionsPanel.h"
#import "DocumentToolbarController.h"
#import "ExtendedSplitView.h"
#import "IconTextCell.h"
#import "Inspector.h"
#import "LDrawApplication.h"
#import "LDrawColorPanel.h"
#import "LDrawDocumentWindow.h"
#import "LDrawFileOutlineView.h"
#import "LDrawGLView.h"
#import "LDrawUtilities.h"
#import "MacLDraw.h"
#import "MinifigureDialogController.h"
#import "MovePanel.h"
#import "PartBrowserDataSource.h"
#import "PartBrowserPanel.h"
#import "PartReport.h"
#import "PieceCountPanel.h"
#import "RotationPanel.h"
#import "StringUtilities.h"
#import "UserDefaultsCategory.h"
#import "WindowCategory.h"


@implementation LDrawDocument

//========== init ==============================================================
//
// Purpose:		Sets up a new untitled document.
//
//==============================================================================
- (id) init
{
    self = [super init];
    if (self)
	{
		[self setDocumentContents:[LDrawFile newFile]];
        insertionMode = insertAtEnd;
		[self setGridSpacingMode:gridModeMedium];
		
		// Add your subclass-specific initialization here.
        // If an error occurs here, send a [self release] message and return nil.
    
    }
    return self;
	
}//end init


#pragma mark -
#pragma mark DOCUMENT
#pragma mark -

//========== windowNibName =====================================================
//
// Purpose:		Returns the name of the Nib file used to display this document.
//
//==============================================================================
- (NSString *) windowNibName
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
- (void) windowControllerDidLoadNib:(NSWindowController *) aController
{
	NSNotificationCenter	*notificationCenter	= [NSNotificationCenter defaultCenter];
	NSUserDefaults			*userDefaults		= [NSUserDefaults standardUserDefaults];
	NSWindow				*window				= [aController window];
	int						 drawerState		= 0;

    [super windowControllerDidLoadNib:aController];
	
	
	// Create the toolbar.
	NSToolbar *toolbar = [[[NSToolbar alloc] initWithIdentifier:@"LDrawDocumentToolbar"] autorelease];
	[toolbar setAutosavesConfiguration:YES];
	[toolbar setAllowsUserCustomization:YES];
	[toolbar setDelegate:self->toolbarController];
	[window setToolbar:toolbar];
	
	[fileContentsOutline setDoubleAction:@selector(showInspector:)];
	[fileContentsOutline setVerticalMotionCanBeginDrag:YES];
	[fileContentsOutline registerForDraggedTypes:[NSArray arrayWithObject:LDrawDirectivePboardType]];
	
	
	// Set our size to whatever it was last time. (We don't do the whole frame 
	// because we want the origin to be nicely staggered as documents open; that 
	// normally happens automatically.)
	NSString *savedSizeString = [userDefaults objectForKey:DOCUMENT_WINDOW_SIZE];
	if(savedSizeString != nil)
	{
		NSSize	size	= NSSizeFromString(savedSizeString);
		[window resizeToSize:size animate:NO];
	}
	
	
	//Set up the window state based on what is found in preferences.
	drawerState = [userDefaults integerForKey:PART_BROWSER_DRAWER_STATE];
	if(drawerState == NSDrawerOpenState)
		[partBrowserDrawer open];
	
	//Restore the state of our 3D viewers.
	[fileGraphicView	setAutosaveName:@"fileGraphicView"];
	[fileDetailView1	setAutosaveName:@"fileDetailView1"];
	[fileDetailView2	setAutosaveName:@"fileDetailView2"];
	[fileDetailView3	setAutosaveName:@"fileDetailView3"];
	
	[fileGraphicView	restoreConfiguration];
	[fileDetailView1	restoreConfiguration];
	[fileDetailView2	restoreConfiguration];
	[fileDetailView3	restoreConfiguration];
	
		//For reasons I have not sufficiently investigated, setting the 
		// zoom percentage on a collapsed (0 width/height) view causes 
		// the view to get stuck at 0 width/height. The easiest fix was 
		// to move this call above the splitview restoration so the 
		// view's panes will never be collapsed.
	[fileDetailView1	setZoomPercentage:75];
	[fileDetailView2	setZoomPercentage:75];
	[fileDetailView3	setZoomPercentage:75];

	[[self foremostWindow] makeFirstResponder:fileGraphicView]; //so we can move it immediately.

	// We have to do the splitview saving manually. C'mon Apple, get with it!
	// Note: They did in Leopard. These calls will use the system function 
	//		 there. 
	[fileContentsSplitView		setAutosaveName:@"fileContentsSplitView"];
	[horizontalSplitView		setAutosaveName:@"HorizontalLDrawSplitview2.1"];
	[verticalDetailSplitView	setAutosaveName:@"Vertical LDraw Splitview"];
	
	[fileContentsSplitView		restoreConfiguration];
	[horizontalSplitView		restoreConfiguration];
	[verticalDetailSplitView	restoreConfiguration];
	
	// update scope step display controls
	[self setStepDisplay:NO];
	
	// Tiger does not have the system-provided template images we use on 
	// Leopard. Fall back on some internal images. 
	if([self->stepNavigator imageForSegment:0] == nil || [[[self->stepNavigator imageForSegment:0] representations] count] == 0)
		[self->stepNavigator setImage:[NSImage imageNamed:@"GoBack"] forSegment:0];
	if([self->stepNavigator imageForSegment:1] == nil || [[[self->stepNavigator imageForSegment:1] representations] count] == 0)
		[self->stepNavigator setImage:[NSImage imageNamed:@"GoForward"] forSegment:1];

	//Display our model.
	[self loadDataIntoDocumentUI];
	
	
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


#pragma mark -
#pragma mark Reading

//========== readFromURL:ofType:error: =========================================
//
// Purpose:		Reads the file off of disk. We are overriding this NSDocument 
//				method to grab the path; the actual data-collection is done 
//				elsewhere.
//
//==============================================================================
- (BOOL) readFromURL:(NSURL *)absoluteURL
			  ofType:(NSString *)typeName
			   error:(NSError **)outError
{
	AMSProgressPanel	*progressPanel	= [AMSProgressPanel progressPanel];
	NSString			*openMessage	= nil;
	
	openMessage = [NSString stringWithFormat:	NSLocalizedString(@"OpeningFileX", nil), 
		[self displayName] ];
	
	//This might take a while. Show that we're doing something!
	[progressPanel setMessage:openMessage];
	[progressPanel setIndeterminate:YES];
	[progressPanel showProgressPanel];

	//do the actual loading.
	[super readFromURL:absoluteURL ofType:typeName error:outError];
	
	// Track the path. I'm not sure what a non-file URL means, and I'm basically 
	// hoping we never encounter one. 
	if([absoluteURL isFileURL] == YES)
		[[self documentContents] setPath:[absoluteURL path]];
	else
		[[self documentContents] setPath:nil];
	
	[progressPanel close];
	
	//Postflight: find missing and moved parts.
	[self doMissingPiecesCheck:self];
	[self doMovedPiecesCheck:self];
	[self doMissingModelnameExtensionCheck:self];
	
	return YES;
	
}//end readFromFile:ofType:


//========== revertToContentsOfURL:ofType:error: ===============================
//
// Purpose:		Called by NSDocument when it reverts the document to its most 
//				recently saved state.
//
//==============================================================================
- (BOOL) revertToContentsOfURL:(NSURL *)absoluteURL
						ofType:(NSString *)typeName
						 error:(NSError **)outError
{
	BOOL success = NO;
	
	//Causes loadDataRepresentation:ofType: to be invoked.
	success = [super revertToContentsOfURL:absoluteURL ofType:typeName error:outError];
	if(success == YES)
	{
		//Display the new document contents. 
		//		(Alas. This doesn't happen automatically.)
		[self loadDataIntoDocumentUI];
	}
	
	return success;
	
}//end revertToSavedFromFile:ofType:


//========== readFromData:ofType:error: ========================================
//
// Purpose:		Read a logical document structure from data. This is the "open" 
//				method.
//
//==============================================================================
- (BOOL) readFromData:(NSData *)data
			   ofType:(NSString *)typeName
				error:(NSError **)outError
{
	NSString			*fileContents	= nil;
	LDrawFile			*newFile		= nil;
	
	//LDraw files are plain text.
	fileContents = [[NSString alloc] initWithData:data
										 encoding:NSUTF8StringEncoding ];
	if(fileContents == nil) //whoops. Not UTF-8. Try the Windows standby.
		fileContents = [[NSString alloc] initWithData:data
											 encoding:NSISOLatin1StringEncoding ];
	if(fileContents == nil) //yikes. Not even Windows. MacRoman should do it.
		fileContents = [[NSString alloc] initWithData:data
											 encoding:NSMacOSRomanStringEncoding ];
	
	//Parse the model.
	// - optimizing models can result in OpenGL calls, so to be ultra-safe we 
	//   set a context and lock on it. We can't use any of the documents GL 
	//   views because the Nib may not have been loaded yet.
	CGLLockContext([[LDrawApplication sharedOpenGLContext] CGLContextObj]);
	{
		[[LDrawApplication sharedOpenGLContext] makeCurrentContext];
	
		newFile = [LDrawFile parseFromFileContents:fileContents];
		[self setDocumentContents:newFile];
	}
	CGLUnlockContext([[LDrawApplication sharedOpenGLContext] CGLContextObj]);
	
	[fileContents release];
	
    return YES;
}//end loadDataRepresentation:ofType:


#pragma mark -
#pragma mark Writing

//========== writeToURL:ofType:error: ==========================================
//
// Purpose:		Saves the file out. We are overriding this NSDocument method to 
//				grab the path; the actual data-collection is done elsewhere.
//
//==============================================================================
- (BOOL) writeToURL:(NSURL *)absoluteURL
			 ofType:(NSString *)typeName
			  error:(NSError **)outError
{
	BOOL success = NO;
	
	//do the actual writing.
	success = [super writeToURL:absoluteURL ofType:typeName error:outError];
	
	//track the path.
	if([absoluteURL isFileURL] == YES)
		[[self documentContents] setPath:[absoluteURL path]];
	else
		[[self documentContents] setPath:nil];
	
	return success;
	
}//end writeToFile:ofType:


//========== dataOfType:error: =================================================
//
// Purpose:		Converts this document into a data object that can be written 
//				to disk. This is where a document gets saved.
//
//==============================================================================
- (NSData *)dataOfType:(NSString *)typeName
				 error:(NSError **)outError
{
    NSString *modelOutput = [[self documentContents] write];
	
	return [modelOutput dataUsingEncoding:NSUTF8StringEncoding];
	
}//end dataOfType:error:


#pragma mark -
#pragma mark ACCESSORS
#pragma mark -

//========== documentContents ==================================================
//
// Purpose:		Returns the logical representation of the LDraw file this 
//				document represents.
//
//==============================================================================
- (LDrawFile *) documentContents
{
	return documentContents;
	
}//end documentContents


//========== foremostWindow ====================================================
//
// Purpose:		Returns the main editing window.
//
//==============================================================================
- (NSWindow *) foremostWindow
{
	return [[[self windowControllers] objectAtIndex:0] window];
	
}//end foremostWindow


//========== gridSpacing =======================================================
//
// Purpose:		Resolves the current grid spacing into an actual value.
//
// Notes:		This value represents distances "along the studs"--that is, 
//			    horizontal along the brick. Vertical distances may be adjusted. 
//
//==============================================================================
- (float) gridSpacing
{
	NSUserDefaults	*userDefaults	= [NSUserDefaults standardUserDefaults];
	float			 gridSpacing	= 0.0;

	switch(self->gridMode)
	{
		case gridModeFine:
			gridSpacing		= [userDefaults floatForKey:GRID_SPACING_FINE];
			break;
			
		case gridModeMedium:
			gridSpacing		= [userDefaults floatForKey:GRID_SPACING_MEDIUM];
			break;
			
		case gridModeCoarse:
			gridSpacing		= [userDefaults floatForKey:GRID_SPACING_COARSE];
			break;
	}
	
	return gridSpacing;
	
}//end gridSpacing


//========== gridSpacingMode ===================================================
//
// Purpose:		Returns the current granularity of the positioning grid being 
//				used in this document.
//
//==============================================================================
- (gridSpacingModeT) gridSpacingMode
{
	return gridMode;
	
}//end gridSpacingMode


//========== partBrowserDrawer =================================================
//
// Purpose:		Returns the drawer for a part browser attached to the document 
//			    window. Note that the user can set a preference to show the Part 
//			    Browser as a single floating panel rather than a drower on each 
//			    window. 
//
//==============================================================================
- (NSDrawer *) partBrowserDrawer
{
	return self->partBrowserDrawer;

}//end partBrowserDrawer


//========== viewingAngle ======================================================
//
// Purpose:		Returns the modelview rotation for the focused LDrawGLView.
//
//==============================================================================
- (Tuple3) viewingAngle
{
	Tuple3	angle	= [self->mostRecentLDrawView viewingAngle];
	
	return angle;
	
}//end viewingAngle


#pragma mark -

//========== setCurrentStep: ===================================================
//
// Purpose:		Sets the current maximum step displayed in step display mode and 
//				updates the UI. 
//
// Notes:		This does not activate step display if it isn't on.
//
// Parameters:	requestedStep	- the 0-relative step number. Does not do 
//								  bounds-checking. 
//
//==============================================================================
- (void) setCurrentStep:(int)requestedStep
{
	LDrawMPDModel		*activeModel	= [[self documentContents] activeModel];
	
	[activeModel setMaximumStepIndexForStepDisplay:requestedStep];
	
	// Update UI
	[self->stepField setIntValue:(requestedStep + 1)]; // make 1-relative
	if([activeModel stepDisplay] == YES)
	{
		[self updateViewingAngleToMatchStep];
		[[self documentContents] setNeedsDisplay];
	}
	
}//end setCurrentStep:


//========== setDocumentContents: ==============================================
//
// Purpose:		Sets the logical representation of the LDraw file this 
//				document represents to newContents. This method should be called 
//				when the document is first created.
//
// Notes:		This method intentionally avoids making the user interface aware 
//				of the new contents. This is because this method is generally 
//				called prior to loading the Nib file. (It also gets called when 
//				reverting.) There is a separate method, -loadDataIntoDocumentUI,
//				to sync the UI.
//
//==============================================================================
- (void) setDocumentContents:(LDrawFile *)newContents
{
	[newContents retain];
	[documentContents release];
	
	documentContents = newContents;
		
}//end setDocumentContents:


//========== setGridSpacingMode: ===============================================
//
// Purpose:		Returns the current granularity of the positioning grid being 
//				used in this document.
//
//==============================================================================
- (void) setGridSpacingMode:(gridSpacingModeT)newMode
{
	self->gridMode = newMode;
	
	[self->toolbarController setGridSpacingMode:newMode];
	
}//end setGridSpacingMode:


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
	
}//end setLastSelectedPart:


//========== toggleStepDisplay: ================================================
//
// Purpose:		Turns step display (like Lego instructions) on or off for the 
//				active model.
//
//==============================================================================
- (void) setStepDisplay:(BOOL)showStepsFlag
{
	LDrawMPDModel	*activeModel	= [[self documentContents] activeModel];
	
	if(showStepsFlag != [activeModel stepDisplay])
	{
		if(showStepsFlag == YES)
		{
			[activeModel setStepDisplay:YES];
			[self setCurrentStep:0];
		}
		else // turn it off now
		{
			[activeModel setStepDisplay:NO];
		}
		
		[[self documentContents] setNeedsDisplay];
	}
	
	// Set scope button state no matter what. The scope buttons are really 
	// toggle buttons which call this method; if you click "Steps" and step 
	// display is already on, you want the button to *stay* selected. This makes 
	// sure that happens. 
	[self->viewAllButton setState:(showStepsFlag == NO)];
	[self->viewStepsButton setState:(showStepsFlag == YES)];
	
	[self->scopeStepControlsContainer setHidden:(showStepsFlag == NO)];
	[self->stepField setIntValue:[activeModel maximumStepIndexForStepDisplay] + 1];
	
}//end toggleStepDisplay:


#pragma mark -
#pragma mark ACTIVITIES
#pragma mark -
//These are *high-level* calls to modify the structure of the model. They call 
// down to appropriate low-level calls (in the "Undoable Activities" section).


//========== moveSelectionBy: ==================================================
//
// Purpose:		Moves all selected (and moveable) directives in the direction 
//				indicated by movementVector.
//
//==============================================================================
- (void) moveSelectionBy:(Vector3) movementVector
{
	NSArray			*selectedObjects	= [self selectedObjects];
	LDrawDirective	*currentObject		= nil;
	int				 counter			= 0;
	
	//find the nudgable items
	for(counter = 0; counter < [selectedObjects count]; counter++)
	{
		currentObject = [selectedObjects objectAtIndex:counter];
		
		if([currentObject isKindOfClass:[LDrawDrawableElement class]])
			[self moveDirective: (LDrawDrawableElement*)currentObject
					inDirection: movementVector];
	}
	
}//end moveSelectionBy:


//========== nudgeSelectionBy: =================================================
//
// Purpose:		Nudges all selected (and nudgeable) directives in the direction 
//				indicated by nudgeVector, which should be normalized. The exact 
//				amount nudged is dependent on the directives themselves, but we 
//				give them our best estimate based on the grid granularity.
//
//==============================================================================
- (void) nudgeSelectionBy:(Vector3) nudgeVector
{
	NSArray					*selectedObjects	= [self selectedObjects];
	LDrawDrawableElement	*firstNudgable		= nil;
	id						 currentObject		= nil;
	float					 nudgeMagnitude		= [self gridSpacing];
	int						 counter			= 0;
	
	//normalize just in case someone didn't get the message!
	nudgeVector = V3Normalize(nudgeVector);
	
	nudgeVector.x *= nudgeMagnitude;
	nudgeVector.y *= nudgeMagnitude;
	nudgeVector.z *= nudgeMagnitude;
	
	//find the first selected item that can acutally be moved.
	for(counter = 0; counter < [selectedObjects count] && firstNudgable == nil; counter++)
	{
		currentObject = [selectedObjects objectAtIndex:counter];
		
		if([currentObject isKindOfClass:[LDrawDrawableElement class]])
			firstNudgable = currentObject;
	}
	
	if(firstNudgable != nil)
	{
		//compute the absolute movement for the relative nudge. The actual 
		// movement for a nudge is dependent on the axis along which the 
		// nudge is occuring (because Lego follows different vertical and 
		// horizontal scales). But we must move all selected parts by the 
		// SAME AMOUNT, otherwise they would get oriented all over the place.
		nudgeVector = [firstNudgable displacementForNudge:nudgeVector];
		
		[self moveSelectionBy:nudgeVector];
	}
}//end nudgeSelectionBy:


//========== rotateSelectionAround: ============================================
//
// Purpose:		Rotates all selected parts in a clockwise direction around the 
//				specified axis. The rotationAxis should be either 
//				+/- i, +/- j or +/- k.
//
//				This method is used by the rotate toolbar methods. It chooses 
//				the actual number of degrees based on the current grid mode.
//
//==============================================================================
- (void) rotateSelectionAround:(Vector3)rotationAxis
{
	NSArray			*selectedObjects	= [self selectedObjects]; //array of LDrawDirectives.
	RotationModeT	 rotationMode		= RotateAroundSelectionCenter;
	Tuple3			 rotation			= {0};
	float			 degreesToRotate	= 0;
	
	//Determine magnitude of nudge.
	switch([self gridSpacingMode])
	{
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
	
	//normalize just in case someone didn't get the message!
	rotationAxis = V3Normalize(rotationAxis);
	
	rotation.x = rotationAxis.x * degreesToRotate;
	rotation.y = rotationAxis.y * degreesToRotate;
	rotation.z = rotationAxis.z * degreesToRotate;
	
	
	//Just one part selected; rotate around that part's origin. That is 
	// presumably what the part's author intended to be the rotation point.
	if([selectedObjects count] == 1){
		rotationMode = RotateAroundPartPositions;
	}
	//More than one part selected. We now must make a "best guess" about 
	// what to rotate around. So we will go with the center of the bounding 
	// box of the selection.
	else
		rotationMode = RotateAroundSelectionCenter;
	
	
	[self rotateSelection:rotation mode:rotationMode fixedCenter:NULL];
	
}//end rotateSelectionAround


//========== rotateSelection:mode:fixedCenter: =================================
//
// Purpose:		Rotates the selected parts according to the specified mode.
//
// Parameters:	rotation	= degrees x,y,z to rotate
//				mode		= how to derive the rotation centerpoint
//				fixedCenter	= explicit centerpoint, or NULL if mode not equal to 
//							  RotateAroundFixedPoint
//
//==============================================================================
- (void) rotateSelection:(Tuple3)rotation
					mode:(RotationModeT)mode
			 fixedCenter:(Point3 *)fixedCenter
{
	NSArray			*selectedObjects	= [self selectedObjects]; //array of LDrawDirectives.
	id				 currentObject		= nil;
	Box3			 selectionBounds	= [LDrawUtilities boundingBox3ForDirectives:selectedObjects];
	Point3			 rotationCenter		= {0};
	int				 counter			= 0;
	
	if(mode == RotateAroundSelectionCenter)
	{
		rotationCenter = V3Midpoint(selectionBounds.min, selectionBounds.max);
	}
	else if(mode == RotateAroundFixedPoint)
	{
		if(fixedCenter != NULL)
			rotationCenter = *fixedCenter;
	}
	
	
	//rotate everything that can be rotated. That would be parts and only parts.
	for(counter = 0; counter < [selectedObjects count]; counter++)
	{
		currentObject = [selectedObjects objectAtIndex:counter];
		
		if([currentObject isKindOfClass:[LDrawPart class]])
		{
			if(mode == RotateAroundPartPositions)
				rotationCenter = [(LDrawPart*)currentObject position];
		
			[self rotatePart:currentObject
				   byDegrees:rotation
				 aroundPoint:rotationCenter ];
		}
	}
}//end rotateSelection:mode:fixedCenter:


//========== selectDirective:byExtendingSelection: =============================
//
// Purpose:		Selects the specified directive.
//				Pass nil to deselect all.
//
//				If shouldExtend is YES, this method toggles the selection of the 
//				given directive. Otherwise, the given directive is made the 
//				exclusive selection in the document. 
//
//==============================================================================
- (void) selectDirective:(LDrawDirective *) directiveToSelect
	byExtendingSelection:(BOOL) shouldExtend
{
	NSArray			*ancestors			= [directiveToSelect ancestors];
	int				 indexToSelect		= 0;
	int				 counter			= 0;
	
	if(directiveToSelect == nil)
		[fileContentsOutline deselectAll:nil];
	else
	{
		//Expand the hierarchy all the way down to the directive we are about to 
		// select.
		for(counter = 0; counter < [ancestors count]; counter++)
			[fileContentsOutline expandItem:[ancestors objectAtIndex:counter]];
		
		//Now we can safely select the directive. It is guaranteed to be visible, 
		// since we expanded all its ancestors.
		indexToSelect = [fileContentsOutline rowForItem:directiveToSelect];
		
		//If we are doing multiple selection (shift-click), we want to deselect 
		// already-selected parts.
		if(		[[fileContentsOutline selectedRowIndexes] containsIndex:indexToSelect]
			&&	shouldExtend == YES )
			[fileContentsOutline deselectRow:indexToSelect];
		else
			[fileContentsOutline selectRowIndexes:[NSIndexSet indexSetWithIndex:indexToSelect]
							 byExtendingSelection:shouldExtend];
		
		[fileContentsOutline scrollRowToVisible:indexToSelect];
	}
	
}//end selectDirective:byExtendingSelection:


//========== setSelectionToHidden: =============================================
//
// Purpose:		Hides or shows all the hideable selected elements.
//
//==============================================================================
- (void) setSelectionToHidden:(BOOL)hideFlag
{
	NSArray			*selectedObjects	= [self selectedObjects];
	id				 currentObject		= nil;
	int				 counter			= 0;
	
	for(counter = 0; counter < [selectedObjects count]; counter++)
	{
		currentObject = [selectedObjects objectAtIndex:counter];
		if([currentObject respondsToSelector:@selector(setHidden:)])
			[self setElement:currentObject toHidden:hideFlag]; //undoable hook.
	}
}//end setSelectionToHidden:


//========== setZoomPercentage: ================================================
//
// Purpose:		Zooms the selected LDraw view to the specified percentage.
//
//==============================================================================
- (void) setZoomPercentage:(float)newPercentage
{
	[self->mostRecentLDrawView setZoomPercentage:newPercentage];
	
}//end setZoomPercentage:


#pragma mark -
#pragma mark ACTIONS
#pragma mark -
//traditional -(void)action:(id)sender type action methods.
// Generally called directly by User Interface controls.


//========== changeLDrawColor: =================================================
//
// Purpose:		Responds to color-change messages sent down the responder chain 
//				by the LDrawColorPanel. Upon the receipt of this message, the 
//				window should change the color of all the selected objects to 
//				the new color specified in the panel.
//
//==============================================================================
- (void) changeLDrawColor:(id)sender
{
	NSArray		*selectedObjects	= [self selectedObjects];
	id			 currentObject		= nil;
	LDrawColorT	 newColor			= [sender LDrawColor];
	int			 counter			= 0;
	
	for(counter = 0; counter < [selectedObjects count]; counter++)
	{
		currentObject = [selectedObjects objectAtIndex:counter];
	
		if([currentObject conformsToProtocol:@protocol(LDrawColorable)])
			[self setObject:currentObject toColor:newColor];
	}
	if([selectedObjects count] > 0)
		[[self documentContents] setNeedsDisplay];
		
}//end changeLDrawColor:


//========== insertLDrawPart: ==================================================
//
// Purpose:		We are being prompted to insert a new part into the model.
//
// Parameters:	sender = PartBrowserDataSource generating the insert request.
//
//==============================================================================
- (void) insertLDrawPart:(id)sender
{
	NSString	*partName	= [sender selectedPartName];
	
	//We got a part; let's add it!
	if(partName != nil)
		[self addPartNamed:partName];
	
	// part-insertion may have been generated by a Part Browser panel which was 
	// in the foreground. Now that the part is inserted, we want the editor 
	// window in the foreground. 
	[[self foremostWindow] makeKeyAndOrderFront:sender];
	
}//end insertLDrawPart:


//========== panelMoveParts: ===================================================
//
// Purpose:		The move panel wants to move parts.
//
// Parameters:	sender = MovePanel generating the move request.
//
//==============================================================================
- (void) panelMoveParts:(id)sender
{
	Vector3			movement		= [sender movementVector];
	
	[self moveSelectionBy:movement];
	
}//end panelMoveParts


//========== panelRotateParts: =================================================
//
// Purpose:		The rotation panel wants to rotate! It's up to us to interrogate 
//				the rotation panel to figure out how exactly this rotation is 
//				supposed to be done.
//
// Parameters:	sender = RotationPanel generating the rotation request.
//
//==============================================================================
- (void) panelRotateParts:(id)sender
{
	Tuple3			angles			= [sender angles];
	RotationModeT	rotationMode	= [sender rotationMode];
	Point3			centerPoint		= [sender fixedPoint];
	
	//the center may not be valid, but that will get taken care of by the 
	// rotation mode.
	
	[self rotateSelection:angles
					 mode:rotationMode
			  fixedCenter:&centerPoint];
	
}//end panelRotateParts


#pragma mark -

//========== doMissingModelnameExtensionCheck: =================================
//
// Purpose:		Ensures that the names of all submodels in the current model end 
//				in a recognized LDraw extension (.ldr, .dat), renaming models 
//				and updating references as needed. 
//
// Notes:		Previous versions of Bricksmith did not force submodel names to 
//				end in a file extension, and this was a seemingly sensible, 
//				Maclike thing to do. Alas, MLCad will NOT RECOGNIZE submodels 
//				whose names do not have an extension. (Why...?!) Furthermore, 
//				according to the LDraw File Specification, a type 1 MUST point 
//				ot a "valid LDraw filename," which MUST include the extension. 
//				http://www.ldraw.org/Article218.html#lt1 Sigh...
//
//				This action is not undoable. Why would you want to?
//
//==============================================================================
- (void) doMissingModelnameExtensionCheck:(id)sender
{
	NSArray			*submodels			= [[self documentContents] submodels];
	LDrawMPDModel	*currentSubmodel	= nil;
	NSString		*currentName		= nil;
	NSString		*acceptableName		= nil;
	int				counter				= 0;
	
	// Find submodels with bad names.
	for(counter = 0; counter < [submodels count]; counter++)
	{
		currentSubmodel	= [submodels objectAtIndex:counter];
		currentName		= [currentSubmodel modelName];
		acceptableName	= [LDrawMPDModel ldrawCompliantNameForName:currentName];
		
		// If the model name does not have a valid LDraw file extension, the 
		// LDraw spec says we must give it one. Ugh. 
		if( [acceptableName isEqualToString:currentName] == NO )
		{
			// For files with only one model, we synthesize a name based on the 
			// model description. We can safely do a direct rename of these 
			// files. This also means LDrawMPDModel doesn't have to clean up 
			// every official part we parse from the LDraw folder. 
			if([submodels count] == 1)
			{
				[currentSubmodel setModelName:acceptableName];
			}
			else
			{
				// For MPD documents, we need to do a complex rename.
				[[self documentContents] renameModel:currentSubmodel toName:acceptableName];
			
				// Mark document as modified.
				[self updateChangeCount:NSChangeDone];
			}
		}
	}
	
}//end doMissingModelnameExtensionCheck:


//========== doMissingPiecesCheck: =============================================
//
// Purpose:		Searches the current model for any missing parts, and displays a 
//				warning if there are some.
//
//==============================================================================
- (void) doMissingPiecesCheck:(id)sender
{
	PartReport		*partReport			= [PartReport partReportForContainer:[self documentContents]];
	NSArray			*missingParts		= [partReport missingParts];
	NSArray			*missingNames		= nil;
	NSMutableString	*informativeString	= nil;
	
	if([missingParts count] > 0)
	{
		//Build a string listing all the missing parts.
		missingNames = [missingParts valueForKey:@"displayName"]; // I love Cocoa.
		
		informativeString = [NSMutableString stringWithString:NSLocalizedString(@"MissingPiecesInformative", nil)];
		[informativeString appendString:@"\n\n"];
		[informativeString appendString:[missingNames componentsJoinedByString:@"\n"]];
		
		//Alert! Alert!
		NSAlert *alert = [[NSAlert alloc] init];
		
		[alert     setMessageText:NSLocalizedString(@"MissingPiecesMessage", nil)];
		[alert setInformativeText:informativeString];
		[alert addButtonWithTitle:NSLocalizedString(@"OKButtonName", nil)];
		
		[alert runModal];
	}
	
}//end doMissingPiecesCheck:


//========== doMovedPiecesCheck: ===============================================
//
// Purpose:		Searches the current model for any ~Moved parts, and displays a 
//				warning if there are some.
//
//==============================================================================
- (void) doMovedPiecesCheck:(id)sender
{
	PartReport		*partReport			= [PartReport partReportForContainer:[self documentContents]];
	NSArray			*movedParts			= [partReport movedParts];
	int				 buttonReturned		= 0;
	int				 counter			= 0;
	
	if([movedParts count] > 0)
	{
		//Alert! Alert! What should we do?
		NSAlert *alert = [[NSAlert alloc] init];
		
		[alert     setMessageText:NSLocalizedString(@"MovedPiecesMessage", nil)];
		[alert setInformativeText:NSLocalizedString(@"MovedPiecesInformative", nil)];
		[alert addButtonWithTitle:NSLocalizedString(@"OKButtonName", nil)];
		[alert addButtonWithTitle:NSLocalizedString(@"CancelButtonName", nil)];
		
		buttonReturned = [alert runModal];
		
		//They want us to update the ~Moved parts.
		if(buttonReturned == NSAlertFirstButtonReturn)
		{
			for(counter = 0; counter < [movedParts count]; counter++)
			{
				[LDrawUtilities updateNameForMovedPart:[movedParts objectAtIndex:counter]];
			}
			
			//mark document as modified.
			[self updateChangeCount:NSChangeDone];
		}
	}
	
}//end doMovedPiecesCheck:


#pragma mark -
#pragma mark Scope Bar

//========== viewAll: ==========================================================
//
// Purpose:		Turn off Step Display.
//
//==============================================================================
- (IBAction) viewAll:(id)sender
{
	// Call the simple method. This also takes care of button state for us.
	[self setStepDisplay:NO];
	
}//end viewAll:


//========== viewSteps: ========================================================
//
// Purpose:		Turn on Step Display.
//
//==============================================================================
- (IBAction) viewSteps:(id)sender
{
	// Call the simple method. This also takes care of button state for us.
	[self setStepDisplay:YES];

}//end viewSteps:


//========== stepFieldChanged: =================================================
//
// Purpose:		This allows you to type in a specific step and go to it.
//
//==============================================================================
- (IBAction) stepFieldChanged:(id)sender
{
	LDrawMPDModel	*activeModel	= [[self documentContents] activeModel];
	int				numberSteps		= [[activeModel steps] count];
	int				requestedStep	= [sender intValue]; // 1-relative
	int				actualStep		= 0; // 1-relative
	
	// The user's number may have been out of range.
	actualStep = CLAMP(requestedStep, 1, numberSteps);
	
	[self setCurrentStep:(actualStep - 1)]; // convert to 0-relative
	
	// If we had to clamp, that is a user error. Tell him.
	if(actualStep != requestedStep)
		NSBeep();
		
}//end stepFieldChanged:


//========== stepNavigatorClicked: =============================================
//
// Purpose:		The step navigator is a segmented control that presents a back 
//				and forward button. 
//
//==============================================================================
- (IBAction) stepNavigatorClicked:(id)sender
{
	// Back == 0; Forward == 1
	if([sender selectedSegment] == 0)
		[self backOneStep:sender];
	else
		[self advanceOneStep:sender];
	
}//end stepNavigatorClicked:


#pragma mark -
#pragma mark File Menu

//========== exportSteps: ======================================================
//
// Purpose:		Presents a save dialog allowing the user to export his model 
//				as a series of files, one for each progressive step.
//
//==============================================================================
- (IBAction) exportSteps:(id)sender
{
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
	NSFileManager	*fileManager		= [NSFileManager defaultManager];
	NSString		*saveName			= nil;
	NSString		*modelName			= nil;
	NSString		*folderName			= nil;
	NSString		*modelnameFormat	= NSLocalizedString(@"ExportedStepsFolderFormat", nil);
	NSString		*filenameFormat		= NSLocalizedString(@"ExportedStepsFileFormat", nil);
	NSString		*fileString			= nil;
	NSData			*fileOutputData		= nil;
	NSString		*outputName			= nil;
	NSString		*outputPath			= nil;
		
	LDrawFile		*fileCopy			= nil;
	
	int				 modelCounter		= 0;
	int				 counter			= 0;
	
	if(returnCode == NSOKButton)
	{
		fileCopy	= [[self documentContents] copy];
		saveName	= [savePanel filename];
		
		//If we got this far, we need to replace any prexisting file.
		if([fileManager fileExistsAtPath:saveName isDirectory:NULL])
			[fileManager removeFileAtPath:saveName handler:nil];
		
		[fileManager createDirectoryAtPath:saveName attributes:nil];
		
		//Output all the steps for all the submodels.
		for(modelCounter = 0; modelCounter < [[[self documentContents] submodels] count]; modelCounter++)
		{
			fileCopy = [[self documentContents] copy];
			
			//Move the target model to the top of the file. That way L3P will know to 
			// render it!
			LDrawMPDModel *currentModel = [[fileCopy submodels] objectAtIndex:modelCounter];
			[currentModel retain];
			[fileCopy removeDirective:currentModel];
			[fileCopy insertDirective:currentModel atIndex:0];
			[fileCopy setActiveModel:currentModel];
			[currentModel release];
			
			//Make a new folder for the model's steps.
			modelName	= [NSString stringWithFormat:modelnameFormat, [currentModel modelName]];
			folderName	= [saveName stringByAppendingPathComponent:modelName];
			
			[fileManager createDirectoryAtPath:folderName attributes:nil];
			
			//Write out each step!
			for(counter = [[currentModel steps] count]-1; counter >= 0; counter--)
			{
				fileString		= [fileCopy write];
				fileOutputData	= [fileString dataUsingEncoding:NSUTF8StringEncoding];
				
				outputName = [NSString stringWithFormat: filenameFormat, 
														 [currentModel modelName],
														 counter+1 ];
				outputPath = [folderName stringByAppendingPathComponent:outputName];
				[fileManager createFileAtPath:outputPath
									 contents:fileOutputData
								   attributes:nil ];
				
				//Remove the step we just wrote, so that the next cycle won't 
				// include it. We can safely do this because we are working with 
				// a copy of the file!
				[currentModel removeDirectiveAtIndex:counter];
			}
			
					
			[fileCopy release];
			
		}
		
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
- (IBAction) delete:(id)sender
{
	NSArray			*selectedObjects	= [self selectedObjects];
	LDrawDirective	*currentObject		= nil;
	int				 counter;
	
	//We'll just try to delete everything. Count backwards so that if a 
	// deletion fails, it's the thing at the top rather than the bottom that 
	// remains.
	for(counter = [selectedObjects count]-1; counter >= 0; counter--)
	{
		currentObject = [selectedObjects objectAtIndex:counter];
		if([self canDeleteDirective:currentObject displayErrors:YES] == YES)
		{	//above method will display an error if the directive can't be deleted.
			[self deleteDirective:currentObject];
		}
	}
	
	[fileContentsOutline deselectAll:sender];
	[[self documentContents] setNeedsDisplay];
}//end delete:


//========== selectAll: ========================================================
//
// Purpose:		Selects all the visible LDraw elements in the active model. This 
//				does not select the steps or model--only the contained elements 
//				themselves. Hidden elements are also ignored.
//
//==============================================================================
- (IBAction) selectAll:(id)sender
{
	LDrawModel	*activeModel	= [[self documentContents] activeModel];
	NSArray		*elements		= [activeModel allEnclosedElements];
	id			 currentElement	= nil;
	int			 counter		= 0;
	
	//Deselect all first.
	[self selectDirective:nil byExtendingSelection:NO];
	
	//Select everything now.
	for(counter = 0; counter < [elements count]; counter++)
	{
		currentElement = [elements objectAtIndex:counter];
		if(		[currentElement respondsToSelector:@selector(isHidden)] == NO
			||	[currentElement isHidden] == NO)
		{
			[self selectDirective:currentElement byExtendingSelection:YES];
		}
	}
}//end selectAll:


//========== duplicate: ========================================================
//
// Purpose:		Makes a copy of the selected object.
//
//==============================================================================
- (IBAction) duplicate:(id)sender
{
	// To take advantage of all the exceptionally cool copy/paste code we 
	// already have, -duplicate: simply "copies" the selection onto a private 
	// pasteboard then "pastes" it right back in. This avoids destroying the 
	// general pasteboard, but allows us some fabulous code reuse. (In case you 
	// haven't noticed, I'm proud of this!) 
	NSPasteboard	*pasteboard			= [NSPasteboard pasteboardWithName:@"BricksmithDuplicationPboard"];
	NSArray			*selectedObjects	= [self selectedObjects];
	NSUndoManager	*undoManager		= [self undoManager];
	
	[self writeDirectives:selectedObjects
			 toPasteboard:pasteboard];
	[self pasteFromPasteboard:pasteboard];

	[undoManager setActionName:NSLocalizedString(@"UndoDuplicate", nil)];
	
}//end duplicate:


//========== orderFrontMovePanel: ==============================================
//
// Purpose:		Opens the advanced rotation panel that provides fine part 
//				rotation controls.
//
//==============================================================================
- (IBAction) orderFrontMovePanel:(id)sender
{
	MovePanel *panel = [MovePanel movePanel];
	
	[panel makeKeyAndOrderFront:self];

}//end orderFrontMovePanel:


//========== orderFrontRotationPanel: ==========================================
//
// Purpose:		Opens the advanced rotation panel that provides fine part 
//				rotation controls.
//
//==============================================================================
- (IBAction) orderFrontRotationPanel:(id)sender
{
	RotationPanel *panel = [RotationPanel rotationPanel];
	
	[panel makeKeyAndOrderFront:self];

}//end openRotationPanel:


#pragma mark -

//========== quickRotateClicked: ===============================================
//
// Purpose:		One of the quick rotation shortcuts was clicked. Build a 
//				rotation in the requested direction (deduced from the sender's 
//				tag). 
//
//==============================================================================
- (IBAction) quickRotateClicked:(id)sender
{
	menuTagsT	tag			= [sender tag];
	Vector3		rotation	= ZeroPoint3;
	
	switch(tag)
	{
		case rotatePositiveXTag:	rotation = V3Make( 1,  0,  0);	break;
		case rotateNegativeXTag:	rotation = V3Make(-1,  0,  0);	break;
		case rotatePositiveYTag:	rotation = V3Make( 0,  1,  0);	break;
		case rotateNegativeYTag:	rotation = V3Make( 0, -1,  0);	break;
		case rotatePositiveZTag:	rotation = V3Make( 0,  0,  1);	break;
		case rotateNegativeZTag:	rotation = V3Make( 0,  0, -1);	break;
		default:													break;
	}
	[self rotateSelectionAround:rotation];
	
}//end quickRotateClicked:


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
- (IBAction) showInspector:(id)sender
{
	[[LDrawApplication sharedInspector] show:sender];
	
}//end showInspector:


//========== toggleFileContentsDrawer: =========================================
//
// Purpose:		Either open or close the file contents outline.
//
// Notes:		Now that the file contents is part of the main window, this has 
//				gotten quite a bit more complicated. 
//
//==============================================================================
- (IBAction) toggleFileContentsDrawer:(id)sender
{
	NSView	*firstSubview	= [[self->fileContentsSplitView subviews] objectAtIndex:0];
	CGFloat	maxPosition		= 0.0;
	
	// We collapse or un-collapse the split view. The API to do this does not 
	// exist on Tiger. Grr... 
	if([self->fileContentsSplitView respondsToSelector:@selector(setPosition:ofDividerAtIndex:)])
	{
		if([self->fileContentsSplitView isSubviewCollapsed:firstSubview])
		{
			// Un-collapse the view
			maxPosition = [[self->fileContentsSplitView delegate] splitView:self->fileContentsSplitView
													 constrainMinCoordinate:0.0
																ofSubviewAt:0];
																
			[self->fileContentsSplitView setPosition:maxPosition ofDividerAtIndex:0];
		}
		else
		{
			// Collapse the view
			[self->fileContentsSplitView setPosition:0.0 ofDividerAtIndex:0];
		}
	}
	
}//end toggleFileContentsDrawer:


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
- (IBAction) gridGranularityMenuChanged:(id)sender
{
	int					menuTag		= [sender tag];
	gridSpacingModeT	newGridMode	= gridModeFine;;
	
	
	switch(menuTag)
	{
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
	
}//end gridGranularityMenuChanged:


//========== showDimensions: ===================================================
//
// Purpose:		Shows the dimensions window for this model.
//
//==============================================================================
- (IBAction) showDimensions:(id)sender {

	DimensionsPanel *dimensions = nil;
	
	dimensions = [DimensionsPanel dimensionPanelForFile:[self documentContents]];
	
	[NSApp beginSheet:dimensions
	   modalForWindow:[self windowForSheet]
		modalDelegate:self
	   didEndSelector:NULL
		  contextInfo:NULL ];
		  
}//end showDimensions


//========== showPieceCount: ===================================================
//
// Purpose:		Shows the dimensions window for this model.
//
//==============================================================================
- (IBAction) showPieceCount:(id)sender {
	
	PieceCountPanel *pieceCount = nil;
	
	pieceCount = [PieceCountPanel pieceCountPanelForFile:[self documentContents]];
	
	[NSApp beginSheet:pieceCount
	   modalForWindow:[self windowForSheet]
		modalDelegate:self
	   didEndSelector:NULL
		  contextInfo:NULL ];
		  
}//end showPieceCount:


#pragma mark -
#pragma mark View Menu

//========== zoomActual: =======================================================
//
// Purpose:		Zoom to 100%.
//
//==============================================================================
- (IBAction) zoomActual:(id)sender
{
	[mostRecentLDrawView setZoomPercentage:100];
	
}//end zoomActual:


//========== zoomIn: ===========================================================
//
// Purpose:		Enlarge the scale of the current LDraw view.
//
//==============================================================================
- (IBAction) zoomIn:(id)sender
{
	[mostRecentLDrawView zoomIn:sender];
	
}//end zoomIn:


//========== zoomOut: ==========================================================
//
// Purpose:		Shrink the scale of the current LDraw view.
//
//==============================================================================
- (IBAction) zoomOut:(id)sender
{
	[mostRecentLDrawView zoomOut:sender];
	
}//end zoomOut:


//========== viewOrientationSelected: ==========================================
//
// Purpose:		The user has chosen a new viewing angle from a menu.
//				sender is the menu item, whose tag is the viewing angle. We'll 
//				just pass this off to the appropriate view.
//
// Note:		This method will get skipped entirely if an LDrawGLView is the 
//				first responder; the message will instead go directly there 
//				because this method has the same name as the one in LDrawGLView.
//
//==============================================================================
- (IBAction) viewOrientationSelected:(id)sender
{
	[self->mostRecentLDrawView viewOrientationSelected:sender];
	
}//end viewOrientationSelected:


//========== toggleStepDisplay: ================================================
//
// Purpose:		Turns step display (like Lego instructions) on or off for the 
//				active model.
//
//==============================================================================
- (IBAction) toggleStepDisplay:(id)sender
{
	LDrawMPDModel	*activeModel	= [[self documentContents] activeModel];
	BOOL			 stepDisplay	= [activeModel stepDisplay];
	
	if(stepDisplay == NO) //was off; so turn it on.
		[self setStepDisplay:YES];
	else //on; turn it off now
		[self setStepDisplay:NO];
	
}//end toggleStepDisplay:


//========== advanceOneStep: ===================================================
//
// Purpose:		Moves the step display forward one step.
//
//==============================================================================
- (IBAction) advanceOneStep:(id)sender
{
	LDrawMPDModel	*activeModel	= [[self documentContents] activeModel];
	int				currentStep		= [activeModel maximumStepIndexForStepDisplay];
	int				numberSteps		= [[activeModel steps] count];
	
	[self setCurrentStep: (currentStep+1) % numberSteps ];
	
}//end advanceOneStep:


//========== backOneStep: ======================================================
//
// Purpose:		Displays the previous step.
//
//==============================================================================
- (IBAction) backOneStep:(id)sender
{
	LDrawMPDModel	*activeModel	= [[self documentContents] activeModel];
	int				currentStep		= [activeModel maximumStepIndexForStepDisplay];
	int				numberSteps		= [[activeModel steps] count];
	
	// Wrap around?
	if(currentStep == 0)
		currentStep = numberSteps;
	
	[self setCurrentStep: (currentStep-1) % numberSteps ];

}//end backOneStep:


#pragma mark -
#pragma mark Piece Menu

//========== showParts: ========================================================
//
// Purpose:		Un-hides all selected parts.
//
//==============================================================================
- (IBAction) showParts:(id)sender
{
	[self setSelectionToHidden:NO];	//unhide 'em
	
}//end showParts:


//========== hideParts: ========================================================
//
// Purpose:		Hides all selected parts so that they are not drawn.
//
//==============================================================================
- (IBAction) hideParts:(id)sender
{
	[self setSelectionToHidden:YES]; //hide 'em
	
}//end hideParts:


//========== snapSelectionToGrid: ==============================================
//
// Purpose:		Aligns all selected parts to the current grid setting.
//
//==============================================================================
- (void) snapSelectionToGrid:(id)sender
{	
	NSUserDefaults		*userDefaults		= [NSUserDefaults standardUserDefaults];
	NSArray				*selectedObjects	= [self selectedObjects];
	id					 currentObject		= nil;
	float				 gridSpacing		= 0;
	float				 degreesToRotate	= 0;
	int					 counter			= 0;
	TransformComponents	snappedComponents	= IdentityComponents;
	
	//Determine granularity of grid.
	switch([self gridSpacingMode])
	{
		case gridModeFine:
			gridSpacing		= [userDefaults floatForKey:GRID_SPACING_FINE];
			degreesToRotate	= GRID_ROTATION_FINE;	//15 degrees
			break;
		
		case gridModeMedium:
			gridSpacing		= [userDefaults floatForKey:GRID_SPACING_MEDIUM];
			degreesToRotate	= GRID_ROTATION_MEDIUM;	//45 degrees
			break;
		
		case gridModeCoarse:
			gridSpacing		= [userDefaults floatForKey:GRID_SPACING_COARSE];
			degreesToRotate	= GRID_ROTATION_COARSE;	//90 degrees
			break;
	}
	
	//nudge everything that can be rotated. That would be parts and only parts.
	for(counter = 0; counter < [selectedObjects count]; counter++)
	{
		currentObject = [selectedObjects objectAtIndex:counter];
		
		if([currentObject isKindOfClass:[LDrawPart class]])
		{
			snappedComponents = [currentObject 
										componentsSnappedToGrid:gridSpacing
												   minimumAngle:degreesToRotate];
			[self setTransformation:snappedComponents
							forPart:currentObject];
		}
		
	}//end update loop
	
	[[self documentContents] setNeedsDisplay];
}//end snapSelectionToGrid


#pragma mark -
#pragma mark Models Menu

//========== addModelClicked: ==================================================
//
// Purpose:		Create a new model and add it to the current file.
//
//==============================================================================
- (IBAction) addModelClicked:(id)sender
{
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
- (IBAction) addStepClicked:(id)sender
{

	LDrawStep		*newStep		= [LDrawStep emptyStep];

	[self addStep:newStep];
	
}//end addStepClicked:


//========== addPartClicked: ===================================================
//
// Purpose:		Adds a new step to the currently-displayed model. If a part of 
//				the model is already selected, the step will be added after 
//				selection. Otherwise, the step appears at the end of the list.
//
//==============================================================================
- (IBAction) addPartClicked:(id)sender
{	
	NSUserDefaults		*userDefaults		= [NSUserDefaults standardUserDefaults];
	PartBrowserStyleT	 partBrowserStyle	= [userDefaults integerForKey:PART_BROWSER_STYLE_KEY];
	PartBrowserPanel	*partBrowserPanel	= nil;
	
	switch(partBrowserStyle)
	{
		case PartBrowserShowAsDrawer:
			
			//is it open?
			if([self->partBrowserDrawer state] == NSDrawerOpenState)
				[self->partsBrowser addPartClicked:sender];
			else
				[self->partBrowserDrawer open];
			
			break;
			
		case PartBrowserShowAsPanel:
			
			partBrowserPanel = [PartBrowserPanel sharedPartBrowserPanel];
			
			//is it open and foremost?
			if([partBrowserPanel isKeyWindow] == YES)
				[[partBrowserPanel partBrowser] addPartClicked:sender];
			else
				[partBrowserPanel makeKeyAndOrderFront:sender];
			
			break;
	} 
	
}//end addPartClicked:


//========== addSubmodelReferenceClicked: ======================================
//
// Purpose:		Add a reference in the current model to the MPD submodel 
//				selected.
//
// Parameters:	sender: the NSMenuItem representing the submodel to add.
//
//==============================================================================
- (void) addSubmodelReferenceClicked:(id)sender
{
	NSString		*partName		= nil;
	
	partName = [[sender representedObject] modelName];
	
	//We got a part; let's add it!
	if(partName != nil){
		[self addPartNamed:partName];
	}
}//end addSubmodelReferenceClicked:


//========== addLineClicked: ===================================================
//
// Purpose:		Adds a new line primitive to the currently-displayed model.
//
//==============================================================================
- (IBAction) addLineClicked:(id)sender
{
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
- (IBAction) addQuadrilateralClicked:(id)sender
{
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
- (IBAction) addConditionalClicked:(id)sender
{
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
- (IBAction) addCommentClicked:(id)sender
{
	LDrawComment	*newComment		= [[[LDrawComment alloc] init] autorelease];
	NSUndoManager	*undoManager	= [self undoManager];
	
	[self addStepComponent:newComment];
	
	[undoManager setActionName:NSLocalizedString(@"UndoAddComment", nil)];
}//end addCommentClicked:


//========== addRawCommandClicked: =============================================
//
// Purpose:		Adds a new comment primitive to the currently-displayed model.
//
//==============================================================================
- (IBAction) addRawCommandClicked:(id)sender
{
	LDrawMetaCommand	*newCommand		= [[[LDrawMetaCommand alloc] init] autorelease];
	NSUndoManager		*undoManager	= [self undoManager];
	
	[self addStepComponent:newCommand];
	
	[undoManager setActionName:NSLocalizedString(@"UndoAddMetaCommand", nil)];
}//end addCommentClicked:


//========== addMinifigure: ====================================================
//
// Purpose:		Create a new minifigure with the amazing Minifigure Generator 
//				and add it to the model.
//
//==============================================================================
- (void) addMinifigure:(id)sender
{
	MinifigureDialogController	*minifigDialog	= [MinifigureDialogController new];
	int							 result			= NSCancelButton;
	
	result = [minifigDialog runModal];
	if(result == NSOKButton)
		[self addModel:[minifigDialog minifigure]];
	
}//end addMinifigure:


//========== modelSelected: ====================================================
//
// Purpose:		A new model from the Models menu was chosen to be the active 
//				model.
//
// Parameters:	sender: an NSMenuItem representing the model to make active.
//
//==============================================================================
- (void) modelSelected:(id)sender
{
	LDrawMPDModel *newActiveModel = [sender representedObject];
	[[self documentContents] setActiveModel:newActiveModel];
	
	//A notification will be generated that updates the models menu.
	
}//end modelSelected



#pragma mark -
#pragma mark UNDOABLE ACTIVITIES
#pragma mark -
//these are *low-level* calls which provide support for the Undo architecture.
// all of these are wrapped by high-level calls, which are all application-level 
// code should ever need to use.


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
			   
}//end addDirective:toParent:


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
	
	[[self documentContents] lockForEditing];
	{
		[[undoManager prepareWithInvocationTarget:self]
			deleteDirective:newDirective ];
		
		[parent insertDirective:newDirective atIndex:index];
	}
	[[self documentContents] unlockEditor];
	
	[self updateInspector];
	
}//end addDirective:toParent:atIndex:


//========== deleteDirective: ==================================================
//
// Purpose:		Removes the specified doomedDirective from its enclosing 
//				container.
//
//==============================================================================
- (void) deleteDirective:(LDrawDirective *)doomedDirective
{
	NSUndoManager	*undoManager	= [self undoManager];
	LDrawContainer	*parent			= [doomedDirective enclosingDirective];
	int				 index			= [[parent subdirectives] indexOfObject:doomedDirective];
	
	[[self documentContents] lockForEditing];
	{
		[[undoManager prepareWithInvocationTarget:self]
				addDirective:doomedDirective
					toParent:parent
					 atIndex:index ];
		
		[parent removeDirective:doomedDirective];
		[self updateInspector];
	}
	[[self documentContents] unlockEditor];

}//end deleteDirective:


//========== moveDirective:inDirection: ========================================
//
// Purpose:		Undo-aware call to move the object in the direction indicated. 
//				The vector here should indicate the exact amount to move. It 
//				should be adjusted to the grid mode already).
//
//==============================================================================
- (void) moveDirective:(LDrawDrawableElement *)object
		   inDirection:(Vector3)moveVector
{
	NSUndoManager	*undoManager	= [self undoManager];
	Vector3			 opposite		= {0};
	
	//Prepare the undo.
	
	opposite.x = -(moveVector.x);
	opposite.y = -(moveVector.y);
	opposite.z = -(moveVector.z);
	
	[[self documentContents] lockForEditing];
	{
		[[self documentContents] unlockEditor];
		[[undoManager prepareWithInvocationTarget:self]
				moveDirective: object
				  inDirection: opposite ];
		[undoManager setActionName:NSLocalizedString(@"UndoMove", nil)];
		
		//Do the move.
		[object moveBy:moveVector];
	}
	
	//our part changed; notify!
	[self updateInspector];
	[[NSNotificationCenter defaultCenter]
					postNotificationName:LDrawDirectiveDidChangeNotification
								  object:object];
								  
}//end moveDirective:inDirection:


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
		  byDegrees:(Tuple3)rotationDegrees
		aroundPoint:(Point3)rotationCenter
{

	NSUndoManager	*undoManager		= [self undoManager];
	Tuple3			 oppositeRotation	= V3Negate(rotationDegrees);
	
	[[undoManager prepareWithInvocationTarget:self]
			rotatePart: part
			 byDegrees: oppositeRotation
		   aroundPoint: rotationCenter  ]; //undo: rotate backwards
	[undoManager setActionName:NSLocalizedString(@"UndoRotate", nil)];
	
	
	[[self documentContents] lockForEditing];
	{
		[part rotateByDegrees:rotationDegrees centerPoint:rotationCenter];
	}
	[[self documentContents] unlockEditor];

	
	[self updateInspector];
	[[NSNotificationCenter defaultCenter]
					postNotificationName:LDrawDirectiveDidChangeNotification
								  object:part];
	
} //rotatePart:onAxis:byDegrees:


//========== setElement:toHidden: ==============================================
//
// Purpose:		Undo-aware call to change the visibility attribute of an element.
//
//==============================================================================
- (void) setElement:(LDrawDrawableElement *)element toHidden:(BOOL)hideFlag
{
	NSUndoManager	*undoManager	= [self undoManager];
	NSString		*actionName		= nil;
	
	if(hideFlag == YES)
		actionName = NSLocalizedString(@"UndoHidePart", nil);
	else
		actionName = NSLocalizedString(@"UndoShowPart", nil);
	
	[[self documentContents] lockForEditing];
	{
		[[self documentContents] unlockEditor];
		[[undoManager prepareWithInvocationTarget:self]
			setElement:element
			  toHidden:(!hideFlag) ];
		[undoManager setActionName:actionName];
		
		[element setHidden:hideFlag];
	}
	[[NSNotificationCenter defaultCenter]
					postNotificationName:LDrawDirectiveDidChangeNotification
								  object:element];
}//end setElement:toHidden:


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
	
	[[self documentContents] lockForEditing];
	{
		[object setLDrawColor:newColor];
	}
	[[self documentContents] unlockEditor];
	[self updateInspector];
	[[NSNotificationCenter defaultCenter]
					postNotificationName:LDrawDirectiveDidChangeNotification
								  object:object];
}//end setObject:toColor:


//========== setTransformation:forPart: ========================================
//
// Purpose:		Undo-aware call to set the entire transformation for a part. 
//				This is an important step in snapping a part to the grid.
//
//==============================================================================
- (void) setTransformation:(TransformComponents)newComponents
				   forPart:(LDrawPart *)part
{
	NSUndoManager		*undoManager		= [self undoManager];
	TransformComponents	 currentComponents	= [part transformComponents];
	
	[[self documentContents] lockForEditing];
	{
		[[self documentContents] unlockEditor];
		[part setTransformComponents:newComponents];
		
		//Be ready to restore the old components.
		[[undoManager prepareWithInvocationTarget:self]
				setTransformation:currentComponents
						  forPart:part ];
		
		[undoManager setActionName:NSLocalizedString(@"UndoSnapToGrid", nil)];
	}
	[self updateInspector];
	
}//end setTransformation:forPart:


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
//========== outlineView:writeItems:toPasteboard: ==============================
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
	
}//end outlineView:writeItems:toPasteboard:


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
	   &&	[[pasteboard types] containsObject:LDrawDirectivePboardType])
	{
		
		//This drag is acceptable. Now figure out the operation.
		if(sourceView == outlineView)
			dragOperation = NSDragOperationMove;
		else
			dragOperation = NSDragOperationCopy;
		
		//---------- Eliminate Illegal Positions -------------------------------
		
		//Read the first object off the pasteboard so we can figure 
		// out where this drop is allowed to happen.
		NSArray			*objects		= [pasteboard propertyListForType:LDrawDirectivePboardType];
		NSData			*data			= nil;
		id				 currentObject	= nil;
		
		//Unarchive.
		data			= [objects objectAtIndex:0];
		currentObject	= [NSKeyedUnarchiver unarchiveObjectWithData:data];
		
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
	
	// Select the item. Watch out--drops at the very top of the file will be 
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
	
	
	if(sourceView == outlineView)
	{
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
		for(counter = 0; counter < [rowsToDelete count]; counter++)
		{
			doomedIndex = [[rowsToDelete objectAtIndex:counter] intValue];
			objectToDelete = [outlineView itemAtRow:doomedIndex];
			[doomedObjects addObject:objectToDelete];
		}
	}
	
	
	//     Do The Move.
	//
	// Due to more lack of foresight, we need to include a special flag if the 
	// move is happening at position 0 in newParent. The trouble is: in a normal 
	// copy/paste or new-part operation, we want to insert the new element at 
	// the *bottom* of the list in the absence of a different selection. But in 
	// a drag, we want to add the  items in the explicit position indicated by 
	// the user. If that position happens to be at the top of the list, then we 
	// are in a pickle. So we set up the insertionMode flag to change the 
	// behavior of the -addDirective:toParent: method just for this drag. 
	self->insertionMode = insertAtBeginning;
	pastedObjects = [self pasteFromPasteboard:pasteboard];
	self->insertionMode = insertAtEnd; //revert back to normal behavior.
	
	
	if(sourceView == outlineView)
	{
		//Now that we've inserted the new objects, we need to delete the 
		// old ones.
		for(counter = 0; counter < [doomedObjects count]; counter++)
			[self deleteDirective:[doomedObjects objectAtIndex:counter]];
		
		[undoManager setActionName:NSLocalizedString(@"UndoReorder", nil)];
	}
	
	//And lastly, select the dragged objects.
	[(LDrawFileOutlineView*)outlineView selectObjects:pastedObjects];

	return YES;
	
}//end outlineView:acceptDrop:item:childIndex:



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
	
}//end outlineView:willDisplayCell:forTableColumn:item:


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
	if(selectedModel != nil)
	{
		// Put the selection on screen (if we need to)
		[[self documentContents] setActiveModel:selectedModel];
		[selectedModel makeStepVisible:selectedStep];
		[self setCurrentStep:[selectedModel maximumStepIndexForStepDisplay]]; // update document UI
	}
	[[self documentContents] setNeedsDisplay];
	
	//See if we just selected a new part; if so, we must remember it.
	if([lastSelectedItem isKindOfClass:[LDrawPart class]])
		[self setLastSelectedPart:lastSelectedItem];

}//end outlineViewSelectionDidChange:


#pragma mark -
#pragma mark LDRAW GL VIEW
#pragma mark -

//**** LDrawGLView ****
//========== LDrawGLView:acceptDrop: ===========================================
//
// Purpose:		The user has deposited some drag-anddrop parts into an 
//			    LDrawGLView. Now they need to be imported into the model. 
//
// Notes:		Just like in -duplicate: and 
//				-outlineView:acceptDrop:item:childIndex:, we appropriate the 
//				pasting architecture to simplify importing the parts.
//
//==============================================================================
- (void) LDrawGLView:(LDrawGLView *)glView
		  acceptDrop:(id < NSDraggingInfo >)info
		  directives:(NSArray *)directives
{
	NSPasteboard		*pasteboard			= [NSPasteboard pasteboardWithName:@"BricksmithDragAndDropPboard"];
	NSUndoManager		*undoManager		= [self undoManager];
	int					 selectionCount		= [self->selectedDirectives count];
	id					 currentDirective	= nil;
	id					 dragPart			= nil;
	Point3				 originalPosition	= ZeroPoint3;
	Point3				 dragPosition		= ZeroPoint3;
	Vector3				 displacement		= ZeroPoint3;
	int					 counter			= 0;
	int					 dropDirectiveIndex	= 0;
	
	// Being dragged within the same document. We must simply apply the 
	// transforms from the dragged parts to the original parts, which have been 
	// hidden during the drag. 
	//
	// Exception: If we have no current selection, it means this was a copy 
	//			  drag. Just paste instead of updating.
	if(		[[info draggingSource] respondsToSelector:@selector(document)]
	   &&	[[info draggingSource] document] == self
	   &&	selectionCount > 0 )
	{
		for(counter = 0; counter < selectionCount; counter++)
		{
			currentDirective	= [self->selectedDirectives objectAtIndex:counter];
			
			if([currentDirective isKindOfClass:[LDrawDrawableElement class]])
			{
				dragPart		= [directives objectAtIndex:dropDirectiveIndex];
				originalPosition= [(LDrawDrawableElement*)currentDirective position];
				dragPosition	= [(LDrawDrawableElement*)dragPart position];
				displacement	= V3Sub(dragPosition, originalPosition);

				[self moveDirective:currentDirective inDirection:displacement];
				[currentDirective setHidden:NO];
				
				dropDirectiveIndex++;
			}
		}
	}
	else
	{
		[self writeDirectives:directives toPasteboard:pasteboard];
		[self pasteFromPasteboard:pasteboard];
		[undoManager setActionName:NSLocalizedString(@"UndoDrop", nil)];
	}
	
}//end LDrawGLView:acceptDrop:


//**** LDrawGLView ****
//========== LDrawGLViewBecameFirstResponder: ==================================
//
// Purpose:		One of our model views just became active, so we need to update 
//				our display to represent that view's characteristics.
//
//==============================================================================
- (void) LDrawGLViewBecameFirstResponder:(LDrawGLView *)glView
{	
	//We used bindings to sync up the ever-in-limbo zoom control. Since 
	// mostRecentLDrawView is a private variable, we manually trigger the 
	// key-value observing updates for it.
	[self willChangeValueForKey:@"mostRecentLDrawView"];
	self->mostRecentLDrawView = glView;
	[self didChangeValueForKey:@"mostRecentLDrawView"];

}//end LDrawGLViewBecameFirstResponder:


//========== LDrawGLViewPartsWereDraggedIntoOblivion: ==========================
//
// Purpose:		The parts which originated the most recent drag operation have 
//				apparently been dragged clear out of the document. Maybe they 
//				went into another document. Maybe they got dragged into empty 
//				space. Whereever they went, they are gone now. 
//
//				The trouble is that when we started dragging them, we just *hid* 
//				them, in anticipation of their landing back within the document. 
//				(It was too much trouble to delete them at the beginning, 
//				because then we might have to reconstruct where they were in the 
//				model hierarchy if they did stay in the same document.) Now that 
//				we know they are really truly gone, we need to delete their 
//				hidden ghosts. 
//
//==============================================================================
- (void) LDrawGLViewPartsWereDraggedIntoOblivion:(LDrawGLView *)glView
{
	int		selectionCount		= [self->selectedDirectives count];
	id		currentDirective	= nil;
	int		counter				= 0;
	
	for(counter = 0; counter < selectionCount; counter++)
	{
		currentDirective	= [self->selectedDirectives objectAtIndex:counter];
		
		if([currentDirective isKindOfClass:[LDrawDrawableElement class]])
		{
			// Even though the directive has been drag-deleted, we still need to 
			// delete it in an undo-friendly way. That means we need to restore 
			// its visibility, since we hid the part when dragging began. 
			[currentDirective setHidden:NO];
		
			[self deleteDirective:currentDirective];
		}
	}
	
}//end LDrawGLViewPartsWereDraggedIntoOblivion:


//========== LDrawGLViewPreferredPartTransform: ================================
//
// Purpose:		Returns the part transform which would be nice applied to new 
//			    parts. This is used during Drag-and-Drop to unpack directives 
//			    and show them in the right place. 
//
//==============================================================================
- (TransformComponents) LDrawGLViewPreferredPartTransform:(LDrawGLView *)glView
{
	TransformComponents	components	 = IdentityComponents;
	
	// If we have a previously-selected part, honor it.
	if(self->lastSelectedPart != nil)
		components = [self->lastSelectedPart transformComponents];
		
	return components;
	
}//end LDrawGLViewPreferredPartTransform:


//**** LDrawGLView ****
//========== LDrawGLView:wantsToSelectDirective:byExtendingSelection: ==========
//
// Purpose:		The given LDrawView has decided some directive should be 
//				selected, probably because the user clicked on it.
//				Pass nil to mean deselect.
//
//==============================================================================
- (void)	LDrawGLView:(LDrawGLView *)glView
 wantsToSelectDirective:(LDrawDirective *)directiveToSelect
   byExtendingSelection:(BOOL) shouldExtend
{
	[self selectDirective:directiveToSelect byExtendingSelection:shouldExtend];
	
}//end LDrawGLView:wantsToSelectDirective:byExtendingSelection:


//========== LDrawGLView:writeDirectivesToPasteboard:asCopy: ===================
//
// Purpose:		Begin a drag-and-drop part insertion initiated in the directive 
//				view. 
//
// Notes:		The parts you see being dragged around are always copies of the 
//				originals. When we aren't actually doing a copy drag, we just 
//				hide the originals. At the end of the drag, we update the 
//				originals with the new dragged positions, unhide them, and 
//				discard the stuff on the pasteboard. This frees us from having 
//				to remember what step each dragged element belonged to. 
//
//==============================================================================
- (BOOL)         LDrawGLView:(LDrawGLView *)glView
 writeDirectivesToPasteboard:(NSPasteboard *)pasteboard
					  asCopy:(BOOL)copyFlag
{
	int				 selectionCount		= [self->selectedDirectives count];
	NSMutableArray	*archivedParts		= [NSMutableArray array];
	id				 currentDirective	= nil;
	NSData			*partData			= nil;
	int				 counter			= 0;
	BOOL			 success			= NO;
	
	// Archive selected moveable directives.
	for(counter = 0; counter < selectionCount; counter++)
	{
		currentDirective = [self->selectedDirectives objectAtIndex:counter];
		
		if([currentDirective isKindOfClass:[LDrawDrawableElement class]])
		{
			partData	= [NSKeyedArchiver archivedDataWithRootObject:currentDirective];
			[archivedParts addObject:partData];
			
			if(copyFlag == NO)
			{
				// Not copying; we want the dragging instance to be the only 
				// visual manifestation of this part as it moves. 
				[currentDirective setHidden:YES];
			}
		}
	}
	
	// If copying, DESELECT all current directives as a visual indicator that 
	// the originals will stay put. 
	if(copyFlag == YES)
		[self selectDirective:nil byExtendingSelection:YES];
	
	// Set up pasteboard
	if([archivedParts count] > 0)
	{
		[pasteboard declareTypes:[NSArray arrayWithObject:LDrawDraggingPboardType] owner:self];
		[pasteboard setPropertyList:archivedParts forType:LDrawDraggingPboardType];
		
		success = YES;
	}

	return success;
	
}//end LDrawGLView:writeDirectivesToPasteboard:asCopy:


#pragma mark -
#pragma mark SPLIT VIEW
#pragma mark -

//**** NSSplitView ****
//========== splitView:canCollapseSubview: =====================================
//
// Purpose:		Collapsing is good if we don't like this multipane view deal.
//
//==============================================================================
- (BOOL)splitView:(NSSplitView *)sender canCollapseSubview:(NSView *)subview
{
	return YES;
	
}//end splitView:canCollapseSubview:


//**** NSSplitView ****
//========== splitView:shouldCollapseSubview:forDoubleClickOnDividerAtIndex: ===
//
// Purpose:		Allow split views to collapse when their divider is 
//				double-clicked. 
//
//==============================================================================
- (BOOL)				splitView:(NSSplitView *)splitView
			shouldCollapseSubview:(NSView *)subview
	forDoubleClickOnDividerAtIndex:(NSInteger)dividerIndex
{
	return YES;
	
}//end splitView:shouldCollapseSubview:forDoubleClickOnDividerAtIndex:


//**** NSSplitView ****
//========== splitView:constrainMinCoordinate:ofSubviewAt: =====================
//
// Purpose:		Allow the file Contents split view to collapse by giving it a 
//				minimum size. 
//
//==============================================================================
- (CGFloat)   splitView:(NSSplitView *)sender
 constrainMinCoordinate:(CGFloat)proposedMin
			ofSubviewAt:(NSInteger)offset
{
	CGFloat	actualMin	= 0.0;

	if(		sender == self->fileContentsSplitView
	   &&	offset == 0 )
	{
		actualMin = 100; // only return a collapsible minimum for the file contents
	}
	else
		actualMin = proposedMin;
	
	return actualMin;
	
}//end splitView:constrainMinCoordinate:ofSubviewAt:


//**** NSSplitView ****
//========== splitView:constrainMaxCoordinate:ofSubviewAt: =====================
//
// Purpose:		Allow the graphics detail view to collapse by defining a maximum 
//				extent for the the main graphic view. (It's counter-intuitive!)
//
//==============================================================================
- (CGFloat)   splitView:(NSSplitView *)sender
 constrainMaxCoordinate:(CGFloat)proposedMax
			ofSubviewAt:(NSInteger)offset
{
	CGFloat	actualMax	= 0.0;
	
	// In order to allow the detail column to collapse, we have to do something 
	// strange: specify a maximum position for the main graphic view pane. When 
	// the divider is dragged more than halfway beyond that maximum point, the 
	// detail column (view index 1) automatically collapses. Weird...
	if(		sender == self->horizontalSplitView
		&&	offset == 0 ) // yes, that offset is correct. This method is NEVER called with offset == 1.
	{
		actualMax = NSMaxX([sender frame]) - 80; // min size of 80 for the detail column
	}
	else
		actualMax = proposedMax;
	
	return actualMax;
	
}//end splitView:constrainMinCoordinate:ofSubviewAt:


//**** NSSplitView ****
//========== splitView:resizeSubviewsWithOldSize: ==============================
//
// Purpose:		Do yucky MANUAL resizing of the split view subviews.
//
//				We use this method to make sure that the size of the File 
//				Contents sidebar remains CONSTANT while the window is being 
//				resized. This is how all Apple applications with sidebars 
//				behave, and it is good. 
//
//==============================================================================
- (void)splitView:(NSSplitView *)sender resizeSubviewsWithOldSize:(NSSize)oldSize
{
	// Make sure the width of the File Contents column remains constant during 
	// live window resize. 
	if(		sender == self->fileContentsSplitView
		&&	[[[sender window] contentView] inLiveResize] == YES )
	{
		NSView	*fileContentsPane	= [[sender subviews] objectAtIndex:0];
		NSView	*graphicPane		= [[sender subviews] objectAtIndex:1];
		NSSize	totalSize			= [sender frame].size;
		NSSize	graphicPaneSize		= [graphicPane frame].size;
		
		// The graphic pane absorbs ALL width changes.
		graphicPaneSize.width		=	totalSize.width 
									 -	[sender dividerThickness]
									 -	NSWidth([fileContentsPane frame]);
		
		[graphicPane setFrameSize:graphicPaneSize];
	}
	
	// Make sure the width of the OpenGL detail views column remains constant 
	// during live window resize. 
	if(		sender == self->horizontalSplitView
		&&	[[[sender window] contentView] inLiveResize] == YES )
	{
		NSView	*mainViewPane		= [[sender subviews] objectAtIndex:0];
		NSView	*detailViewsPane	= [[sender subviews] objectAtIndex:1];
		NSSize	totalSize			= [sender frame].size;
		NSSize	mainViewPaneSize	= [mainViewPane frame].size;
		
		// The graphic pane absorbs ALL width changes.
		mainViewPaneSize.width		=	totalSize.width 
									 -	[sender dividerThickness]
									 -	NSWidth([detailViewsPane frame]);
		
		[mainViewPane setFrameSize:mainViewPaneSize];
	}
	
	// Allow the split view to finish normal calculations. For the File Contents 
	// split view, this does height resizing for us. For all other split views, 
	// it just does behavior as normal. 
	[sender adjustSubviews];
	
}//end splitView:resizeSubviewsWithOldSize:


//**** NSSplitView ****
//========== splitViewWillResizeSubviews: ======================================
//
// Purpose:		A splitview is about to resize. Since we are displaying OpenGL 
//				in our split-view, we have to do some special graphics flushing.
//
//==============================================================================
- (void)splitViewWillResizeSubviews:(NSNotification *)notification
{
	//Quoting Apple's comments in its GLChildWindow sample code:
	//
	// Resizing the [OpenGL-bearing] split view causes some flicker.  So, as 
	// soon as we know the resize is going to happen we use a Carbon call to 
	// disable screen updates.
	//
	// Later when the parent window finally flushes we re-enable updates
	// so that everything hits the screen at once.
		
//	[[self foremostWindow] disableScreenUpdatesUntilFlush];
	
}//end splitViewWillResizeSubviews:


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
	[self addModelsToMenus];
	
	[self setLastSelectedPart:nil];
	
}//end activeModelDidChange:


//**** NSDrawer ****
//========== drawerWillOpen: ===================================================
//
// Purpose:		The Parts Browser drawer is opening.
//
//==============================================================================
- (void)drawerWillOpen:(NSNotification *)notification
{
	if([notification object] == self->partBrowserDrawer)
	{
		// We have a problem. When the main window is resized while the drawer is 
		// closed, the OpenGLView moves, but the OpenGL drawing region doesn't! To 
		// fix this problem, we need to adjust the drawer's size while it is open; 
		// that causes the OpenGL to synchronize itself properly. 
		//
		// This doesn't feel like the right solution to this problem, but it works.
		// Also listed are some other things I tried that didn't work.
		
		//Works, but animation is very chunky. (better than adjusting the window, though)
		NSSize contentSize = [partBrowserDrawer contentSize];
		
		contentSize.height += 1;
		[partBrowserDrawer setContentSize:contentSize];
		contentSize.height -= 1;
		[partBrowserDrawer setContentSize:contentSize];

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
}//end drawerWillOpen:


//========== partChanged: ======================================================
//
// Purpose:		Somewhere, somehow, a part (or some other LDrawDirective) was 
//				changed. There is some possibility that our data could be stale 
//				now. 
//
//==============================================================================
- (void) partChanged:(NSNotification *)notification
{
	LDrawDirective *changedDirective = [notification object];
	
	if([[changedDirective ancestors] containsObject:[self documentContents]])
	{
		[[self documentContents] setNeedsDisplay];
		[fileContentsOutline reloadData];
		
		//Model menu needs to change if:
		//	*model list changes (in the file)
		//	*model name changes (in the model)
		if(		[[notification object] isKindOfClass:[LDrawFile class]]
			||	[[notification object] isKindOfClass:[LDrawModel class]])
		{
			[self addModelsToMenus];
		}
		// If a step changed and we're in step display, we need to reset the 
		// step's viewing angle. 
		else if(	[[notification object] isKindOfClass:[LDrawStep class]]
				&&	[[[self documentContents] activeModel] stepDisplay] == YES)
		{
			[self updateViewingAngleToMatchStep];
		}
	}
}//end partChanged:


//========== syntaxColorChanged: ===============================================
//
// Purpose:		The preferences have been updated; we need to refresh our data 
//				display.
//
//==============================================================================
- (void) syntaxColorChanged:(NSNotification *)notification
{
	[fileContentsOutline reloadData];
	
}//end syntaxColorChanged:


//**** NSWindow ****
//========== windowDidBecomeMain: ==============================================
//
// Purpose:		The window has come to the foreground.
//
//==============================================================================
- (void) windowDidBecomeMain:(NSNotification *)aNotification
{
	[self updateInspector];
	
	[self addModelsToMenus];
	
}//end windowDidBecomeMain:


//**** NSWindow ****
//========== windowWillClose: ==================================================
//
// Purpose:		The window is about to close; let's save some state info.
//
//==============================================================================
- (void)windowWillClose:(NSNotification *)notification
{
	NSUserDefaults	*userDefaults	= [NSUserDefaults standardUserDefaults];
	NSWindow		*window			= [notification object];
	
	[userDefaults setInteger:[partBrowserDrawer state]	forKey:PART_BROWSER_DRAWER_STATE];
	
	[userDefaults setObject:NSStringFromSize([window frame].size) forKey:DOCUMENT_WINDOW_SIZE];
	[userDefaults synchronize]; //because we may be quitting, we have to force this here.
	
	//Un-inspect everything
	[[LDrawApplication sharedInspector] inspectObjects:nil];

	//Bug: if this document isn't the foremost window, this will botch up the menu!
	// remember, we can close windows in the background.
	if([window isMainWindow] == YES){
		[self clearModelMenus];
	}
	
	[self->bindingsController setContent:nil];
	
}//end windowWillClose:


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
- (BOOL) validateMenuItem:(NSMenuItem *)menuItem
{
	int				 tag			= [menuItem tag];
	NSArray			*selectedItems	= [self selectedObjects];
	LDrawPart		*selectedPart	= [self selectedPart];
	NSPasteboard	*pasteboard		= [NSPasteboard generalPasteboard];
	LDrawMPDModel	*activeModel	= [[self documentContents] activeModel];
	BOOL			 enable			= NO;
	
	switch(tag)
	{

		////////////////////////////////////////
		//
		// Edit Menu
		//
		////////////////////////////////////////

		case cutMenuTag:
		case copyMenuTag:
		case deleteMenuTag:
		case duplicateMenuTag:
		case rotatePositiveXTag:
		case rotateNegativeXTag:
		case rotatePositiveYTag:
		case rotateNegativeYTag:
		case rotatePositiveZTag:
		case rotateNegativeZTag:
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
		
		
		////////////////////////////////////////
		//
		// Piece Menu
		//
		////////////////////////////////////////
			
		case hidePieceMenuTag:
			enable = [self elementsAreSelectedOfVisibility:YES]; //there are visible parts to hide.
			break;
			
		case showPieceMenuTag:
			enable = [self elementsAreSelectedOfVisibility:NO]; //there are invisible parts to show.
			break;
			
		case snapToGridMenuTag:
			enable = (selectedPart != nil);
			break;
		
				
		////////////////////////////////////////
		//
		// Model Menu
		//
		////////////////////////////////////////
		
		case submodelReferenceMenuTag:
			//we can't insert a reference to the active model into itself.
			// That would be an inifinite loop.
			enable = (activeModel != [menuItem representedObject]);
			break;
		
		
		////////////////////////////////////////
		//
		// Something else.
		//
		////////////////////////////////////////
		
		default:
			//We are an NSDocument; it has its own validator to track certain 
			// items.
			enable = [super validateMenuItem:menuItem];
			break;
	}
	
	return enable;
	
}//end validateMenuItem:


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
	
}//end validateToolbarItem:


#pragma mark -

//========== addModelsToMenus ==================================================
//
// Purpose:		Creates a menu used to switch the active model. A list of all 
//				the models in the document is inserted into the Models menu in 
//				the application's menu bar; the active model gets a check next 
//				to it.
//
//				We also regenerate the Insert Reference submenu (for inserting 
//				MPD submodels as parts in a different model). They require 
//				additional validation which occurs in validateMenuItem.
//
//==============================================================================
- (void) addModelsToMenus
{
	NSMenu			*mainMenu			= [NSApp mainMenu];
	NSMenu			*modelMenu			= [[mainMenu itemWithTag:modelsMenuTag] submenu];
	NSMenu			*referenceMenu		= [[modelMenu itemWithTag:insertReferenceMenuTag] submenu];
	int				 separatorIndex		= [modelMenu indexOfItemWithTag:modelsSeparatorMenuTag];
	NSMenuItem		*modelItem			= nil;
	NSMenuItem		*referenceItem		= nil;
	NSArray			*models				= [[self documentContents] submodels];
	LDrawMPDModel	*currentModel		= nil;
	NSString		*modelDescription	= nil;
	int				 counter			= 0;
	
	[self clearModelMenus];
	
	//Create menu items for each model.
	for(counter = 0; counter < [models count]; counter++)
	{
		currentModel		= [models objectAtIndex:counter];
		modelDescription	= [currentModel browsingDescription];
		
		//
		// Active Model menu items
		//
		modelItem = [[[NSMenuItem alloc] init] autorelease];
		[modelItem setTitle:modelDescription];
		[modelItem setRepresentedObject:currentModel];
		[modelItem setTarget:self];
		[modelItem setAction:@selector(modelSelected:)];
		
		//
		// MPD reference menu items
		//
		referenceItem = [[[NSMenuItem alloc] init] autorelease];
		[referenceItem setTitle:modelDescription];
		[referenceItem setRepresentedObject:currentModel];
		//We set the same tag for all items in the reference menu.
		// Validation will distinguish them with their represented objects.
		[referenceItem setTag:submodelReferenceMenuTag];
		[referenceItem setTarget:self];
		[referenceItem setAction:@selector(addSubmodelReferenceClicked:)];
		
		//
		// Insert the new item at the end.
		//
		[modelMenu insertItem:modelItem atIndex:separatorIndex+counter+1];
		[referenceMenu addItem:referenceItem];
		[[self->submodelPopUpMenu menu] addItem:[[modelItem copy] autorelease]];
		
		//
		// Set (or re-set) the selected state
		//
		if([[self documentContents] activeModel] == currentModel)
		{
			[modelItem setState:NSOnState];
			[self->submodelPopUpMenu selectItemAtIndex:counter];
		}
	}
	
}//end addModelsToMenus


//========== clearModelMenus ===================================================
//
// Purpose:		Removes all submodels from the menus. There are two places we 
//				track the submodels: in the Model menu (for selecting the active 
//				model, and in the references submenu (for inserting submodels as 
//				parts).
//
//==============================================================================
- (void) clearModelMenus
{
	NSMenu			*mainMenu		= [NSApp mainMenu];
	NSMenu			*modelMenu		= [[mainMenu itemWithTag:modelsMenuTag] submenu];
	NSMenu			*referenceMenu	= [[modelMenu itemWithTag:insertReferenceMenuTag] submenu];
	int				 separatorIndex	= [modelMenu indexOfItemWithTag:modelsSeparatorMenuTag];
	int				 counter		= 0;
	
	//Kill all model menu items.
	for(counter = [modelMenu numberOfItems]-1; counter > separatorIndex; counter--)
		[modelMenu removeItemAtIndex: counter];
	
	for(counter = [referenceMenu numberOfItems]-1; counter >= 0; counter--)
		[referenceMenu removeItemAtIndex:counter];
		
	[self->submodelPopUpMenu removeAllItems];
	
}//end clearModelMenus


#pragma mark -
#pragma mark UTILITIES
#pragma mark -

//========== addModel: =========================================================
//
// Purpose:		Add newModel to the current file.
//
// Notes:		Duplicate model names are verboten, so if newModel's name 
//				matches an existing model name, an approriate "copy X" will be 
//				appended automatically. 
//
//				There is a bug here in that if several models having references 
//				to one another are pasted at once into a file with name 
//				conflicts, the file reference structure of the pasted models 
//				will point to the wrong names once this method does its renaming 
//				magic. To this I respond, "don't do that."
//
//==============================================================================
- (void) addModel:(LDrawMPDModel *)newModel
{
	NSString		*proposedModelName	= [newModel modelName];
	LDrawModel		*selectedModel		= [self selectedModel];
	NSUndoManager	*undoManager		= [self undoManager];
	int				indexOfModel		= 0;
	int				rowForItem			= 0;
	
	// Derive a non-duplicating name for this new model
	while([[self documentContents] modelWithName:proposedModelName] != nil)
	{
		proposedModelName = [StringUtilities nextCopyPathForFilePath:proposedModelName];
	}
	[newModel setModelName:proposedModelName];
	
	
	// Add directly after the currently-selected model?
	if(selectedModel != nil)
	{
		indexOfModel = [[self documentContents] indexOfDirective:selectedModel];
		[self addDirective:newModel
				  toParent:[self documentContents]
				   atIndex:indexOfModel+1 ];
	}
	// Add to the end of the model list.
	else
		[self addDirective:newModel
				  toParent:[self documentContents] ];
	
	//Select the new model.
	[fileContentsOutline expandItem:newModel];
	rowForItem = [fileContentsOutline rowForItem:newModel];
	[fileContentsOutline selectRowIndexes:[NSIndexSet indexSetWithIndex:rowForItem]
					 byExtendingSelection:NO];
	
	[undoManager setActionName:NSLocalizedString(@"UndoAddModel", nil)];
	
}//end addModel:


//========== addStep: ==========================================================
//
// Purpose:		Adds newStep to the currently-displayed model. If a part of 
//				the model is already selected, the step will be added after 
//				selection. Otherwise, the step appears at the end of the list.
//
//==============================================================================
- (void) addStep:(LDrawStep *)newStep
{
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
	
}//end addStep:


//========== addPartNamed: =====================================================
//
// Purpose:		Adds a part with the given name to the current step in the 
//				currently-displayed model.
//
//==============================================================================
- (void) addPartNamed:(NSString *)partName
{
	LDrawPart			*newPart		= [[[LDrawPart alloc] init] autorelease];
	NSUndoManager		*undoManager	= [self undoManager];
	LDrawColorT			 selectedColor	= [[LDrawColorPanel sharedColorPanel] LDrawColor];
	TransformComponents	 transformation	= IdentityComponents;
	//We got a part; let's add it!
	if(partName != nil)
	{
		//Set up the part attributes
		[newPart setLDrawColor:selectedColor];
		[newPart setDisplayName:partName];
		
		if(self->lastSelectedPart != nil)
		{
			// Collect the transformation from the previous part and apply it to 
			// the new one. 
			transformation = [lastSelectedPart transformComponents];
			[newPart setTransformComponents:transformation];
		}
		
		[self addStepComponent:newPart];
		
		[undoManager setActionName:NSLocalizedString(@"UndoAddPart", nil)];
		[[self documentContents] setNeedsDisplay];
	}
}//end addPartNamed:


//========== addStepComponent: =================================================
//
// Purpose:		Adds newDirective to the bottom of the current step, or after 
//				the currently-selected element in the step if there is one.
//
// Parameters:	newDirective: a directive which can be added to a step. These 
//						include parts, geometric primitives, and comments.
//
//==============================================================================
- (void) addStepComponent:(LDrawDirective *)newDirective
{
	LDrawDirective	*selectedComponent	= [self selectedStepComponent];
	LDrawStep		*selectedStep		= [self selectedStep];
	LDrawMPDModel	*selectedModel		= [self selectedModel];
	int				 indexOfElement		= 0;
	int				 rowForItem			= 0;
	
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
	{
		[self addDirective:newDirective
				  toParent:selectedStep ];
	}
	//Otherwise, we add the new element right after the selected element.
	else
	{
		indexOfElement = [selectedStep indexOfDirective:selectedComponent];
		[self addDirective:newDirective
				  toParent:selectedStep
				   atIndex:indexOfElement+1 ];
	}

	// Show the new element.
	[fileContentsOutline expandItem:selectedModel];
	[fileContentsOutline expandItem:selectedStep];
	
	// Select it too.
	rowForItem = [fileContentsOutline rowForItem:newDirective];
	[fileContentsOutline selectRowIndexes:[NSIndexSet indexSetWithIndex:rowForItem]
					 byExtendingSelection:NO];
					 
	// Allow us to immediately use the keyboard to move the new part.
	[[self foremostWindow] makeFirstResponder:mostRecentLDrawView];
	
}//end addStepComponent:


#pragma mark -

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


//========== elementsAreSelectedOfVisibility: ==================================
//
// Purpose:		Returns YES if there are elements selected which have the 
//				requested visibility. 
//
//==============================================================================
- (BOOL) elementsAreSelectedOfVisibility:(BOOL)visibleFlag
{
	NSArray			*selectedObjects	= [self selectedObjects];
	id				 currentObject		= nil;
	int				 counter			= 0;
	BOOL			 invisibleSelected	= NO;
	BOOL			 visibleSelected	= NO;
	
	
	for(counter = 0; counter < [selectedObjects count]; counter++)
	{
		currentObject = [selectedObjects objectAtIndex:counter];
		if([currentObject respondsToSelector:@selector(isHidden)])
		{
			invisibleSelected	= invisibleSelected || [currentObject isHidden];
			visibleSelected		= visibleSelected   || ([currentObject isHidden] == NO);
		}
	}
	
	if(visibleFlag == YES)
		return visibleSelected;
	else
		return invisibleSelected;
		
}//end elementsAreSelectedOfVisibility:


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
	NSNumber				*obliqueness	= [NSNumber numberWithFloat:0.0]; //italicize?
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
	
	else if([item isKindOfClass:[LDrawColor class]])
		colorKey = SYNTAX_COLOR_COLORS_KEY;
	
	else
		colorKey = SYNTAX_COLOR_UNKNOWN_KEY;
	
	//We have the syntax coloring we want.
	syntaxColor = [userDefaults colorForKey:colorKey];
	
	if([item respondsToSelector:@selector(isHidden)])
		if([(id)item isHidden])
			obliqueness = [NSNumber numberWithFloat:0.5];
	
	
	//Assemble the attributes dictionary.
	[attributes setObject:paragraphStyle	forKey:NSParagraphStyleAttributeName];
	[attributes setObject:syntaxColor		forKey:NSForegroundColorAttributeName];
	[attributes setObject:obliqueness		forKey:NSObliquenessAttributeName];
	
	//Create the attributed string.
	styledString = [[NSAttributedString alloc]
							initWithString:representation
								attributes:attributes ];
	
	//Release stuff we created or copied.
	[paragraphStyle release];
	
	return [styledString autorelease];

}//end formatDirective:withStringRepresentation:


//========== loadDataIntoDocumentUI ============================================
//
// Purpose:		Informs the document's user interface widgets about the contents 
//				of the document they are supposed to be representing.
//
//				There are two occasions when this method must be called:
//					1) immediately after the document UI has first been loaded
//						(in windowControllerDidLoadNib:)
//					2) when reverting the document.
//						(in revertToSavedFromFile:ofType:)
//
//==============================================================================
- (void) loadDataIntoDocumentUI {
	
	[self->fileGraphicView		setLDrawDirective:[self documentContents]];
	[self->fileDetailView1		setLDrawDirective:[self documentContents]];
	[self->fileDetailView2		setLDrawDirective:[self documentContents]];
	[self->fileDetailView3		setLDrawDirective:[self documentContents]];
	[self->fileContentsOutline	reloadData];
	
	[self addModelsToMenus];

}//end loadDataIntoDocumentUI


//========== selectedObjects ===================================================
//
// Purpose:		Returns the LDraw objects currently selected in the file.
//
//==============================================================================
- (NSArray *) selectedObjects
{
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
	
}//end selectedObjects


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
- (LDrawMPDModel *) selectedModel
{
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
}//end selectedModel


//========== selectedModel =====================================================
//
// Purpose:		Returns the step that encloses (or is) the current selection, or  
//				nil if there is no step in the selection chain.
//
//==============================================================================
- (LDrawStep *) selectedStep
{
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
}//end selectedStep


//========== selectedStepComponent =============================================
//
// Purpose:		Returns the drawable LDraw element that is currently selected.
//				(e.g., Part, Quadrilateral, Triangle, etc.)
//
//				Returns nil if the selection is not one of these atomic LDraw
//				commands.
//
//==============================================================================
- (LDrawDirective *) selectedStepComponent
{
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
}//end selectedStep


//========== selectedPart ======================================================
//
// Purpose:		Returns the first part that is currently selected, or nil if no 
//				part is selected.
//
//==============================================================================
- (LDrawPart *) selectedPart
{
	NSArray	*selectedObjects	= [self selectedObjects];
	id		 currentObject		= nil;
	int		 counter			= 0;
	
	while(counter < [selectedObjects count])
	{
		currentObject = [selectedObjects objectAtIndex:counter];
		if([currentObject isKindOfClass:[LDrawPart class]])
			break;
		else
			counter++;
	}
	
	//Either we just found one, on we found nothing.
	return currentObject;
}//end 


//========== updateInspector ===================================================
//
// Purpose:		Updates the Inspector to display the currently-selected objects.
//				This should be called in response to any potentially state-
//				changing actions on a directive.
//
//==============================================================================
- (void) updateInspector
{
	NSArray *selectedObjects = [self selectedObjects];
	
	[[LDrawApplication sharedInspector] inspectObjects:selectedObjects];
	[[LDrawColorPanel sharedColorPanel] updateSelectionWithObjects:selectedObjects];
	
}//end updateInspector


//========== updateViewingAngleToMatchStep =====================================
//
// Purpose:		Sets the viewing angle of the main viewport to the angle 
//				requested by the current step for Step Display mode. 
//
//==============================================================================
- (void) updateViewingAngleToMatchStep
{
	LDrawMPDModel		*activeModel	= [[self documentContents] activeModel];
	int					requestedStep	= [activeModel maximumStepIndexForStepDisplay];
	Tuple3				viewingAngle	= [activeModel rotationAngleForStepAtIndex:requestedStep];
	ViewOrientationT	viewOrientation	= [LDrawUtilities viewOrientationForAngle:viewingAngle];
	
	// Set the Viewing angle
	if(viewOrientation != ViewOrientation3D)
		[self->fileGraphicView setProjectionMode:ProjectionModeOrthographic];
	else
		[self->fileGraphicView setProjectionMode:ProjectionModePerspective];
	
	[self->fileGraphicView setViewOrientation:viewOrientation];
	[self->fileGraphicView setViewingAngle:viewingAngle];
	
}//end updateViewingAngleToMatchStep


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
	for(counter = 0; counter < [directives count]; counter++)
	{
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
	for(counter = 0; counter < [objectsToCopy count]; counter++)
	{
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
	if([[pasteboard types] containsObject:LDrawDirectivePboardType])
	{
		//Unarchived everything and dump it into our file.
		objects = [pasteboard propertyListForType:LDrawDirectivePboardType];
		for(counter = 0; counter < [objects count]; counter++)
		{
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
// Note:		We DO NOT RELEASE TOP-LEVEL NIB OBJECTS HERE! NSWindowController 
//				does that automagically.
//
//==============================================================================
- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[documentContents	release];
	[lastSelectedPart	release];
	[selectedDirectives	release];

	[super dealloc];
	
}//end dealloc

@end