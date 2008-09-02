/*
 *  MatrixMath.c
 *  Bricksmith
 *
 */

#include "MatrixMath.h"
#include <math.h>
#include <stdio.h>
#include <stdlib.h>

//Box which represents no bounds. It is defined in such a way that it can 
// be used transparently in size comparisons -- its minimum is inifinity,
// so any valid point will be smaller than that!
const Box3 InvalidBox = {	INFINITY,
							INFINITY,
							INFINITY,
							
							-INFINITY,
							-INFINITY,
							-INFINITY   };
							
const TransformationComponents IdentityComponents = {
							1, //scale_X;
							1, //scale_Y;
							1, //scale_Z;
							0, //shear_XY;
							0, //shear_XZ;
							0, //shear_YZ;
							0, //rotate_X; //in radians
							0, //rotate_Y; //in radians
							0, //rotate_Z; //in radians
							0, //translate_X;
							0, //translate_Y;
							0, //translate_Z;
							0, //perspective_X;
							0, //perspective_Y;
							0, //perspective_Z;
							0, //perspective_W;
						};


#pragma mark 2-D LIBRARY
#pragma mark -

/*
 * float = det2x2( float a, float b, float c, float d )
 * 
 * calculate the determinant of a 2x2 matrix.
 */
float det2x2( float a, float b, float c, float d)
{
    float ans;
    ans = a * d - b * c;
    return ans;
}


#pragma mark -
#pragma mark 3-D LIBRARY
#pragma mark -

/******************/
/*   3d Library   */
/******************/

/* create, initialize, and return a new vector */
Vector3 *V3New(float x, float y, float z)
{
	Vector3 *v = NEWTYPE(Vector3);
	v->x = x;  v->y = y;  v->z = z;
	return(v);
}

/* create, initialize, and return a duplicate vector */
Vector3 *V3Duplicate(Vector3 *a)
{
	Vector3 *v = NEWTYPE(Vector3);
	v->x = a->x;  v->y = a->y;  v->z = a->z;
	return(v);
}

//========== V3FromV4 ==========================================================
//
// Purpose:		Create a new 3D vector whose components match the given 4D 
//				vector. Using this function is really only sensible when the 4D 
//				vector is really a 3D one being used for convenience in 4D math.
//
//==============================================================================
Vector3 V3FromV4(Vector4 *originalVector) {
	Vector3 newVector;
	
	//This is very bad.
	if(originalVector->w != 1)
		printf("lossy 4D vector conversion: <%f, %f, %f, %f>\n", originalVector->x, originalVector->y, originalVector->z, originalVector->w);
	
	newVector.x = originalVector->x;
	newVector.y = originalVector->y;
	newVector.z = originalVector->z;
	
	return newVector;
}


#pragma mark -

/* returns squared length of input vector */	
float V3SquaredLength(Vector3 *a) 
{
	return((a->x * a->x)+(a->y * a->y)+(a->z * a->z));
}

/* returns length of input vector */
float V3Length(Vector3 *a) 
{
	return(sqrt(V3SquaredLength(a)));
}

/* negates the input vector and returns it */
Vector3 *V3Negate(Vector3 *v) 
{
	v->x = -v->x;  v->y = -v->y;  v->z = -v->z;
	return(v);
}

/* normalizes the input vector and returns it */
Vector3 *V3Normalize(Vector3 *v) 
{
	float len = V3Length(v);
	if (len != 0.0) { v->x /= len;  v->y /= len; v->z /= len; }
	return(v);
}

/* scales the input vector to the new length and returns it */
Vector3 *V3Scale(Vector3 *v, float newlen) 
{
	float len = V3Length(v);
	if (len != 0.0) {
		v->x *= newlen/len;   v->y *= newlen/len;  v->z *= newlen/len;
	}
	return(v);
}


/* return vector sum c = a+b */
Vector3 *V3Add(Vector3 *a, Vector3 *b, Vector3 *c)
{
	c->x = a->x+b->x;  c->y = a->y+b->y;  c->z = a->z+b->z;
	return(c);
}

