//==============================================================================
//
// File:		LDrawDirective.m
//
// Purpose:		Base class for all LDraw objects provides a few basic utilities.
//
//  Created by Allen Smith on 2/19/05.
//  Copyright (c) 2005. All rights reserved.
//==============================================================================
#import "LDrawDirective.h"

//GAA! Incest! Importing the subclasses inside the base class has got to violate 
// sixteen kerjillion holy principles of object-oriented programming. But in my 
// limited knowledge, nothing else is coming to mind.
#import "LDrawMetaCommand.h"
#import "LDrawPart.h"
#import "LDrawLine.h"
#import "LDrawTriangle.h"
#import "LDrawQuadrilateral.h"
#import "LDrawConditionalLine.h"
#import "LDrawContainer.h"

#import "MacLDraw.h"
	
@implementation LDrawDirective


#pragma mark -
#pragma mark INITIALIZATION
#pragma mark -

//========== directiveWithString: ==============================================
//
// Purpose:		Returns the LDraw directive based on lineFromFile, a single line 
//				of LDraw code from a file.
//
//				This method is intended to be overridden by subclasses.
//				LDrawDirective's implementation simply returns a useless empty 
//				directive.
//
//				A subclass implementation would look something like:
//				---------------------------------------------------------------
//
//				//The linecode (0, 1, 2, 3, 4, 5) identifies the type of command, 
//				// and is always the first character in the line.
//				NSString *lineCode = [lineFromFile substringToIndex:1];
//				Class LineTypeClass = [LDrawDirective classForLineType:[lineCode intValue]];
//				//Now initialize whatever subclass we came up with for this line.
//				newDirective = [LineTypeClass directiveWithString:lineFromFile];
//
//==============================================================================
+ (id) directiveWithString:(NSString *)lineFromFile{
	id newDirective = [LDrawDirective new];
	
	return [newDirective autorelease];
}

//========== init ==============================================================
//
// Purpose:		Start me up. This should be called before any other subclass 
//				initialization code.
//
//==============================================================================
- (id) init {
	self = [super init];
	enclosingDirective = nil;
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
	//The superclass doesn't support NSCoding. So we just call the default init.
	self = [super init];
	
	[self setEnclosingDirective:[decoder decodeObjectForKey:@"enclosingDirective"]];
	
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
	//self = [super encodeWithCoder:encoder]; //super doesn't implement this method.
	
	//We encode the parent conditionally--it won't actually get encoded unless 
	// someone else encodes the parent unconditionally.
	[encoder encodeConditionalObject:enclosingDirective forKey:@"enclosingDirective"];
	
}


//========== copyWithZone: =====================================================
//
// Purpose:		Returns a duplicate of this object. 
//				This thing has issules. Note caveats in LDrawContainer.
//
//==============================================================================
- (id) copyWithZone:(NSZone *)zone {
	//Allocate a new instance because we don't inherit -copy: from anybody.
	// Note the code to ensure that the correct subclass is allocated!
	// Since LDrawDirective is the root LDraw class, all [subclass copy] 
	// messages wind up here.
	LDrawDirective *copied = [[[self class] allocWithZone:zone] init];
	
	[copied setEnclosingDirective:nil]; //if that is to be copied, then it should be assigned via accessors.
	[copied setSelected:self->isSelected];
	
	return copied;
}


#pragma mark -
#pragma mark DIRECTIVES
#pragma mark -

//========== draw ==============================================================
//
// Purpose:		Issues the OpenGL code necessary to draw this element.
//
//				This method is intended to be overridden by subclasses.
//				LDrawDirective's implementation does nothing.
//
//==============================================================================
- (void) draw:(unsigned int) optionsMask parentColor:(GLfloat *)parentColor {
	//subclasses should override this with OpenGL code to draw the line.
}

//========== write =============================================================
//
// Purpose:		Returns the LDraw code for this directive, which can then be 
//				written out to a LDraw file and read by any LDraw interpreter.
//
//				This method is intended to be overridden by subclasses.
//				LDrawDirective's implementation does nothing.
//
//==============================================================================
- (NSString *) write{
	//Returns a representation of the line which can be written out to a file.
	return [NSString string]; //empty string; subclasses should override this method.
}


#pragma mark -
#pragma mark DISPLAY
#pragma mark -

