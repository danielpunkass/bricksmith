//==============================================================================
//
// File:		LDrawLine.m
//
// Purpose:		Line command.
//				Draws a line between two points.
//
//				Line format:
//				2 colour x1 y1 z1 x2 y2 z2 
//
//				where
//
//				* colour is a colour code: 0-15, 16, 24, 32-47, 256-511
//				* x1, y1, z1 is the position of the first point
//				* x2, y2, z2 is the position of the second point 
//
//  Created by Allen Smith on 2/19/05.
//  Copyright (c) 2005. All rights reserved.
//==============================================================================
#import "LDrawLine.h"

#import "LDrawStep.h"
#import "LDrawUtilities.h"
#import "MacLDraw.h"

@implementation LDrawLine

#pragma mark -
#pragma mark INITIALIZATION
#pragma mark -

//---------- lineWithDirectiveText: ----------------------------------[static]--
//
// Purpose:		Given a line from an LDraw file, parse a line primitive.
//
//				directive should have the format:
//
//				2 colour x1 y1 z1 x2 y2 z2 
//
//------------------------------------------------------------------------------
+ (LDrawLine *) lineWithDirectiveText:(NSString *)directive
{
	return [LDrawLine directiveWithString:directive];
	
}//end lineWithDirectiveText:


//---------- directiveWithString: ------------------------------------[static]--
//
// Purpose:		Returns the LDraw directive based on lineFromFile, a single line 
//				of LDraw code from a file.
//
//------------------------------------------------------------------------------
+ (id) directiveWithString:(NSString *)lineFromFile
{
	LDrawLine		*parsedLDrawLine = nil;
	NSString		*workingLine = lineFromFile;
	NSString		*parsedField;
	
	Point3		 workingVertex;
	
	//A malformed part could easily cause a string indexing error, which would 
	// raise an exception. We don't want this to happen here.
	@try
	{
		//Read in the line code and advance past it.
		parsedField = [LDrawUtilities readNextField:  workingLine
										  remainder: &workingLine ];
		//Only attempt to create the part if this is a valid line.
		if([parsedField integerValue] == 2){
			parsedLDrawLine = [[LDrawLine new] autorelease];
			
			//Read in the color code.
			// (color)
			parsedField = [LDrawUtilities readNextField:  workingLine
											  remainder: &workingLine ];
			[parsedLDrawLine setLDrawColor:[parsedField intValue]];
			
			//Read Vertex 1.
			// (x1)
			parsedField = [LDrawUtilities readNextField:workingLine  remainder: &workingLine ];
			workingVertex.x = [parsedField floatValue];
			// (y1)
			parsedField = [LDrawUtilities readNextField:workingLine  remainder: &workingLine ];
			workingVertex.y = [parsedField floatValue];
			// (z1)
			parsedField = [LDrawUtilities readNextField:workingLine  remainder: &workingLine ];
			workingVertex.z = [parsedField floatValue];
			
			[parsedLDrawLine setVertex1:workingVertex];
				
			//Read Vertex 2.
			// (x2)
			parsedField = [LDrawUtilities readNextField:workingLine  remainder: &workingLine ];
			workingVertex.x = [parsedField floatValue];
			// (y2)
			parsedField = [LDrawUtilities readNextField:workingLine  remainder: &workingLine ];
			workingVertex.y = [parsedField floatValue];
			// (z2)
			parsedField = [LDrawUtilities readNextField:workingLine  remainder: &workingLine ];
			workingVertex.z = [parsedField floatValue];
			
			[parsedLDrawLine setVertex2:workingVertex];
		}
	}
	@catch(NSException *exception)
	{	
		NSLog(@"the line primitive %@ was fatally invalid", lineFromFile);
		NSLog(@" raised exception %@", [exception name]);
	}
	
	return parsedLDrawLine;
	
}//end directiveWithString:


//========== initWithCoder: ====================================================
//
// Purpose:		Reads a representation of this object from the given coder,
//				which is assumed to always be a keyed decoder. This allows us to 
//				read and write LDraw objects as NSData.
//
//==============================================================================
- (id) initWithCoder:(NSCoder *)decoder
{
	const uint8_t *temporary = NULL; //pointer to a temporary buffer returned by the decoder.
	
	self		= [super initWithCoder:decoder];
	
	//Decoding structures is a bit messy.
	temporary	= [decoder decodeBytesForKey:@"vertex1" returnedLength:NULL];
	memcpy(&vertex1, temporary, sizeof(Point3));
	
	temporary	= [decoder decodeBytesForKey:@"vertex2" returnedLength:NULL];
	memcpy(&vertex2, temporary, sizeof(Point3));
	
	return self;
	
}//end initWithCoder:


//========== encodeWithCoder: ==================================================
//
// Purpose:		Writes a representation of this object to the given coder,
//				which is assumed to always be a keyed decoder. This allows us to 
//				read and write LDraw objects as NSData.
//
//==============================================================================
- (void) encodeWithCoder:(NSCoder *)encoder
{
	[super encodeWithCoder:encoder];
	
	[encoder encodeBytes:(void *)&vertex1 length:sizeof(Point3) forKey:@"vertex1"];
	[encoder encodeBytes:(void *)&vertex2 length:sizeof(Point3) forKey:@"vertex2"];
		
}//end encodeWithCoder:


//========== copyWithZone: =====================================================
//
// Purpose:		Returns a duplicate of this file.
//
//==============================================================================
- (id) copyWithZone:(NSZone *)zone
{
	LDrawLine *copied = (LDrawLine *)[super copyWithZone:zone];
	
	[copied setVertex1:[self vertex1]];
	[copied setVertex2:[self vertex2]];
	
	return copied;
	
}//end copyWithZone:


#pragma mark -
#pragma mark DIRECTIVES
#pragma mark -

//========== drawElement:parentColor: ==========================================
//
// Purpose:		Draws the graphic of the element represented. This call is a 
//				subroutine of -draw: in LDrawDrawableElement.
//
//==============================================================================
- (void) drawElement:(NSUInteger) optionsMask withColor:(GLfloat *)drawingColor
{
	//Have we already begun drawing somewhere upstream? If so, all we need to 
	// do here is add the vertices.
	if((optionsMask & DRAW_BEGUN) != 0)
	{
		glColor4fv(drawingColor);
		glNormal3f(0.0, -1.0, 0.0); //lines need normals! Who knew?
		glVertex3f(vertex1.x, vertex1.y, vertex1.z);
		
		glColor4fv(drawingColor);
		glNormal3f(0.0, -1.0, 0.0);
		glVertex3f(vertex2.x, vertex2.y, vertex2.z);
	}
	//Drawing not begun; we must start it explicitly.
	else
	{
		glBegin(GL_LINES);
		
			glColor4fv(drawingColor);
			glNormal3f(0.0, -1.0, 0.0);
			glVertex3f(vertex1.x, vertex1.y, vertex1.z);
			
			glColor4fv(drawingColor);
			glNormal3f(0.0, -1.0, 0.0);
			glVertex3f(vertex2.x, vertex2.y, vertex2.z);
			
		glEnd();
	}

}//end drawElement:drawingColor:


//========== write =============================================================
//
// Purpose:		Returns a line that can be written out to a file.
//				Line format:
//				2 colour x1 y1 z1 x2 y2 z2 
//
//==============================================================================
- (NSString *) write
{
	return [NSString stringWithFormat:
				@"2 %3d %12f %12f %12f %12f %12f %12f",
				color,
				
				vertex1.x,
				vertex1.y,
				vertex1.z,
				
				vertex2.x,
				vertex2.y,
				vertex2.z
				
			];
}//end write


#pragma mark -
#pragma mark DISPLAY
#pragma mark -

//========== browsingDescription ===============================================
//
// Purpose:		Returns a representation of the directive as a short string 
//				which can be presented to the user.
//
//==============================================================================
- (NSString *) browsingDescription
{
	return NSLocalizedString(@"Line", nil);
	
}//end browsingDescription


