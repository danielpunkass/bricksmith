//==============================================================================
//
// File:		ViewportArranger.h
//
// Purpose:		Displays a configurable grid of viewports. The user can add or 
//				remove viewports by clicking buttons embedded in the scrollers 
//				of each viewport. 
//
// Modified:	10/03/2009 Allen Smith. Creation Date.
//
//==============================================================================

#import <Cocoa/Cocoa.h>

#import "ExtendedSplitView.h"

@class ExtendedScrollView;
@protocol ViewportArrangerDelegate;

////////////////////////////////////////////////////////////////////////////////
//
// class ViewportArranger
//
////////////////////////////////////////////////////////////////////////////////
@interface ViewportArranger : ExtendedSplitView
{
	IBOutlet NSView                 *splitAndClosePlacardPrototype;	// split and close buttons
	IBOutlet NSView                 *closePlacardPrototype;			// close button only
	id<ViewportArrangerDelegate>    delegate;
}

// Accessors
- (NSArray *) allViewports;
- (id<ViewportArrangerDelegate>) delegate;

- (void) setDelegate:(id<ViewportArrangerDelegate>)delegate;

// Actions
- (IBAction) splitViewportClicked:(id)sender;
- (IBAction) closeViewportClicked:(id)sender;

// Utilities
- (ExtendedScrollView *) newViewport;
- (void) restoreViewportsWithAutosaveName:(NSString *)autosaveName;
- (void) storeViewports;
- (void) updateAutosaveNames;
- (void) updatePlacardsForViewports;

@end


////////////////////////////////////////////////////////////////////////////////
//
// ViewportArrangerDelegate
//
////////////////////////////////////////////////////////////////////////////////
@protocol ViewportArrangerDelegate <NSObject>

@optional
- (void) viewportArranger:(ViewportArranger *)viewportArranger didAddViewport:(ExtendedScrollView *)newViewport sourceViewport:(ExtendedScrollView *)sourceViewport;
- (void) viewportArrangerDidRemoveViewports:(ViewportArranger *)viewportArranger;

@end