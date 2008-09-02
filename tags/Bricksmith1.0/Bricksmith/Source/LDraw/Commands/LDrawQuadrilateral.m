//==============================================================================
//
// File:		LDrawQuadrilateral.m
//
// Purpose:		Quadrilateral command.
//				Draws a four-sided, filled shape between four points.
//
//				Line format:
//				4 colour x1 y1 z1 x2 y2 z2 x3 y3 z3 x4 y4 z4 
//
//				where
//
//				* colour is a colour code: 0-15, 16, 24, 32-47, 256-511
//				* x1, y1, z1 is the position of the first point
//				* x2, y2, z2 is the position of the second point
//				* x3, y3, z3 is the position of the third point
//				* x4, y4, z4 is the position of the fourth point 
//
//  Created by Allen Smith on 2/19/05.
//  Copyright (c) 2005. All rights reserved.
//==============================================================================
#import "LDrawQuadrilateral.h"

#import "MacLDraw.h"

@implementation LDrawQuadrilateral

#pragma mark -
#pragma mark INITIALIZATION
#pragma mark -


//========== quadrilateralWithDirectiveText: =========================================
//
// Purpose:		Given a line from an LDraw file, parse a triangle primitive.
//
//				directive should have the format:
//
//				4 colour x1 y1 z1 x2 y2 z2 x3 y3 z3 x4 y4 z4 
//
//==============================================================================
+ (LDrawQuadrilateral *) quadrilateralWithDirectiveText:(NSString *)directive{
	return [LDrawQuadrilateral directiveWithString:directive];
}


//========== directiveWithString: ==============================================
//
// Purpose:		Returns the LDraw directive based on lineFromFile, a single line 
//				of LDraw code from a file.
//
//==============================================================================
+ (id) directiveWithString:(NSString *)lineFromFile{
	
	LDrawQuadrilateral	*parsedQuadrilateral = nil;
	NSString			*workingLine = lineFromFile;
	NSString			*parsedField;
	
	Point3			 workingVertex;
	
	//A malformed part could easily cause a string indexing error, which would 
	// raise an exception. We don't want this to happen here.
	NS_DURING
		//Read in the line code and advance past it.
		parsedField = [LDrawDirective readNextField:  workingLine
										  remainder: &workingLine ];
		//Only attempt to create the part if this is a valid line.
		if([parsedField intValue] == 4){
			parsedQuadrilateral = [LDrawQuadrilateral new];
			
			//Read in the color code.
			// (color)
			parsedField = [LDrawDirective readNextField:  workingLine
											  remainder: &workingLine ];
			[parsedQuadrilateral setLDrawColor:[parsedField intValue]];
			
			//Read Vertex 1.
			// (x1)
			parsedField = [LDrawDirective readNextField:workingLine  remainder: &workingLine ];
			workingVertex.x = [parsedField floatValue];
			// (y1)
			parsedField = [LDrawDirective readNextField:workingLine  remainder: &workingLine ];
			workingVertex.y = [parsedField floatValue];
			// (z1)
			parsedField = [LDrawDirective readNextField:workingLine  remainder: &workingLine ];
			workingVertex.z = [parsedField floatValue];
			
			[parsedQuadrilateral setVertex1:workingVertex];
				
			//Read Vertex 2.
			// (x2)
			parsedField = [LDrawDirective readNextField:workingLine  remainder: &workingLine ];
			workingVertex.x = [parsedField floatValue];
			// (y2)
			parsedField = [LDrawDirective readNextField:workingLine  remainder: &workingLine ];
			workingVertex.y = [parsedField floatValue];
			// (z2)
			parsedField = [LDrawDirective readNextField:workingLine  remainder: &workingLine ];
			workingVertex.z = [parsedField floatValue];
			
			[parsedQuadrilateral setVertex2:workingVertex];
			
			//Read Vertex 3.
			// (x3)
			parsedField = [LDrawDirective readNextField:workingLine  remainder: &workingLine ];
			workingVertex.x = [parsedField floatValue];
			// (y3)
			parsedField = [LDrawDirective readNextField:workingLine  remainder: &workingLine ];
			workingVertex.y = [parsedField floatValue];
			// (z3)
			parsedField = [LDrawDirective readNextField:workingLine  remainder: &workingLine ];
			workingVertex.z = [parsedField floatValue];
			
			[parsedQuadrilateral setVertex3:workingVertex];
			
			//Read Vertex 4.
			// (x4)
			parsedField = [LDrawDirective readNextField:workingLine  remainder: &workingLine ];
			workingVertex.x = [parsedField floatValue];
			// (y4)
			parsedField = [LDrawDirective readNextField:workingLine  remainder: &workingLine ];
			workingVertex.y = [parsedField floatValue];
			// (z4)
			parsedField = [LDrawDirective readNextField:workingLine  remainder: &workingLine ];
			workingVertex.z = [parsedField floatValue];
			
			[parsedQuadrilateral setVertex4:workingVertex];
			
		}
		
	NS_HANDLER
		NSLog(@"the quadrilateral primitive %@ was fatally invalid", lineFromFile);
		NSLog(@" raised exception %@", [localException name]);
	NS_ENDHANDLER
	
	return parsedQuadrilateral;
}//end directiveWithString


