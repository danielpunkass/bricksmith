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
#import <OpenGL/GL.h>

#import "LDrawColor.h"
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

#define SIMPLIFICATION_THRESHOLD	0.4 //seconds
#define CAMERA_DISTANCE_FACTOR		6.5	//controls perspective; cameraLocation = modelSize * CAMERA_DISTANCE_FACTOR


typedef enum {
	ProjectionModePerspective	= 0,
	ProjectionModeOrthographic	= 1
} ProjectionModeT;


typedef enum {
	LDrawGLDrawNormal			= 0,	//full draw
	LDrawGLDrawExtremelyFast	= 1		//bounds only
} RotationDrawModeT;


typedef enum {
	ViewingAngle3D				= 0,
	ViewingAngleFront			= 1,
	ViewingAngleBack			= 2,
	ViewingAngleLeft			= 3,
	ViewingAngleRight			= 4,
	ViewingAngleTop				= 5,
	ViewingAngleBottom			= 6
} ViewingAngleT;


////////////////////////////////////////////////////////////////////////////////
//
//		LDrawGLView
//
////////////////////////////////////////////////////////////////////////////////
@interface LDrawGLView : NSOpenGLView <LDrawColorable>
{
	IBOutlet LDrawDocument	*document;			//optional weak link. Enables editing capabilities.
	
	BOOL				 acceptsFirstResponder;	//YES if we can become key
	NSString			*autosaveName;
	LDrawDirective		*fileBeingDrawn;		//Should only be an LDrawFile or LDrawModel.
												// if you want to do anything else, you must 
												// tweak the selection code in LDrawDrawableElement
												// and here in -mouseUp: to handle such cases.
	
	//Drawing Environment
	unsigned			 numberDrawRequests;	//how many threaded draws are piling up in the queue.
	GLfloat				 cameraDistance;
	LDrawColorT			 color;					//default color to draw parts if none is specified
	GLfloat				 glColor[4];			//OpenGL equivalent of the LDrawColor.
	ProjectionModeT		 projectionMode;
	RotationDrawModeT	 rotationDrawMode;		//drawing detail while rotating.
	ViewingAngleT		 viewingAngle;			//our orientation
	
	//Event Tracking
	BOOL				 isDragging;			//true if the last mousedown was followed by a drag.
}

//Drawing
- (void) drawThreaded:(id)sender;
- (void) drawFocusRing;
- (void) strokeInsideRect:(NSRect)rect thickness:(float)borderWidth;

//Accessors
- (LDrawColorT) LDrawColor;
- (NSPoint) centerPoint;
- (Matrix4) getInverseMatrix;
- (ViewingAngleT) viewingAngle;
- (float) zoomPercentage;
- (void) setAcceptsFirstResponder:(BOOL)flag;
- (void) setAutosaveName:(NSString *)newName;
- (void) setLDrawColor:(LDrawColorT)newColor;
- (void) setLDrawDirective:(LDrawDirective *) newFile;
- (void) setProjectionMode:(ProjectionModeT) newProjectionMode;
- (void) setViewingAngle:(ViewingAngleT) newAngle;
- (void) setZoomPercentage:(float) newPercentage;

//Actions
- (IBAction) viewingAngleSelected:(id)sender;
- (IBAction) zoomIn:(id)sender;
- (IBAction) zoomOut:(id)sender;

//Events
- (void) resetCursor;
- (void) nudgeKeyDown:(NSEvent *)theEvent;
- (void) panDragged:(NSEvent *)theEvent;
- (void) rotationDragged:(NSEvent *)theEvent;
- (void) zoomDragged:(NSEvent *)theEvent;
- (void) mouseCenterClick:(NSEvent*)theEvent ;
- (void) mousePartSelection:(NSEvent *)theEvent;
- (void) mouseZoomClick:(NSEvent*)theEvent;

//Notifications
- (void) displayNeedsUpdating:(NSNotification *)notification;

//Utilities
- (LDrawDirective *) getPartFromHits:(GLuint *)nameBuffer hitCount:(GLuint)numberHits;
- (void) resetFrameSize;
- (void) restoreConfiguration;
- (void) makeProjection;
- (void) saveConfiguration;
- (void) scrollCenterToPoint:(NSPoint)newCenter;

@end

////////////////////////////////////////////////////////////////////////////////
//
//		Delegate Methods
//
////////////////////////////////////////////////////////////////////////////////
@interface NSObject (LDrawGLViewDelegate)

- (void) LDrawGLViewBecameFirstResponder:(LDrawGLView *)glView;

//Delegate method is called when the user has changed the selection of parts 
// by clicking in the view. This does not actually do any selecting; that is 
// left entirely to the delegate. Some may rightly question the design of this 
// system.
- (void)	LDrawGLView:(LDrawGLView *)glView
 wantsToSelectDirective:(LDrawDirective *)directiveToSelect
   byExtendingSelection:(BOOL) shouldExtend;

- (void) LDrawGLViewWillBeginDrawing:(LDrawGLView *)glView;
- (void) LDrawGLViewDidEndDrawing:(LDrawGLView *)glView;

@end
