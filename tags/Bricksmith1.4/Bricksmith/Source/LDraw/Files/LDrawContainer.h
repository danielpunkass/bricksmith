//==============================================================================
//
// File:		LDrawContainer.m
//
// Purpose:		Abstract subclass for LDrawDirectives which represent a 
//				collection of related directives.
//
//  Created by Allen Smith on 3/31/05.
//  Copyright (c) 2005. All rights reserved.
//==============================================================================
#import <Cocoa/Cocoa.h>

#import "LDrawDirective.h"
#import "MatrixMath.h"

@class PartReport;

@interface LDrawContainer : LDrawDirective <NSCoding, NSCopying> {
	NSMutableArray		*containedObjects;
}

//Accessors
- (NSArray *) allEnclosedElements;
- (Box3) boundingBox3;
- (int) indexOfDirective:(LDrawDirective *)directive;
- (NSArray *) subdirectives;

//Actions
- (void) addDirective:(LDrawDirective *)directive;
- (void) collectPartReport:(PartReport *)report;
- (void) insertDirective:(LDrawDirective *)directive atIndex:(int)index;
- (void) removeDirective:(LDrawDirective *)doomedDirective;
- (void) removeDirectiveAtIndex:(int)index;

@end
