//==============================================================================
//
// File:		LDrawContainer.m
//
// Purpose:		Abstract subclass for LDrawDirectives which represent a 
//				collection of related directives.
//
//				Subclasses: LDrawFile, LDrawModel, LDrawStep
//
//  Created by Allen Smith on 3/31/05.
//  Copyright (c) 2005. All rights reserved.
//==============================================================================
#import "LDrawContainer.h"

#import "MacLDraw.h"
#import "PartReport.h"

@implementation LDrawContainer

#pragma mark -
#pragma mark INITIALIZATION
#pragma mark -

//========== init ==============================================================
//
// Purpose:		Creates a new container with absolutely nothing in it, but 
//				ready to receive objects.
//
//==============================================================================
- (id) init {
	self = [super init];
	
	containedObjects = [NSMutableArray array];
	[containedObjects retain];
	
	return self;
}


//========== initWithCoder: ====================================================
//
// Purpose:		Reads a representation of this object from the given coder,
//				which is assumed to always be a keyed decoder. This allows us to 
//				read and write LDraw objects as NSData.
//
//==============================================================================
- (id)initWithCoder:(NSCoder *)decoder
{
	self = [super initWithCoder:decoder];
	
	containedObjects = [[decoder decodeObjectForKey:@"containedObjects"] retain];
	
	return self;
}


//========== encodeWithCoder: ==================================================
//
// Purpose:		Writes a representation of this object to the given coder,
//				which is assumed to always be a keyed decoder. This allows us to 
//				read and write LDraw objects as NSData.
//
//==============================================================================
- (void)encodeWithCoder:(NSCoder *)encoder
{
	[super encodeWithCoder:encoder];
	
	[encoder encodeObject:containedObjects forKey:@"containedObjects"];
}


//========== copyWithZone: =====================================================
//
// Purpose:		Returns a duplicate of this object. Each contained directive is 
//				copied, so the returned object is a complete duplicate of the 
//				receiver.
//
//==============================================================================
- (id) copyWithZone:(NSZone *)zone {
	LDrawContainer *copiedContainer = (LDrawContainer *)[super copyWithZone:zone];
	int numberSubdirectives = [self->containedObjects count];
	id	currentObject = nil;
	id	copiedObject = nil;
	int counter		= 0;
	
	//Allocate our instance varibales.
	copiedContainer->containedObjects = [[NSMutableArray alloc] initWithCapacity:numberSubdirectives];
	
	//Copy each subdirective and transfer it into the copied container.
	for(counter = 0; counter < numberSubdirectives; counter++){
		currentObject = [containedObjects objectAtIndex:counter];
		copiedObject = [currentObject copy];
		[copiedContainer insertDirective:copiedObject atIndex:counter];
		[copiedObject release];
	}
	
	return copiedContainer;
}


#pragma mark -
#pragma mark ACCESSORS
#pragma mark -

//========== boundingBox3 ======================================================
//
// Purpose:		Returns the minimum and maximum points of the box which 
//				perfectly contains this object.
//
//==============================================================================
- (Box3) boundingBox3 {
	return [LDrawDirective boundingBox3ForDirectives:self->containedObjects];
}


//========== indexOfDirective: =================================================
//
// Purpose:		Adds directive into the collection at position index.
//
//==============================================================================
- (int) indexOfDirective:(LDrawDirective *)directive {
	return [containedObjects indexOfObjectIdenticalTo:directive];
}


//========== subdirectives =====================================================
//
// Purpose:		Returns the LDraw directives stored in this collection.
//
//==============================================================================
- (NSArray *) subdirectives{
	return containedObjects;
}

#pragma mark -
#pragma mark ACTIONS
#pragma mark -

//========== addDirective: =====================================================
//
// Purpose:		Adds directive into the collection at the end of the list.
//
//==============================================================================
- (void) addDirective:(LDrawDirective *)directive {
	
	int index = [containedObjects count];
	[self insertDirective:directive atIndex:index];
}


//========== collectPartReport: ================================================
//
// Purpose:		Collects a report on all the parts in this container, no matter 
//				how deeply they may be contained.
//
//==============================================================================
- (void) collectPartReport:(PartReport *)report {
	id		currentDirective	= nil;
	int		counter				= 0;
	
	for(counter = 0; counter < [containedObjects count]; counter++){
		currentDirective = [containedObjects objectAtIndex:counter];
		if([currentDirective respondsToSelector:@selector(collectPartReport:)])
			[currentDirective collectPartReport:report];
	}
}


//========== removeDirective: ==================================================
//
// Purpose:		Removes the specified LDraw directive stored in this collection.
//
//				If it isn't in the collection, well, that's that.
//
//==============================================================================
- (void) removeDirective:(LDrawDirective *)doomedDirective{
	//First, find the object (making sure it's actually there in the process)
	int indexOfObject = [self indexOfDirective:doomedDirective];
	
	if(indexOfObject != NSNotFound) {
		//We found it; kill it!
		[self removeDirectiveAtIndex:indexOfObject];
	}
}


//========== insertDirective:atIndex: ==========================================
//
// Purpose:		Adds directive into the collection at position index.
//
//==============================================================================
- (void) insertDirective:(LDrawDirective *)directive atIndex:(int)index{
	
	[containedObjects insertObject:directive atIndex:index];
	[directive setEnclosingDirective:self];
	
	[[NSNotificationCenter defaultCenter]
			postNotificationName:LDrawDirectiveDidChangeNotification
						  object:self];
	
}


//========== removeDirectiveAtIndex: ===========================================
//
// Purpose:		Removes the LDraw directive stored at index in this collection.
//
//==============================================================================
- (void) removeDirectiveAtIndex:(int)index{
	LDrawDirective *doomedDirective = [self->containedObjects objectAtIndex:index];
	
	if([doomedDirective enclosingDirective] == self)
		[doomedDirective setEnclosingDirective:nil]; //no parent anymore; it's an orphan now.
	[containedObjects removeObjectAtIndex:index]; //or disowned at least.
	
	[[NSNotificationCenter defaultCenter]
			postNotificationName:LDrawDirectiveDidChangeNotification
						  object:self];
}

#pragma mark -
#pragma mark DESTRUCTOR
#pragma mark -

//========== dealloc ===========================================================
//
// Purpose:		IT'S THE END OF THE WORLD AS WE KNOW IT!!!
//
//==============================================================================
- (void) dealloc {
	[containedObjects release];
	
	[super dealloc];
}


@end
