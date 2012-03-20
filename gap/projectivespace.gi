#############################################################################
##
##  projectivespace.gi        FinInG package
##                                                              John Bamberg
##                                                              Anton Betten
##                                                              Jan De Beule
##                                                             Philippe Cara
##                                                            Michel Lavrauw
##                                                                 Maska Law
##                                                           Max Neunhoeffer
##                                                            Michael Pauley
##                                                             Sven Reichard
##
##  Copyright 2011	Colorado State University, Fort Collins
##					Università degli Studi di Padova
##					Universeit Gent
##					University of St. Andrews
##					University of Western Australia, Perth
##                  Vrije Universiteit Brussel
##                 
##
##  Implementation stuff for projective spaces.
##
#############################################################################

## To do
#  - Use compressed matrices
#  - Order functions in this file, and write more comments. (almost done, jdb).
#  think about generic methods for dimension, projective dimension, basefield, underlying vector space
#  for Lie geometries and their elements, to be placed in liegeometry.gi of course.
#  - Reconsider the function OnProjSubspaces. using this function for elements of a polar space e.g. and
#    an ProjGrpElWithFrob, can cause to get back a subspace of a projective space which is not an element of 
#    the polar space. No problem of course, but since Wrap is used (and that should be used for effeciency), 
#    one can get up with an element of a projective space not belonging to the polar space, but which is displayed
#    as being an element of the polar space. I kept it as is currently, but I would like to reconsider this when dealing
#    with the polar space section. jdb 11/9/11
#  - check wheter output of RepresentativesOfElements can be changed using the Flag stuff. 11/09/11 jdb.
#  - make some tiny changes at Meet for lists, such that, when possible, the empty subspace is returned and not []. (this is a
#    detail). 14/9/2011 jdb.
#  - think whether it makes sense that Span and Meet return [] when they receive []. (recall that [] used to represent the 
#    trivial subspace in earlier days. 14/9/2011 jdb.
#  - improve Random method for shadow elements. see comment there.
#  - have a closer look at the Baer substuff methods in this file.
#  - whenever Wrap is used, check whether the input should be normalized or not. Done.
#############################################################################
# Low level help methods:
#############################################################################

Print(", projectivespace\c");

# CHECKED 6/09/11 jdb
#############################################################################
#O  Wrap( <geo>, <type>, <o> )
# This is an internal subroutine which is not expected to be used by the user;
# they would be using VectorSpaceToElement. Recall that Wrap is declared in 
# geometry.gd. 
##
InstallMethod( Wrap, 
	"for a projective space and an object",
	[IsProjectiveSpace, IsPosInt, IsObject],
	function( geo, type, o )
		local w;
		w := rec( geo := geo, type := type, obj := o );
		Objectify( NewType( SoPSFamily, IsElementOfIncidenceStructure and
			IsElementOfIncidenceStructureRep and IsSubspaceOfProjectiveSpace ), w );
		return w;
	end );

# CHECKED 6/09/11 jdb
#############################################################################
#O  \^( <v>, <u> )
# If the object "v" to be unwrapped is a point of a vector space, then we do not want to use
# return v!.obj, but we want to return a list with one vector, i.e. [v!.obj]
# e.g. if p is a point of a projective space
# gap> p^_; 
# will return a list, with the coordinate vector of the point p
##
InstallMethod( \^, 
	"for a subspace of a projective space and an unwrapper",
	[ IsSubspaceOfProjectiveSpace, IsUnwrapper ],
	function( v, u )
		if v!.type = 1 then return [v!.obj];
		else return v!.obj;
		fi;
	end );

#############################################################################
# Constructor methods and some operations/attributes for projective spaces.
#############################################################################

# CHECKED 6/09/11 jdb
#############################################################################
#O  ProjectiveSpace( <d>, <f> )
# returns PG(d,f), f a finite field.
##
InstallMethod( ProjectiveSpace, "for a proj dimension and a field",
  [ IsInt, IsField ],
  function( d, f )
    local geo, ty;
    geo := rec( dimension := d, basefield := f, 
                vectorspace := FullRowSpace(f, d+1) );
    ty := NewType( GeometriesFamily,
                  IsProjectiveSpace and IsProjectiveSpaceRep );
    Objectify( ty, geo );
    SetAmbientSpace(geo,geo);
    return geo;
  end );
  
# CHECKED 6/09/11 jdb
#############################################################################
#O  ProjectiveSpace( <d>, <q> )
# returns PG(d,q). 
##
InstallMethod( ProjectiveSpace, "for a proj dimension and a prime power",
  [ IsInt, IsPosInt ],
  function( d, q )
          return ProjectiveSpace(d, GF(q));
  end );
  
#############################################################################
# Display methods:
#############################################################################

InstallMethod( ViewObj, [ IsProjectiveSpace and IsProjectiveSpaceRep ],
  function( p )
    Print("ProjectiveSpace(",p!.dimension,", ",Size(p!.basefield),")");
  end );

InstallMethod( PrintObj, [ IsProjectiveSpace and IsProjectiveSpaceRep ],
  function( p )
          Print("ProjectiveSpace(",p!.dimension,",",p!.basefield,")");
  end );

InstallMethod( Display, [ IsProjectiveSpace and IsProjectiveSpaceRep ],
  function( p )
    Print("ProjectiveSpace(",p!.dimension,",",p!.basefield,")\n");
    #if HasDiagramOfGeometry( p ) then      
    #   Display( DiagramOfGeometry( p ) );
    #fi;
  end );

# CHECKED 6/09/11 jdb
#############################################################################
#O  UnderlyingVectorSpace( <ps> )
# returns the Underlying vectorspace of the projective space <ps>
##
InstallMethod( UnderlyingVectorSpace, 
	"for a projective space",
	[IsProjectiveSpace and IsProjectiveSpaceRep],
	function(ps)
		return ShallowCopy(ps!.vectorspace);
	end);

# CHECKED 6/09/11 jdb
#############################################################################
#O  \=( <pg1>, <pg2> )
##
InstallMethod( \=, 
	"for two projective spaces",
	[IsProjectiveSpace, IsProjectiveSpace],
	function(pg1,pg2);
		return UnderlyingVectorSpace(pg1) = UnderlyingVectorSpace(pg2);
	end );

# CHECKED 8/09/11 jdb
#############################################################################
#A  ProjectiveDimension( <ps> )
# returns the projective dimension of <ps>
##
InstallMethod( ProjectiveDimension,
	"for a projective space",
	[ IsProjectiveSpace and IsProjectiveSpaceRep ],
	ps -> ps!.dimension
	);
	
# CHECKED 8/09/11 jdb
#############################################################################
#A  Dimension( <ps> )
# returns the projective dimension of <ps>
##
InstallMethod( Dimension, 
	"for a projective space",
	[ IsProjectiveSpace and IsProjectiveSpaceRep ],
	ps -> ps!.dimension
	);

# CHECKED 8/09/11 jdb
#############################################################################
#O  Rank( <ps> )
# returns the projective dimension of <ps>
##
InstallMethod( Rank, 
	"for a projective space",
	[ IsProjectiveSpace and IsProjectiveSpaceRep ],
	ps -> ps!.dimension
	);

# CHECKED 8/09/11 jdb
#############################################################################
#O  BaseField( <ps> )
# returns the basefield of <ps>
##
InstallMethod( BaseField, 
	"for a projective space", 
	[IsProjectiveSpace],
	pg -> pg!.basefield );

#############################################################################
#O  BaseField( <sub> )
# returns the basefield of an element of a projective space
##
InstallMethod( BaseField, 
	"for an element of a projective space", 
	[IsSubspaceOfProjectiveSpace],
	sub -> AmbientSpace(sub)!.basefield );

# CHECKED 6/09/11 jdb
#############################################################################
#A  StandardFrame( <ps> )
# if the dimension of the projective space is n, then StandardFrame 
# makes a list of points with coordinates 
# (1,0,...0), (0,1,0,...,0), ..., (0,...,0,1) and (1,1,...,1) 
##
InstallMethod( StandardFrame, 
	"for a projective space", 
	[IsProjectiveSpace], 
	function( pg )
		local bas, frame, unitpt;
		if not pg!.dimension > 0 then 
			Error("The argument needs to be a projective space of dimension at least 1!");
		else
			bas:=Basis(pg!.vectorspace);	
			frame:=List(BasisVectors(bas),v->VectorSpaceToElement(pg,v));
			unitpt:=VectorSpaceToElement(pg,Sum(BasisVectors(bas)));
			Add(frame,unitpt);
			return frame;
		fi;
	end );

# CHECKED 11/09/11 jdb
#############################################################################
#A  RepresentativesOfElements( <ps> )
# Returns the canonical maximal flag for the projective space <ps>
##
InstallMethod( RepresentativesOfElements, 
	"for a projective space", [IsProjectiveSpace],
	# returns the canonical maximal flag
	function( ps )
		local d, gf, id, elts;  
		d := ProjectiveDimension(ps);
		gf := BaseField(ps);
		id := IdentityMat(d+1,gf);
		elts := List([1..d], i -> VectorSpaceToElement(ps, id{[1..i]}));
		return elts;
	end );

# CHECKED 18/4/2011 jdb
#############################################################################
#O  Hyperplanes( <ps> )
# returns Hyperplanes(ps,ps!.dimension), <ps> a projective space
## 
InstallMethod( Hyperplanes,
	"for a projective space",
	[ IsProjectiveSpace ],
	function( ps )
		return ElementsOfIncidenceStructure(ps, ps!.dimension);
	end);

# CHECKED 11/09/11 jdb
#############################################################################
#A  TypesOfElementsOfIncidenceStructure( <ps> )
# returns the names of the types of the elements of the projective space <ps>
# the is a helper operation.
## 
InstallMethod( TypesOfElementsOfIncidenceStructure, 
	"for a projective space", [IsProjectiveSpace],
	function( ps )
		local d,i,types;
		types := ["point"];
		d := ProjectiveDimension(ps);
		if d >= 2 then Add(types,"line"); fi;
		if d >= 3 then Add(types,"plane"); fi;
		if d >= 4 then Add(types,"solid"); fi;
		for i in [5..d] do
			Add(types,Concatenation("proj. ",String(i-1),"-space"));
		od;
		return types;
	end );

