//==============================================================================
//
// File:		LDrawGLView.h
//
// Purpose:		Draws an LDrawFile with OpenGL.
//
//  Created by Allen Smith on 4/17/05.
//  Copyright 2005. All rights reserved.
//==============================================================================
#import <Cocoa/Cocoa.h>
#import <OpenGL/OpenGL.h>

#import "ColorLibrary.h"
#import "MatrixMath.h"
#import "ToolPalette.h"

//Forward declarations
@class LDrawDirective;
@class LDrawDocument;

////////////////////////////////////////////////////////////////////////////////
//
//		Types and Constants
//
////////////////////////////////////////////////////////////////////////////////

#define SIMPLIFICATION_THRESHOLD	0.3 //seconds
#define CAMERA_DISTANCE_FACTOR		6.5	//controls perspective; cameraLocation = modelSize * CAMERA_DISTANCE_FACTOR


// Projection Mode
typedef enum
{
	ProjectionModePerspective	= 0,
	ProjectionModeOrthographic	= 1
	
} ProjectionModeT;


// Draw Mode
typedef enum
{
	LDrawGLDrawNormal			= 0,	//full draw
	LDrawGLDrawExtremelyFast	= 1		//bounds only
	
} RotationDrawModeT;


// Viewing Angle
typedef enum
{
	ViewOrientation3D			= 0,
	ViewOrientationFront		= 1,
	ViewOrientationBack			= 2,
	ViewOrientationLeft			= 3,
	ViewOrientationRight		= 4,
	ViewOrientationTop			= 5,
	ViewOrientationBottom		= 6
	
} ViewOrientationT;


////////////////////////////////////////////////////////////////////////////////
//
//		LDrawGLView
//
////////////////////////////////////////////////////////////////////////////////
@interface LDrawGLView : NSOpenGLView <LDrawColorable>
{
	id					 delegate;
	IBOutlet LDrawDocument	*document;			// optional weak link. Enables editing capabilities.
	
	BOOL				 acceptsFirstResponder;	// YES if we can become key
	NSString			*autosaveName;
	LDrawDirective		*fileBeingDrawn;		// Should only be an LDrawFile or LDrawModel.
												// if you want to do anything else, you must 
												// tweak the selection code in LDrawDrawableElement
												// and here in -mouseUp: to handle such cases.
	
	// Drawing Environment
	unsigned			 numberDrawRequests;	// how many threaded draws are piling up in the queue.
	GLfloat				 cameraDistance;
	LDrawColorT			 color;					// default color to draw parts if none is specified
	GLfloat				 glBackgroundColor[4];
	GLfloat				 glColor[4];			// OpenGL equivalent of the LDrawColor.
	ProjectionModeT		 projectionMode;
	RotationDrawModeT	 rotationDrawMode;		// drawing detail while rotating.
	ViewOrientationT	 viewOrientation;		// our orientation
	
	// Event Tracking
	BOOL				 isTrackingDrag;		// true if the last mousedown was followed by a drag, and we're tracking it (drag-and-drop doesn't count)
	NSTimer				*mouseDownTimer;		// countdown to beginning drag-and-drop
	BOOL				 canBeginDragAndDrop;	// the next mouse-dragged will initiate a drag-and-drop.
	BOOL				 didPartSelection;		// tried part selection during this click
	BOOL				 dragEndedInOurDocument;// YES if the drag we initiated ended in the document we display
	Vector3				 draggingOffset;		// displacement between part 0's position and the initial click point of the drag
	Point3				 initialDragLocation;	// point in model where part was positioned at draggingEntered
}

// Drawing
- (void) drawThreaded:(id)sender;
- (void) drawFocusRing;
- (void) strokeInsideRect:(NSRect)rect thickness:(float)borderWidth;

// Accessors
- (LDrawColorT) LDrawColor;
- (NSPoint) centerPoint;
- (LDrawDocument *) document;
- (Matrix4) getInverseMatrix;
- (Matrix4) getMatrix;
- (Tuple3) viewingAngle;
- (ViewOrientationT) viewOrientation;
- (float) zoomPercentage;