/* return vector difference c = a-b */
Vector3 *V3Sub(Vector3 *a, Vector3 *b, Vector3 *c)
{
	c->x = a->x-b->x;  c->y = a->y-b->y;  c->z = a->z-b->z;
	return(c);
}

/* return the dot product of vectors a and b */
float V3Dot(Vector3 *a, Vector3 *b) 
{
	return((a->x*b->x)+(a->y*b->y)+(a->z*b->z));
}

/* linearly interpolate between vectors by an amount alpha */
/* and return the resulting vector. */
/* When alpha=0, result=lo.  When alpha=1, result=hi. */
Vector3 *V3Lerp(Vector3 *lo, Vector3 *hi, float alpha, Vector3 *result) 
{
	result->x = LERP(alpha, lo->x, hi->x);
	result->y = LERP(alpha, lo->y, hi->y);
	result->z = LERP(alpha, lo->z, hi->z);
	return(result);
}

/* make a linear combination of two vectors and return the result. */
/* result = (a * ascl) + (b * bscl) */
Vector3 *V3Combine (Vector3 *a, Vector3 *b, Vector3 *result, float ascl, float bscl) 
{
	result->x = (ascl * a->x) + (bscl * b->x);
	result->y = (ascl * a->y) + (bscl * b->y);
	result->z = (ascl * a->z) + (bscl * b->z);
	return(result);
}


/* multiply two vectors together component-wise and return the result */
Vector3 *V3Mul (Vector3 *a, Vector3 *b, Vector3 *result) 
{
	result->x = a->x * b->x;
	result->y = a->y * b->y;
	result->z = a->z * b->z;
	return(result);
}

/* return the distance between two points */
float V3DistanceBetween2Points(Point3 *a, Point3 *b)
{
	float dx = a->x - b->x;
	float dy = a->y - b->y;
	float dz = a->z - b->z;
	return(sqrt((dx*dx)+(dy*dy)+(dz*dz)));
}

/* return the cross product c = a cross b */
Vector3 *V3Cross(Vector3 *a, Vector3 *b, Vector3 *c)
{
	c->x = (a->y*b->z) - (a->z*b->y);
	c->y = (a->z*b->x) - (a->x*b->z);
	c->z = (a->x*b->y) - (a->y*b->x);
	return(c);
}


//========== V3Midpoint ========================================================
//
// Purpose:		Returns the midpoint of the line segment between point1 and 
//				point2.
//
//==============================================================================
Point3 V3Midpoint(Point3 *point1, Point3 *point2) {
	Point3 midpoint;
	midpoint.x = (point1->x + point2->x)/2;
	midpoint.y = (point1->y + point2->y)/2;
	midpoint.z = (point1->z + point2->z)/2;
	
	return midpoint;
}//end V3Midpoint


//========== V3BoundsFromPoints ================================================
//
// Purpose:		Sorts the points into their minimum and maximum.
//
//==============================================================================
Box3 *V3BoundsFromPoints(Point3 *point1, Point3 *point2, Box3 *bounds) {
	bounds->min.x = MIN(point1->x, point2->x);
	bounds->min.y = MIN(point1->y, point2->y);
	bounds->min.z = MIN(point1->z, point2->z);
	
	bounds->max.x = MAX(point1->x, point2->x);
	bounds->max.y = MAX(point1->y, point2->y);
	bounds->max.z = MAX(point1->z, point2->z);
	
	return bounds;
}


//========== V3EqualsBoxes =====================================================
//
// Purpose:		Returns 1 (YES) if the two boxes are equal; 0 otherwise.
//
//==============================================================================
extern int V3EqualsBoxes(Box3 *box1, Box3 *box2){
	return (	box1->min.x == box2->min.x,
				box1->min.y == box2->min.y,
				box1->min.z == box2->min.z,
				
				box1->max.x == box2->max.x,
				box1->max.y == box2->max.y,
				box1->max.z == box2->max.z  );
}