# CHECKED 11/09/11 jdb
#############################################################################
#A  TypesOfElementsOfIncidenceStructurePlural( <ps> )
# retunrs the plural of the names of the types of the elements of the 
# projective space <ps>. This is a helper operation.
## 
InstallMethod( TypesOfElementsOfIncidenceStructurePlural, 
	"for a projective space",
	[IsProjectiveSpace],
	function( ps )
		local d,i,types;
		types := ["points"];
		d := ProjectiveDimension(ps);
		if d >= 2 then Add(types,"lines"); fi;
		if d >= 3 then Add(types,"planes"); fi;
		if d >= 4 then Add(types,"solids"); fi;
		for i in [5..d] do
			Add(types,Concatenation("proj. ",String(i-1),"-subspaces"));
		od;
		return types;
	end );

# CHECKED 11/09/11 jdb
#############################################################################
#O  ElementsOfIncidenceStructure( <ps>, <j> )
# returns the elements of the projective space <ps> of type <j>
## 
InstallMethod( ElementsOfIncidenceStructure, 
	"for a projective space and an integer",
	[IsProjectiveSpace, IsPosInt],
	function( ps, j )
		local r;
		r := Rank(ps);
		if j > r then
			Error("<ps> has no elements of type <j>");
		else
			return Objectify(
			NewType( ElementsCollFamily, IsSubspacesOfProjectiveSpace and IsSubspacesOfProjectiveSpaceRep ),
				rec( geometry := ps,
					type := j,
					size := Size(Subspaces(ps!.vectorspace, j))
					)
					);
		fi;
	end);

# CHECKED 11/09/11 jdb
#############################################################################
#O  ElementsOfIncidenceStructure( <ps> )
# returns all the elements of the projective space <ps> 
## 
InstallMethod( ElementsOfIncidenceStructure, 
	"for a projective space",
	[IsProjectiveSpace],
	function( ps )
		return Objectify(
			NewType( ElementsCollFamily, IsAllSubspacesOfProjectiveSpace and IsAllSubspacesOfProjectiveSpaceRep ),
				rec( geometry := ps,
					type := "all") #added this field in analogy with the collection that contains all subspaces of a vector space. 14/9/2011 jdb.
				);
	end);

# CHECKED 14/09/11 jdb
#############################################################################
#O  \=( <x>, <y> )
# returns true if the collections <x> and <y> of all subspaces of a projective
# space are the same.
## 
InstallMethod( \=,
  "for set of all subspaces of a projective space",
  [ IsAllSubspacesOfProjectiveSpace, IsAllSubspacesOfProjectiveSpace ],
  function(x,y)
  return ((x!.geometry!.dimension = y!.geometry!.dimension) and (x!.geometry!.basefield =
  y!.geometry!.basefield));
end );


# CHECKED 11/09/11 jdb
#############################################################################
#O  Size( <subs>) 
# returns the number of elements in the collection <subs>.
##
InstallMethod( Size,
	"for subspaces of a projective space",
	[IsSubspacesOfProjectiveSpace and IsSubspacesOfProjectiveSpaceRep],
	function(subs);
		return ShallowCopy(subs!.size);
	end);

# CHECKED 11/09/11 jdb
#############################################################################
#O  \in( <x>, <dom> )
# returns true if <x> belongs to the elements collected in <dom> It is checked if their 
# geometry matches.
## 
InstallMethod( \in, 
	"for an element and set of elements",  
	# 1*SUM_FLAGS+3 increases the ranking for this method
    [IsElementOfIncidenceStructure, IsElementsOfIncidenceStructure], 1*SUM_FLAGS+3,
	function( x, dom )
		return x in dom!.geometry and x!.type = dom!.type;
	end );

# CHECKED 11/09/11 jdb
#############################################################################
#O  \in( <x>, <dom> )
# returns true if <x> belongs to the elements collected in <dom> It is checked if their 
# geometry matches.
## 
InstallMethod( \in, 
	"for an element and domain",  
	# 1*SUM_FLAGS+3 increases the ranking for this method
    [IsElementOfIncidenceStructure, IsAllElementsOfIncidenceStructure], 1*SUM_FLAGS+3,
	function( x, dom )
		return x in dom!.geometry;
	end );

#############################################################################
# Constructor methods and some operations/attributes for subspaces of 
# projective spaces.
#############################################################################

#############################################################################
#  VectorSpaceToElement methods
#############################################################################

## Things to check for (dodgy input)
## ---------------------------------
## - dimension
## - field
## - compress the matrix at the end
## - rank of matrix
## - an empty list

## Much of the following will need to change in the new
## version of GAP, with the new Row and Matrix types.

## Should we have methods for the new types given by the cvec package?
## Currently we don't load the cvec package.

# CHECKED 20/09/11
#############################################################################
#O  VectorSpaceToElement( <geom>, <v> ) returns the elements in <geom> determined
# by the vectorspace <v>. Several checks are built in. 
##
InstallMethod( VectorSpaceToElement, 
	"for a projective space and a Plist",
	[IsProjectiveSpace, IsPlistRep],
	function( geom, v )
		local  x, n, i; 
		## when v is empty... 
        if IsEmpty(v) then
			Error("<v> does not represent any element");
		fi; 		
		#x := EchelonMat(v).vectors;
		x := MutableCopyMat(v);
		TriangulizeMat(x); 
		## dimension should be correct
		if Length(v[1]) <> geom!.dimension + 1 then
			Error("Dimensions are incompatible");
		fi;
        
		## Remove zero rows. It is possible the the user
		## has inputted a matrix which does not have full rank
        n := Length(x);
		i := 0;
		while i < n and ForAll(x[n-i], IsZero) do
			i := i+1; 
		od;
		if i = n then
			return EmptySubspace(geom);
		fi;
		x := x{[1..n-i]};
		if Length(x)=ProjectiveDimension(geom)+1 then
			return geom;
		fi;

		## It is possible that (a) the user has entered a
		## matrix with one row, or that (b) the user has
		## entered a matrix with rank 1 (thus at this stage
		## we will have a matrix with one row).
        ## We must also compress our vector/matrix.
        if Length(x) = 1 then
			x := x[1];
			ConvertToVectorRep(x, geom!.basefield); # the extra basefield is necessary.
			return Wrap(geom, 1, x);
		else
			ConvertToMatrixRep(x, geom!.basefield); # the same here.
			return Wrap(geom, Length(x), x);
		fi;
	end );

# CHECKED 20/09/11
#############################################################################
#O  VectorSpaceToElement( <geom>, <v> ) returns the elements in <geom> determined
# by the vectorspace <v>. Several checks are built in. 
##
InstallMethod( VectorSpaceToElement, 
	"for a projective space and a compressed GF(2)-matrix",
	[IsProjectiveSpace, IsGF2MatrixRep],
	function( geom, v )
		local  x, n, i;
		## when v is empty... 
		if IsEmpty(v) then
			Error("<v> does not represent any element");
		fi;
		x := MutableCopyMat(v);
		TriangulizeMat(x); 
		#x := EchelonMat(v).vectors;
		## dimension should be correct
		if Length(v[1]) <> geom!.dimension + 1 then
			Error("Dimensions are incompatible");
		fi;
		#if Length(x) = 0 then
		#	return EmptySubspace(geom);
		#fi;
		#if Length(x)=ProjectiveDimension(geom)+1 then
		#	return geom;
		#fi;
		
		## Remove zero rows. It is possible the the user
		## has inputted a matrix which does not have full rank
		n := Length(x);
		i := 0;
		while i < n and ForAll(x[n-i], IsZero) do
			i := i+1; 
		od;
		if i = n then
			return EmptySubspace(geom);
		fi;
		x := x{[1..n-i]};
		if Length(x)=ProjectiveDimension(geom)+1 then
			return geom;
		fi;

		
		## It is possible that (a) the user has entered a
		## matrix with one row, or that (b) the user has
		## entered a matrix with rank 1 (thus at this stage
		## we will have a matrix with one row).
	    ## We must also compress our vector/matrix.
		if Length(x) = 1 then
			x := x[1];
			ConvertToVectorRep(x, geom!.basefield); # the extra basefield is necessary.
			return Wrap(geom, 1, x);
		else
			ConvertToMatrixRep(x, geom!.basefield);
			return Wrap(geom, Length(x), x);
		fi;
	end );
  
# CHECKED 20/09/11
#############################################################################
#O  VectorSpaceToElement( <geom>, <v> ) returns the elements in <geom> determined
# by the vectorspace <v>. Several checks are built in. 
##
InstallMethod( VectorSpaceToElement, 
	"for a compressed basis of a vector subspace",
	[IsProjectiveSpace, Is8BitMatrixRep],
	function( geom, v )
		local  x, n, i;
		## when v is empty... 
		if IsEmpty(v) then
			Error("<v> does not represent any element");
		fi;
		#x := EchelonMat(v).vectors;
		x := MutableCopyMat(v);
		TriangulizeMat(x); 
		
		## dimension should be correct
		if Length(v[1]) <> geom!.dimension + 1 then
			Error("Dimensions are incompatible");
		fi;	
		
		#if Length(x) = 0 then
		#	return EmptySubspace(geom);
		#fi;
		#if Length(x)=ProjectiveDimension(geom)+1 then
		#	return geom;
		#fi;
		
		n := Length(x);
		i := 0;
		while i < n and ForAll(x[n-i], IsZero) do
			i := i+1; 
		od;
		if i = n then
			return EmptySubspace(geom);
		fi;
		x := x{[1..n-i]};
		if Length(x)=ProjectiveDimension(geom)+1 then
			return geom;
		fi;

		
		## It is possible that (a) the user has entered a
		## matrix with one row, or that (b) the user has
		## entered a matrix with rank 1 (thus at this stage
		## we will have a matrix with one row).
		## We must also compress our vector/matrix.
		if Length(x) = 1 then
			x := x[1];
			ConvertToVectorRep(x, geom!.basefield); # the extra basefield is necessary.
			return Wrap(geom, 1, x);
		else
			ConvertToMatrixRep(x, geom!.basefield);
			return Wrap(geom, Length(x), x);
		fi;
	end );  
  