//========== iconName ==========================================================
//
// Purpose:		Returns the name of image file used to display this kind of 
//				object, or nil if there is no icon.
//
//==============================================================================
- (NSString *) iconName
{
	return @"Line";
	
}//end iconName


//========== inspectorClassName ================================================
//
// Purpose:		Returns the name of the class used to inspect this one.
//
//==============================================================================
- (NSString *) inspectorClassName
{
	return @"InspectionLine";
	
}//end inspectorClassName


#pragma mark -
#pragma mark ACCESSORS
#pragma mark -

//========== boundingBox3 ======================================================
//
// Purpose:		Returns the minimum and maximum points of the box which 
//				perfectly contains this object.
//
//==============================================================================
- (Box3) boundingBox3
{
	Box3 bounds = V3BoundsFromPoints(vertex1, vertex2);
	
	return bounds;
	
}//end boundingBox3


//========== position ==========================================================
//
// Purpose:		Returns some position for the element. This is used by 
//				drag-and-drop. This is not necessarily human-usable information.
//
//==============================================================================
- (Point3) position
{
	return self->vertex1;
	
}//end position


//========== vertex1 ===========================================================
//
// Purpose:		Returns the line's start point.
//
//==============================================================================
- (Point3) vertex1
{
	return vertex1;
	
}//end vertex1

//========== vertex2 ===========================================================
//
// Purpose:		Returns the line's end point.
//
//==============================================================================
- (Point3) vertex2
{
	return vertex2;
	
}//end vertex2


#pragma mark -

//========== setVertex1: =======================================================
//
// Purpose:		Sets the line's start point.
//
//==============================================================================
-(void) setVertex1:(Point3)newVertex
{
	vertex1 = newVertex;
	
}//end setVertex1:


//========== setVertex2: =======================================================
//
// Purpose:		Sets the line's end point.
//
//==============================================================================
-(void) setVertex2:(Point3)newVertex
{
	vertex2 = newVertex;
	
}//end setVertex2:


#pragma mark -
#pragma mark ACTIONS
#pragma mark -

//========== moveBy: ============================================================
//
// Purpose:		Moves the receiver in the specified direction.
//
//==============================================================================
- (void) moveBy:(Vector3)moveVector
{
	vertex1.x += moveVector.x;
	vertex1.y += moveVector.y;
	vertex1.z += moveVector.z;
	
	vertex2.x += moveVector.x;
	vertex2.y += moveVector.y;
	vertex2.z += moveVector.z;
	
}//end moveBy:


#pragma mark -
#pragma mark UTILITIES
#pragma mark -

//========== flattenIntoLines:triangles:quadrilaterals:other:currentColor: =====
//
// Purpose:		Appends the directive into the appropriate container. 
//
//==============================================================================
- (void) flattenIntoLines:(LDrawStep *)lines
				triangles:(LDrawStep *)triangles
		   quadrilaterals:(LDrawStep *)quadrilaterals
					other:(LDrawStep *)everythingElse
			 currentColor:(LDrawColorT)parentColor
		 currentTransform:(Matrix4)transform
{
	[super flattenIntoLines:lines triangles:triangles quadrilaterals:quadrilaterals other:everythingElse currentColor:parentColor currentTransform:transform];
	
	self->vertex1 = V3MulPointByProjMatrix(self->vertex1, transform);
	self->vertex2 = V3MulPointByProjMatrix(self->vertex2, transform);
	
	[lines addDirective:self];
	
}//end flattenIntoLines:triangles:quadrilaterals:other:currentColor:


//========== registerUndoActions ===============================================
//
// Purpose:		Registers the undo actions that are unique to this subclass, 
//				not to any superclass.
//
//==============================================================================
- (void) registerUndoActions:(NSUndoManager *)undoManager
{

	[super registerUndoActions:undoManager];

	[[undoManager prepareWithInvocationTarget:self] setVertex2:[self vertex2]];
	[[undoManager prepareWithInvocationTarget:self] setVertex1:[self vertex1]];
	
	[undoManager setActionName:NSLocalizedString(@"UndoAttributesLine", nil)];
	
}//end registerUndoActions:


@end
