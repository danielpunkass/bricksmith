//==============================================================================
//
// File:		LDrawGLView.h
//
// Purpose:		Draws an LDrawFile with OpenGL.
//
// Modified:	4/17/05 Allen Smith. Creation Date.
//
//==============================================================================
#import <Cocoa/Cocoa.h>
#import <OpenGL/OpenGL.h>

#import "ColorLibrary.h"
#import "LDrawUtilities.h"
#import "MatrixMath.h"
#import "ToolPalette.h"

//Forward declarations
@class FocusRingView;
@class LDrawDirective;


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


////////////////////////////////////////////////////////////////////////////////
//
//		LDrawGLView
//
////////////////////////////////////////////////////////////////////////////////
@interface LDrawGLView : NSOpenGLView <LDrawColorable>
{
	FocusRingView			*focusRingView;
	
	IBOutlet id             delegate;
	id                      target;
	SEL                     backAction;
	SEL                     forwardAction;
	SEL						nudgeAction;
	
	BOOL                    acceptsFirstResponder;	// YES if we can become key
	NSString                *autosaveName;
	LDrawDirective          *fileBeingDrawn;		// Should only be an LDrawFile or LDrawModel.
													// if you want to do anything else, you must 
													// tweak the selection code in LDrawDrawableElement
													// and here in -mouseUp: to handle such cases.
	
	// Threading
	NSConditionLock			*canDrawLock;			// when condition is YES, render thread will wake up and draw.
	BOOL					keepDrawThreadAlive;	// when it has no items in it, the thread will die
	NSUInteger              numberDrawRequests;		// how many threaded draws are piling up in the queue.
	BOOL					hasThread;
	
	// Drawing Environment
	GLfloat                 cameraDistance;			// location of camera on the z-axis; distance from (0,0,0);
	NSSize					snugFrameSize;
	LDrawColorT             color;					// default color to draw parts if none is specified
	GLfloat                 glBackgroundColor[4];
	GLfloat                 glColor[4];				// OpenGL equivalent of the LDrawColor.
	gridSpacingModeT		gridMode;
	ProjectionModeT         projectionMode;
	RotationDrawModeT       rotationDrawMode;		// drawing detail while rotating.
	ViewOrientationT        viewOrientation;		// our orientation
	NSTimeInterval			fpsStartTime;
	NSInteger				framesSinceStartTime;
	
	// Event Tracking
	BOOL                    isGesturing;			// true if performing a multitouch trackpad gesture.
	BOOL                    isTrackingDrag;			// true if the last mousedown was followed by a drag, and we're tracking it (drag-and-drop doesn't count)
	NSTimer                 *mouseDownTimer;		// countdown to beginning drag-and-drop
	BOOL                    canBeginDragAndDrop;	// the next mouse-dragged will initiate a drag-and-drop.
	BOOL                    didPartSelection;		// tried part selection during this click
	BOOL                    dragEndedInOurDocument;	// YES if the drag we initiated ended in the document we display
	Vector3                 draggingOffset;			// displacement between part 0's position and the initial click point of the drag
	Point3                  initialDragLocation;	// point in model where part was positioned at draggingEntered
	Vector3					nudgeVector;			// direction of nudge action (valid only in nudgeAction callback)
}

- (void) internalInit;

// Drawing
- (void) draw;
- (void) drawFocusRing;
- (void) strokeInsideRect:(NSRect)rect thickness:(CGFloat)borderWidth;

// Accessors
- (LDrawColorT) LDrawColor;
- (NSPoint) centerPoint;
- (Matrix4) getInverseMatrix;
- (Matrix4) getMatrix;
- (LDrawDirective *) LDrawDirective;
- (Vector3) nudgeVector;
- (ProjectionModeT) projectionMode;
- (Tuple3) viewingAngle;
- (ViewOrientationT) viewOrientation;
- (CGFloat) zoomPercentage;

- (void) setAcceptsFirstResponder:(BOOL)flag;
- (void) setAutosaveName:(NSString *)newName;
- (void) setBackAction:(SEL)newAction;
- (void) setDelegate:(id)object;
- (void) setForwardAction:(SEL)newAction;
- (void) setGridSpacingMode:(gridSpacingModeT)newMode;
- (void) setLDrawColor:(LDrawColorT)newColor;
- (void) setLDrawDirective:(LDrawDirective *) newFile;
- (void) setNudgeAction:(SEL)newAction;
- (void) setProjectionMode:(ProjectionModeT) newProjectionMode;
- (void) setTarget:(id)target;
- (void) setViewingAngle:(Tuple3)newAngle;
- (void) setViewOrientation:(ViewOrientationT) newAngle;
- (void) setZoomPercentage:(CGFloat) newPercentage;

// Actions
- (IBAction) viewOrientationSelected:(id)sender;
- (IBAction) zoomIn:(id)sender;
- (IBAction) zoomOut:(id)sender;
- (IBAction) zoomToFit:(id)sender;

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
- (void) saveConfiguration;
- (void) scrollCenterToModelPoint:(Point3)modelPoint;
- (void) scrollCenterToPoint:(NSPoint)newCenter;
- (void) takeBackgroundColorFromUserDefaults;

// - Geometry
- (float) fieldDepth;
- (void) getModelAxesForViewX:(Vector3 *)outModelX Y:(Vector3 *)outModelY Z:(Vector3 *)outModelZ;
- (void) makeProjection;
- (Point3) modelPointForPoint:(NSPoint)viewPoint;
- (Point3) modelPointForPoint:(NSPoint)viewPoint depthReferencePoint:(Point3)depthPoint;
- (NSRect) nearOrthoClippingRectFromVisibleRect:(NSRect)visibleRect;
- (NSRect) nearFrustumClippingRectFromVisibleRect:(NSRect)visibleRect;
- (NSRect) nearOrthoClippingRectFromNearFrustumClippingRect:(NSRect)visibilityPlane;
- (NSRect) visibleRectFromNearOrthoClippingRect:(NSRect)visibilityPlane;
- (NSRect) visibleRectFromNearFrustumClippingRect:(NSRect)visibilityPlane;

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

// Delegate method is called when the user has changed the selection of parts 
// by clicking in the view. This does not actually do any selecting; that is 
// left entirely to the delegate. Some may rightly question the design of this 
// system.
- (void)	LDrawGLView:(LDrawGLView *)glView
 wantsToSelectDirective:(LDrawDirective *)directiveToSelect
   byExtendingSelection:(BOOL) shouldExtend;

@end


////////////////////////////////////////////////////////////////////////////////
//
//		Currently-private API
//		which might just be released in an upcoming OS...
//
////////////////////////////////////////////////////////////////////////////////
#if MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_5
@interface NSEvent (GestureMethods)
- (CGFloat) magnification;
@end
#else
	#warning This can be removed now.
#endif