# CHECKED 11/04/15 jdb
# CHANGED 19/9/2011 jdb + ml
# CHECKED 21/09/2011 jdb
#############################################################################
#O  VectorSpaceToElement( <geom>, <v> ) returns the elements in <geom> determined
# by the rowvector <v>. Several checks are built in.
##
InstallMethod( VectorSpaceToElement,
	"for a row vector",
	[IsProjectiveSpace, IsRowVector],
	function( geom, v )
		local  x;
		## when v is empty... does this ever occur for a row vector? No. jdb 21/09/2011
		#if IsEmpty(v) then
		#	Error("<v> does not represent any element");
		#fi;
		x := ShallowCopy(v);
		## dimension should be correct
		if Length(v) <> geom!.dimension + 1 then
			Error("Dimensions are incompatible");
		fi;
		## We must also compress our vector.
		#ConvertToVectorRep(x, geom!.basefield);
		## bad characters, such as jdb, checked this with input zero vector...
		if IsZero(x) then
			return EmptySubspace(geom);
		else
			MultRowVector(x,Inverse( x[PositionNonZero(x)] ));
			ConvertToVectorRep(x, geom!.basefield);
			return Wrap(geom, 1, x);
		fi;
	end );

# CHECKED 11/04/15 jdb
# CHANGED 19/9/2011 jdb + ml
#############################################################################
#O  VectorSpaceToElement( <geom>, <v> ) returns the elements in <geom> determined
# by the rowvector <v>. Several checks are built in.
##
InstallMethod( VectorSpaceToElement, 
	"for a projective space and an 8-bit vector",
	[IsProjectiveSpace, Is8BitVectorRep],
	function( geom, v )
		local  x, n, i;
		## when v is empty...
		if IsEmpty(v) then
			return EmptySubspace(geom);
		fi;
		x := ShallowCopy(v);
		## dimension should be correct
		if Length(v) <> geom!.dimension + 1 then
			Error("Dimensions are incompatible");
		fi;
		## We must also compress our vector.
		#ConvertToVectorRep(x, geom!.basefield);
		## bad characters, such as jdb, checked this with input zero vector...
		if IsZero(x) then
			return EmptySubspace(geom);
		else
			MultRowVector(x,Inverse( x[PositionNonZero(x)] ));
			ConvertToVectorRep(x, geom!.basefield);
			return Wrap(geom, 1, x);
		fi;
	end );

#############################################################################
#  attributes/operations for subspaces
#############################################################################

# CHECKED 14/09/11 jdb
#############################################################################
#O  UnderlyingVectorSpace( <subspace> ) returns the underlying vectorspace of
# <subspace>, i.e. the vectorspace determining <subspace>
##
InstallMethod( UnderlyingVectorSpace, 
	"for a subspace of a projective space",
	[IsSubspaceOfProjectiveSpace],
	function(subspace)
		local vspace,W;
		vspace:=UnderlyingVectorSpace(subspace!.geo);
		if subspace!.type = 1 then
			W:=SubspaceNC(vspace,[subspace!.obj]);
		else
			W:=SubspaceNC(vspace,subspace!.obj);
		fi;
		return W;
	end);

# CHECKED 8/09/11 jdb
#############################################################################
#O  ProjectiveDimension( <v> ) returns the projective dimension of <v>
##
InstallMethod( ProjectiveDimension, 
	"for a subspace of a projective space",
	[ IsSubspaceOfProjectiveSpace ],
	function( v )
		return v!.type - 1;
	end );

#InstallMethod( ProjectiveDimension, [ IsEmpty ], function(x) return -1;end );

# CHECKED 8/09/11 jdb
#############################################################################
#O  Dimension( <v> ) returns the projective dimension of <v>
##
InstallMethod( Dimension, 
	"for a subspace of a projective space",
    [ IsSubspaceOfProjectiveSpace ],
	function( v )
		return v!.type - 1;
	end );

#InstallMethod( Dimension, [ IsEmpty ], function(x) return -1;end );

# CHECKED 8/09/11 jdb
#############################################################################
#O  StandardFrame( <subspace> ) returns a standard frame for <subspace>
##
InstallMethod( StandardFrame, 
	"for a subspace of a projective space", 
	[IsSubspaceOfProjectiveSpace],
	# if the dimension of the subspace is d (needs to be at least 1), then this returns d+2
	# points of the subspace, the first d+1 are the points "basispoints"
	# the last point has as coordinates the sum of the basispoints.
	function( subspace )
		local list,v;
		if not Dimension(subspace) > 0 then 
			Error("The argument needs to be a projective space of dimension at least 1!");
		else
		list:=ShallowCopy(subspace!.obj);
		Add(list,Sum(subspace!.obj));
		return List(list,v->VectorSpaceToElement(subspace!.geo,v));
		fi;
	end );

# CHECKED 8/09/11 jdb
#############################################################################
#O  Coordinates( <point> ) returns the coordinates of the projective point <point>
##
InstallMethod( Coordinates, 
	"for a point of a projective space",
	[IsSubspaceOfProjectiveSpace],
	function( point )
		if not Dimension(point)=0 then 
			Error("The argument is not a projective point");
		else 
			return ShallowCopy(point!.obj);
		fi;
	end );
  
# CHECKED 8/09/11 jdb
#############################################################################
#O  CoordinatesOfHyperplane( <hyp> ) returns the coordinates of the hyperplane
# <hyp>
##
InstallMethod( CoordinatesOfHyperplane, 
	"for a hyperplane of a projective space",
	[IsSubspaceOfProjectiveSpace],
	function(hyp)
		local pg;
		pg:=ShallowCopy(hyp!.geo);
		if not hyp!.type=Dimension(pg) then 
			Error("The argument is not a hyperplane");
		else 
			#perp:=StandardDualityOfProjectiveSpace(pg);
			return Coordinates(VectorSpaceToElement(pg,NullspaceMat(TransposedMat(hyp!.obj))));
		fi;
	end );

# CHECKED 8/09/11 jdb
#############################################################################
#O  EquationOfHyperplane( <hyp> ) returns the euqation of the hyperplane
# <hyp>
##
InstallMethod( EquationOfHyperplane, 
	"for a hyperplane of a projective space",
	[IsSubspaceOfProjectiveSpace],
	function(hyp)
		local pg,r,v,indets;
		pg:=AmbientGeometry(hyp);
		r:=PolynomialRing(pg!.basefield,pg!.dimension + 1);
		indets:=IndeterminatesOfPolynomialRing(r);
		v:=CoordinatesOfHyperplane(hyp);
		return Sum(List([1..Size(indets)],i->v[i]*indets[i]));
	end );
	
# CHECKED 11/09/11 jdb
# Commented out 28/11/11 jdb + pc, according to new regulations
#############################################################################
#O  AmbientSpace( <subspace> ) returns the ambient space of <subspace>
##
#InstallMethod( AmbientSpace, [IsSubspaceOfProjectiveSpace],
#	function(subspace)
#		return subspace!.geo;
#	end );

#############################################################################
#  Span/Meet for trivial subspaces
#############################################################################

# CHECKED 8/09/11 jdb
#############################################################################
#O  Span( <x>, <y> ) returns the span of <x> and <y> 
##
InstallMethod( Span, 
	"for the trivial subspace and a projective space", 
	[ IsEmptySubspace, IsProjectiveSpace ],
	function( x, y )
		if x!.geo!.vectorspace = y!.vectorspace then
			return y;
		else
			Error( "The subspace <x> has a different ambient space than <y>" );
		fi;
	end );

# CHECKED 8/09/11 jdb
#############################################################################
#O  Span( <x>, <y> ) returns the span of <x> and <y> 
##
InstallMethod( Span, 
	"for the trivial subspace and a projective space", 
	[ IsProjectiveSpace, IsEmptySubspace ],
	function( x, y )
		if x!.vectorspace = y!.geo!.vectorspace then
			return x;
		else
			Error( "The subspace <x> has a different ambient space than <y>" );
		fi;
	end );

# CHECKED 8/09/11 jdb
#############################################################################
#O  Meet( <x>, <y> ) returns the intersection of <x> and <y> 
##
InstallMethod( Meet, 
	"for the trivial subspace and a projective subspace", 
	[ IsEmptySubspace, IsProjectiveSpace ],
	function( x, y )
		if x!.geo!.vectorspace = y!.vectorspace then
			return x;
		else
			Error( "The subspace <x> has a different ambient space than <y>" );
		fi;
	end );

# CHECKED 8/09/11 jdb
#############################################################################
#O  Meet( <x>, <y> ) returns the intersection of <x> and <y> 
##
InstallMethod( Meet, 
	"for the trivial subspace and a projective subspace", 
	[ IsProjectiveSpace, IsEmptySubspace ],
	function( x, y )
		if x!.vectorspace = y!.geo!.vectorspace then
			return y;
		else
			Error( "The subspace <x> has a different ambient space than <y>" );
		fi;
	end );

