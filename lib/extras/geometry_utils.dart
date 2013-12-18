library GeometryUtils;

import "package:three/three.dart";
import 'package:vector_math/vector_math.dart';

// TODO(nelsonsilva) - Add remaining functions

void merge(Geometry geometry1, Object3D object2 /* mesh | geometry */, [int materialIndexOffset = 0]) {

  Matrix4 matrix, normalMatrix;
  int vertexOffset = geometry1.vertices.length;
  int uvPosition = geometry1.faceVertexUvs[ 0 ].length;
  Geometry geometry2 = ( object2 is Mesh ) ? object2.geometry : object2;
  
  List<Vector3> vertices1 = geometry1.vertices;
  List<Vector3> vertices2 = geometry2.vertices;
  
  List<Face> faces1 = geometry1.faces;
  List<Face> faces2 = geometry2.faces;
  
  List uvs1 = geometry1.faceVertexUvs[ 0 ];
  List uvs2 = geometry2.faceVertexUvs[ 0 ];


  if ( object2 is Mesh ) {

    object2.matrixAutoUpdate && object2.updateMatrix();

    matrix = object2.matrix;

    var tmp = new Matrix4.identity();
    tmp.invert();
    normalMatrix = tmp.transposed();
  }

  // vertices

  for ( var i = 0, il = vertices2.length; i < il; i ++ ) {
    
    var vertex = vertices2[ i ];
    
    var vertexCopy = vertex.clone();
    
    if ( matrix != null ) vertexCopy.applyProjection( matrix );
    
    vertices1.add( vertexCopy );
  }

  // faces

  for ( var i = 0, il = faces2.length; i < il; i ++ ) {
    
    var face = faces2[ i ], faceCopy, normal, color,
        faceVertexNormals = face.vertexNormals,
        faceVertexColors = face.vertexColors;
    
    faceCopy = new Face3( face.a + vertexOffset, face.b + vertexOffset, face.c + vertexOffset );
    
    faceCopy.normal.setFrom( face.normal );
    
    if ( normalMatrix != null ) {
      
      faceCopy.normal.applyProjection( normalMatrix ).normalize();
      
    }

    for ( var j = 0, jl = faceVertexNormals.length; j < jl; j ++ ) {
      
      normal = faceVertexNormals[ j ].clone();
      
      if ( normalMatrix != null ) {
        
        normal.applyMatrix3( normalMatrix ).normalize();
        
      }
      
      faceCopy.vertexNormals.add( normal );
      
    }

    faceCopy.color.copy( face.color );

    for ( var j = 0, jl = faceVertexColors.length; j < jl; j ++ ) {
      
      color = faceVertexColors[ j ];
      faceCopy.vertexColors.add( color.clone() );
      
    }

    faceCopy.materialIndex = face.materialIndex + materialIndexOffset;
    
    faceCopy.centroid.setFrom( face.centroid );

    if ( matrix != null ) {
      
      faceCopy.centroid.applyProjection( matrix );
      
    }
    faces1.add( faceCopy );

  }

  // uvs

  for ( var i = 0, il = uvs2.length; i < il; i ++ ) {

    var uv = uvs2[ i ], uvCopy = [];

    for ( var j = 0, jl = uv.length; j < jl; j ++ ) {

      uvCopy.add( new Vector2( uv[ j ].x, uv[ j ].y ) );

    }

    uvs1.add( uvCopy );
  }

}

clone( Geometry geometry ) {

    var cloneGeo = new Geometry();

    var i, il;

    var vertices = geometry.vertices,
      faces = geometry.faces,
      uvs = geometry.faceVertexUvs[ 0 ];

    // materials

    if ( geometry.materials != null) {

      cloneGeo.materials = new List.from(geometry.materials);

    }

    // vertices
    cloneGeo.vertices = vertices.map((vertex) => vertex.clone()).toList();

    // faces
    cloneGeo.faces = faces.map((face) => face.clone()).toList();

    // uvs
    il = uvs.length;
    for ( i = 0; i < il; i ++ ) {

      var uv = uvs[ i ], uvCopy = [];

      var jl = uv.length;
      for ( var j = 0; j < jl; j ++ ) {

        uvCopy.add( new UV( uv[ j ].u, uv[ j ].v ) );

      }

      cloneGeo.faceVertexUvs[ 0 ].add( uvCopy );

    }

    return cloneGeo;

}

triangleArea ( Vector3 vectorA, Vector3 vectorB, Vector3 vectorC ) {

  var tmp = (vectorB - vectorA).cross( vectorC - vectorA );

  return 0.5 * tmp.length;
}

// Center geometry so that 0,0,0 is in center of bounding box

center ( Geometry geometry ) {
  geometry.computeBoundingBox();
  
  var bb = geometry.boundingBox;
  
  var offset = (bb.min + bb.max) * -0.5;
  
  geometry.applyMatrix( new Matrix4.translation(offset) );
  geometry.computeBoundingBox();
  
  return offset;
}