//========== V3IsolateGreatestComponent ========================================
//
// Purpose:		Leaves unchanged the component of vector which has the greatest 
//				absolute value, but zeroes the other components. 
//				Example: <4, -7, 1> -> <0, -7, 0>.
//				This is useful for figuring out the direction of input.
//
//==============================================================================
Vector3 *V3IsolateGreatestComponent(Vector3 *vector) {

	if(fabs(vector->x) > fabs(vector->y) ){
		vector->y = 0;
		if(fabs(vector->x) > fabs(vector->z) )
			vector->z = 0;
		else
			vector->x = 0;
	}
	else{
		vector->x = 0;
		if(fabs(vector->y) > fabs(vector->z) )
			vector->z = 0;
		else
			vector->y = 0;
	}
	
	return vector;
}


/* multiply a point by a matrix and return the transformed point */
Point3 *V3MulPointByMatrix(pin, m, pout)
Point3 *pin, *pout;
Matrix3 *m;
{
	pout->x = (pin->x * m->element[0][0]) + (pin->y * m->element[1][0]) + 
	(pin->z * m->element[2][0]);
	pout->y = (pin->x * m->element[0][1]) + (pin->y * m->element[1][1]) + 
		(pin->z * m->element[2][1]);
	pout->z = (pin->x * m->element[0][2]) + (pin->y * m->element[1][2]) + 
		(pin->z * m->element[2][2]);
	return(pout);
}

/* multiply a point by a projective matrix and return the transformed point */
Point3 *V3MulPointByProjMatrix(pin, m, pout)
Point3 *pin, *pout;
Matrix4 *m;
{
	float w;
	pout->x = (pin->x * m->element[0][0]) + (pin->y * m->element[1][0]) + 
		(pin->z * m->element[2][0]) + m->element[3][0];
	pout->y = (pin->x * m->element[0][1]) + (pin->y * m->element[1][1]) + 
		(pin->z * m->element[2][1]) + m->element[3][1];
	pout->z = (pin->x * m->element[0][2]) + (pin->y * m->element[1][2]) + 
		(pin->z * m->element[2][2]) + m->element[3][2];
	w =    (pin->x * m->element[0][3]) + (pin->y * m->element[1][3]) + 
		(pin->z * m->element[2][3]) + m->element[3][3];
	if (w != 0.0) { pout->x /= w;  pout->y /= w;  pout->z /= w; }
	return(pout);
}

/* multiply together matrices c = ab */
/* note that c must not point to either of the input matrices */
Matrix4 *V3MatMul(Matrix4 *a, Matrix4 *b, Matrix4 *c)
{
	int i, j, k;
	for (i=0; i<4; i++) {
		for (j=0; j<4; j++) {
			c->element[i][j] = 0;
			for (k=0; k<4; k++) c->element[i][j] += 
				a->element[i][k] * b->element[k][j];
		}
	}
	return(c);
}

/*
 * float = det3x3(  a1, a2, a3, b1, b2, b3, c1, c2, c3 )
 * 
 * calculate the determinant of a 3x3 matrix
 * in the form
 *
 *     | a1,  b1,  c1 |
 *     | a2,  b2,  c2 |
 *     | a3,  b3,  c3 |
 */

float det3x3( a1, a2, a3, b1, b2, b3, c1, c2, c3 )
float a1, a2, a3, b1, b2, b3, c1, c2, c3;
{
    float ans;
	
    ans = a1 * det2x2( b2, b3, c2, c3 )
        - b1 * det2x2( a2, a3, c2, c3 )
        + c1 * det2x2( a2, a3, b2, b3 );
    return ans;
}

#pragma mark -
#pragma mark 4-D LIBRARY
#pragma mark -

//========== V3FromV4 ==========================================================
//
// Purpose:		Create a new 4D vector whose components match the given 3D 
//				vector, with a 1 in the 4th dimension.
//
//==============================================================================
Vector4 V4FromV3(Vector3 *originalVector) {
	Vector4 newVector;
	
	newVector.x = originalVector->x;
	newVector.y = originalVector->y;
	newVector.z = originalVector->z;
	newVector.w = 1;
	
	return newVector;
}