- (void) setAcceptsFirstResponder:(BOOL)flag;
- (void) setAutosaveName:(NSString *)newName;
- (void) setDelegate:(id)object;
- (void) setLDrawColor:(LDrawColorT)newColor;
- (void) setLDrawDirective:(LDrawDirective *) newFile;
- (void) setProjectionMode:(ProjectionModeT) newProjectionMode;
- (void) setViewingAngle:(Tuple3)newAngle;
- (void) setViewOrientation:(ViewOrientationT) newAngle;
- (void) setZoomPercentage:(float) newPercentage;

// Actions
- (IBAction) viewOrientationSelected:(id)sender;
- (IBAction) zoomIn:(id)sender;
- (IBAction) zoomOut:(id)sender;

// Events
- (void) resetCursor;

- (void) nudgeKeyDown:(NSEvent *)theEvent;

- (void) dragAndDropDragged:(NSEvent *)theEvent;
- (void) panDragged:(NSEvent *)theEvent;
- (void) rotationDragged:(NSEvent *)theEvent;
- (void) zoomDragged:(NSEvent *)theEvent;
- (void) mouseCenterClick:(NSEvent*)theEvent ;
- (void) mousePartSelection:(NSEvent *)theEvent;
- (void) mouseZoomClick:(NSEvent*)theEvent;

- (void) cancelClickAndHoldTimer;

// Drag and Drop
- (BOOL) updateDirectives:(NSArray *)directives withDragPosition:(NSPoint)dragPointInWindow depthReferencePoint:(Point3)modelReferencePoint constrainAxis:(BOOL)constrainAxis;

// Notifications
- (void) displayNeedsUpdating:(NSNotification *)notification;

// Utilities
- (NSArray *) getDirectivesUnderMouse:(NSEvent *)theEvent
					  amongDirectives:(NSArray *)directives
							 fastDraw:(BOOL)fastDraw;
- (NSArray *) getPartsFromHits:(GLuint *)nameBuffer hitCount:(GLuint)numberHits;
- (LDrawDirective *) getDirectiveFromHitCode:(GLuint)name;
- (void) resetFrameSize;
- (void) restoreConfiguration;
- (void) makeProjection;
- (void) saveConfiguration;
- (void) scrollCenterToPoint:(NSPoint)newCenter;
- (void) takeBackgroundColorFromUserDefaults;

// - Geometry
- (void) getModelAxesForViewX:(Vector3 *)outModelX Y:(Vector3 *)outModelY Z:(Vector3 *)outModelZ;
- (Point3) modelPointForPoint:(NSPoint)viewPoint depthReferencePoint:(Point3)depthPoint;


@end

////////////////////////////////////////////////////////////////////////////////
//
//		Delegate Methods
//
////////////////////////////////////////////////////////////////////////////////
@interface NSObject (LDrawGLViewDelegate)

- (void) LDrawGLViewBecameFirstResponder:(LDrawGLView *)glView;

- (BOOL) LDrawGLView:(LDrawGLView *)glView writeDirectivesToPasteboard:(NSPasteboard *)pasteboard asCopy:(BOOL)copyFlag;
- (void) LDrawGLView:(LDrawGLView *)glView acceptDrop:(id < NSDraggingInfo >)info directives:(NSArray *)directives;
- (void) LDrawGLViewPartsWereDraggedIntoOblivion:(LDrawGLView *)glView;

- (TransformComponents) LDrawGLViewPreferredPartTransform:(LDrawGLView *)glView;

//Delegate method is called when the user has changed the selection of parts 
// by clicking in the view. This does not actually do any selecting; that is 
// left entirely to the delegate. Some may rightly question the design of this 
// system.
- (void)	LDrawGLView:(LDrawGLView *)glView
 wantsToSelectDirective:(LDrawDirective *)directiveToSelect
   byExtendingSelection:(BOOL) shouldExtend;

@end
