//==============================================================================
//
// File:		LDrawDocument.h
//
// Purpose:		Document controller for an LDraw document.
//
//				Opens the document and manages its editor and viewer.
//
//  Created by Allen Smith on 2/14/05.
//  Copyright (c) 2005. All rights reserved.
//==============================================================================
#import <Cocoa/Cocoa.h>

#import "LDrawColor.h"
#import "MatrixMath.h"

@class DocumentToolbarController;
@class ExtendedSplitView;
@class LDrawContainer;
@class LDrawDirective;
@class LDrawDrawableElement;
@class LDrawFile;
@class LDrawFileOutlineView;
@class LDrawGLView;
@class LDrawModel;
@class LDrawMPDModel;
@class LDrawStep;
@class LDrawPart;
@class PartBrowserDataSource;

//Where new parts are inserted in the abscence of a peer selection.
typedef enum insertionMode {
	insertAtEnd,
	insertAtBeginning
} insertionModeT;

// How much parts move when you nudge them
// in the viewer.
typedef enum gridSpacingMode { //Keep these 0,1,2,...
	gridModeFine	= 0,	//the segmented control depends on them being such
	gridModeMedium	= 1,	// (not necessary in Tiger, but we want other cats at the party.)
	gridModeCoarse	= 2
} gridSpacingModeT;

@interface LDrawDocument : NSDocument
{
	IBOutlet DocumentToolbarController	*toolbarController;
	IBOutlet NSObjectController			*bindingsController;

	IBOutlet NSDrawer					*partBrowserDrawer;
	IBOutlet NSDrawer					*fileContentsDrawer;
	IBOutlet LDrawFileOutlineView		*fileContentsOutline;
	IBOutlet PartBrowserDataSource		*partsBrowser;
	
	IBOutlet ExtendedSplitView			*horizontalSplitView;
	IBOutlet ExtendedSplitView			*verticalDetailSplitView;
	IBOutlet LDrawGLView				*fileGraphicView;
	IBOutlet LDrawGLView				*fileDetailView1;
	IBOutlet LDrawGLView				*fileDetailView2;
	IBOutlet LDrawGLView				*fileDetailView3;
	
	@private
		LDrawFile		*documentContents;
		LDrawPart		*lastSelectedPart; //the part in the file which was most recently selected in the contents. (retained)
		NSArray			*selectedDirectives; //mirrors the selection of the file contents outline.
		insertionModeT	 insertionMode;
		gridSpacingModeT gridMode;
		LDrawGLView		*mostRecentLDrawView; //file graphic view which most recently had focus. Weak link.
}

//Accessors
- (LDrawFile *) documentContents;
- (NSWindow *)foremostWindow;
- (gridSpacingModeT) gridSpacingMode;
- (void) setDocumentContents:(LDrawFile *)newContents;
- (void) setGridSpacingMode:(gridSpacingModeT)newMode;
- (void) setLastSelectedPart:(LDrawPart *)newPart;

//Actions
- (void) changeLDrawColor:(id)sender;
- (void) nudgeSelectionBy:(Vector3) nudgeVector;
- (void) rotateSelectionAround:(Vector3)rotationAxis;
- (void) selectDirective:(LDrawDirective *)directiveToSelect byExtendingSelection:(BOOL)shouldExtend;
- (void) setSelectionToHidden:(BOOL)hideFlag;
- (void) setZoomPercentage:(float)newPercentage;

// - miscellaneous
- (void) doMissingPiecesCheck:(id)sender;
- (void) doMovedPiecesCheck:(id)sender;

// - File menu
- (IBAction) exportSteps:(id)sender;

// - Edit menu
- (IBAction) copy:(id)sender;
- (IBAction) paste:(id)sender;
- (IBAction) delete:(id)sender;
- (IBAction) duplicate:(id)sender;

// - Tools menu
- (IBAction) showInspector:(id)sender;
- (IBAction) togglePartBrowserDrawer:(id)sender;
- (IBAction) toggleFileContentsDrawer:(id)sender;
- (IBAction) gridGranularityMenuChanged:(id)sender;
- (IBAction) showDimensions:(id)sender;
- (IBAction) showPieceCount:(id)sender;

// - View menu
- (IBAction) zoomActual:(id)sender;
- (IBAction) zoomIn:(id)sender;
- (IBAction) zoomOut:(id)sender;
- (IBAction) toggleStepDisplay:(id)sender;
- (IBAction) advanceOneStep:(id)sender;
- (IBAction) backOneStep:(id)sender;

// - Piece menu
- (IBAction) showParts:(id)sender;
- (IBAction) hideParts:(id)sender;
- (void) snapSelectionToGrid:(id)sender;

// - Models menu
- (IBAction) addModelClicked:(id)sender;
- (IBAction) addStepClicked:(id)sender;
- (IBAction) addPartClicked:(id)sender;
- (void) addSubmodelReferenceClicked:(id)sender;
- (IBAction) addLineClicked:(id)sender;
- (IBAction) addTriangleClicked:(id)sender;
- (IBAction) addQuadrilateralClicked:(id)sender;
- (IBAction) addConditionalClicked:(id)sender;
- (IBAction) addCommentClicked:(id)sender;
- (void) modelSelected:(id)sender;

//Undoable Activities
- (void) addDirective:(LDrawDirective *)newDirective toParent:(LDrawContainer * )parent;
- (void) addDirective:(LDrawDirective *)newDirective toParent:(LDrawContainer * )parent atIndex:(int)index;
- (void) deleteDirective:(LDrawDirective *)doomedDirective;
- (void) moveDirective:(LDrawDrawableElement *)object inDirection:(Vector3)moveVector;
- (void) rotatePart:(LDrawPart *)part aroundPoint:(Point3)rotationCenter onAxis:(Vector3)rotationAxis byDegrees:(float)degreesToRotate;
- (void) setElement:(LDrawDrawableElement *)element toHidden:(BOOL)hideFlag;
- (void) setObject:(id <LDrawColorable> )object toColor:(LDrawColorT)newColor;
- (void) setTransformation:(TransformationComponents) newComponents forPart:(LDrawPart *)part;

//Notifications
- (void)partChanged:(NSNotification *)notification;
- (void)syntaxColorChanged:(NSNotification *)notification;

//Menus
- (void) addModelsToMenu;
- (void) clearModelMenus;

//Utilites
- (void) addModel:(LDrawMPDModel *)newModel;
- (void) addStep:(LDrawStep *)newStep;
- (void) addPartNamed:(NSString *)partName;
- (void) addStepComponent:(LDrawDirective *)newDirective;

- (BOOL) canDeleteDirective:(LDrawDirective *)directive displayErrors:(BOOL)errorFlag;
- (BOOL) elementsAreSelectedOfVisibility:(BOOL)visibleFlag;
- (NSAttributedString *) formatDirective:(LDrawDirective *)item withStringRepresentation:(NSString *)representation;
- (void) loadDataIntoDocumentUI;
- (NSArray *) selectedObjects;
- (LDrawMPDModel *) selectedModel;
- (LDrawStep *) selectedStep;
- (LDrawDirective *) selectedStepComponent;
- (LDrawPart *) selectedPart;
- (void) updateInspector;
- (void) writeDirectives:(NSArray *)directives toPasteboard:(NSPasteboard *)pasteboard;
- (NSArray *) pasteFromPasteboard:(NSPasteboard *) pasteboard;

@end