//========== matrix4FromGLMatrix4() ============================================
//
// Purpose:		Returns a two-dimensional (row matrix) representation of the 
//				given OpenGL transformation matrix.
//
//																+-       -+
//				+-                           -+        +-     -+| a d g 0 |
//				|a d g 0 b e h c f i 0 x y z 1|  -->   |x y z 1|| b e h 0 |
//				+-                           -+        +-     -+| c f i 0 |
//																| x y z 1 |
//																+-       -+
//					  OpenGL Matrix Format                Matrix4 Format
//				(flat column-major of transpose)   (shown multiplied by a point)  
//
//==============================================================================
Matrix4 matrix4FromGLMatrix4(const GLfloat *glMatrix) {
	int		row, column;
	Matrix4	newMatrix;
	
	for(row = 0; row < 4; row++)
		for(column = 0; column < 4; column++)
			newMatrix.element[row][column] = glMatrix[row * 4 + column];
	
	return newMatrix;
}


//========== createTransformationMatrix() ======================================
//
// Purpose:		Given the scale, shear, rotation, translation, and perspective 
//				paramaters, create a 4x4 transformation.element matrix used to modify 
//				row-matrix points.
//
//				To reverse the procedure, pass the returned matrix to unmatrix().
//
// Notes:		This ignores perspective, which is not supported.
//
// Source:		Allen Smith, after too much handwork.
//
//==============================================================================
Matrix4 createTransformationMatrix(TransformationComponents *components) {

	Matrix4 transformation = {0}; //zero out the whole thing.
	float rotation[3][3];
	
	//Create the rotation matrix.
	double sinX = sin(components->rotate_X);
	double cosX = cos(components->rotate_X);
	
	double sinY = sin(components->rotate_Y);
	double cosY = cos(components->rotate_Y);
	
	double sinZ = sin(components->rotate_Z);
	double cosZ = cos(components->rotate_Z);
	
	rotation[0][0] = cosY * cosZ;
	rotation[0][1] = cosY * sinZ;
	rotation[0][2] = -sinY;
	
	rotation[1][0] = sinX*sinY*cosZ - cosX*sinZ;
	rotation[1][1] = sinX*sinY*sinZ + cosX*cosZ;
	rotation[1][2] = sinX*cosY;
	
	rotation[2][0] = cosX*sinY*cosZ + sinX*sinZ;
	rotation[2][1] = cosX*sinY*sinZ - sinX*cosZ;
	rotation[2][2] = cosX*cosY;
	
	//Build the transformation.element matrix.
	// Seeing the transformation.element matrix in these terms helps to make sense of unmatrix().
	transformation.element[0][0] = components->scale_X * rotation[0][0];
	transformation.element[0][1] = components->scale_X * rotation[0][1];
	transformation.element[0][2] = components->scale_X * rotation[0][2];

	transformation.element[1][0] = components->scale_Y * (components->shear_XY * rotation[0][0] + rotation[1][0]);
	transformation.element[1][1] = components->scale_Y * (components->shear_XY * rotation[0][1] + rotation[1][1]);
	transformation.element[1][2] = components->scale_Y * (components->shear_XY * rotation[0][2] + rotation[1][2]);

	transformation.element[2][0] = components->scale_Z * (components->shear_XZ * rotation[0][0] + components->shear_YZ * rotation[1][0] + rotation[2][0]);
	transformation.element[2][1] = components->scale_Z * (components->shear_XZ * rotation[0][1] + components->shear_YZ * rotation[1][1] + rotation[2][1]);
	transformation.element[2][2] = components->scale_Z * (components->shear_XZ * rotation[0][2] + components->shear_YZ * rotation[1][2] + rotation[2][2]);
	
	//translation is so nice and easy.
	transformation.element[3][0] = components->translate_X;
	transformation.element[3][1] = components->translate_Y;
	transformation.element[3][2] = components->translate_Z;
	
	//And lastly the corner.
	transformation.element[3][3] = 1;
	
	return transformation;
}