//========== initWithCoder: ====================================================
//
// Purpose:		Reads a representation of this object from the given coder,
//				which is assumed to always be a keyed decoder. This allows us to 
//				read and write LDraw objects as NSData.
//
//==============================================================================
- (id)initWithCoder:(NSCoder *)decoder
{
	const uint8_t *temporary = NULL; //pointer to a temporary buffer returned by the decoder.
	
	self = [super initWithCoder:decoder];
	
	//Decoding structures is a bit messy.
	temporary = [decoder decodeBytesForKey:@"vertex1" returnedLength:NULL];
	memcpy(&vertex1, temporary, sizeof(Point3));
	
	temporary = [decoder decodeBytesForKey:@"vertex2" returnedLength:NULL];
	memcpy(&vertex2, temporary, sizeof(Point3));
	
	temporary = [decoder decodeBytesForKey:@"vertex3" returnedLength:NULL];
	memcpy(&vertex3, temporary, sizeof(Point3));
	
	temporary = [decoder decodeBytesForKey:@"vertex4" returnedLength:NULL];
	memcpy(&vertex4, temporary, sizeof(Point3));
	
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
	[encoder encodeInt:color forKey:@"color"];
	[encoder encodeBytes:(void *)&vertex1 length:sizeof(Point3) forKey:@"vertex1"];
	[encoder encodeBytes:(void *)&vertex2 length:sizeof(Point3) forKey:@"vertex2"];
	[encoder encodeBytes:(void *)&vertex3 length:sizeof(Point3) forKey:@"vertex3"];
	[encoder encodeBytes:(void *)&vertex4 length:sizeof(Point3) forKey:@"vertex4"];
	
}


//========== copyWithZone: =====================================================
//
// Purpose:		Returns a duplicate of this file.
//
//==============================================================================
- (id) copyWithZone:(NSZone *)zone {
	
	LDrawQuadrilateral *copied = (LDrawQuadrilateral *)[super copyWithZone:zone];
	
	[copied setVertex1:[self vertex1]];
	[copied setVertex2:[self vertex2]];
	[copied setVertex3:[self vertex3]];
	[copied setVertex4:[self vertex4]];
	
	return copied;
}


#pragma mark -
#pragma mark DIRECTIVES
#pragma mark -

//========== drawElement =======================================================
//
// Purpose:		Draws the graphic of the element represented. This call is a 
//				subroutine of -draw: in LDrawDrawableElement.
//
//==============================================================================
- (void) drawElement:(unsigned int) optionsMask parentColor:(GLfloat *)parentColor {
	
	//Have we already begun drawing somewhere upstream? If so, all we need to 
	// do here is add the vertices.
	if((optionsMask & DRAW_BEGUN) != 0) {
		glNormal3f(normal.x, normal.y, normal.z);
		
		glVertex3f(vertex1.x, vertex1.y, vertex1.z);
		glVertex3f(vertex2.x, vertex2.y, vertex2.z);
		glVertex3f(vertex3.x, vertex3.y, vertex3.z);
		glVertex3f(vertex4.x, vertex4.y, vertex4.z);
	}
	//Drawing not begun; we must start it explicitly.
	else {
		glBegin(GL_QUADS);
			glNormal3f(normal.x, normal.y, normal.z);
			
			glVertex3f(vertex1.x, vertex1.y, vertex1.z);
			glVertex3f(vertex2.x, vertex2.y, vertex2.z);
			glVertex3f(vertex3.x, vertex3.y, vertex3.z);
			glVertex3f(vertex4.x, vertex4.y, vertex4.z);
		glEnd();
	}
}


