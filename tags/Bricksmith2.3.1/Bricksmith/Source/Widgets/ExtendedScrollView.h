//==============================================================================
//
// File:		ExtendedScrollView.m
//
// Purpose:		A scroll view which supports displaying placards in the 
//				scrollbar regions. 
//
// Modified:	04/19/2009 Allen Smith. Creation Date.
//
//==============================================================================
#import <Cocoa/Cocoa.h>


////////////////////////////////////////////////////////////////////////////////
//
// class ExtendedScrollView
//
////////////////////////////////////////////////////////////////////////////////
@interface ExtendedScrollView : NSScrollView
{
	NSPoint documentScrollCenterPoint;
	BOOL    preservesScrollCenterDuringLiveResize;
	NSView  *verticalPlacard;
}

// Accessors
- (void) setPreservesScrollCenterDuringLiveResize:(BOOL)flag;
- (void) setVerticalPlacard:(NSView *)placardView;

@end