//========== browsingDescription ===============================================
//
// Purpose:		Returns a representation of the directive as a short string 
//				which can be presented to the user.
//
//==============================================================================
- (NSString *)browsingDescription
{
	return [NSString stringWithFormat:@"%@", [self class]];
}


//========== iconName ==========================================================
//
// Purpose:		Returns the name of image file used to display this kind of 
//				object.
//
//==============================================================================
- (NSString *) iconName{
	return @""; //Nothing.
}


//========== inspectorClassName ================================================
//
// Purpose:		Returns the name of the class used to inspect this one.
//
//==============================================================================
- (NSString *) inspectorClassName{
	return @"";
}

#pragma mark -
#pragma mark ACCESSORS
#pragma mark -


//========== ancestors =========================================================
//
// Purpose:		Returns the ancestors enclosing this directive (as well as the 
//				directive itself), with the oldest ancestor (highest node) at
//				the first index.
//
//==============================================================================
- (NSArray *)ancestors {
	NSMutableArray *ancestors		= [NSMutableArray arrayWithCapacity:3];
	LDrawDirective *currentAncestor = self;
	
	while(currentAncestor != nil){
		[ancestors insertObject:currentAncestor atIndex:0];
		currentAncestor = [currentAncestor enclosingDirective];
	}
	
	return ancestors;
}


//========== enclosingDirective ================================================
//
// Purpose:		Bricksmith imposes a rigid hierarchy on the data in a file:
//
//				LDrawFile
//					|
//					|-----> LDrawMPDModels
//								|
//								|-----> LDrawSteps
//											|
//											|-----> LDrawParts
//											|
//											|-----> LDraw Primitives
//											|
//											|-----> LDrawMetaCommands
//
//				With the exception of LDrawFile at the root, all directives 
//				must be enclosed within another directive. This method returns 
//				the directive in which this one is stored. 
//
// Notes:		LDrawFiles return nil.
//
//==============================================================================
- (LDrawContainer *) enclosingDirective {
	return enclosingDirective;
}


//========== setEnclosingDirective: ============================================
//
// Purpose:		Just about all directives can be nested inside another one, so 
//				this is where this method landed.
//
//==============================================================================
- (void) setEnclosingDirective:(LDrawContainer *)newParent{
	enclosingDirective = newParent;
}


//========== setSelected: ======================================================
//
// Purpose:		Somebody make this a protocol method.
//
//==============================================================================
- (void) setSelected:(BOOL)flag {
	self->isSelected = flag;
}

#pragma mark -
#pragma mark UTILITIES
#pragma mark -
//This is stuff that didn't really go anywhere else.

//========== description =======================================================
//
// Purpose:		Overrides NSObject method to get a more meaningful description 
//				suitable for printing to the console.
//
//==============================================================================
- (NSString *)description{
	return [NSString stringWithFormat:@"%@\n%@", [self class], [self write]];
}


//========== isAncestorInList ==================================================
//
// Purpose:		Given a list of LDrawContainers, returns YES if any of the 
//				containers is a direct ancestor of the receiver. An ancestor is 
//				specified by enclosingDirective; each enclosingDirective can 
//				also have an ancestor. This method searchs the whole chain.
//
// Note:		I think this method is potentially buggy. Shouldn't we be doing 
//				pointer equality tests?
//
//==============================================================================
- (BOOL)isAncestorInList:(NSArray *)containers
{
	LDrawDirective	*ancestor		= self;
	BOOL			 foundInList	= NO;
	
	do {
		ancestor = [ancestor enclosingDirective];
		foundInList = [containers containsObject:ancestor];
	}while(ancestor != nil && foundInList == NO);
	
	return foundInList;
}

//========== registerUndoActions ===============================================
//
// Purpose:		Registers the undo actions that are unique to this subclass, 
//				not to any superclass.
//
//==============================================================================
- (void) registerUndoActions:(NSUndoManager *)undoManager {
	
	//LDrawDirectives are fairly abstract, so all undoable attributes come 
	// from subclasses.
}


