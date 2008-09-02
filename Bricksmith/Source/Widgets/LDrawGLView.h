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

@class LDrawDirective;
@class LDrawDocument;

#define SIMPLIFICATION_THRESHOLD 0.4 //seconds

typedef enum {
	LDrawGLDrawNormal,			//full draw
	LDrawGLDrawExtremelyFast	//bounds only
} RotationDrawModeT;

//
// Class
//
@interface LDrawGLView : NSOpenGLView <LDrawColorable>
{
	LDrawDirective		*fileBeingDrawn; //Should only be an LDrawFile or LDrawModel.
										//if you want to do anything else, you must 
										//tweak the selection code in LDrawDrawableElement
										//and here in -mouseUp: to handle such cases.
	
	LDrawColorT			color; //default color to draw parts if none is specified
	GLfloat				glColor[4]; //OpenGL equivalent of the LDrawColor.
	BOOL				acceptsFirstResponder; //YES if we can become key
	BOOL				hasInfiniteDepth;
	
	IBOutlet LDrawDocument	*document;
	BOOL				isRotating; //true if the last mousedown was followed by a drag.
	RotationDrawModeT	rotationDrawMode; //drawing detail while rotating.
}

//Accessors
- (LDrawColorT) LDrawColor;
- (NSPoint) centerPoint;
- (BOOL) hasInfiniteDepth;
- (float) zoomPercentage;
- (void)setAcceptsFirstResponder:(BOOL)flag;
- (void) setHasInfiniteDepth:(BOOL)flag;
- (void) setLDrawColor:(LDrawColorT)newColor;
- (void) setLDrawDirective:(LDrawDirective *) newFile;
- (void) setZoomPercentage:(float) newPercentage;

//Actions
- (IBAction) zoomIn:(id)sender;
- (IBAction) zoomOut:(id)sender;

//Events
- (LDrawDirective *) getPartFromHits:(GLuint *)nameBuffer hitCount:(GLuint)numberHits;

//Notifications
- (void) displayNeedsUpdating:(NSNotification *)notification;

//Utilities
- (void) resetFrameSize;
- (void) makeProjection;
- (void) scrollCenterToPoint:(NSPoint)newCenter;

@end

//
// Delegate
//
@interface NSObject (LDrawGLViewDelegate)

- (void) LDrawGLViewBecameFirstResponder:(LDrawGLView *)glView;

//Delegate method is called when the user has changed the selection of parts 
// by clicking in the view. This does not actually do any selecting; that is 
// left entirely to the delegate. Some may rightly question the design of this 
// system.
- (void)	LDrawGLView:(LDrawGLView *)glView
 wantsToSelectDirective:(LDrawDirective *)directiveToSelect
   byExtendingSelection:(BOOL) shouldExtend;
@end