#pragma mark -

//========== unmatrix() ========================================================
//
// Purpose:		Decompose a non-degenerate 4x4 transformation.element matrix into
//				the sequence of transformations that produced it.
//
//		[Sx][Sy][Sz][Shearx/y][Sx/z][Sz/y][Rx][Ry][Rz][Tx][Ty][Tz][P(x,y,z,w)]
//
//				The coefficient of each transformation.element is returned in the 
//				corresponding element of the vector tran.
//
// Returns:		1 upon success, 0 if the matrix is singular.
//
// Source:		Graphic Gems II, Spencer W. Thomas
//
//==============================================================================
int unmatrix( Matrix4 *originalMatrix, TransformationComponents *decomposed )
{
	int counter, j;
	Matrix4 localMatrix;
	Matrix4 pmat, invpmat, tinvpmat;
	Vector4 prhs, psol;
	Point3 row[3], dummyPoint;
	
	localMatrix = *originalMatrix;
	
 	// Normalize the matrix.
 	if ( localMatrix.element[3][3] == 0 )
 		return 0;
	
 	for ( counter=0; counter<4;counter++ )
 		for ( j=0; j<4; j++ )
 			localMatrix.element[counter][j] /= localMatrix.element[3][3];
	
 	//pmat is used to solve for perspective, but it also provides
	//an easy way to test for singularity of the upper 3x3 component.
 	pmat = localMatrix;
 	for ( counter = 0; counter < 3; counter++ )
 		pmat.element[counter][3] = 0;
 	pmat.element[3][3] = 1;
	
 	if ( det4x4(&pmat) == 0.0 )
 		return 0;
	
 	// First, isolate perspective.  This is the messiest.
	// Perspective is not used by Bricksmith.
 	if ( localMatrix.element[0][3] != 0 || localMatrix.element[1][3] != 0 ||
		 localMatrix.element[2][3] != 0 ) {
 		// prhs is the right hand side of the equation.
 		prhs.x = localMatrix.element[0][3];
 		prhs.y = localMatrix.element[1][3];
 		prhs.z = localMatrix.element[2][3];
 		prhs.w = localMatrix.element[3][3];
		
 		// Solve the equation by inverting pmat and multiplying
		// prhs by the inverse.  (This is the easiest way, not
		// necessarily the best.)
		// inverse function (and det4x4, above) from the Matrix
		// Inversion gem in the first volume.
 		inverse( &pmat, &invpmat );
		transposeMatrix4( &invpmat, &tinvpmat );
 		V4MulPointByMatrix(&prhs, &tinvpmat, &psol);
		
 		// Stuff the answer away.
 		decomposed->perspective_X = psol.x;
 		decomposed->perspective_Y = psol.y;
 		decomposed->perspective_Z = psol.z;
 		decomposed->perspective_W = psol.w;
 		// Clear the perspective partition.
 		localMatrix.element[0][3] = 0;
		localMatrix.element[1][3] = 0;
		localMatrix.element[2][3] = 0;
 		localMatrix.element[3][3] = 1;
 	}
	//No perspective
	else{
 		decomposed->perspective_X = 0;
		decomposed->perspective_Y = 0;
		decomposed->perspective_Z = 0;
		decomposed->perspective_W = 0;
	}
	
 	// Next take care of translation (easy).
	decomposed->translate_X = localMatrix.element[3][0];
	decomposed->translate_Y = localMatrix.element[3][1];
	decomposed->translate_Z = localMatrix.element[3][2];
	
	//Zero out the translation as we continue to decompose.
	for ( counter = 0; counter < 3; counter++ ) {
		localMatrix.element[3][counter] = 0;
 	}
	
 	// Now get scale and shear.
 	for ( counter=0; counter<3; counter++ ) {
 		row[counter].x = localMatrix.element[counter][0];
 		row[counter].y = localMatrix.element[counter][1];
 		row[counter].z = localMatrix.element[counter][2];
 	}
	
 	// Compute X scale factor and normalize first row.
 	decomposed->scale_X = V3Length(&row[0]);
 	V3Scale(&row[0], 1.0);
	
 	// Compute XY shear factor and make 2nd row orthogonal to 1st.
 	decomposed->shear_XY = V3Dot(&row[0], &row[1]);
 	V3Combine(&row[1], &row[0], &row[1], 1.0, -decomposed->shear_XY);
	
 	// Now, compute Y scale and normalize 2nd row.
 	decomposed->scale_Y = V3Length(&row[1]);
 	V3Scale(&row[1], 1.0);
 	decomposed->shear_XY /= decomposed->scale_Y;
	
 	// Compute XZ and YZ shears, orthogonalize 3rd row.
 	decomposed->shear_XZ = V3Dot(&row[0], &row[2]);
 	V3Combine(&row[2], &row[0], &row[2], 1.0, -decomposed->shear_XZ);
 	decomposed->shear_YZ = V3Dot(&row[1], &row[2]);
 	V3Combine(&row[2], &row[1], &row[2], 1.0, -decomposed->shear_YZ);
	
 	// Next, get Z scale and normalize 3rd row.
 	decomposed->scale_Z = V3Length(&row[2]);
 	V3Scale(&row[2], 1.0);
 	decomposed->shear_XZ /= decomposed->scale_Z;
 	decomposed->shear_YZ /= decomposed->scale_Z;
	
 	// At this point, the matrix (in rows[]) is orthonormal.
 	// Check for a coordinate system flip.  If the determinant
 	// is -1, then negate the matrix and the scaling factors.
 	if ( V3Dot( &row[0], V3Cross( &row[1], &row[2], &dummyPoint) ) < 0 ) {
		
		decomposed->scale_X *= -1;
		decomposed->scale_Y *= -1;
		decomposed->scale_Z *= -1;
		
 		for ( counter = 0; counter < 3; counter++ ) {
 			row[counter].x *= -1;
 			row[counter].y *= -1;
 			row[counter].z *= -1;
 		}
		
	}
	
	// Now, extract the rotation angles.
	// This is just some simple algebra on the simplest components of the 
	// rotation matrix.
	decomposed->rotate_Y = asin(-row[0].z);
 	if ( cos(decomposed->rotate_Y) != 0 ) {
 		decomposed->rotate_X = atan2(row[1].z, row[2].z);
 		decomposed->rotate_Z = atan2(row[0].y, row[0].x);
 	}
	else {
 		decomposed->rotate_X = atan2(-row[2].x, row[1].y);
 		decomposed->rotate_Z = 0;
 	}
	
 	// All done!
 	return 1;
}