# CHECKED 8/09/11 jdb
#############################################################################
#O ShadowOfElement(<ps>, <v>, <j> ). Recall that for every particular Lie 
# geometry a method for ShadowOfElement  must be installed. 
##
InstallMethod( ShadowOfElement, 
	"for a projective space, an element, and an integer",
	[IsProjectiveSpace, IsSubspaceOfProjectiveSpace, IsPosInt],
	# returns the shadow of an element v as a record containing the projective space (geometry), 
	# the type j of the elements (type), the element v (parentflag), and some extra information
	# useful to compute with the shadows, e.g. iterator
	function( ps, v, j )
		local localinner, localouter, localfactorspace;
		if j < v!.type then
			localinner := [];
			localouter := v!.obj;
		elif j = v!.type then
			localinner := v!.obj;
			localouter := localinner;
		else
			localinner := v!.obj;
			localouter := BasisVectors(Basis(ps!.vectorspace));
		fi;
    	if IsVector(localinner) and not IsMatrix(localinner) then
			localinner := [localinner]; 
		fi;
		if IsVector(localouter) and not IsMatrix(localouter) then
			localouter := [localouter]; 
		fi;
		localfactorspace := Subspace(ps!.vectorspace,
		BaseSteinitzVectors(localouter, localinner).factorspace);
		return Objectify( NewType( ElementsCollFamily, IsElementsOfIncidenceStructure and
							IsShadowSubspacesOfProjectiveSpace and
							IsShadowSubspacesOfProjectiveSpaceRep),
							rec( geometry := ps,
									type := j,
									inner := localinner,
									outer := localouter,
									factorspace := localfactorspace,
									parentflag := v,
									size := Size(Subspaces(localfactorspace))
								)
						);
	end);

# CHECKED 11/09/11 jdb
#############################################################################
#O  Size( <vs>) 
# returns the number of elements in the shadow collection <vs>.
##
InstallMethod( Size, 
	"for shadow subspaces of a projective space",
	[IsShadowSubspacesOfProjectiveSpace and IsShadowSubspacesOfProjectiveSpaceRep ],
	function( vs )
		return Size(Subspaces(vs!.factorspace,
		vs!.type - Size(vs!.inner)));
	end);

#############################################################################
# Shortcuts to ShadowOfElement, specifically for projective spaces. 
#############################################################################

# CHECKED 7/09/2011 jdb
#############################################################################
#O  Hyperplanes( <el> )
# returns the hyperplanes incident with <el>, relying on ShadowOfElement 
# for particular <el>.
##
#InstallMethod( Hyperplanes, 
#	"for elements of a Lie geometry",
#	[ IsSubspaceOfProjectiveSpace ],
#	function( var )
#		local geo, d, f;
#		geo := var!.geo;
#		#d := geo!.dimension;
#		#f := geo!.basefield;
#		# return ShadowOfElement( ProjectiveSpace(d, f), var, var!.type - 1 ); changed this into
#	    return ShadowOfElement( geo, var, geo!.dimension );
# end );

# CHECKED 7/09/2011 jdb
#############################################################################
#O  Hyperplanes( <geo>, <el> )
# returns the hyperplanes incident with <el>, relying on ShadowOfElement 
# for particular <el>.
##
#InstallMethod( Hyperplanes, 
#	"for a Lie geometry and elements of a Lie geometry",
#	[ IsProjectiveSpace, IsSubspaceOfProjectiveSpace ],
#	function( geo, var )
#		local d, f;
#		d := geo!.dimension;
#		f := geo!.basefield;
#		return ShadowOfElement( geo, var, geo!.dimension );
#end );

#############################################################################
# Constructors for groups of projective spaces.
#############################################################################

# CHECKED 10/09/2011 jdb
#############################################################################
#A  CollineationGroup( <ps> )
# returns the collineation group of the projective space <ps>
##
InstallMethod( CollineationGroup, 
	"for a full projective space",
	[ IsProjectiveSpace and IsProjectiveSpaceRep ],
	function( ps )
		local coll,d,f,frob,g,newgens,q,s,pow;
		f := ps!.basefield;
		q := Size(f);
		d := ProjectiveDimension(ps);
		if d <= -1 then 
			Error("The dimension of the projective spaces needs to be at least 0");
		fi;
		g := GL(d+1,q);
		frob := FrobeniusAutomorphism(f);
		newgens := List(GeneratorsOfGroup(g),x->[x,frob^0]);
		Add(newgens,[One(g),frob]);
		newgens := ProjElsWithFrob(newgens);
		coll := GroupWithGenerators(newgens);
		pow := LogInt(q, Characteristic(f));
		s := pow * q^(d*(d+1)/2)*Product(List([2..d+1], i->q^i-1)); 
		if pow > 1 then 
			SetName( coll, Concatenation("PGammaL(",String(d+1),",",String(q),")") );
		else
			SetName( coll, Concatenation("PGL(",String(d+1),",",String(q),")") );
		fi;	
		SetSize( coll, s );    
		return coll;
	end );

# CHECKED 10/09/2011 jdb
#############################################################################
#A  HomographyGroup( <ps> )
# returns the homogrphy group of the projective space <ps>
##
InstallMethod( HomographyGroup, 
	"for a full projective space",
	[ IsProjectiveSpace ],
	function( ps )
		local gg,d,f,frob,g,newgens,q,s;
		f := ps!.basefield;
		q := Size(f);
		d := ProjectiveDimension(ps);
		if d <= -1 then 
			Error("The dimension of the projective spaces needs to be at least 0");
		fi;
		g := GL(d+1,q);
		frob := FrobeniusAutomorphism(f);
		newgens := List(GeneratorsOfGroup(g),x->[x,frob^0]);
		newgens := ProjElsWithFrob(newgens);
		gg := GroupWithGenerators(newgens);
		s := q^(d*(d+1)/2)*Product(List([2..d+1], i->q^i-1)); 
		SetName( gg, Concatenation("PGL(",String(d+1),",",String(q),")") );
		SetSize( gg, s );
		return gg;
	end );

# CHECKED 10/09/2011 jdb
#############################################################################
#A  SpecialHomographyGroup( <ps> )
# returns the special homogrphy group of the projective space <ps>
##
InstallMethod( SpecialHomographyGroup, 
	"for a full projective space",
	[ IsProjectiveSpace ],
	function( ps )
		local gg,d,f,frob,g,newgens,q,s;
		f := ps!.basefield;
		q := Size(f);
		d := ProjectiveDimension(ps);
		if d <= -1 then 
			Error("The dimension of the projective spaces needs to be at least 0");
		fi;
		g := SL(d+1,q);
		frob := FrobeniusAutomorphism(f);
		newgens := List(GeneratorsOfGroup(g),x->[x,frob^0]);
		newgens := ProjElsWithFrob(newgens);
		gg := GroupWithGenerators(newgens);
		s := q^(d*(d+1)/2)*Product(List([2..d+1], i->q^i-1)) / GCD_INT(q-1, d+1);
		SetName( gg, Concatenation("PSL(",String(d+1),",",String(q),")") );
		SetSize( gg, s );    
		return gg;
	end );

#############################################################################
# Action functions intended for the user.
#############################################################################

# CHECKED 10/09/2011 jdb, to be reconsidered. See to do in beginning of file.
# CHANGED 19/09/2011 jdb + ml
#############################################################################
#F  OnProjSubspaces( <var>, <el> )
# computes <var>^<el>, where <var> is an element of a projective space, and 
# <el> a projective semilinear element. Important: we are allowed to use Wrap
# rather than VectorSpaceToElement, since the OnProjSubspacesWithFrob and OnProjPointsWithFrob
# deal with making the representation of <var>^<el> canonical.
##
InstallGlobalFunction( OnProjSubspaces,
  function( var, el )
    local amb,geo,newvar;
    geo := var!.geo;   
    if var!.type = 1 then
        newvar := OnProjPointsWithFrob(var!.obj,el);
    else
        newvar := OnProjSubspacesWithFrob(var!.obj,el);
    fi;
    return Wrap(geo,var!.type,newvar);
  end );

# CHECKED, but I am unhappy with the too general filter IsElementOfIncidenceStructure
# I left it, but will reconsider it when dealing with polar spaces.
# 11/09/11 jdb
#############################################################################
#O  /^( <x>, <em> )
# computes <var>^<el>, where <var> is an element of a incidence structure, and 
# <em> a projective semilinear element.
##
InstallOtherMethod( \^, 
	"for an element of an incidence structure and a projective semilinear element",
	[IsElementOfIncidenceStructure, IsProjGrpElWithFrob],
	function(x, em)
		return OnProjSubspaces(x,em);
	end );
	
#############################################################################
#O  /^( <x>, <em> )
# computes <var>^<el>, where <var> is an element of a incidence structure, and 
# <em> a projective semilinear with projective space isomorhpism element.
##
InstallOtherMethod( \^, 
	"for an element of an incidence structure and a projective semilinear element",
	[IsElementOfIncidenceStructure, IsProjGrpElWithFrobWithPSIsom],
	function(x, em)
		return OnProjSubspacesReversing(x,em);
	end );

# CHECKED 11/09/11 jdb
#############################################################################
#F  OnSetsProjSubspaces( <var>, el )
# computes <x>^<el>, for all x in <var> 
##
InstallGlobalFunction( OnSetsProjSubspaces,
  function( var, el )
    return Set( var, i -> OnProjSubspaces( i, el ) );
  end );

#############################################################################
# Iterator and Enumerating
#############################################################################

# CHECKED 11/09/11 jdb
#############################################################################
#O  AsList( <vs>) 
# returns a list of all elements in <vs>, which is a collection of subspaces of
# a projective space of a given type. This methods uses functionality from the 
# orb package.
##
InstallMethod( AsList, 
	"for subspaces of a projective space",
	[IsSubspacesOfProjectiveSpace],
	function( vs )
	## We use the package "orb" by Mueller, Neunhoeffer and Noeske,
	## which is much quicker than using an iterator to get all of the
	## projective subspaces of a certain dimension.
	local geo, g, p, o, type, sz;
	geo := vs!.geometry;
	g := ProjectivityGroup(geo);
	type := vs!.type; 
	sz := Size(vs);
	if type = 1 then
		o := MakeAllProjectivePoints(geo!.basefield, geo!.dimension);
		o := List(o, t -> Wrap(geo, type, t));;   
	else
		p := NextIterator(Iterator(vs));
		o := Orb(g, p, OnProjSubspaces, rec( hashlen:=Int(5/4*sz), 
                                          orbsizebound := sz ));
		Enumerate(o, sz);
	fi;
	return o;
	end );
	