//========== write =============================================================
//
// Purpose:		Returns a line that can be written out to a file.
//				Line format:
//				4 colour x1 y1 z1 x2 y2 z2 x3 y3 z3 x4 y4 z4 
//
//==============================================================================
- (NSString *) write{
	return [NSString stringWithFormat:
				@"4 %3d %12f %12f %12f %12f %12f %12f %12f %12f %12f %12f %12f %12f",
				color,
				
				vertex1.x,
				vertex1.y,
				vertex1.z,
				
				vertex2.x,
				vertex2.y,
				vertex2.z,
				
				vertex3.x,
				vertex3.y,
				vertex3.z,
		
				vertex4.x,
				vertex4.y,
				vertex4.z
		
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
- (NSString *)browsingDescription
{
	return NSLocalizedString(@"Quadrilateral", nil);
}


//========== iconName ==========================================================
//
// Purpose:		Returns the name of image file used to display this kind of 
//				object, or nil if there is no icon.
//
//==============================================================================
- (NSString *) iconName{
	return @"Quadrilateral";
}


//========== inspectorClassName ================================================
//
// Purpose:		Returns the name of the class used to inspect this one.
//
//==============================================================================
- (NSString *) inspectorClassName{
	return @"InspectionQuadrilateral";
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
	
	Box3 bounds12, bounds34, bounds;
	
	V3BoundsFromPoints(&vertex1, &vertex2, &bounds12);
	V3BoundsFromPoints(&vertex3, &vertex4, &bounds34);
	
	//Combine and we have the result. This is yucky.
	bounds.min.x = MIN(bounds12.min.x, bounds34.min.x);
	bounds.min.y = MIN(bounds12.min.y, bounds34.min.y);
	bounds.min.z = MIN(bounds12.min.z, bounds34.min.z);
	
	bounds.max.x = MAX(bounds12.max.x, bounds34.max.x);
	bounds.max.y = MAX(bounds12.max.y, bounds34.max.y);
	bounds.max.z = MAX(bounds12.max.z, bounds34.max.z);
	
	return bounds;
}


//========== vertex1 ===========================================================
//
// Purpose:		Returns the quadrilateral's first vertex.
//
//==============================================================================
- (Point3) vertex1{
	return vertex1;
}

//========== vertex2 ===========================================================
//
// Purpose:		
//
//==============================================================================
- (Point3) vertex2{
	return vertex2;
}

//========== vertex3 ===========================================================
//
// Purpose:		
//
//==============================================================================
- (Point3) vertex3{
	return vertex3;
}

//========== vertex2 ===========================================================
//
// Purpose:		
//
//==============================================================================
- (Point3) vertex4{
	return vertex4;
}

//========== setVertex1: =======================================================
//
// Purpose:		
//
//==============================================================================
-(void) setVertex1:(Point3)newVertex{
	vertex1 = newVertex;
	[self recomputeNormal];
}//end setVertex1


//========== setVertex2: =======================================================
//
// Purpose:		
//
//==============================================================================
-(void) setVertex2:(Point3)newVertex{
	vertex2 = newVertex;
	[self recomputeNormal];
}//end setVertex2


//========== setVertex3: =======================================================
//
// Purpose:		
//
//==============================================================================
-(void) setVertex3:(Point3)newVertex{
	vertex3 = newVertex;
	[self recomputeNormal];
}//end setVertex3


//========== setVertex4: =======================================================
//
// Purpose:		
//
//==============================================================================
-(void) setVertex4:(Point3)newVertex{
	vertex4 = newVertex;
	[self recomputeNormal];
}//end setVertex4


#pragma mark -
#pragma mark ACTIONS
#pragma mark -

//========== nudge: ============================================================
//
// Purpose:		Moves the receiver in the specified direction.
//
//==============================================================================
- (void) nudge:(Vector3)nudgeVector{
	vertex1.x += nudgeVector.x;
	vertex1.y += nudgeVector.y;
	vertex1.z += nudgeVector.z;
	
	vertex2.x += nudgeVector.x;
	vertex2.y += nudgeVector.y;
	vertex2.z += nudgeVector.z;
	
	vertex3.x += nudgeVector.x;
	vertex3.y += nudgeVector.y;
	vertex3.z += nudgeVector.z;
	
	vertex4.x += nudgeVector.x;
	vertex4.y += nudgeVector.y;
	vertex4.z += nudgeVector.z;
}

#pragma mark -
#pragma mark UTILITIES
#pragma mark -

//========== recomputeNormal ===================================================
//
// Purpose:		Finds the normal vector for this surface.
//
//==============================================================================
- (void) recomputeNormal {
	Vector3 vector1, vector2;
	
	V3Sub(&(self->vertex2), &(self->vertex1), &vector1);
	V3Sub(&(self->vertex4), &(self->vertex1), &vector2);
	
	V3Cross(&vector1, &vector2, &(self->normal));
}


//========== registerUndoActions ===============================================
//
// Purpose:		Registers the undo actions that are unique to this subclass, 
//				not to any superclass.
//
//==============================================================================
- (void) registerUndoActions:(NSUndoManager *)undoManager {
	
	[super registerUndoActions:undoManager];
	
	[[undoManager prepareWithInvocationTarget:self] setVertex4:[self vertex4]];
	[[undoManager prepareWithInvocationTarget:self] setVertex3:[self vertex3]];
	[[undoManager prepareWithInvocationTarget:self] setVertex2:[self vertex2]];
	[[undoManager prepareWithInvocationTarget:self] setVertex1:[self vertex1]];
	
	[undoManager setActionName:NSLocalizedString(@"UndoAttributesQuadrilateral", nil)];
}


@end