//========== rotateMatrix4() ===================================================
//
// Purpose:		Rotates the given matrix by the given number of degrees around 
//				each axis, placing the rotated matrix into the Matrix specified 
//				by the result parameter. Also returns result.
//
// Note:		You may safely pass the same matrix for original and result.
//
//==============================================================================
Matrix4* rotateMatrix4(Matrix4 *original, Tuple3 *degreesToRotate, Matrix4 *result)
{
	TransformationComponents	rotateComponents	= IdentityComponents;
	Matrix4						addedRotation		= {0};
	Matrix4						newMatrix			= {0};

	//Create a new matrix that causes the rotation we want.
	//  (start with identity matrix)
	rotateComponents.rotate_X = radians(degreesToRotate->x);
	rotateComponents.rotate_Y = radians(degreesToRotate->y);
	rotateComponents.rotate_Z = radians(degreesToRotate->z);
	addedRotation = createTransformationMatrix(&rotateComponents);
	
	V3MatMul(original, &addedRotation, &newMatrix); //rotate at rotationCenter
	
	//Copy in the answer. Doing it via the temporary newMatrix variable means we
	// can pass the same parameter for original and result.
	*result = newMatrix;
	
	return result;

}//end rotateMatrix4

//========== translateMatrix4() ================================================
//
// Purpose:		Translates the given matrix by the given displacement, placing 
//				the translated matrix into the Matrix specified by the result 
//				parameter. Also returns result.
//
// Note:		You may safely pass the same matrix for original and result.
//
//==============================================================================
Matrix4* translateMatrix4(Matrix4 *original, Vector3 *displacement, Matrix4 *result){
	//Copy original to result
	if(original != result) //pointer compare
		*result = *original;
	
	result->element[3][0] += displacement->x; //applied directly to 
	result->element[3][1] += displacement->y; //the matrix because 
	result->element[3][2] += displacement->z; //that's easier here.
	
	return result;
}//end translateMatrix4