# One of the best features of all of the orb package is the FindSuborbits command
# Here's an example
#
# gap> pg:=PG(3,4);
#PG(3, 4)
#gap> lines:=AsList(Lines(pg));
#<closed orbit, 357 points>
#gap> g:=ProjectivityGroup(pg);
#PGL(4,4)
#gap> h:=SylowSubgroup(g,5);
#<projective semilinear group of size 25>
#gap> FindSuborbits(lines,GeneratorsOfGroup(h));
##I  Have suborbits, compiling result record...
#rec( o := <closed orbit, 357 points>, nrsuborbits := 21,
# reps := [ 1, 2, 3, 4, 5, 7, 9, 10, 12, 16, 18, 25, 26, 28, 36, 39, 56, 62,
#     124, 276, 324 ],
# words := [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ],
# lens := [ 25, 25, 25, 25, 5, 25, 25, 25, 25, 25, 5, 25, 25, 25, 5, 25, 5,
#     5, 5, 1, 1 ],
# suborbnr := [ 1, 2, 3, 4, 5, 3, 6, 6, 7, 8, 2, 9, 8, 4, 1, 10, 7, 11, 2, 6,
#     6, 8, 1, 7, 12, 13, 3, 14, 8, 12, 13, 10, 14, 12, 7, 15, 13, 1, 16, 9,
#     4, 8, 7, 2, 10, 12, 10, 1, 4, 10, 3, 8, 14, 7, 7, 17, 6, 1, 14, 9, 10,
#     18, 4, 9, 1, 3, 14, 12, 6, 1, 9, 8, 17, 8, 2, 13, 2, 4, 6, 16, 13, 13,
#     3, 3, 1, 10, 1, 14, 3, 12, 14, 14, 7, 10, 1, 14, 1, 4, 13, 2, 16, 2,
#     14, 16, 4, 9, 13, 12, 3, 14, 10, 6, 15, 12, 1, 16, 4, 6, 6, 8, 17, 12,
#     4, 19, 3, 13, 10, 9, 9, 16, 16, 7, 9, 4, 7, 1, 5, 3, 10, 19, 12, 13, 9,
#     2, 6, 10, 6, 16, 2, 2, 3, 6, 10, 4, 4, 16, 8, 14, 6, 13, 9, 12, 12, 16,
#     15, 13, 3, 9, 3, 10, 2, 1, 4, 7, 10, 8, 8, 14, 10, 11, 7, 9, 1, 8, 7,
#     2, 1, 12, 17, 4, 6, 15, 16, 16, 7, 14, 13, 14, 3, 8, 18, 12, 7, 16, 14,
#     6, 14, 7, 16, 13, 1, 9, 13, 1, 14, 18, 16, 16, 1, 17, 13, 6, 10, 16,
#     10, 6, 10, 7, 3, 18, 13, 15, 2, 3, 7, 8, 1, 4, 2, 2, 13, 7, 4, 8, 8, 2,
#     13, 14, 1, 10, 6, 10, 19, 6, 12, 12, 7, 13, 9, 2, 2, 7, 19, 2, 16, 14,
#     3, 13, 10, 5, 14, 12, 8, 8, 9, 20, 13, 14, 9, 12, 6, 9, 12, 13, 7, 12,
#     6, 11, 16, 4, 5, 2, 12, 10, 2, 12, 9, 9, 14, 14, 3, 11, 9, 8, 3, 8, 4,
#     16, 8, 1, 2, 12, 5, 4, 8, 11, 4, 3, 6, 6, 9, 3, 3, 21, 9, 4, 2, 8, 16,
#     16, 12, 3, 7, 7, 9, 6, 4, 8, 9, 14, 2, 3, 16, 7, 16, 1, 13, 4, 16, 4,
#     13, 10, 18, 12, 1, 10, 19 ],
# suborbs := [ [ 1, 15, 23, 38, 48, 58, 65, 70, 85, 87, 95, 97, 115, 136,
#         172, 183, 187, 211, 214, 219, 237, 249, 310, 346, 355 ],
#     [ 2, 11, 19, 44, 75, 77, 100, 102, 144, 149, 150, 171, 186, 233, 239,
#         240, 246, 260, 261, 264, 292, 295, 311, 327, 341 ],
#     [ 3, 6, 27, 51, 66, 83, 84, 89, 109, 125, 138, 151, 167, 169, 199, 229,
#         234, 267, 301, 305, 318, 322, 323, 332, 342 ],
#     [ 4, 14, 41, 49, 63, 78, 98, 105, 117, 123, 134, 154, 155, 173, 190,
#         238, 243, 290, 307, 314, 317, 326, 337, 348, 350 ],
#     [ 5, 137, 270, 291, 313 ],
#     [ 7, 8, 20, 21, 57, 69, 79, 112, 118, 119, 145, 147, 152, 159, 191,
#         206, 222, 226, 251, 254, 281, 287, 319, 320, 336 ],
#     [ 9, 17, 24, 35, 43, 54, 55, 93, 132, 135, 174, 181, 185, 195, 203,
#         208, 228, 235, 242, 257, 262, 285, 333, 334, 344 ],
#     [ 10, 13, 22, 29, 42, 52, 72, 74, 120, 157, 176, 177, 184, 200, 236,
#         244, 245, 273, 274, 304, 306, 309, 315, 328, 338 ],
#     [ 12, 40, 60, 64, 71, 106, 128, 129, 133, 143, 161, 168, 182, 212, 259,
#         275, 279, 282, 297, 298, 303, 321, 325, 335, 339 ],
#     [ 16, 32, 45, 47, 50, 61, 86, 94, 111, 127, 139, 146, 153, 170, 175,
#         179, 223, 225, 227, 250, 252, 269, 294, 352, 356 ],
#     [ 18, 180, 288, 302, 316 ],
#     [ 25, 30, 34, 46, 68, 90, 108, 114, 122, 141, 162, 163, 188, 202, 255,
#         256, 272, 280, 283, 286, 293, 296, 312, 331, 354 ],
#     [ 26, 31, 37, 76, 81, 82, 99, 107, 126, 142, 160, 166, 197, 210, 213,
#         221, 231, 241, 247, 258, 268, 277, 284, 347, 351 ],
#     [ 28, 33, 53, 59, 67, 88, 91, 92, 96, 103, 110, 158, 178, 196, 198,
#         205, 207, 215, 248, 266, 271, 278, 299, 300, 340 ],
#     [ 36, 113, 165, 192, 232 ],
#     [ 39, 80, 101, 104, 116, 130, 131, 148, 156, 164, 193, 194, 204, 209,
#         217, 218, 224, 265, 289, 308, 329, 330, 343, 345, 349 ],
#     [ 56, 73, 121, 189, 220 ], [ 62, 201, 216, 230, 353 ],
#     [ 124, 140, 253, 263, 357 ], [ 276 ], [ 324 ] ],
# conjsuborbit := [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
#     0, 0 ], issuborbitrecord := true )

######################################
#
# Put compressed matrices here....
#
#####################################

# CHECKED 11/09/11 jdb
#############################################################################
#O  Iterator( <vs>) 
# returns an iterator for <vs>, a collection of subspaces of a projective space.
##
InstallMethod(Iterator,
	"for subspaces of a projective space",
	[IsSubspacesOfProjectiveSpace],
	function( vs )
		local ps, j, d, F;
		ps := vs!.geometry;
		j := vs!.type;
		d := ps!.dimension;
		F := ps!.basefield;
        return IteratorByFunctions( rec(
			NextIterator := function(iter)
            local mat;
            mat := NextIterator(iter!.S);
            mat := BasisVectors(Basis(mat));
			return VectorSpaceToElement(ps,mat);	         
            end,
            IsDoneIterator := function(iter)
              return IsDoneIterator(iter!.S);
            end,
            ShallowCopy := function(iter)
              return rec(
                S := ShallowCopy(iter!.S)
                );
            end,
            S := Iterator(Subspaces(ps!.vectorspace,j))
          ));
	end);

#############################################################################
# Methods to create flags.
#############################################################################

# CHECKED 18/4/2011 jdb
#############################################################################
#O  FlagOfIncidenceStructure( <ps>, <els> )
# returns the flag of the projective space <ps> with elements in <els>.
# the method checks whether the input really determines a flag.
##
InstallMethod( FlagOfIncidenceStructure,
	"for a projective space and list of subspaces of the projective space",
	[ IsProjectiveSpace, IsSubspaceOfProjectiveSpaceCollection ],
	function(ps,els)
		local list,i,test,type,flag;
		list := Set(ShallowCopy(els));
		if Length(list) > Rank(ps) then
		  Error("A flag must contain at least two elements and at most Rank(<ps>) elemnts");
		fi;
		test := Set(List([1..Length(list)-1],i -> IsIncident(list[i],list[i+1])));
		if (test <> [ true ] and test <> []) then
		  Error("<els> does not determine a flag>");
		fi;
		flag := rec(geo := ps, types := List(list,x->x!.type), els := list);
		ObjectifyWithAttributes(flag, IsFlagOfPSType, IsEmptyFlag, false);
		return flag;
	end);

# CHECKED 18/4/2011 jdb
#############################################################################
#O  FlagOfIncidenceStructure( <ps>, <els> )
# returns the empty flag of the projective space <ps>.
##
InstallMethod( FlagOfIncidenceStructure,
	"for a projective space and an empty list",
	[ IsProjectiveSpace, IsList and IsEmpty ],
	function(ps,els)
		local flag;
		flag := rec(geo := ps, types := [], els := []);
		ObjectifyWithAttributes(flag, IsFlagOfPSType, IsEmptyFlag, true);
		return flag;
	end);

#############################################################################
# View/Print/Display methods for flags
#############################################################################