//========== snapshot ==========================================================
//
// Purpose:		Record the current state of our object in a way suitable for 
//				undo/redo.
//
// Note:		Undo operations are stored on a *stack*, so the order of undo 
//				registration in the code is the opposite from the order in 
//				which the undo operations are executed.
//
//				Subclasses should only override this method to provide a custom 
//				undo name, but even that can be placed just as well in 
//				-registerUndoActions:.
//
//==============================================================================
- (void) snapshot
{
	// ** Read code bottom-to-top ** //
	
	NSDocument		*currentDocument	= [[NSDocumentController sharedDocumentController] currentDocument];
	NSUndoManager	*undoManager		= [currentDocument undoManager];
	

	//Now that all the undo actions have happened, post a notification that 
	// the object has changed.
	[[undoManager prepareWithInvocationTarget:[NSNotificationCenter defaultCenter]]
			postNotificationName:LDrawDirectiveDidChangeNotification
						  object:self];
	
	[self registerUndoActions:undoManager];
	//Now issue the commands necessary to revert our object to current values.
	
	[[undoManager prepareWithInvocationTarget:self] snapshot];
	//First thing to call is snapshot, so that redo commands are filled 
	// with the values of the current state.
}


//========== classForLineType ==================================================
//
// Purpose:		Allows initializing the right kind of class based on the code 
//				found at the beginning of an LDraw line.
//
//==============================================================================
+ (Class) classForLineType:(int)lineType
{
	Class classForType = nil;
	
	switch(lineType){
		case 0:
			classForType = [LDrawMetaCommand class];
			break;
		case 1:
			classForType = [LDrawPart class];
			break;
		case 2:
			classForType = [LDrawLine class];
			break;
		case 3:
			classForType = [LDrawTriangle class];
			break;
		case 4:
			classForType = [LDrawQuadrilateral class];
			break;
		case 5:
			classForType = [LDrawConditionalLine class];
			break;
		default:
			NSLog(@"unrecognized LDraw line type: %d", lineType);
	}
	
	return classForType;
}

//========== readNextField: ====================================================
//
// Purpose:		Given the portion of the LDraw line, read the first available 
//				field. Fields are separated by whitespace of any length.
//
//				If remainder is not NULL, return by indirection the remainder of 
//				partialDirective after the first field has been removed. If 
//				there is no remainder, an empty string will be returned.
//
//				So, given the line
//				1 8 -150 -8 20 0 0 -1 0 1 0 1 0 0 3710.DAT
//
//				remainder will be set to:
//				 8 -150 -8 20 0 0 -1 0 1 0 1 0 0 3710.DAT
//
// Notes:		This method is incapable of reading field strings with spaces 
//				in them!
//
//				A case could be made to replace this method with an NSScanner!
//				They don't seem to be as adept at scanning in unknown string 
//				tags though, which would make them difficult to use to 
//				distinguish between "0 WRITE blah" and "0 COMMENT blah".
//
//==============================================================================
+ (NSString *) readNextField:(NSString *) partialDirective
				   remainder:(NSString **) remainder
{
	NSCharacterSet	*whitespaceCharacterSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
	NSRange			 rangeOfNextWhiteSpace;
	NSString		*fieldContents			= nil;
	
	//First, remove any heading whitespace.
	partialDirective = [partialDirective stringByTrimmingCharactersInSet:whitespaceCharacterSet];
	//Find the beginning of the next field separation
	rangeOfNextWhiteSpace = [partialDirective rangeOfCharacterFromSet:whitespaceCharacterSet];
	
	//The text between the beginning and the next field separator is the first 
	// field (what we are after).
	if(rangeOfNextWhiteSpace.location != NSNotFound){
		fieldContents = [partialDirective substringToIndex:rangeOfNextWhiteSpace.location];
		//See if they want the rest of the line, sans the field we just parsed.
		if(remainder != NULL)
			*remainder = [partialDirective substringFromIndex:rangeOfNextWhiteSpace.location];
	}
	else{
		//There was no subsequent field separator; we must be at the end of the line.
		fieldContents = partialDirective;
		if(remainder != NULL)
			*remainder = [NSString string];
	}
	
	return fieldContents;
}//end readNextField


//========== LDrawEqualPoints() ================================================
//
// Purpose:		Returns YES if point1 and point2 have the same coordinates..
//
//==============================================================================
BOOL LDrawEqualPoints(Point3 point1, Point3 point2){
	if(point1.x == point2.x &&
	   point1.y == point2.y &&
	   point1.z == point2.z )
		return YES;
	else
		return NO;
}


@end