//========== transposeMatrix4() ================================================
//
// Purpose:		transpose rotation portion of matrix a, return b
//
// Source:		Graphic Gems II, Spencer W. Thomas
//
//==============================================================================
Matrix4 *transposeMatrix4(Matrix4 *a, Matrix4 *b)
{
	int i, j;
	for (i=0; i<4; i++)
		for (j=0; j<4; j++)
			b->element[i][j] = a->element[j][i];
	return(b);
}

//========== V4MulPointByMatrix() ==============================================
//
// Purpose:		multiply a hom. point by a matrix and return the transformed 
//				point
//
// Source:		Graphic Gems II, Spencer W. Thomas
//
//==============================================================================
Vector4 *V4MulPointByMatrix(Vector4 *pin, Matrix4 *m, Vector4 *pout)
{
	pout->x = (pin->x * m->element[0][0]) + (pin->y * m->element[1][0]) +
	(pin->z * m->element[2][0]) + (pin->w * m->element[3][0]);
	pout->y = (pin->x * m->element[0][1]) + (pin->y * m->element[1][1]) +
		(pin->z * m->element[2][1]) + (pin->w * m->element[3][1]);
	pout->z = (pin->x * m->element[0][2]) + (pin->y * m->element[1][2]) +
		(pin->z * m->element[2][2]) + (pin->w * m->element[3][2]);
	pout->w = (pin->x * m->element[0][3]) + (pin->y * m->element[1][3]) +
		(pin->z * m->element[2][3]) + (pin->w * m->element[3][3]);
	return(pout);
}


/* 
*   inverse( original_matrix, inverse_matrix )
 * 
 *    calculate the inverse of a 4x4 matrix
 *
 *     -1     
 *     A  = ___1__ adjoint A
 *         det A
 */

void inverse( Matrix4 *in, Matrix4 *out )
{
    int i, j;
    float det, det4x4();
	
    /* calculate the adjoint matrix */
	
    adjoint( in, out );
	
    /*  calculate the 4x4 determinant
		*  if the determinant is zero, 
		*  then the inverse matrix is not unique.
		*/
	
    det = det4x4( in );
	
    if ( fabs( det ) < SMALL_NUMBER) {
        printf("Non-singular matrix, no inverse!\n");
        exit(1);
    }
	
    /* scale the adjoint matrix to get the inverse */
	
    for (i=0; i<4; i++)
        for(j=0; j<4; j++)
			out->element[i][j] = out->element[i][j] / det;
}


/* 
*   adjoint( original_matrix, inverse_matrix )
 * 
 *     calculate the adjoint of a 4x4 matrix
 *
 *      Let  a   denote the minor determinant of matrix A obtained by
 *           ij
 *
 *      deleting the ith row and jth column from A.
 *
 *                    i+j
 *     Let  b   = (-1)    a
 *          ij            ji
 *
 *    The matrix B = (b  ) is the adjoint of A
 *                     ij
 */