InstallMethod( ViewObj, "for a flag of a projective space",
	[ IsFlagOfProjectiveSpace and IsFlagOfIncidenceStructureRep ],
	function( flag )
		Print("<a flag of ProjectiveSpace(",flag!.geo!.dimension,", ",Size(flag!.geo!.basefield),")>");
	end );

InstallMethod( PrintObj, "for a flag of a projective space",
	[ IsFlagOfProjectiveSpace and IsFlagOfIncidenceStructureRep ],
	function( flag )
		PrintObj(flag!.els);
	end );

InstallMethod( Display, "for a flag of a projective space",
	[ IsFlagOfProjectiveSpace and IsFlagOfIncidenceStructureRep  ],
	function( flag )
		if IsEmptyFlag(flag) then
			Print("<empty flag of ProjectiveSpace(",flag!.geo!.dimension,", ",Size(flag!.geo!.basefield),")>\n");
		else
			Print("<a flag of ProjectiveSpace(",flag!.geo!.dimension,", ",Size(flag!.geo!.basefield),")> with elements of types ",flag!.types,"\n");
			Print("respectively spanned by\n");
			Display(flag!.els);
		fi;
	end );

# CHECKED 18/4/2011 jdb
#############################################################################
#O  ShadowOfFlag( <ps>, <flag>, <j> )
# returns the shadow elements of <flag>, i.e. the elements of <ps> of type <j> 
# incident with all elements of <flag>.
# returns the shadow of a flag as a record containing the projective space (geometry), 
# the type j of the elements (type), the flag (parentflag), and some extra information
# useful to compute with the shadows, e.g. iterator
##
InstallMethod( ShadowOfFlag, "for a projective space, a flag and an integer",
	[IsProjectiveSpace, IsFlagOfProjectiveSpace, IsPosInt],
	function( ps, flag, j )
    local localinner, localouter, localfactorspace, v, smallertypes, biggertypes, ceiling, floor;
    
    #empty flag - return all subspaces of the right type
    if IsEmptyFlag(flag) then
      return ElementsOfIncidenceStructure(ps, j);
    fi;
    
    # find the element in the flag of highest type less than j, and the subspace
    # in the flag of lowest type more than j.
	
	#listoftypes:=List(flag,x->x!.type);
	smallertypes:=Filtered(flag!.types,t->t <= j);
	biggertypes:=Filtered(flag!.types,t->t >= j);
	if smallertypes=[] then 
		localinner := [];
		ceiling:=Minimum(biggertypes);
		localouter:=flag!.els[Position(flag!.types,ceiling)];
	elif biggertypes=[] then 
		localouter:=BasisVectors(Basis(ps!.vectorspace));
		floor:=Maximum(smallertypes);
		localinner:=flag!.els[Position(flag!.types,floor)];
	else
		floor:=Maximum(smallertypes);
		ceiling:=Minimum(biggertypes);
		localinner:=flag!.els[Position(flag!.types,floor)];
		localouter:=flag!.els[Position(flag!.types,ceiling)];
	fi;
	if not smallertypes = [] then
		if localinner!.type = 1 then
			localinner:=[localinner!.obj];
		else
			localinner:=localinner!.obj;
		fi;
	fi;
    if not biggertypes = [] then
		if localouter!.type = 1 then
			localouter := [localouter!.obj];
        else
			localouter := localouter!.obj;
        fi;
	fi;
    localfactorspace := Subspace(ps!.vectorspace, 
		BaseSteinitzVectors(localouter, localinner).factorspace);
    return Objectify(
		NewType( ElementsCollFamily, IsElementsOfIncidenceStructure and
                                IsShadowSubspacesOfProjectiveSpace and
                                IsShadowSubspacesOfProjectiveSpaceRep),
        rec(
          geometry := ps,
          type := j,
          inner := localinner,
          outer := localouter,
          factorspace := localfactorspace,
		  parentflag := flag,
          size := Size(Subspaces(localfactorspace))
        )
      );
	end);

# CHECKED 11/09/11 jdb
#############################################################################
#O  Iterator( <vs>) 
# returns an iterator for <vs>, a collection of shadowsubspaces of a projective space.
##
InstallMethod( Iterator, 
	"for shadows subspaces of a projective space",
	[IsShadowSubspacesOfProjectiveSpace and IsShadowSubspacesOfProjectiveSpaceRep ],
	function( vs )
		local ps, j, d, F;
		ps := vs!.geometry;
		j := vs!.type;
		d := ps!.dimension;
		F := ps!.basefield;
		return IteratorByFunctions( rec(
			NextIterator := function(iter)
			local mat;
			mat := NextIterator(iter!.S);
			mat := MutableCopyMat(Concatenation(
				BasisVectors(Basis(mat)),
				iter!.innermat
			));
			return VectorSpaceToElement(ps,mat);
			end,
			IsDoneIterator := function(iter)
			return IsDoneIterator(iter!.S);
			end,
			ShallowCopy := function(iter)
			return rec(
				innermat := iter!.innermat,
				S := ShallowCopy(iter!.S)
			);
			end,
			innermat := vs!.inner,
			S := Iterator(Subspaces(vs!.factorspace,j-Size(vs!.inner)))
		));
	end);

#############################################################################
# Methods for incidence.
# Recall that: - we have a generic method to check set theoretic containment
#                for two *elements* of a Lie geometry, and trivial subspaces.
#              - IsIncident is symmetrized set theoretic containment
#              - we can extend the \in method (if desired) for the particular
#                Lie geometry, such that we can get true if we ask if an 
#                element is contained in the complete space, or if we consider
#                the whole space and the trivial subspce.
#              - \* is a different notation for IsIncident, declared and
#                implement in geometry.g* 
#############################################################################

# CHECKED 7/09/11 jdb
#############################################################################
#O  \in( <x>, <y> )
# set theoretic containment for a projective space and a subspace. 
##
InstallOtherMethod( \in, 
	"for a projective space and any of its subspaces", 
	[ IsProjectiveSpace, IsSubspaceOfProjectiveSpace ],
	function( x, y )
		if x = y!.geo then
			return false;
		else
			Error( "<x> is different from the ambient space of <y>" );
		fi;
	end );

# CHECKED 11/09/11 jdb
#############################################################################
#O  \in( <x>, <y> )
# returns false if and only if (and this is checked) <y> is the trivial subspace
# in the projective space <x>.
##
InstallOtherMethod( \in, 
	"for a projective subspace and its trivial subspace ", 
	[ IsProjectiveSpace, IsEmptySubspace ],
	function( x, y )
		if x = y!.geo then
			return false;
		else
			Error( "<x> is different from the ambient space of <y>" );
		fi;
	end );

# CHECKED 11/09/11 jdb
#############################################################################
#O  \in( <x>, <dom> )
# returns true if and only if (and this is checked) <x> is the trivial subspace
# in the projective space <dom>.
##
InstallMethod( \in, 
	"for a subspace of a projective space and projective space",  
    [IsSubspaceOfProjectiveSpace, IsProjectiveSpace],
	function( x, dom )
		local ps;
		ps := x!.geo;
		return ps!.dimension = dom!.dimension and 
			ps!.basefield = dom!.basefield;
	end );

# CHECKED 11/09/11 jdb
#############################################################################
#O  \in( <x>, <dom> )
# returns true if and only if (and this is checked) <x> is the trivial subspace
# in the projective space <dom>.
##
InstallMethod( \in, 
	"for a subspace of a projective space and projective space",  
    [IsProjectiveSpace, IsSubspaceOfProjectiveSpace],
	function( dom, x )
		local ps;
		ps := x!.geo;
		return ps!.dimension = dom!.dimension and 
			ps!.basefield = dom!.basefield;
	end );


# CHECKED 14/09/11 jdb
#############################################################################
#O  IsIncident( <x>, <y> )
# returns true if and only if <x> is incident with <y>. Relies on set theoretic
# containment, which is implemented genericly for elements of Lie geometries.
##
InstallMethod( IsIncident,  
		[IsSubspaceOfProjectiveSpace, IsSubspaceOfProjectiveSpace],
		# returns true if the subspace is contained in the projective space
        function(x,y)
                return x in y or y in x;
        end );

#InstallMethod( IsIncident,  [IsProjectiveSpace,
#        IsSubspaceOfProjectiveSpace],
#        # returns true if the subspace is contained in the projective space
#        function(x,y)
#                return y in x;
#        end );

#InstallMethod( IsIncident,  [IsSubspaceOfProjectiveSpace,
#        IsProjectiveSpace],
#        # returns true if the subspace is contained in the projective space
#        function(x,y)
#                return x in y;
#        end );

#InstallMethod( IsIncident,  [IsProjectiveSpace,
#        IsSubspaceOfProjectiveSpace],
#        # returns true if the subspace is contained in the projective space
#        function(x,y)
#                return y in x;
#        end );


# I will change "drastically" here.
# this method is converted into a generic method to test set theoretic containment
# for elements of Lie geometries. Put in the file liegeometry.gi 

#InstallMethod( IsIncident,  [IsSubspaceOfProjectiveSpace,
## some of this function is based on the
## SemiEchelonMat function. we save time by assuming that the matrix of
## each subspace is already in semiechelon form.
## method only applies to projective and polar spaces
#  IsSubspaceOfProjectiveSpace],
#  function( x, y )
#    local ambx, amby, typx, typy, mat,
#          zero,      # zero of the field of <mat>
#          nrows,
#          ncols,     # number of columns in <mat>
#          vectors,   # list of basis vectors
#          nvectors,
#          i,         # loop over rows
#          j,         # loop over columns
#          z,         # a current element
#          nzheads,   # list of non-zero heads
#          row;       # the row of current interest


#    ambx := x!.geo;
#    amby := y!.geo;
#    typx := x!.type;
#    typy := y!.type;
#    
#    if ambx!.vectorspace = amby!.vectorspace then
    
#        if typx >= typy then
#          vectors := x!.obj;
#          nvectors := typx;
#          mat := MutableCopyMat(y!.obj);
#          nrows := typy;
#        else
#          vectors := y!.obj;
#          nvectors := typy;
#          mat := MutableCopyMat(x!.obj);
#          nrows := typx;
#        fi;
      # subspaces of type 1 need to be nested to make them lists of vectors

