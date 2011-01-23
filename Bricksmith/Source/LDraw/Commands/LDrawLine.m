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

#import "LDrawColor.h"
#import "LDrawStep.h"
#import "LDrawUtilities.h"
#import "MacLDraw.h"


@implementation LDrawLine

#pragma mark -
#pragma mark INITIALIZATION
#pragma mark -

//========== initWithLines:inRange:parentGroup: ================================
//
// Purpose:		Returns the LDraw directive based on lineFromFile, a single line 
//				of LDraw code from a file.
//
//				directive should have the format:
//
//				2 colour x1 y1 z1 x2 y2 z2 
//
//==============================================================================
- (id) initWithLines:(NSArray *)lines
			 inRange:(NSRange)range
		 parentGroup:(dispatch_group_t)parentGroup
{
	NSString    *workingLine    = [lines objectAtIndex:range.location];
	NSString    *parsedField    = nil;
	Point3      workingVertex   = ZeroPoint3;
	LDrawColor  *parsedColor    = nil;
	
	self = [super initWithLines:lines inRange:range parentGroup:parentGroup];
	
	//A malformed part could easily cause a string indexing error, which would 
	// raise an exception. We don't want this to happen here.
	@try
	{
		//Read in the line code and advance past it.
		parsedField = [LDrawUtilities readNextField:  workingLine
										  remainder: &workingLine ];
		//Only attempt to create the part if this is a valid line.
		if([parsedField integerValue] == 2)
		{
			//Read in the color code.
			// (color)
			parsedField = [LDrawUtilities readNextField:  workingLine
											  remainder: &workingLine ];
			parsedColor = [LDrawUtilities parseColorFromField:parsedField];
			[self setLDrawColor:parsedColor];
			
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
			
			[self setVertex1:workingVertex];
				
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
			
			[self setVertex2:workingVertex];
		}
		else
			@throw [NSException exceptionWithName:@"BricksmithParseException" reason:@"Bad line syntax" userInfo:nil];
	}
	@catch(NSException *exception)
	{	
		NSLog(@"the line primitive %@ was fatally invalid", [lines objectAtIndex:range.location]);
		NSLog(@" raised exception %@", [exception name]);
		[self release];
		self = nil;
	}
	
	return self;
	
}//end initWithLines:inRange:


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
- (void) drawElement:(NSUInteger) optionsMask withColor:(LDrawColor *)drawingColor
{
//	{
//		glBegin(GL_LINES);
//		
//			glColor4fv(drawingColor);
//			glNormal3f(0.0, -1.0, 0.0);
//			glVertex3f(vertex1.x, vertex1.y, vertex1.z);
//			
//			glColor4fv(drawingColor);
//			glNormal3f(0.0, -1.0, 0.0);
//			glVertex3f(vertex2.x, vertex2.y, vertex2.z);
//			
//		glEnd();
//	}

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
				@"2 %@ %@ %@ %@ %@ %@ %@",
				[LDrawUtilities outputStringForColor:self->color],
				
				[LDrawUtilities outputStringForFloat:vertex1.x],
				[LDrawUtilities outputStringForFloat:vertex1.y],
				[LDrawUtilities outputStringForFloat:vertex1.z],
				
				[LDrawUtilities outputStringForFloat:vertex2.x],
				[LDrawUtilities outputStringForFloat:vertex2.y],
				[LDrawUtilities outputStringForFloat:vertex2.z]				
			];
}//end write


//========== writeElementToVertexBuffer:withColor: =============================
//
// Purpose:		Writes this object into the specified vertex buffer, which is a 
//				pointer to the offset into which the first vertex point's data 
//				is to be stored. Store subsequent vertexs after the first.
//
//==============================================================================
- (VBOVertexData *) writeElementToVertexBuffer:(VBOVertexData *)vertexBuffer
									 withColor:(LDrawColor *)drawingColor
{
	Vector3 normal          = V3Make(0.0, -1.0, 0.0); //lines need normals! Who knew?
	GLfloat components[4]   = {};
	
	[drawingColor getColorRGBA:components];
	
	memcpy(&vertexBuffer[0].position, &vertex1,     sizeof(Point3));
	memcpy(&vertexBuffer[0].normal,   &normal,      sizeof(Point3));
	memcpy(&vertexBuffer[0].color,    components,   sizeof(GLfloat)*4);
	
	memcpy(&vertexBuffer[1].position, &vertex2,     sizeof(Point3));
	memcpy(&vertexBuffer[1].normal,   &normal,      sizeof(Point3));
	memcpy(&vertexBuffer[1].color,    components,   sizeof(GLfloat)*4);
	
	return vertexBuffer + 2;
	
}//end writeElementToVertexBuffer:withColor:


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
- (void) flattenIntoLines:(NSMutableArray *)lines
				triangles:(NSMutableArray *)triangles
		   quadrilaterals:(NSMutableArray *)quadrilaterals
					other:(NSMutableArray *)everythingElse
			 currentColor:(LDrawColor *)parentColor
		 currentTransform:(Matrix4)transform
		  normalTransform:(Matrix3)normalTransform
				recursive:(BOOL)recursive
{
	[super flattenIntoLines:lines
				  triangles:triangles
			 quadrilaterals:quadrilaterals
					  other:everythingElse
			   currentColor:parentColor
		   currentTransform:transform
			normalTransform:normalTransform
				  recursive:recursive];
	
	self->vertex1 = V3MulPointByProjMatrix(self->vertex1, transform);
	self->vertex2 = V3MulPointByProjMatrix(self->vertex2, transform);
	
	[lines addObject:self];
	
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