void adjoint( Matrix4 *in, Matrix4 *out )
{
    float a1, a2, a3, a4, b1, b2, b3, b4;
    float c1, c2, c3, c4, d1, d2, d3, d4;
	
    /* assign to individual variable names to aid  */
    /* selecting correct values  */
	
	a1 = in->element[0][0]; b1 = in->element[0][1]; 
	c1 = in->element[0][2]; d1 = in->element[0][3];
	
	a2 = in->element[1][0]; b2 = in->element[1][1]; 
	c2 = in->element[1][2]; d2 = in->element[1][3];
	
	a3 = in->element[2][0]; b3 = in->element[2][1];
	c3 = in->element[2][2]; d3 = in->element[2][3];
	
	a4 = in->element[3][0]; b4 = in->element[3][1]; 
	c4 = in->element[3][2]; d4 = in->element[3][3];
	
	
    /* row column labeling reversed since we transpose rows & columns */
	
    out->element[0][0]  =   det3x3( b2, b3, b4, c2, c3, c4, d2, d3, d4);
    out->element[1][0]  = - det3x3( a2, a3, a4, c2, c3, c4, d2, d3, d4);
    out->element[2][0]  =   det3x3( a2, a3, a4, b2, b3, b4, d2, d3, d4);
    out->element[3][0]  = - det3x3( a2, a3, a4, b2, b3, b4, c2, c3, c4);
	
    out->element[0][1]  = - det3x3( b1, b3, b4, c1, c3, c4, d1, d3, d4);
    out->element[1][1]  =   det3x3( a1, a3, a4, c1, c3, c4, d1, d3, d4);
    out->element[2][1]  = - det3x3( a1, a3, a4, b1, b3, b4, d1, d3, d4);
    out->element[3][1]  =   det3x3( a1, a3, a4, b1, b3, b4, c1, c3, c4);
	
    out->element[0][2]  =   det3x3( b1, b2, b4, c1, c2, c4, d1, d2, d4);
    out->element[1][2]  = - det3x3( a1, a2, a4, c1, c2, c4, d1, d2, d4);
    out->element[2][2]  =   det3x3( a1, a2, a4, b1, b2, b4, d1, d2, d4);
    out->element[3][2]  = - det3x3( a1, a2, a4, b1, b2, b4, c1, c2, c4);
	
    out->element[0][3]  = - det3x3( b1, b2, b3, c1, c2, c3, d1, d2, d3);
    out->element[1][3]  =   det3x3( a1, a2, a3, c1, c2, c3, d1, d2, d3);
    out->element[2][3]  = - det3x3( a1, a2, a3, b1, b2, b3, d1, d2, d3);
    out->element[3][3]  =   det3x3( a1, a2, a3, b1, b2, b3, c1, c2, c3);
}
/*
 * float = det4x4( matrix )
 * 
 * calculate the determinant of a 4x4 matrix.
 */
float det4x4( Matrix4 *m )
{
    float ans;
    float a1, a2, a3, a4, b1, b2, b3, b4, c1, c2, c3, c4, d1, d2, d3, 			d4;
	
    /* assign to individual variable names to aid selecting */
	/*  correct elements */
	
	a1 = m->element[0][0]; b1 = m->element[0][1]; 
	c1 = m->element[0][2]; d1 = m->element[0][3];
	
	a2 = m->element[1][0]; b2 = m->element[1][1]; 
	c2 = m->element[1][2]; d2 = m->element[1][3];
	
	a3 = m->element[2][0]; b3 = m->element[2][1]; 
	c3 = m->element[2][2]; d3 = m->element[2][3];
	
	a4 = m->element[3][0]; b4 = m->element[3][1]; 
	c4 = m->element[3][2]; d4 = m->element[3][3];
	
    ans = a1 * det3x3( b2, b3, b4, c2, c3, c4, d2, d3, d4)
        - b1 * det3x3( a2, a3, a4, c2, c3, c4, d2, d3, d4)
        + c1 * det3x3( a2, a3, a4, b2, b3, b4, d2, d3, d4)
        - d1 * det3x3( a2, a3, a4, b2, b3, b4, c2, c3, c4);
    return ans;
}