#      if nrows = 1 then mat := [mat]; fi;
#      if nvectors = 1 then vectors := [vectors]; fi;

#      ncols:= amby!.dimension + 1;
#      zero:= Zero( mat[1][1] );

      # here we are going to treat "vectors" as a list of basis vectors. first
      # figure out which column is the first nonzero column for each row
#      nzheads := [];
#      for i in [ 1 .. nvectors ] do
#        row := vectors[i];
#        j := PositionNot( row, zero );
#        Add(nzheads,j);
#      od;

      # now try to reduce each row of "mat" with the basis vectors
#      for i in [ 1 .. nrows ] do
#        row := mat[i];
#        for j in [ 1 .. Length(nzheads) ] do
#            z := row[nzheads[j]];
#            if z <> zero then
#              AddRowVector( row, vectors[ j ], - z );
#            fi;
#        od;

        # if the row is now not zero then y is not a subvariety of x
#        j := PositionNot( row, zero );
#        if j <= ncols then
#                return false;
#        fi;

#      od;
      
#      return true;
#    else
#      Error( "The subspaces belong to different ambient spaces" );
#    fi;
#    return false;
#  end );

#############################################################################
# Span/Meet methods in many flavours. 
#############################################################################

# CHECKED 11/09/11 jdb
#############################################################################
#O  Span( <x>, <y> )
# returns <x> if and only if <y> is a subspace in the projective space <x>
##
InstallMethod( Span, 
	"for a projective space and a subspace",
	[IsProjectiveSpace, IsSubspaceOfProjectiveSpace],
    function(x,y)
		if y in x then return x; fi;
	end );

# CHECKED 11/09/11 jdb
#############################################################################
#O  Span( <x>, <y> )
# returns <y> if and only if <x> is a subspace in the projective space <y>
##
InstallMethod( Span, "for a subspace of a projective space and a projective space",
	[IsSubspaceOfProjectiveSpace, IsProjectiveSpace],
	function(x,y)
	if x in y then return y; fi;
end );

#InstallMethod( Span, [IsSubspaceOfProjectiveSpace, IsSubspaceOfProjectiveSpace],
#  function( x, y )  
#    local ux, uy, ambx, amby, typx, typy, span, F;
#    ambx := AmbientSpace(x!.geo);
#    amby := AmbientSpace(y!.geo);
#    typx := x!.type;
#    typy := y!.type;
#    F := ambx!.basefield;

#    if ambx!.vectorspace = amby!.vectorspace then
#      ux := ShallowCopy(x!.obj); 
#      uy := ShallowCopy(y!.obj);
#        
#      if typx = 1 then ux := [ux]; fi;
#      if typy = 1 then uy := [uy]; fi;

#      span := MutableCopyMat(ux);
#      Append(span,uy);
#      span := MutableCopyMat(EchelonMat(span).vectors);
#      # if the span is the whole space, return that.
#      if Length(span) = ambx!.dimension + 1 then
#        return ambx;
#      fi;
#	  return VectorSpaceToElement(ambx,span); 
#    else
#      Error("The subspaces belong to different ambient spaces");
#    fi;
#    return;
#  end );

# CHECKED 11/09/11 jdb
#############################################################################
#O  Span( <x>, <y> )
# returns <x,y>, <x> and <y> two subspaces of a projective space.
##
InstallMethod( Span, 
	"for two subspaces of a projective space",
	[IsSubspaceOfProjectiveSpace, IsSubspaceOfProjectiveSpace],
	function( x, y )
	## This method is quicker than the old one
	local ux, uy, typx, typy, span, vec;
	typx := x!.type;
	typy := y!.type;
	vec := x!.geo!.vectorspace;
	if vec = y!.geo!.vectorspace then
		ux := Unwrap(x);
		uy := Unwrap(y);
		if typx = 1 then ux := [ux]; fi;
		if typy = 1 then uy := [uy]; fi;
		span := SumIntersectionMat(ux, uy)[1];	
		if Length(span) < vec!.DimensionOfVectors then
			return VectorSpaceToElement( AmbientSpace(x!.geo), span);
		else
			return AmbientSpace(x!.geo);
		fi;
	else
		Error("Subspaces belong to different ambient spaces");
	fi;
	end );

# ADDED 30/11/2011 jdb
#############################################################################
#O  Span( <x>, <y> )
# returns <x,y>, <x> and <y> two subspaces of a projective space.
##
InstallMethod( Span, 
	"for two subspaces of a projective space and a boolean",
	[IsSubspaceOfProjectiveSpace, IsSubspaceOfProjectiveSpace, IsBool],
	function( x, y, b )
		return Span(x,y);
	end );

# CHECKED 20/09/11 
#############################################################################
#O  Span( <l> )
# returns the span of the projective subspaces in <l>.
##
InstallMethod( Span, "for a homogeneous list of subspaces of a projective space",
	[ IsHomogeneousList and IsSubspaceOfProjectiveSpaceCollection ],
	function( l )  
		local unwrapped, r, unr, amb, span, temp, x, F, list;  
		# first we check that all items in the list belong to the same ambient space
		if Length(l)=0 then 
			return [];
		elif not Size(AsDuplicateFreeList(List(l,x->AmbientSpace(x))))=1 then 
			Error("The elements in the list do not have a common ambient space");
		else
			x := l[1];
			amb := AmbientSpace(x!.geo);
			F := amb!.basefield;
			unwrapped := [];
			for r in l do
				unr := r!.obj;
				if r!.type = 1 then unr := [unr]; fi;
				Append(unwrapped, unr);
			od;
			span := MutableCopyMat(unwrapped);
			# span := MutableCopyMat(EchelonMat(span).vectors); #not necessary anyway, since VectorSpaceToElement is used.
#   JB: Yes it is necessary for the following part!!!
#			if Length(span) = amb!.dimension + 1 then
#				return amb;
#			fi;
			return VectorSpaceToElement(amb,span);
		fi;
	end );

# CHECKED 11/09/11 jdb
#############################################################################
#O  Span( <l> )
# returns the span of the projective subspaces in <l>.
##
InstallMethod( Span, 
	"for a list",
	[ IsList ],
	function( l )  
		local pg,list,x;
		# This method is added to allow the list ("l") to contain the projective space 
		# or the empty subspace. If this method is selected, it follows that the list must
		# contain the whole projective space or the empty set. 
		# First we remove the emptysubspace from the list, then we check if the list
		# contains the whold projective space. If it does, return that, if it doesn't
		# return the span of the remaining elements of the list, which will then select
		# the previous method for Span
		if Length(l)=0 then return [];
		elif Length(l)=1 then return l[1];
		else
			list:=Filtered(l,x->not IsEmptySubspace(x));
			if not Size(AsDuplicateFreeList(List(list,x->AmbientSpace(x))))=1 then 
				Error("The elements in the list do not have a common ambient space");
			else
				pg:=AmbientSpace(list[1]);
				if pg in list then return pg;
				else
					return Span(list);
				fi;
			fi;
		fi;
	end );

# ADDED 30/11/2011 jdb
# this is a "helper" operation. We do not expect the user to use this variant
# when he knows that list is a list of projective subspaces. In this case, we will
# not document it. When dealing with a list of subspaces polar spaces, the user
# could get into this without realising. The result is of course then just Span(l).
#############################################################################
#O  Span( <x>, <y> )
# returns <x,y>, <x> and <y> two subspaces of a projective space.
##
InstallMethod( Span, 
	"for a list and a boolean",
	[IsList, IsBool],
	function( l, b )
		return Span(l);
	end );

# CHECKED 14/09/11 jdb
#############################################################################
#O  Meet( <x>, <y> )
# returns <y> if and only if <y> is a subspace in the projective space <x>
##
InstallMethod( Meet, 
	"for a projective space and a subspace of a projective space",
	[IsProjectiveSpace, IsSubspaceOfProjectiveSpace],
    function(x,y)
		if y in x then return y;
	fi;
end );

# CHECKED 14/09/11 jdb
#############################################################################
#O  Meet( <x>, <y> )
# returns <y> if and only if <y> is a subspace in the projective space <x>
##
InstallMethod( Meet, 
	"for a subspace of a projective space and a projective space",
	[IsSubspaceOfProjectiveSpace, IsProjectiveSpace],
	function(x,y)
		if x in y then return x;
	fi;
end );

# CHECKED 14/09/2011 jdb.
# CHANGED 30/11/2011 jdb. it is not possible to compare e.g. two quadrics, or
# just any two lie geometries using \=. So if <x> and <y> belong to two different
# Lie geometries with the same ambient projective space, it is not possible to decide
# if the two geometries equal. So it makes no sense to construct the result in any other
# space then the ambient space.
#############################################################################
#O  Meet( <x>, <y> )
# returns the intersection of <x> and <y>, two subspaces of a projective space.
##
InstallMethod( Meet,
	"for two subspaces of a projective space",
	[IsSubspaceOfProjectiveSpace, IsSubspaceOfProjectiveSpace],
	function( x, y )
		local ux, uy, typx, typy, int, f, rk;
		typx := x!.type;
		typy := y!.type;
		if x!.geo!.vectorspace = y!.geo!.vectorspace then 
			ux := Unwrap(x); 
			uy := Unwrap(y);
			if typx = 1 then ux := [ux]; fi;
			if typy = 1 then uy := [uy]; fi;
			f := x!.geo!.basefield; 
			int := SumIntersectionMat(ux, uy)[2];
			if not int=[] then 
				return VectorSpaceToElement( AmbientSpace(x), int);
			else 
				return EmptySubspace(AmbientSpace(x));
			fi;
		else
			Error("Subspaces belong to different ambient spaces");
		fi;
    #return; #why is this return;?
  end );

