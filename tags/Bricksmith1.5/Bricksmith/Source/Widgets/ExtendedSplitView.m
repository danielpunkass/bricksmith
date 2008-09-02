//==============================================================================
//
// File:		ExtendedSplitView.m
//
// Purpose:		Fills in some of the many blanks Apple left in NSSplitView.
//
//  Created by Allen Smith on 11/11/05.
//  Copyright 2005. All rights reserved.
//==============================================================================
#import "ExtendedSplitView.h"


@implementation ExtendedSplitView

#pragma mark -
#pragma mark ACCESSORS
#pragma mark -

//========== autosaveName ======================================================
//
// Purpose:		Returns the name under which this SplitView is configured to 
//				save itself to preferences.
//
//==============================================================================
- (NSString *) autosaveName {
	return self->autosaveName;
}


//========== setAutosaveName: ==================================================
//
// Purpose:		Sets the name under which this SplitView is configured to save 
//				itself to preferences. It will be saved automatically upon 
//				deallocation.
//
//==============================================================================
- (void) setAutosaveName:(NSString *)newName {
	[newName retain];
	[self->autosaveName release];
	
	autosaveName = newName;
}


#pragma mark -
#pragma mark PERSISTENCE
#pragma mark -

//========== restoreConfiguration ==============================================
//
// Purpose:		Restores the split view from preferences, if an autosave name 
//				has been set.
//
//==============================================================================
- (void) restoreConfiguration {

	NSUserDefaults	*userDefaults	= [NSUserDefaults standardUserDefaults];
	NSArray			*subviews		= [self subviews];
	NSView			*currentSubview	= nil;
	NSRect			 currentRect	= NSZeroRect;
	NSString		*rectString		= nil;
	NSMutableArray	*frameSizes		= [NSMutableArray array];
	int				 counter		= 0;
	
	if(self->autosaveName != nil){
		frameSizes = [userDefaults objectForKey:self->autosaveName];
		if(frameSizes != nil && [subviews count] == [frameSizes count])
		{
			for(counter = 0; counter < [subviews count]; counter++){
				currentSubview	= [subviews objectAtIndex:counter];
				rectString		= [frameSizes objectAtIndex:counter];
				currentRect		= NSRectFromString(rectString);
				
				//we have a BIG collapsing problem. The SplitView does not 
				// have a convenient -setCollapsed: method! We are going 
				// off this experimentally-verified result that the origin 
				// of a collapsed subview gets set to (1,000,000 , 1,000,000).
				// But if we just restore that frame, it WON'T WORK! Sooooo...
				// we set the size to 0, which forcesit it out of view.
				if(NSMinX(currentRect) == 1e6 && NSMinY(currentRect) == 1e6) {
					currentRect.size.height = 0;
					currentRect.size.width = 0;
				}				   
				
				[currentSubview setFrame:currentRect];
			}
		}
	}
	
	//clean up our mess.
	[self adjustSubviews];
	
//	subviews		= [self subviews];
//	for(counter = 0; counter < [subviews count]; counter++){
//		currentSubview	= [subviews objectAtIndex:counter];
//		currentRect		= [currentSubview frame];
//		rectString		= NSStringFromRect(currentRect);
//		NSLog(@"%@", rectString);
//	}
//	NSLog(@"\n\n\n");

}//end restoreConfiguration


//========== saveConfiguration =================================================
//
// Purpose:		Saves the splitview into preferences, provided an autosave name 
//				has been set.
//
//==============================================================================
- (void) saveConfiguration{
	
	NSUserDefaults	*userDefaults	= [NSUserDefaults standardUserDefaults];
	NSArray			*subviews		= [self subviews];
	NSView			*currentSubview	= nil;
	NSRect			 currentRect	= NSZeroRect;
	NSString		*rectString		= nil;
	NSMutableArray	*frameSizes		= [NSMutableArray array];
	int				 counter		= 0;
	
	for(counter = 0; counter < [subviews count]; counter++){
		currentSubview	= [subviews objectAtIndex:counter];
		currentRect		= [currentSubview frame];
		rectString		= NSStringFromRect(currentRect);
		[frameSizes addObject:rectString];
	}
	
	if(self->autosaveName != nil){
		[userDefaults setObject:frameSizes forKey:self->autosaveName];
	}
	
}//end saveConfiguration


#pragma mark -
#pragma mark DESTRUCTOR
#pragma mark -

//========== dealloc ===========================================================
//
// Purpose:		We're sloughing off our mortal coil.
//
//==============================================================================
- (void) dealloc {
	if(self->autosaveName != nil)
		[self saveConfiguration];
	[super dealloc];
}

@end