# CHECKED 14/09/2011 jdb.
#############################################################################
#O  Meet( <l> )
# returns the intersection the subspaces of a projective space in the list <l>
##
InstallMethod( Meet,
	"for a homogeneous list that is a collection of subspaces of a projective space",
	[ IsHomogeneousList and IsSubspaceOfProjectiveSpaceCollection],
	function( l )  
		local int, iter, ps,em;
		# first we check if all subspaces have the same ambient geometry
		ps := AsDuplicateFreeList(List(l,x->AmbientSpace(x)));
		if not Size(ps)=1 then 
			Error("The elements in the list do not have a common ambient space");
		else
		# We use recursion for this routine.
		# Not ideal, but there is no "SumIntersectionMat" for lists
			ps := ps[1];
			em := EmptySubspace(ps);
			if not IsEmpty(l) then
				if Length(l)=1 then return l;
				else
					iter := Iterator(l);
					int := NextIterator(iter);
					repeat
						int := Meet(int, NextIterator(iter));
					until int = em or IsDoneIterator(iter);
					return int;
				fi;
			else return []; #I think this will never happen, since IsSubspaceOfProjectiveSpaceCollection([]) is false.
			fi;
		fi;
	end );

# CHECKED 14/09/2011 jdb.
#############################################################################
#O  Meet( <l> )
# returns the intersection the objects list <l>
##
InstallMethod( Meet,
	"for a list",
	[ IsList ],
	function( l )  
		local pg,checklist,list,x;
		# This method is added to allow the list ("l") to contain the projective space 
		# or the empty subspace. If this method is selected, it follows that the list must
		# contain the whole projective space or the empty set. 
		if IsEmpty(l) then return [];
		else
			if Length(l)=1 then return l[1];
			else
				# First we check that the non emptysubspace elements belong to the same ambient space
				checklist:=Filtered(l,x->not IsEmptySubspace(x) and not IsProjectiveSpace(x));
				if not Size(AsDuplicateFreeList(List(checklist,x->AmbientSpace(x))))=1 then 
					Error("The elements in the list do not have a common ambient space");
				else	
					if EmptySubspace(AmbientSpace(l[1])) in l then return EmptySubspace(AmbientSpace(l[1]));
					else
						pg:=AmbientSpace(checklist[1]); 
						# the first element in l could be the emptysubspace,
						# so we choose the first element of the checklist
						list:=Filtered(l,x->not x = pg);
						return Meet(list);
					fi;
				fi;
			fi;
		fi;
	end );

#############################################################################
## Methods for random selection of elements
#############################################################################  

# CHECKED 14/09/2011 jdb.
#############################################################################
#O  RandomSubspace( <pg>, <d> )
# returns a random subspace of projective dimension <d> in the projective space
# <pg>
##
InstallMethod( RandomSubspace,
	"for a projective space and a projective dimension",
	[IsProjectiveSpace,IsInt],
	function(pg,d)
		local vspace,list,W,w;
        if d>ProjectiveDimension(pg) then
			Error("The dimension of the subspace is larger that of the projective space");
        fi;
		if IsNegInt(d) then
			Error("The dimension of the subspace must be at least 0!");
		fi;
        vspace:=pg!.vectorspace;
		W:=RandomSubspace(vspace,d+1);
        return(VectorSpaceToElement(pg,AsList(Basis(W))));
	end );

# CHECKED 14/09/2011 jdb.
#############################################################################
#O  RandomSubspace( <subspace>, <d> )
# returns a random subspace of projective dimension <d> contained in the given
# projective subspace <subspace>
##
InstallMethod( RandomSubspace,
	"for a subspace of a projective space and a dimension",
    [IsSubspaceOfProjectiveSpace,IsInt],
    function(subspace,d)
		local vspace,list,W,w;
        if d>ProjectiveDimension(subspace) then
			Error("The dimension of the random subspace is too large");
        fi;
		if IsNegInt(d) then
			Error("The dimension of the random subspace must be at least 0!");
		fi;
        vspace:=UnderlyingVectorSpace(subspace);
		W:=RandomSubspace(vspace,d+1);
		return(VectorSpaceToElement(subspace!.geo,AsList(Basis(W))));
	end );  

# CHECKED 14/09/2011 jdb.
#############################################################################
#O  RandomSubspace( <pg> )
# returns a random subspace of random projective dimension in the given projective
# space <pg>
##
InstallMethod( RandomSubspace, 
	"for a projective space",
	[IsProjectiveSpace],
	function(pg)
		local list,i;
		list:=[0..Dimension(pg)-1];
		i:=Random(list);
		return RandomSubspace(pg,i);
	end );
			
		
# CHECKED 14/09/2011 jdb.
#############################################################################
#O  Random( <subs> )
# returns a random subspace out of the collection of subspaces of given dimension
# of a projective space.
##
InstallMethod( Random, 
	"for a collection of subspaces of a projective space",
	[ IsSubspacesOfProjectiveSpace ],
    # chooses a random element out of the collection of subspaces of given
    # dimension of a projective space
	function( subs )
		local d, pg, vspace, W, w;
		## the underlying projective space
		pg := subs!.geometry;
		vspace:=pg!.vectorspace;
		if not IsInt(subs!.type) then
			Error("The subspaces of the collection need to have the same dimension");
        fi;
		## the common type of elements of subs
		d := subs!.type;        
		W:=RandomSubspace(vspace,d);
        return(VectorSpaceToElement(pg,AsList(Basis(W))));
  end );
  
# CHECKED 14/09/2011 jdb.
#############################################################################
#O  Random( <subs> )
# returns a random subspace out of the collection of all subspaces of 
# a projective space.
##
InstallMethod( Random, 
	"for a collection of all subspaces of a projective space",
	[ IsAllSubspacesOfProjectiveSpace ],
    # chooses a random element out of the collection of all subspaces of a projective space
	function( subs )
	    return RandomSubspace(subs!.geometry);
	end );

# CHECKED 14/09/2011 jdb.
# but I am unhappy with this method, since it is not possible to select e.g. 
# a random line through a point now.
#############################################################################
#O  Random( <subs> )
# returns a random element out of the collection of subspaces of given
# dimension contained in a subspace of a projective space
##
InstallMethod( Random, 
	"for a collection of subspaces of a subspace of a projective space",
	[ IsShadowSubspacesOfProjectiveSpace ],
    # chooses a random element out of the collection of subspaces of given
    # dimension of a subspace of a projective space
	function( subs )
		local d, pg, subspace, vspace, W, w;
		## the underlying projective space
		pg := subs!.geometry;
		subspace:=subs!.parentflag;
		vspace:=UnderlyingVectorSpace(subspace);
		if not IsInt(subs!.type) then
			Error("The subspaces of the collection need to have the same dimension");
        fi;
		## the common type of elements of subs
		d := subs!.type;        
		W:=RandomSubspace(vspace,d);
        return(VectorSpaceToElement(pg,AsList(Basis(W))));
	end );

#############################################################################
# Baer sublines and Baer subplanes:
# These objects are particular cases of subgeometries, and should be returned
# as embeddings. To construct subgeometries on a general frame, we should
# use the unique projectivity mapping the standard frame to this frame, and
# then construct the subgeometry as the image of the canonical subgeometry
# (this is the one that contains the standard frame)
#
# The general functions could be: 
# CanonicalSubgeometry(projectivespace,primepower)
# SubgeometryByFrame(projectivespace,primepower,frame)
# The function
# ProjectivityByFrame(frame) (DONE, see "ProjectivityByImageOfStandardFrameNC")
# ProjectivityByTwoFrames(frame1,frame2)
#############################################################################

InstallMethod( BaerSublineOnThreePoints,
	"for three points of a projective space",
	[IsSubspaceOfProjectiveSpace, IsSubspaceOfProjectiveSpace, IsSubspaceOfProjectiveSpace],
	# UNCHECKED
	function( x, y, z )
  # returns the Baersubline determined by three collinear points x,y,z
	local geo, gfq2, gfq, t, subline;
	if Length(DuplicateFreeList(List([x,y,z],t->AmbientSpace(t)))) <> 1 then
		Error( "<x>, <y>, <z> must be points of the same projective space" );
	fi;
	geo := AmbientSpace(x);
	gfq2 := geo!.basefield;
	if RootInt(Size(gfq2),2)^2 <> Size(gfq2) then
		Error( "the order of the basefield must be a square" );
	fi;
	gfq := GF(Sqrt(Size(gfq2)));

	## Write z as x + ty
  
	t := First(gfq2, u -> Rank([z!.obj, x!.obj + u * y!.obj]) = 1); 

	## Then the subline is just the set of points
	## of the form x + w (ty), w in GF(q) (together
	## with x and y of course).
	
	subline := List(gfq, w -> VectorSpaceToElement(geo, x!.obj + w * t * y!.obj));
	Add( subline, y );
	return subline;
end);

InstallMethod( BaerSubplaneOnQuadrangle, [IsSubspaceOfProjectiveSpace, 
         IsSubspaceOfProjectiveSpace, IsSubspaceOfProjectiveSpace, IsSubspaceOfProjectiveSpace],
# UNCHECKED
 function( w, x, y, z )
  local geo, gfq2, gfq, s, t, subplane, coeffs, ow, ox, oy;
  geo := AmbientSpace(w!.geo);
  gfq2 := geo!.basefield;
  gfq := GF(Sqrt(Size(gfq2)));

  ## Write z as element in <w, x, y>
  
  coeffs := SolutionMat([w!.obj,x!.obj,y!.obj], z!.obj);
  ow := coeffs[1] * w!.obj;  
  ox := coeffs[2] * x!.obj;  
  oy := coeffs[3] * y!.obj;  

  ## Then just write down the subplane
  
  subplane := List(gfq, t -> VectorSpaceToElement(geo, ox + t * oy));
  Add( subplane, VectorSpaceToElement(geo, oy) );
  for s in gfq do
      for t in gfq do
          Add( subplane, VectorSpaceToElement(geo, ow + s * ox + t * oy));
      od;
  od;
  return subplane;
end);
