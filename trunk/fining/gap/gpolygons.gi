#############################################################################
##
##  gpolygons.gi              FinInG package
##                                                              John Bamberg
##                                                              Anton Betten
##                                                              Jan De Beule
##                                                             Philippe Cara
##                                                            Michel Lavrauw
##                                                           Max Neunhoeffer
##
##  Copyright 2014	Colorado State University, Fort Collins
##					Università degli Studi di Padova
##					Universeit Gent
##					University of St. Andrews
##					University of Western Australia, Perth
##                  Vrije Universiteit Brussel
##                 
##
##  Implementation stuff for generalised polygons.
##
#############################################################################

Print(", gpolygons\c");

#############################################################################
# Part I: generic part
# This section is generic, i.e. if someone constructs a GP and obeys the representation,
# these methods will work.
#############################################################################
# about IsGeneralisedPolygonRep
# objects belonging to IsGeneralisedPolygonRep should have several fields in their record:
# pointsobj, linesobj, incidence, listelements, shadowofpoint, shadowofline, distance.
#
# pointsobj: a list containing the *underlying objects* for the points of the GP
#
# linesobj: a list containing the *underlying objects* for the lines of the GP
#
# incidence: a function, taking two *elements of the GP* as argument, returning true or false
#			 we assume that the elements that are argument of this built in function, belong
#			 to the same geometry. See generic method IsIncident.
#
# listelements: a function taking an integer as argument, returning 
#	a list of all elements of the GP of the given type. This list will be turned into an iterator
#	by the method installed for Iterator for elements of GPs.
#
# shadowofpoint: a function, taking a *point of a GP* as argument, returning a list
#	of lines incident with the given point.
#
# shadowofline: a function, taking a *line of a GP* as argument, returning a list
#	of points incident with the given line. 
#		The method for ShadowOfElement should do the necessary checks and pass the appropriate 
#		function to the method installed for Iterator for shadow objects.
#
# distance: a function taking two *elements of a GP* and returning their distance in the incidence graph.
#
# action: a function describing an action on the *underlying objects*.
#
# Note: - If an object belongs to IsGeneralisedPolygon, then the "generic operations" to explore the GP
#			are *applicable* (does not imply that a specific method is installed or will be working).
#		- If a GP is constructed using a "Generic method", the above fields are created as described, making
#			all the methods for the "generic operations" working.
#		- If a GP is created as an object in IsGeneralisedPolygon and IsGeneralisedPolygonRep, with some of
#			these fields lacking or different, than separate methods need to be installed for certain operations
#			This is not problematic. A typical example are the hexagons: they belong also to IsLieGeometry, 
#			so it is easy to get the right methods selected. Furthermore, typical methods for Lie geometries become
#			applicable (but might also need separate methods).
#		- If a GP is constructed using the "generic construction methods", there is always an underlying graph (to
#			check whether the user really constructs a GP. Creating the graph can be time consuming, but there is
#			the possibility to use a group. There is no NC version, either you are a developper, and you want to make
#			a particular GP (e.g. the hexagons) and then you know what you od and there is no need to check whether your
#			developed GP is really a GP, or you are a user and must be protected against yourself. 
#			The computed graph is stored as a mutable attribute.
#		- For the particular GPs: of course we know that they are a GP, so on construction, we do not compute
#			the underlying graph.
#		- The classical GQs belong to IsGeneralisedPolygon but *not* to IsGeneralisedPolygonRep. For them there is
#			either an atrtibute set on creation (e.g. Order), or a seperate method for other generic operations.
#
#############################################################################

#############################################################################
#
# Construction of GPs
#
#############################################################################

#############################################################################
#O  GeneralisedPolygonByBlocks( <list> )
# returns a GP, the points are Union(blocks), the lines are the blocks. functions
# for shadows are installed. It is checked whether this is really a GP.
##
InstallMethod( GeneralisedPolygonByBlocks,
    "for a homogeneous list",
    [ IsHomogeneousList ],
    function( blocks )
        local pts, gp, ty, i, graph, sz, adj, girth, shadpoint, shadline, s, t, dist, vn, 
		listels, objs, act;
        pts := Union(blocks);
        s := Size(blocks[1]) - 1;
        if not ForAll(blocks, b -> Size(b) = s + 1 ) then
            Error("Not every block has size ", s + 1);
        fi;
        
        i := function( x, y )
        if IsSet( x!.obj ) and not IsSet( y!.obj ) then
            return y!.obj in x!.obj;
        elif IsSet( y!.obj ) and not IsSet( x!.obj ) then
            return x!.obj in y!.obj;
        else
            return x!.obj = y!.obj;
        fi;
        end;
        
        sz := Size(pts);
		
		adj := function(x,y)
			if IsSet(x) and not IsSet(y) then
				return y in x;
			elif IsSet(y) and not IsSet(x) then	
				return x in y;
			else
				return false;
			fi;
		end;

		act := function(x,g)
			return x;
		end;
			
        graph := Graph(Group(()), Concatenation(pts,blocks), act, adj );
        girth := Girth(graph);

        if IsBipartite(graph) then
            if not girth = 2*Diameter(graph) then
                Error("<blocks> are not defining a generalised polygon");
            fi;
        else
            Error("<blocks are not defining a generalised polygon");
        fi;
        
        if girth = 6 then
            ty := NewType( GeometriesFamily, IsProjectivePlane and IsGeneralisedPolygonRep );
        elif girth = 8 then
            ty := NewType( GeometriesFamily, IsGeneralisedQuadrangle and IsGeneralisedPolygonRep );
        elif girth = 12 then
            ty := NewType( GeometriesFamily, IsGeneralisedHexagon and IsGeneralisedPolygonRep );
        elif girth = 16 then
            ty := NewType( GeometriesFamily, IsGeneralisedOctagon and IsGeneralisedPolygonRep );
        else
            Error("<blocks> do not define a thick finite generalised polygon");
        fi;
        
        listels := function( geom, i )
			if i = 1 then
				return List(pts,x->Wrap(geom,i,x));
			else
				return List(blocks,x->Wrap(geom,i,x));
			fi;
		end;
				
		vn := VertexNames(graph);
		
        shadpoint := function( pt )
            return List(Filtered(blocks,x->pt!.obj in x),y->Wrap(pt!.geo,2,y));
        end;
        
        shadline := function( line )
            return List(line!.obj,x->Wrap(line!.geo,1,x));
        end;
		
		#we have the graph now, the following is efficient.
		t := Length(Adjacency(graph,1))-1; # number of lines on a point minus 1.

		dist := function( el1, el2 )
			return Distance(graph,Position(vn,el1!.obj),Position(vn,el2!.obj));
		end;

        gp := rec( pointsobj := pts, linesobj := blocks, incidence := i, listelements := listels, 
					shadowofpoint := shadpoint, shadowofline := shadline, distance := dist );

        Objectify( ty, gp );
        SetTypesOfElementsOfIncidenceStructure(gp, ["point","line"]);
        SetOrder(gp, [s, t]);
        SetRankAttr(gp, 2);
        Setter( IncidenceGraphOfGeneralisedPolygonAttr )( gp, graph );
        Setter( HasGraphWithUnderlyingObjectsAsVertices )( gp, true);
        return gp;
  end );

#############################################################################
#O  GeneralisedPolygonByIncidenceMatrix( <matrix> )
# returns a GP. points are [1..Size(matrix)], blocks are sets of entries equal to one.
# Blocks are then used through GeneralisedPolygonByBlocks.
##
InstallMethod( GeneralisedPolygonByIncidenceMatrix,
    "for a matrix",
    [ IsMatrix ],
    function( mat )
    ## Rows represent blocks and columns represent points...  
    local v, q, row, blocks, gp;
    v := Size(mat);
    if not ForAll(mat, t->Size(t)=v) then
       Error("Matrix is not square");
    fi;

    blocks := [];
    for row in mat do
        Add(blocks, Positions(row,1));
    od;
    
    gp := GeneralisedPolygonByBlocks( blocks );
    Setter( IncidenceMatrixOfGeneralisedPolygon )( gp, mat );
    return gp;
  end );

#############################################################################
#O  GeneralisedPolygonByElements( <pts>, <lns>, <inc> )
# <pts>: set of elements of some incidence structure, representing points of GP.
# <lns>: set of elements of some incidence structure, representing points of GP.
# <inc>: incidence function.
# it is checked throug the graph that the incidence structure is a GP.
##
InstallMethod( GeneralisedPolygonByElements,
    "for two sets (points and lines), and an incidence function",
    [ IsSet, IsSet, IsFunction ],
    function( pts, lns, inc )
    local adj, act, graph, ty, girth, shadpoint, shadline, s, t, 
	gp, vn, dist, listels, wrapped_incidence;

    adj := function(x,y)
    if x in pts and y in pts then
        return false;
    elif x in lns and y in lns then
        return false;
    else
        return inc(x,y);
    fi;
    end;
    
    # this is the situation where the user gives no group at all. So action function is trivial too.
    act := function(x,g)
        return x;
    end;

    graph := Graph(Group(()), Concatenation(pts,lns), act, adj, true );
    girth := Girth(graph);

    if IsBipartite(graph) then
        if not girth = 2*Diameter(graph) then
            Error("<blocks> are not defining a generalised polygon");
        fi;
    else
        Error("elements are not defining a generalised polygon");
    fi;
        
    if girth = 6 then
        ty := NewType( GeometriesFamily, IsProjectivePlane and IsGeneralisedPolygonRep );
    elif girth = 8 then
        ty := NewType( GeometriesFamily, IsGeneralisedQuadrangle and IsGeneralisedPolygonRep );
    elif girth = 12 then
        ty := NewType( GeometriesFamily, IsGeneralisedHexagon and IsGeneralisedPolygonRep );
    elif girth = 16 then
        ty := NewType( GeometriesFamily, IsGeneralisedOctagon and IsGeneralisedPolygonRep );
    else
        Error("<points>, <lines> and <inc> do not define a thick finite generalised polygon");
    fi;

	s := Length(Adjacency(graph,Size(pts)+1))-1; # number of points on a line minus 1.
	t := Length(Adjacency(graph,1))-1; # number of linbes on a point minus 1.

	# inc takes in fact underlying objects as arguments. So we must make a new function that takes
	# as arguments elements of this geometry and pipes the underlying objects to inc.

	wrapped_incidence := function(x,y)
		return inc(x!.obj,y!.obj);
	end;
	
    listels := function( geom, i )
		if i = 1 then
			return List(pts,x->Wrap(geom,i,x));
		else
			return List(lns,x->Wrap(geom,i,x));
		fi;
	end;

    shadpoint := function( pt )
        return List(vn{Adjacency(graph,Position(vn,pt!.obj))},x->Wrap(gp,2,x));
    end;

    shadline := function( line )
        return List(vn{Adjacency(graph,Position(vn,line!.obj))},x->Wrap(gp,1,x));
    end;
    
    vn := VertexNames(graph);
	dist := function( el1, el2 )
        return Distance(graph,Position(vn,el1!.obj),Position(vn,el2!.obj));
    end;
    
    gp := rec( pointsobj := pts, linesobj := lns, incidence := wrapped_incidence, listelements := listels, 
				shadowofpoint := shadpoint, shadowofline := shadline, distance := dist );

    Objectify( ty, gp );
	SetOrder(gp, [s,t] );
    SetTypesOfElementsOfIncidenceStructure(gp, ["point","line"]);
    SetRankAttr(gp, 2);
    Setter( IncidenceGraphOfGeneralisedPolygonAttr )( gp, graph );
    Setter( HasGraphWithUnderlyingObjectsAsVertices )( gp, true);
    return gp;
end );

#############################################################################
#O  GeneralisedPolygonByElements( <pts>, <lns>, <inc>, <group>, <act> )
# <pts>: set of elements of some incidence structure, representing points of GP.
# <lns>: set of elements of some incidence structure, representing points of GP.
# <inc>: incidence function.
# <group>: group preserving <pts>, <lns> and <inc>
# <act>: action function for group on <pts> and <lns>.
# it is checked throug the graph that the incidence structure is a GP, by using
# the group, this is much more efficient. The user is responsible the <group>
# really preserves <pts> and <lns>
##
InstallMethod( GeneralisedPolygonByElements,
    "for two sets (points and lines), and an incidence function",
    [ IsSet, IsSet, IsFunction, IsGroup, IsFunction ],
    function( pts, lns, inc, group, act )
    local adj, graph, ty, girth, shadpoint, shadline, s, t, gp, vn, 
	dist, listels, wrapped_incidence;

    adj := function(x,y)
    if x in pts and y in pts then
        return false;
    elif x in lns and y in lns then
        return false;
    else
        return inc(x,y);
    fi;
    end;

    graph := Graph(group, Concatenation(pts,lns), act, adj, true );
    girth := Girth(graph);

    if IsBipartite(graph) then
        if not girth = 2*Diameter(graph) then
            Error("<blocks> are not defining a generalised polygon");
        fi;
    else
        Error("elements are not defining a generalised polygon");
    fi;
        
    if girth = 6 then
        ty := NewType( GeometriesFamily, IsProjectivePlane and IsGeneralisedPolygonRep );
    elif girth = 8 then
        ty := NewType( GeometriesFamily, IsGeneralisedQuadrangle and IsGeneralisedPolygonRep );
    elif girth = 12 then
        ty := NewType( GeometriesFamily, IsGeneralisedHexagon and IsGeneralisedPolygonRep );
    elif girth = 16 then
        ty := NewType( GeometriesFamily, IsGeneralisedOctagon and IsGeneralisedPolygonRep );
    else
        Error("<points>, <lines> and <inc> do not define a thick finite generalised polygon");
    fi;

	s := Length(Adjacency(graph,Size(pts)+1))-1; # number of points on a line minus 1.
	t := Length(Adjacency(graph,1))-1; # number of linbes on a point minus 1.
    
    vn := VertexNames(graph);

	# inc takes in fact underlying objects as arguments. So we must make a new function that takes
	# as arguments elements of this geometry and pipes the underlying objects to inc.

	wrapped_incidence := function(x,y)
		return inc(x!.obj,y!.obj);
	end;

    listels := function( geom, i )
		if i = 1 then
			return List(pts,x->Wrap(geom,i,x));
		else
			return List(lns,x->Wrap(geom,i,x));
		fi;
	end;

    shadpoint := function( pt )
        return List(vn{Adjacency(graph,Position(vn,pt!.obj))},x->Wrap(gp,2,x));
    end;

    shadline := function( line )
        return List(vn{Adjacency(graph,Position(vn,line!.obj))},x->Wrap(gp,1,x));
    end;
    
    dist := function( el1, el2 )
        return Distance(graph,Position(vn,el1!.obj),Position(vn,el2!.obj));
    end;
    
    gp := rec( pointsobj := pts, linesobj := lns, incidence := wrapped_incidence, listelements := listels, 
				shadowofpoint := shadpoint, shadowofline := shadline, distance := dist, action := act );

    Objectify( ty, gp );
	SetOrder(gp, [s,t] );
    SetTypesOfElementsOfIncidenceStructure(gp, ["point","line"]);
    SetRankAttr(gp, 2);
    Setter( IncidenceGraphOfGeneralisedPolygonAttr )( gp, graph );        
    Setter( HasGraphWithUnderlyingObjectsAsVertices )( gp, true);
    return gp;
end );

#############################################################################
# View methods for GPs.
#############################################################################

InstallMethod( ViewObj, 
	"for a projective plane in GP rep",
	[ IsProjectivePlane and IsGeneralisedPolygonRep],
	function( p )
        if HasOrder(p) then
            Print("<projective plane order ",Order(p)[1],">");
        else
            Print("<projective plane>");
        fi;
	end );

InstallMethod( ViewObj,
	"for a projective plane in GP rep",
	[ IsGeneralisedQuadrangle and IsGeneralisedPolygonRep],
	function( p )
        if HasOrder(p) then
            Print("<generalised quadrangle of order ",Order(p),">");
        else
            Print("<generalised quadrangle>");
        fi;
	end );

InstallMethod( ViewObj, 
	"for a projective plane in GP rep",
	[ IsGeneralisedHexagon and IsGeneralisedPolygonRep],
	function( p )
        if HasOrder(p) then
            Print("<generalised hexagon of order ",Order(p),">");
        else
            Print("<generalised hexagon>");
        fi;
	end );

InstallMethod( ViewObj, 
	"for a projective plane in GP rep",
	[ IsGeneralisedOctagon and IsGeneralisedPolygonRep],
	function( p )
        if HasOrder(p) then
            Print("<generalised octagon of order ",Order(p),">");
        else
            Print("<generalised octagon>");
        fi;
	end );

#############################################################################
#
# Basic methods for elements (including construction and iterator).
#
#############################################################################

#############################################################################
#O  UnderlyingObject( <x> )
##
InstallMethod( UnderlyingObject, 
	"for an element of a LieGeometry",
	[ IsElementOfGeneralisedPolygon ],
	function( x )
		return x!.obj;
	end );

#############################################################################
#O  ObjectToElement( <geom>, <type>, <obj> )
# returns the subspace of <geom>, with representative <v> and subspace at infinity
# determined by <m> if and only if <obj> is the list [v,m].
##
InstallMethod( ObjectToElement,
	"for ageneralised polygon, an integer and an object",
	[ IsGeneralisedPolygon and IsGeneralisedPolygonRep, IsPosInt, IsObject],
	function(gp, t, obj)
		if t=1 then
			if obj in gp!.pointsobj then
				return Wrap(gp,t,obj);
			else
				Error("<obj> does not represent a point of <gp>");
			fi;
		elif t=2 then
			if obj in gp!.linesobj then
				return Wrap(gp,t,obj);
			else
				Error("<obj> does not represent a line of <gp>");
			fi;
		else
			Error("<gp> is a point-line geometry not containing elements of type ",t);
		fi;
	end );

#############################################################################
#O  ObjectToElement( <geom>, <obj> )
# returns the subspace of <geom>, with representative <v> and subspace at infinity
# determined by <m> if and only if <obj> is the list [v,m].
##
InstallMethod( ObjectToElement,
	"for ageneralised polygon and an object",
	[ IsGeneralisedPolygon and IsGeneralisedPolygonRep, IsObject],
	function(gp, obj)
		if obj in gp!.pointsobj then
			return Wrap(gp,1,obj);
		elif obj in gp!.linesobj then
			return Wrap(gp,2,obj);
		else
			Error("<obj> does not represent an element of <gp>");
		fi;
	end );

#############################################################################
#O  ElementsOfIncidenceStructure( <gp>, <j> )
# returns the elements of <gp> of type <j>
##
InstallMethod( ElementsOfIncidenceStructure, 
	"for a generalised polygon and a positive integer",
	[IsGeneralisedPolygon and IsGeneralisedPolygonRep, IsPosInt],
	function( gp, j )
		local s, t, sz;
		if j in [1,2] then 
			s := Order(gp)[j]; t := Order(gp)[3-j];
		else 
			Error("Incorrect type value");
		fi;
		if IsProjectivePlane(gp) then
			sz := s^2 + s + 1;
		elif IsGeneralisedQuadrangle(gp) then 
			sz := (1+s)*(1+s*t);
		elif IsGeneralisedHexagon(gp) then
			sz := (1+s)*(1+s*t+s^2*t^2);
		elif IsGeneralisedOctagon(gp) then
			sz := (1+s)*(1+s*t+s^2*t^2+s^3*t^3);
		fi;        
		return Objectify( NewType( ElementsCollFamily, IsElementsOfGeneralisedPolygon and
                                IsElementsOfGeneralisedPolygonRep),
        rec( geometry := gp, type := j, size := sz )
						);
	end );

#############################################################################
#O  Points( <gp>  )
# returns the points of <gp>.
##
InstallMethod( Points, 
	"for a generalised polygon",
	[IsGeneralisedPolygon and IsGeneralisedPolygonRep],
	function( gp )
		return ElementsOfIncidenceStructure(gp, 1);
	end);

#############################################################################
#O  Lines( <gp>  )
# returns the lines of <gp>.
##
InstallMethod( Lines, 
	"for a generalised polygon",
	[IsGeneralisedPolygon and IsGeneralisedPolygonRep],
	function( gp )
		return ElementsOfIncidenceStructure(gp, 2);
	end);

#############################################################################
# Display methods: Element collections
#############################################################################

InstallMethod( ViewObj,
	"for elements of a generalised polygon",
	[ IsElementsOfGeneralisedPolygon and IsElementsOfGeneralisedPolygonRep ],
	function( vs )
		local l;
		l := ["points","lines"];
		Print("<", l[vs!.type]," of ");
		ViewObj(vs!.geometry);
		Print(">");
	end );

InstallMethod( PrintObj, 
	"for elements of a generalised polygon",
	[ IsElementsOfGeneralisedPolygon and IsElementsOfGeneralisedPolygonRep ],
	function( vs )
		Print("ElementsOfIncidenceStructure( ",vs!.geometry," , ",vs!.type,")");
	end );

#############################################################################
#O  Size( <gp>  )
# returns the size of a collection of elements of a <gp>
##
InstallMethod(Size, 
	"for elements of a generalised polygon",
	[IsElementsOfGeneralisedPolygon], 
	vs -> vs!.size );

#############################################################################
#O  Iterator( <vs>  )
# returns an iterator for the elements of a gp
##
InstallMethod(Iterator, 
	"for elements of a generalised polygon",
	[IsElementsOfGeneralisedPolygon and IsElementsOfGeneralisedPolygonRep],
	function( vs )
		local gp, j, vars;
		gp := vs!.geometry;
		j := vs!.type;
		if j in [1,2] then
			return IteratorList(gp!.listelements(gp,j)); #looks a bit strange, but correct.
		else 
			Error("Element type does not exist");
		fi;
	end );

#############################################################################
#O  IsIncident( <x>, <y>  )
# simply uses the incidence relation that is built in in the gp.
# caveat: check here that elements belong to the same geometry! 
##
InstallMethod( IsIncident, 
	"for elements of a generalised polygon", 
    [IsElementOfGeneralisedPolygon, IsElementOfGeneralisedPolygon],
	function( x, y )
		local inc;
		if not x!.geo = y!.geo then
			Error("The elements <x> and <y> do not belong to the same geometry");
		else
			inc := x!.geo!.incidence;
			return inc(x, y);
		fi;
	end );

#############################################################################
#O  Span( <x>, <y>  )
# return the line spanned by <x> and <y>, if they span a line at all.
##
InstallMethod( Span,
    "for two elements of a generalised polygon",
    [ IsElementOfGeneralisedPolygon, IsElementOfGeneralisedPolygon ],
    function( x, y )
        local graph, vn, el, i, j, span;
        if not x!.type = 1 and y!.type = 1 then
            Error("<x> and <y> must be points of a generalised polygon");
        elif not x!.geo = y!.geo then
            Error("<x> and <y> must belong to the same generalised polygon");
        fi;
        graph := IncidenceGraphOfGeneralisedPolygon(x!.geo);
        vn := VertexNames(graph);
        if HasGraphWithUnderlyingObjectsAsVertices(x!.geo) then
            i := Position(vn,x!.obj);
            j := Position(vn,y!.obj);
            el := Intersection(DistanceSet(graph,[1],i), DistanceSet(graph,[1],j));
            if not Length(el) = 0 then
                span := vn{el};
                return Wrap(x!.geo,2,span[1]);
            else
                Info(InfoFinInG, 1, "<x> and <y> do not span a line of gp");
                return fail;
            fi;
        else
            i := Position(vn,x);
            j := Position(vn,y);
            el := Intersection(DistanceSet(graph,[1],i), DistanceSet(graph,[1],j));
            if not Length(el) = 0 then
                span := vn{el};
                return span[1];
            else
                Info(InfoFinInG, 1, "<x> and <y> do not span a line of gp");
                return fail;
            fi;
        fi;
    end );

#############################################################################
#O  Meet( <x>, <y>  )
# return the line spanned by <x> and <y>, if they span a line at all.
##
InstallMethod( Meet,
    "for two elements of a generalised polygon",
    [ IsElementOfGeneralisedPolygon, IsElementOfGeneralisedPolygon ],
    function( x, y )
        local graph, vn, el, i, j, meet;
        if not x!.type = 2 and y!.type = 2 then
            Error("<x> and <y> must be lines of a generalised polygon");
        elif not x!.geo = y!.geo then
            Error("<x> and <y> must belong to the same generalised polygon");
        fi;
        graph := IncidenceGraphOfGeneralisedPolygon(x!.geo);
        vn := VertexNames(graph);
        if HasGraphWithUnderlyingObjectsAsVertices(x!.geo) then
            i := Position(vn,x!.obj);
            j := Position(vn,y!.obj);
            el := Intersection(DistanceSet(graph,[1],i), DistanceSet(graph,[1],j));
            if not Length(el) = 0 then
                meet := vn{el};
                return Wrap(x!.geo,2,meet   [1]);
            else
                Info(InfoFinInG, 1, "<x> and <y> do meet in a common point of gp");
                return fail;
            fi;
        else
            i := Position(vn,x);
            j := Position(vn,y);
            el := Intersection(DistanceSet(graph,[1],i), DistanceSet(graph,[1],j));
            if not Length(el) = 0 then
                meet := vn{el};
                return meet[1];
            else
                Info(InfoFinInG, 1, "<x> and <y> do meet in a common point of gp");
                return fail;
            fi;
        fi;
    end );


#############################################################################
#O  Wrap( <geo>, <type>, <o>  )
# returns the element of <geo> represented by <o>.
# this method is generic, but of course not fool proof.
##
InstallMethod( Wrap, 
	"for a generalised polygon and an object",
	[IsGeneralisedPolygon, IsPosInt, IsObject],
	function( geo, type, o )
		local w;
		w := rec( geo := geo, type := type, obj := o );
		Objectify( NewType( ElementsOfIncidenceStructureFamily,   # ElementsFamily,
			IsElementOfIncidenceStructureRep and IsElementOfGeneralisedPolygon ), w );
		return w;
  end );

# CHECKED 11/09/11 jdb
#############################################################################
#A  TypesOfElementsOfIncidenceStructure( <gp> )
# returns the names of the types of the elements of the projective space <ps>
# the is a helper operation.
## 
InstallMethod( TypesOfElementsOfIncidenceStructurePlural,
	"for a generalised polygon in the general representation",
    [ IsGeneralisedPolygon and IsGeneralisedPolygonRep ],
		x -> ["points", "lines"] );

#############################################################################
#O ShadowOfElement(<gp>, <el>, <j> )
##
InstallMethod( ShadowOfElement, 
	"for a generalised polygon, an element, and an integer",
	[IsGeneralisedPolygon and IsGeneralisedPolygonRep, IsElementOfGeneralisedPolygon, IsPosInt],
	function( gp, el, j )
		local shadow, func;
        if j = el!.type then
            func := x->[x];
        elif j = 1 then
            func := gp!.shadowofline;
        elif j = 2 then
            func := gp!.shadowofpoint;
        else
            Error("<gp> has no shadow elements of type", j );
        fi;

        shadow := rec( geometry := gp, type := j, element := el, func := func );
		return Objectify( NewType( ElementsCollFamily, IsElementsOfIncidenceStructure and
							IsShadowElementsOfGeneralisedPolygon and
							IsShadowElementsOfGeneralisedPolygonRep),
							shadow
						);
	end);

#############################################################################
# View methods for shadow objects.
#############################################################################

InstallMethod( ViewObj,
	"for shadow elements of a generalised polygon",
	[ IsShadowElementsOfGeneralisedPolygon and IsShadowElementsOfGeneralisedPolygonRep ],
	function( vs )
		Print("<shadow ",TypesOfElementsOfIncidenceStructurePlural(vs!.geometry)[vs!.type]," in ");
		ViewObj(vs!.geometry);
		Print(">");
	end );
 
InstallMethod( Iterator, 
	"for shadow elements of a generalised polygon",
	[IsShadowElementsOfGeneralisedPolygon and IsShadowElementsOfGeneralisedPolygonRep ],
	function( vs )
        return IteratorList(vs!.func(vs!.element));
	end);
    
#############################################################################
#O  ElementsIncidentWithElementOfIncidenceStructure( <el>, <i> )
# returns the elements of type <i> in <el>, relying on ShadowOfElement 
# for particular <el>.
## 
InstallMethod( ElementsIncidentWithElementOfIncidenceStructure, "for IsElementOfLieGeometry",
	[ IsElementOfGeneralisedPolygon, IsPosInt],
	function( el, i )
		return ShadowOfElement(el!.geo, el, i);
	end );

#############################################################################
#O  Points( <el> )
# returns the points, i.e. elements of type <1> in <el>, relying on ShadowOfElement 
# for particular <el>.
## 
InstallMethod( Points, 
    "for an element of a generalised polygon",
	[ IsElementOfGeneralisedPolygon ],
	function( var )
		return ShadowOfElement(var!.geo, var, 1);
	end );

#############################################################################
#O  Lines( <el> )
# returns the lines, i.e. elements of type <2> in <el>, relying on ShadowOfElement 
# for particular <el>.
## 
InstallMethod( Lines, 
    "for an element of a generalised polygon",
	[ IsElementOfGeneralisedPolygon ],
	function( var )
		return ShadowOfElement(var!.geo, var, 2);
	end );

#############################################################################
#O  DistanceBetweenElements( <gp>, <el1>, <el2> )
# returns the distance in the incidence graph between two elements
## 
InstallMethod( DistanceBetweenElements,
    "for a gp in gpRep and two of its elements",
	[ IsElementOfGeneralisedPolygon, IsElementOfGeneralisedPolygon],
	function( p, q )
		local geo;
        geo := p!.geo;
        if not geo = q!.geo then
            Error("<p> and <q> are not elements of the same generalised polygon");
        fi;
        return geo!.distance(p,q);
	end );

#############################################################################
#O  IncidenceGraphOfGeneralisedPolygon( <gp> )
# We could install a generic method. But currently, our particular GPs (hexagons, 
# elation GQs, and classical GQs) have a particular method for good reasons. All other GPs
# currently possible to construct, have their incidence graph computed upon construction.
# So we may restrict here to checking whether this attribute is bounded, and return it,
# or print an error message. Note that we deal here with a mutable attribute.
###
InstallMethod( IncidenceGraphOfGeneralisedPolygon,
    "for a generalised polygon (in all possible representations",
    [ IsGeneralisedPolygon ],
    function( gp )
    local points, lines, graph, sz, adj, elations, gg, coll;
    if not "grape" in RecNames(GAPInfo.PackagesLoaded) then
       Error("You must load the GRAPE package\n");
    fi;
    if IsBound(gp!.IncidenceGraphOfGeneralisedPolygonAttr) then
       return gp!.IncidenceGraphOfGeneralisedPolygonAttr;
    else
        Error("no method installed currently");
    fi;
    end );

#############################################################################
#O  IncidenceMatrixOfGeneralisedPolygon( <gp> )
#
InstallMethod( IncidenceMatrixOfGeneralisedPolygon,
	"for a generalised polygon",
	[ IsGeneralisedPolygon ],
	function( gp )
		local graph, mat, incmat, szpoints, szlines;
		graph := IncidenceGraphOfGeneralisedPolygon( gp );
		mat := CollapsedAdjacencyMat(Group(()), graph);

    ## The matrix above is the adjacency matrix of the
    ## bipartite incidence graph.
    
		szpoints := Size(Points(gp));
		szlines := Size(Lines(gp));

		incmat := mat{[1..szpoints]}{[szpoints+1..szpoints+szlines]};
		return incmat;
	end );

#############################################################################
#O  CollineationGroup( <gp> )
# This method is generic. Note that:
# - for classical GQs, we have completely different methods to compute their
#	collineation group, of course for good reasons;
# - for classical generalised hexagons, the same remark applies;
# - when a GP is constructed through generic methods, the underlying graph is
#	always computed, since this is the only way to check if the input is not rubbish.
#	But then the VertexNames of the constructed graph are the underlying objects.
#	For particular GQs, the underlying graph is not computed upon construction, since
#	the developpers know what they are doing (?). But computing a graph afterwards, is
#	very naturally done with the elements themselves as VertexNames. This has some technical
#	consequences to compute the collineation group and to define the CollineationAction of it.
#	To distinguish in this method, we introduced the property HasGraphWithUnderlyingObjectsAsVertices.
###
InstallMethod( CollineationGroup, 
    "for a generalised polygon",
    [ IsGeneralisedPolygon and IsGeneralisedPolygonRep ],
    function( gp )
        local graph, aut, act, stab, coll, ptsn, points, pointsobj;
        graph := IncidenceGraphOfGeneralisedPolygon( gp );
        aut := AutomorphismGroup( graph );
        points := AsList(Points(gp));
        if HasGraphWithUnderlyingObjectsAsVertices(gp) then
            pointsobj := List(points,x->x!.obj);
            ptsn := Set(pointsobj,x->Position(VertexNames(graph),x));
        else
            ptsn := Set(points,x->Position(VertexNames(graph),x));
        fi;
        stab := Stabilizer(aut, ptsn, OnSets);
        coll := Action(stab, ptsn, OnPoints);
        if HasGraphWithUnderlyingObjectsAsVertices(gp) then
            act := function(el,g)
                local src,img;
                if el!.type = 1 then
                    src := Position(VertexNames(graph),el!.obj);
                    img := src^g;
                    return Wrap(gp,1,VertexNames(graph)[img]);
                elif el!.type = 2 then
                    src := Position(VertexNames(graph),el!.obj);
                    img := src^g;
                    return Wrap(gp,2,VertexNames(graph)[img]);
                fi;
            end;
        else
            act := function(el,g)
                local src,img;
                if el!.type = 1 then
                    src := Position(VertexNames(graph),el); #change wrt generic function which would be el!.obj
                    img := src^g;
                    return VertexNames(graph)[img];
                elif el!.type = 2 then
                    src := Position(VertexNames(graph),el); #change wrt generic funciton ...
                    img := src^g;
                    return VertexNames(graph)[img];
                fi;
            end;
        fi;
        SetCollineationAction( coll, act );
		return coll;
    end );

InstallMethod( BlockDesignOfGeneralisedPolygon,
             [ IsProjectivePlane and IsGeneralisedPolygonRep ], 
  function( gp )
    local points, lines, des;
    if not "design" in RecNames(GAPInfo.PackagesLoaded) then
       Error("You must load the DESIGN package\n");
    fi;
    if IsBound(gp!.BlockDesignOfGeneralisedPolygonAttr) then
       return gp!.BlockDesignOfGeneralisedPolygonAttr;
    fi;
    points := gp!.points;
    lines := gp!.lines;
    Info(InfoFinInG, 1, "Computing block design of generalised polygon...");
    des := BlockDesign(Size(points), Set(lines, AsSet));
    Setter( BlockDesignOfGeneralisedPolygonAttr )( gp, des );
    return des;
  end );

InstallMethod( BlockDesignOfGeneralisedPolygon,
             [ IsGeneralisedPolygon and IsGeneralisedPolygonRep ], 
  function( gp )
    local points, lines, des, blocks, l, b, elations, gg, orbs;
    if not "design" in RecNames(GAPInfo.PackagesLoaded) then
       Error("You must load the DESIGN package\n");
    fi;
    if IsBound(gp!.BlockDesignOfGeneralisedPolygonAttr) then
       return gp!.BlockDesignOfGeneralisedPolygonAttr;
    fi;
    points := AsList(Points(gp));;
    lines := AsList(Lines(gp));;    


    if IsElationGQ(gp) and HasElationGroup( gp ) then
	   elations := ElationGroup(gp);
          Info(InfoFinInG, 1, "Computing orbits on lines of gen. polygon...");
	   orbs := List( Orbits(elations, lines, CollineationAction(elations)), Representative);
	   orbs := List(orbs, l -> Filtered([1..Size(points)], i -> points[i] * l));
	   gg := Action(elations, points, CollineationAction( elations ) );
          Info(InfoFinInG, 1, "Computing block design of generalised polygon...");    
	   des := BlockDesign(Size(points), orbs, gg ); 
	elif HasCollineationGroup(gp) then
	   gg := CollineationGroup(gp);
	   orbs := List( Orbits(gg, lines, CollineationAction(gg)), Representative);
	   orbs := List(orbs, l -> Filtered([1..Size(points)], i -> points[i] * l));
	   gg := Action(gg, points, CollineationAction( elations ) );
	   des := BlockDesign(Size(points), orbs, gg );
	else
  	   blocks := [];
       for l in lines do
          b := Filtered([1..Size(points)], i -> points[i] * l);
          Add(blocks, b);
       od;   
       des := BlockDesign(Size(points), Set(blocks));
	fi;

    Setter( BlockDesignOfGeneralisedPolygonAttr )( gp, des );
    return des;
  end );

#############################################################################
#
# Part II: particular models of GPs.
#
#############################################################################

#############################################################################
#
# Desarguesian projective planes: only need a method for 
# IncidenceGraphOfGeneralisedPolygon
#
#############################################################################

#############################################################################
#O  IncidenceGraphOfGeneralisedPolygon( <gp> )
###
InstallMethod( IncidenceGraphOfGeneralisedPolygon,
    "for a generalised polygon (in all possible representations",
    [ IsDesarguesianPlane ],
    function( gp )
        local points, lines, graph, adj, group, coll, sz;
        if not "grape" in RecNames(GAPInfo.PackagesLoaded) then
            Error("You must load the GRAPE package\n");
        fi;
        if IsBound(gp!.IncidenceGraphOfGeneralisedPolygonAttr) then
            return gp!.IncidenceGraphOfGeneralisedPolygonAttr;
        fi;
        if not HasCollineationGroup(gp) then
            Error("No collineation group computed. Please compute collineation group before computing incidence graph\,n");
        else
            points := AsList(Points(gp));
            lines := AsList(Lines(gp));
            Setter( HasGraphWithUnderlyingObjectsAsVertices )( gp, false );

            Info(InfoFinInG, 1, "Computing incidence graph of generalised polygon...");
    
            adj := function(x,y)
                if x!.type <> y!.type then
                    return IsIncident(x,y);
                else
                    return false;
                fi;
            end;
            group := CollineationGroup(gp);
            graph := Graph(group,Concatenation(points,lines),OnProjSubspaces,adj,true);
            Setter( IncidenceGraphOfGeneralisedPolygonAttr )( gp, graph );
            return graph;
        fi;
  end );

#############################################################################
#
# Classical GQs: only need a method for IncidenceGraphOfGeneralisedPolygon
#
#############################################################################

#############################################################################
#O  IncidenceGraphOfGeneralisedPolygon( <gp> )
###
InstallMethod( IncidenceGraphOfGeneralisedPolygon,
    "for a generalised polygon (in all possible representations",
    [ IsClassicalGQ ],
    function( gp )
        local points, lines, graph, adj, group, coll, sz;
        if not "grape" in RecNames(GAPInfo.PackagesLoaded) then
            Error("You must load the GRAPE package\n");
        fi;
        if IsBound(gp!.IncidenceGraphOfGeneralisedPolygonAttr) then
            return gp!.IncidenceGraphOfGeneralisedPolygonAttr;
        fi;
        if not HasCollineationGroup(gp) then
            Error("No collineation group computed. Please compute collineation group before computing incidence graph\,n");
        else
            points := AsList(Points(gp));
            lines := AsList(Lines(gp));
            Setter( HasGraphWithUnderlyingObjectsAsVertices )( gp, false );

            Info(InfoFinInG, 1, "Computing incidence graph of generalised polygon...");
    
            adj := function(x,y)
                if x!.type <> y!.type then
                    return IsIncident(x,y);
                else
                    return false;
                fi;
            end;
            group := CollineationGroup(gp);
            graph := Graph(group,Concatenation(points,lines),OnProjSubspaces,adj,true);
            Setter( IncidenceGraphOfGeneralisedPolygonAttr )( gp, graph );
            return graph;
        fi;
  end );

#############################################################################
#
#  Classical Generalised Hexagons
#  This section implements H(q) and T(q,q^3). In FinInG, these geometries 
#  are nicely constructed inside polar spaces, but are also constructed
#  formally as generalised polygons, which make typical operations available
#  Both are also Lie geometries, and are hard wired embedded inside the corresponding
#  polar space. See chapter 4 of the documentation.
#
#  For both models we (have to) install methods for Wrap etc. This makes other 
#  operations, like OnProjSubspaces (action function) generic. As such, we can fully
#  exploit the fact that these geometries are also Lie geometries.
#
#############################################################################

#############################################################################
#O  Wrap( <geo>, <type>, <o>  )
# returns the element of <geo> represented by <o>
##
InstallMethod( Wrap, 
	"for a generalised polygon and an object",
	[IsClassicalGeneralisedHexagon, IsPosInt, IsObject],
	function( geo, type, o )
		local w;
		w := rec( geo := geo, type := type, obj := o );
		Objectify( NewType( SoPSFamily, IsElementOfIncidenceStructureRep and IsElementOfGeneralisedPolygon 
			and IsSubspaceOfClassicalPolarSpace ), w );
		return w;
  end );

#############################################################################
# The fixed, hard-coded triality :-)
#############################################################################

#############################################################################
#F  SplitCayleyPointToPlane5( <el> )
# returns a list of vectors spanning the plane of W(5,q): ---, which is the
# image of the point represented by <w> under the fixed triality
###
InstallGlobalFunction( SplitCayleyPointToPlane5,
    function(w, f)
        local z, hyps, q, y, spacevec, hyp, vec, int, n;
        q := Size(f);
        #w := Unpack(elvec);
		y := w{[1..3]};
        y{[5..7]} := w{[4..6]};
        y[4] := (y[1]*y[5]+y[2]*y[6]+y[3]*y[7])^(q/2);
        y[8] := -y[4];
        z := [];
		n := Zero(f);
        z[1] := [n,y[3],-y[2],y[5],y[8],n,n,n];
        z[2] := [-y[3],n,y[1],y[6],n,y[8],n,n];
        z[3] := [y[2],-y[1],n,y[7],n,n,y[8],n];
        z[4] := [n,n,n,-y[4],y[1],y[2],y[3],n];
        z[5] := [y[4],n,n,n,n,y[7],-y[6],y[1]];
        z[6] := [n,y[4],n,n,-y[7],n,y[5],y[2]];
        z[7] := [n,n,y[4],n,y[6],-y[5],n,y[3]];
        z[8] := [y[5],y[6],y[7],n,n,n,n,-y[8]];
        z := Filtered(z,x->not IsZero(x));
        hyp := [0,0,0,1,0,0,0,1]*Z(q)^0;
        Add(z,[0,0,0,1,0,0,0,1]*Z(q)^0);
        spacevec := NullspaceMat(TransposedMat(z));
		int := IdentityMat(8,f){[1..7]};
		int[4][8] := -One(f); #could have been One(f) too or course since this is only used in even char...
		vec := SumIntersectionMat(spacevec, int)[2];
        return vec{[1..3]}{[1,2,3,5,6,7]};
    end );

#############################################################################
#F  SplitCayleyPointToPlane( <elvec>, <f> )
# returns a list of vectors spanning the plane of Q(6,q): ---, which is the
# image of the point represented by <elvec> under the fixed triality
##
InstallGlobalFunction( SplitCayleyPointToPlane,
	function(elvec, f)
		local z, hyps, y, spacevec, hyp, vec, int, n;
		y := ShallowCopy(elvec);
		y[8] := -y[4];
		z := [];
		n := Zero(f);
		z[1] := [n,y[3],-y[2],y[5],y[8],n,n,n];
		z[2] := [-y[3],n,y[1],y[6],n,y[8],n,n];
		z[3] := [y[2],-y[1],n,y[7],n,n,y[8],n];
		z[4] := [n,n,n,-y[4],y[1],y[2],y[3],n];
		z[5] := [y[4],n,n,n,n,y[7],-y[6],y[1]];
		z[6] := [n,y[4],n,n,-y[7],n,y[5],y[2]];
		z[7] := [n,n,y[4],n,y[6],-y[5],n,y[3]];
		z[8] := [y[5],y[6],y[7],n,n,n,n,-y[8]];
		z := Filtered(z,x->not IsZero(x));
		hyp := [0,0,0,1,0,0,0,1]*One(f);
		Add(z,[0,0,0,1,0,0,0,1]*One(f));
		spacevec := NullspaceMat(TransposedMat(z));
		int := IdentityMat(8,f){[1..7]};
		int[4][8] := -One(f);
		vec := SumIntersectionMat(spacevec, int)[2];
		return vec{[1..3]}{[1..7]};
	end );

#############################################################################
#F  ZeroPointToOnePointsSpaceByTriality( <elvec>, <frob>, <f> )
# returns a list of vectors spanning the solid of Q+(7,q): ---, which is the
# image of the point represented by <elvec> under the fixed triality
##
InstallGlobalFunction( ZeroPointToOnePointsSpaceByTriality,
	function(elvec,frob,f)
	# elvec represents a point of T(q,q^3)
		local z, hyps, y, spacevec, n;
		n := Zero(f);
		y := elvec^frob;
		z := [];
		z[1] := [n,y[3],-y[2],y[5],y[8],n,n,n];
		z[2] := [-y[3],n,y[1],y[6],n,y[8],n,n];
		z[3] := [y[2],-y[1],n,y[7],n,n,y[8],n];
		z[4] := [n,n,n,-y[4],y[1],y[2],y[3],n];
		z[5] := [y[4],n,n,n,n,y[7],-y[6],y[1]];
		z[6] := [n,y[4],n,n,-y[7],n,y[5],y[2]];
		z[7] := [n,n,y[4],n,y[6],-y[5],n,y[3]];
		z[8] := [y[5],y[6],y[7],n,n,n,n,-y[8]];
		z := Filtered(z,x->not IsZero(x));
		spacevec := NullspaceMat(TransposedMat(z));
		return spacevec;
	end );

#############################################################################
#F  TwistedTrialityHexagonPointToPlaneByTwoTimesTriality( <elvec>, <frob>, <f> )
# elvec represents a point of T(q^3,q). elvec^frob is a one point, elvec^frob^2
# is a two point. This function computes a basis for the intersection of the
# one and two point (which are actually generators of Q+(7,q)). There intersection
# will be a plane containing the q+1 lines through elvec.
##
InstallGlobalFunction( TwistedTrialityHexagonPointToPlaneByTwoTimesTriality,
	function(elvec,frob,f)
		local z, hyps, y, pg, spacevec1, spacevec2, n;
		n := Zero(f);
		#y := Unpack(elvec)^frob;
		y := elvec^frob;
		z := [];
		z[1] := [n,y[3],-y[2],y[5],y[8],n,n,n];
		z[2] := [-y[3],n,y[1],y[6],n,y[8],n,n];
		z[3] := [y[2],-y[1],n,y[7],n,n,y[8],n];
		z[4] := [n,n,n,-y[4],y[1],y[2],y[3],n];
		z[5] := [y[4],n,n,n,n,y[7],-y[6],y[1]];
		z[6] := [n,y[4],n,n,-y[7],n,y[5],y[2]];
		z[7] := [n,n,y[4],n,y[6],-y[5],n,y[3]];
		z[8] := [y[5],y[6],y[7],n,n,n,n,-y[8]];
		z := Filtered(z,x->not IsZero(x));
		spacevec1 := NullspaceMat(TransposedMat(z));
		z := y^frob;
		y := [];
		y[1] := [n,-z[3],z[2],n,z[4],n,n,z[5]];
		y[2] := [z[3],n,-z[1],n,n,z[4],n,z[6]];
		y[3] := [-z[2],z[1],n,n,n,n,z[4],z[7]];
		y[4] := [z[5],z[6],z[7],-z[4],n,n,n,n];
		y[5] := [z[8],n,n,z[1],n,-z[7],z[6],n];
		y[6] := [n,z[8],n,z[2],z[7],n,-z[5],n];
		y[7] := [n,n,z[8],z[3],-z[6],z[5],n,n];
		y[8] := [n,n,n,n,z[1],z[2],z[3],-z[8]];
		y := Filtered(y,x->not IsZero(x));
		spacevec2 := NullspaceMat(TransposedMat(y));
		return SumIntersectionMat(spacevec1, spacevec2)[2];
	end );

#############################################################################
# Constructor operations for the Classical Generalised Hexagons.
#############################################################################

# JB: A big change here. I've separated the CollineationGroup out to an
# attribute, just like we do for polar spaces and the like. 19/06/2012

# 24/3/2014. cmat changes.
#############################################################################
#O  SplitCayleyHexagon( <f> )
# returns the split cayley hexagon over <f>
##
InstallMethod( SplitCayleyHexagon, 
	"for a finite field", 
	[ IsField and IsFinite ],
	function( f )
    local geo, ty, repline, reppointvect, reppoint, replinevect, dist,
	    hvm, ps, hvmform, form, nonzerof, x, w, listels, shadpoint, shadline;
    if IsOddInt(Size(f)) then    
       ## the corresponding sesquilinear form here for 
       ## q odd is the matrix 
       ## [[0,0,0,0,1,0,0],[0,0,0,0,0,1,0],
       ## [0,0,0,0,0,0,1],[0,0,0,-2,0,0,0],
       ## [1,0,0,0,0,0,0],[0,1,0,0,0,0,0],[0,0,1,0,0,0,0]];

	   ## this is Hendrik's form
		hvm := List([1..7], i -> [0,0,0,0,0,0,0]*One(f));
		hvm{[1..3]}{[5..7]} := IdentityMat(3, f);
		hvm{[5..7]}{[1..3]} := IdentityMat(3, f);
		hvm[4][4] := -2*One(f);
		hvmform := BilinearFormByMatrix(hvm, f);
		ps := PolarSpace(hvmform);
		# UnderlyingObject will return a cvec. 
		reppointvect := UnderlyingObject(RepresentativesOfElements(ps)[1]);

       ## Hendrik's canonical line is <(1,0,0,0,0,0,0), (0,0,0,0,0,0,1)>
		replinevect := [[1,0,0,0,0,0,0], [0,0,0,0,0,0,1]] * One(f);
		TriangulizeMat(replinevect);
		#ConvertToMatrixRep(replinevect, f); #is useless now.
        shadpoint := function( pt )
            local planevec, flag, plane, f;
            f := BaseField( pt );
            planevec := SplitCayleyPointToPlane( Unpack(pt!.obj), f );
            plane := VectorSpaceToElement(PG(6,f),planevec);
            flag := FlagOfIncidenceStructure(PG(6,f),[pt,plane]);
            return List(ShadowOfFlag(PG(6,f),flag,2),x->Wrap(pt!.geo,2,Unwrap(x)));
        end;
        
        dist := function(el1,el2)
            local x,y;
            if el1=el2 then
                return 0;
            elif el1!.type = 1 and el2!.type = 1 then
                y := VectorSpaceToElement(PG(6,f), SplitCayleyPointToPlane(Unpack(el2!.obj),f)); #PG(5,f): avoids some unnecessary checks
                if el1 in y then
                    return 2;
                else
                    x := VectorSpaceToElement(PG(6,f), SplitCayleyPointToPlane(Unpack(el1!.obj),f));
                    if ProjectiveDimension(Meet(x,y)) = 0 then
                        return 4;
                    else
                        return 6;
                    fi;
                fi;
            elif el1!.type = 2 and el2!.type = 2 then
                if ProjectiveDimension(Meet(el1,el2)) = 0 then
                    return 2;
                fi;
                x := TangentSpace(ps,el1);
                if ProjectiveDimension(Meet(x,el2)) = 0 then
                    return 4;
                else
                    return 6;
                fi;
            elif el1!.type = 1 and el2!.type = 2 then
                if el1 in el2 then
                    return 1;
                fi;
                x := VectorSpaceToElement(PG(6,f), SplitCayleyPointToPlane(Unpack(el1!.obj),f));
                if ProjectiveDimension(Meet(x,el2)) = 0 then
                    return 3;
                else
                    return 5;
                fi;
            else
                return dist(el2,el1);
            fi;
        end;

    else
       ## Here we embed the hexagon in W(5,q)
       ## Hendrik's form
		hvm := List([1..6], i -> [0,0,0,0,0,0]*One(f));
		hvm{[1..3]}{[4..6]} := IdentityMat(3, f);
		hvm{[4..6]}{[1..3]} := IdentityMat(3, f);       
		hvmform := BilinearFormByMatrix(hvm, f);   
		ps := PolarSpace(hvmform);
		# UnderlyingObject will return a cvec. 
		reppointvect := UnderlyingObject(RepresentativesOfElements(ps)[1]); #to be changed

		## Hendrik's canonical line is <(1,0,0,0,0,0), (0,0,0,0,0,1)>
		replinevect := [[1,0,0,0,0,0], [0,0,0,0,0,1]] * One(f);
		TriangulizeMat(replinevect);
		#ConvertToMatrixRep(replinevect, f); #is useless now.
        shadpoint := function( pt )
            local planevec, flag, plane, f;
            f := BaseField( pt );
            planevec := SplitCayleyPointToPlane5( Unpack(pt!.obj), f );
            plane := VectorSpaceToElement(PG(5,f),planevec);
            flag := FlagOfIncidenceStructure(PG(5,f),[pt,plane]);
            return List(ShadowOfFlag(PG(5,f),flag,2),x->Wrap(pt!.geo,2,Unwrap(x)));
        end;
        
        dist := function(el1,el2)
            local x,y;
            if el1=el2 then
                return 0;
            elif el1!.type = 1 and el2!.type = 1 then
                y := VectorSpaceToElement(PG(5,f), SplitCayleyPointToPlane5(Unpack(el2!.obj),f)); #PG(5,f): avoids some unnecessary checks
                if el1 in y then
                    return 2;
                else
                    x := VectorSpaceToElement(PG(5,f), SplitCayleyPointToPlane5(Unpack(el1!.obj),f));
                    if ProjectiveDimension(Meet(x,y)) = 0 then
                        return 4;
                    else
                        return 6;
                    fi;
                fi;
            elif el1!.type = 2 and el2!.type = 2 then
                if ProjectiveDimension(Meet(el1,el2)) = 0 then
                    return 2;
                fi;
                x := TangentSpace(ps,el1);
                if ProjectiveDimension(Meet(x,el2)) = 0 then
                    return 4;
                else
                    return 6;
                fi;
            elif el1!.type = 1 and el2!.type = 2 then
                if el1 in el2 then
                    return 1;
                fi;
                x := VectorSpaceToElement(PG(5,f), SplitCayleyPointToPlane5(Unpack(el1!.obj),f));
                if ProjectiveDimension(Meet(x,el2)) = 0 then
                    return 3;
                else
                    return 5;
                fi;
            else
                return dist(el2,el1);
            fi;
        end;

    fi;
	#now comes the cmatrixification of the replinevect
	replinevect := NewMatrix(IsCMatRep,f,Length(reppointvect),replinevect);
	
	listels := function(gp,j)
		local coll,reps;
		coll := CollineationGroup(gp);
		reps := RepresentativesOfElements( gp );
		return Enumerate(Orb(coll, reps[j], OnProjSubspaces));
	end;
	
	shadline := function( l )
		return List(Points(ElementToElement(AmbientSpace(l),l)),x->Wrap(l!.geo,1,x!.obj));
	end;

	#in the next line, we set the data fields for the geometry. We have to take into account that H(q) will also be
	#a Lie geometry, so it needs more data fields than a GP. But we can derive this information from ps.
	geo := rec( pointsobj := [], linesobj := [], incidence:= \*, listelements := listels, basefield := BaseField(ps), 
		dimension := Dimension(ps), vectorspace := UnderlyingVectorSpace(ps), polarspace := ps, 
		shadowofpoint := shadpoint, shadowofline := shadline, distance := dist);
    ty := NewType( GeometriesFamily, IsClassicalGeneralisedHexagon and IsGeneralisedPolygonRep ); #change by jdb 7/12/11
    Objectify( ty, geo );
    SetAmbientSpace(geo, AmbientSpace(ps));
    SetAmbientPolarSpace(geo,ps);
    SetOrder(geo, [Size(f), Size(f)]);
    SetTypesOfElementsOfIncidenceStructure(geo, ["point","line"]);
    SetRankAttr(geo, 2);

    #now we are ready to pack the representatives of the elements, which are also elements of a polar space.
    #recall that reppointvect and replinevect are triangulized.
	#we can not count here on VectorSpaceToElement (yet). Otherwise I could have left out the "replinevect := NewMatrix(Is..." part above.
    w := rec(geo := geo, type := 1, obj := reppointvect);
    reppoint := Objectify( NewType( SoPSFamily,  IsElementOfGeneralisedPolygon and IsElementOfIncidenceStructureRep
					            	and IsSubspaceOfClassicalPolarSpace ), w );
    w := rec(geo := geo, type := 2, obj := replinevect);
    repline := Objectify( NewType( SoPSFamily, IsElementOfGeneralisedPolygon and IsElementOfIncidenceStructureRep 
					            	and IsSubspaceOfClassicalPolarSpace ), w );
    SetRepresentativesOfElements(geo, [reppoint, repline]);
    #SetName(geo,Concatenation("Split Cayley Hexagon of order ", String(Size(f))));
	SetName(geo,Concatenation("H(",String(Size(f)),")"));
	return geo;
  end );

#############################################################################
#O  SplitCayleyHexagon( <q> )
# shortcut to previous method.
##
InstallMethod( SplitCayleyHexagon, 
	"input is a prime power", 
	[ IsPosInt ],
	function( q )
		return SplitCayleyHexagon(GF(q));
	end );

# 24/3/2014. cmat changes.
#############################################################################
#O  SplitCayleyHexagon( <ps> )
# returns the split cayley hexagon over <f>
##
InstallMethod( SplitCayleyHexagon, 
	"for a classical polar space", 
	[ IsClassicalPolarSpace ],
	function( ps )
    local geo, ty, repline, reppointvect, reppoint, replinevect, f, naampje, eq, dist,
	    hvm, hvmform, form, nonzerof, x, w, listels, shadpoint, shadline, change, c1, c2;
		f := BaseField(ps);
	if IsParabolicQuadric(ps) and Dimension(ps) = 6 then
		hvm := List([1..7], i -> [0,0,0,0,0,0,0]*One(f));
		hvm{[1..3]}{[5..7]} := IdentityMat(3, f);
		hvm[4][4] := -One(f); #took me hours to remove the 2 here (necessary when you switch from bilinear form to quad forms... Wenn darf man Scheisse sagen...?
		hvmform := QuadraticFormByMatrix(hvm, f);
		hvm := PolarSpace(hvmform);
		c1 := BaseChangeToCanonical(hvmform);
		if not IsCanonicalPolarSpace(ps) then
			c2 := BaseChangeToCanonical(QuadraticForm(ps));
			change := c1^-1*c2;
		else 
			change := c1^-1;
		fi;
		# UnderlyingObject will return a cvec. We must be a bit carefull: reppointvect must be normed.
		reppointvect := UnderlyingObject(RepresentativesOfElements(hvm)[1]) * change; #to be changed
		reppointvect := reppointvect / First(reppointvect,x->not IsZero(x));
		replinevect := ([[1,0,0,0,0,0,0], [0,0,0,0,0,0,1]] * One(f)) * change;
		TriangulizeMat(replinevect);

        shadpoint := function( pt )
            local planevec, flag, plane, f;
            f := BaseField( pt );
            planevec := SplitCayleyPointToPlane( Unpack(pt!.obj) * change^-1, f ) * change;
            plane := VectorSpaceToElement(PG(6,f),planevec);
            flag := FlagOfIncidenceStructure(PG(6,f),[pt,plane]);
            return List(ShadowOfFlag(PG(6,f),flag,2),x->Wrap(pt!.geo,2,Unwrap(x)));
        end;
        dist := function(el1,el2)
            local x,y;
            if el1=el2 then
                return 0;
            elif el1!.type = 1 and el2!.type = 1 then
                y := VectorSpaceToElement(PG(6,f), SplitCayleyPointToPlane(Unpack(el2!.obj) * change^-1,f) * change); #PG(6,f): avoids some unnecessary checks
                if el1 in y then
                    return 2;
                else
                    x := VectorSpaceToElement(PG(6,f), SplitCayleyPointToPlane(Unpack(el1!.obj) * change^-1,f) * change);
                    if ProjectiveDimension(Meet(x,y)) = 0 then
                        return 4;
                    else
                        return 6;
                    fi;
                fi;
            elif el1!.type = 2 and el2!.type = 2 then
                if ProjectiveDimension(Meet(el1,el2)) = 0 then
                    return 2;
                fi;
                x := TangentSpace(ps,el1);
                if ProjectiveDimension(Meet(x,el2)) = 0 then
                    return 4;
                else
                    return 6;
                fi;
            elif el1!.type = 1 and el2!.type = 2 then
                if el1 in el2 then
                    return 1;
                fi;
                x := VectorSpaceToElement(PG(6,f), SplitCayleyPointToPlane(Unpack(el1!.obj) * change^-1,f) * change);
                if ProjectiveDimension(Meet(x,el2)) = 0 then
                    return 3;
                else
                    return 5;
                fi;
            else
                return dist(el2,el1);
            fi;
        end;
    elif IsSymplecticSpace(ps) and Dimension(ps) = 5 then
       ## Here we embed the hexagon in W(5,q)
       ## Hendrik's form
		hvm := List([1..6], i -> [0,0,0,0,0,0]*One(f));
		hvm{[1..3]}{[4..6]} := IdentityMat(3, f);
		hvm{[4..6]}{[1..3]} := IdentityMat(3, f);       
		hvmform := BilinearFormByMatrix(hvm, f);   
		hvm := PolarSpace(hvmform);
		c1 := BaseChangeToCanonical(hvmform);
		if not IsCanonicalPolarSpace(ps) then
			c2 := BaseChangeToCanonical(SesquilinearForm(ps));
			change := c1^-1*c2;
		else 
			change := c1^-1;
		fi;
		# UnderlyingObject will return a cvec. We must be a bit carefull: reppointvect must be normed.
		reppointvect := UnderlyingObject(RepresentativesOfElements(hvm)[1]) * change; #to be changed
		reppointvect := reppointvect / First(reppointvect,x->not IsZero(x));
		
		## Hendrik's canonical line is <(1,0,0,0,0,0), (0,0,0,0,0,1)>
		replinevect := ([[1,0,0,0,0,0], [0,0,0,0,0,1]] * One(f)) * change;
		TriangulizeMat(replinevect);
		#ConvertToMatrixRep(replinevect, f); #is useless now.
        shadpoint := function( pt )
            local planevec, flag, plane, f;
            f := BaseField( pt );
            planevec := SplitCayleyPointToPlane5( Unpack(pt!.obj) * change^-1, f ) * change;
            plane := VectorSpaceToElement(PG(5,f),planevec);
            flag := FlagOfIncidenceStructure(PG(5,f),[pt,plane]);
            return List(ShadowOfFlag(PG(5,f),flag,2),x->Wrap(pt!.geo,2,Unwrap(x)));
        end;
        dist := function(el1,el2)
            local x,y;
            if el1=el2 then
                return 0;
            elif el1!.type = 1 and el2!.type = 1 then
                y := VectorSpaceToElement(PG(5,f), SplitCayleyPointToPlane5(Unpack(el2!.obj) * change^-1,f) * change); #PG(5,f): avoids some unnecessary checks
                if el1 in y then
                    return 2;
                else
                    x := VectorSpaceToElement(PG(5,f), SplitCayleyPointToPlane5(Unpack(el1!.obj) * change^-1,f) * change);
                    if ProjectiveDimension(Meet(x,y)) = 0 then
                        return 4;
                    else
                        return 6;
                    fi;
                fi;
            elif el1!.type = 2 and el2!.type = 2 then
                if ProjectiveDimension(Meet(el1,el2)) = 0 then
                    return 2;
                fi;
                x := TangentSpace(ps,el1);
                if ProjectiveDimension(Meet(x,el2)) = 0 then
                    return 4;
                else
                    return 6;
                fi;
            elif el1!.type = 1 and el2!.type = 2 then
                if el1 in el2 then
                    return 1;
                fi;
                x := VectorSpaceToElement(PG(5,f), SplitCayleyPointToPlane5(Unpack(el1!.obj) * change^-1,f) * change);
                if ProjectiveDimension(Meet(x,el2)) = 0 then
                    return 3;
                else
                    return 5;
                fi;
            else
                return dist(el2,el1);
            fi;
        end;
    else
        Error("No embedding of split Cayley hexagon possible in <ps>");
    fi;
	#now comes the cmatrixification of the reppointvect and replinevect
	reppointvect :=  NewMatrix(IsCMatRep,f,Length(reppointvect),[reppointvect])[1];
	replinevect := NewMatrix(IsCMatRep,f,Length(reppointvect),replinevect);
	
	listels := function(gp,j)
		local coll,reps;
		coll := CollineationGroup(gp);
		reps := RepresentativesOfElements( gp );
		return Enumerate(Orb(coll, reps[j], OnProjSubspaces));
	end;
	
	shadline := function( l )
		return List(Points(ElementToElement(AmbientSpace(l),l)),x->Wrap(l!.geo,1,x!.obj));
	end;

	#in the next line, we set the data fields for the geometry. We have to take into account that H(q) will also be
	#a Lie geometry, so it needs more data fields than a GP. But we can derive this information from ps.
	geo := rec( pointsobj := [], linesobj := [], incidence:= \*, listelements := listels, basefield := BaseField(ps), 
		dimension := Dimension(ps), vectorspace := UnderlyingVectorSpace(ps), polarspace := ps, 
		shadowofpoint := shadpoint, shadowofline := shadline, distance := dist, basechange := change);
    ty := NewType( GeometriesFamily, IsClassicalGeneralisedHexagon and IsGeneralisedPolygonRep ); #change by jdb 7/12/11
    Objectify( ty, geo );
    SetAmbientSpace(geo, AmbientSpace(ps));
    SetAmbientPolarSpace(geo,ps);
    SetOrder(geo, [Size(f), Size(f)]);
    SetTypesOfElementsOfIncidenceStructure(geo, ["point","line"]);
    SetRankAttr(geo, 2);

    #now we are ready to pack the representatives of the elements, which are also elements of a polar space.
    #recall that reppointvect and replinevect are triangulized.
	#we can not count here on VectorSpaceToElement (yet). Otherwise I could have left out the "replinevect := NewMatrix(Is..." part above.
    w := rec(geo := geo, type := 1, obj := reppointvect);
    reppoint := Objectify( NewType( SoPSFamily,  IsElementOfGeneralisedPolygon and IsElementOfIncidenceStructureRep
					            	and IsSubspaceOfClassicalPolarSpace ), w );
    w := rec(geo := geo, type := 2, obj := replinevect);
    repline := Objectify( NewType( SoPSFamily, IsElementOfGeneralisedPolygon and IsElementOfIncidenceStructureRep 
					            	and IsSubspaceOfClassicalPolarSpace ), w );
    SetRepresentativesOfElements(geo, [reppoint, repline]);
    #it looks a bit exagerated to do such an effort for the name, but polar spaces do have a Name attribute set...
	if not IsCanonicalPolarSpace(ps) then
		eq := Concatenation(": ",String(EquationForPolarSpace(ps)));
	else
		eq := "";
	fi;
	if ps!.dimension = 5 then
		naampje := Concatenation("W(5, ",String(Size(f)),")",eq);
	else
		naampje := Concatenation("Q(6, ",String(Size(f)),")",eq);
	fi;
	SetName(geo,Concatenation("H(",String(Size(f)),")"," in ",naampje));
	return geo;
  end );

# 24/3/2014. cmat changes. Same principle as SplitCayleyHexagon
#############################################################################
#O  TwistedTrialityHexagon( <f> )
# returns the twisted triality hexagon over <f>
##
InstallMethod( TwistedTrialityHexagon, 
	"input is a finite field", 
    [ IsField and IsFinite ],
	function( f )
    local geo, ty, points, lines, repline, hvm, ps, orblen, hvmc, c, listels, dist,
          hvmform, form, q, pps, reppoint, reppointvect, replinevect, w, shadline, 
          shadpoint, frob;
       ## Field must be GF(q^3);
	frob := FrobeniusAutomorphism(f);
    q := RootInt(Size(f), 3);
	if not q^3 = Size(f) then
       Error("Field order must be a cube of a prime power");
    fi;
    pps := PrimePowersInt( Size(f) );

       ## Hendrik's form
    hvm := List([1..8], i -> [0,0,0,0,0,0,0,0]*One(f));
    hvm{[1..4]}{[5..8]} := IdentityMat(4, f);
    hvmform := QuadraticFormByMatrix(hvm, f);
    ps := PolarSpace( hvmform );

	## Hendrik's canonical point is <(1,0,0,0,0,0,0,0)>	
    reppointvect := ([1,0,0,0,0,0,0,0] * One(f));
    MultRowVector(reppointvect,Inverse( reppointvect[PositionNonZero(reppointvect)] ));
	#ConvertToVectorRep(reppointvect, f); #useless now.

	## Hendrik's canonical line is <(1,0,0,0,0,0,0,0), (0,0,0,0,0,0,1,0)>
    replinevect := ([[1,0,0,0,0,0,0,0], [0,0,0,0,0,0,1,0]] * One(f));
	#ConvertToMatrixRep(replinevect, f); #useless now.

	listels := function(gp,j)
		local coll,reps;
		coll := CollineationGroup(gp);
		reps := RepresentativesOfElements( gp );
		return Enumerate(Orb(coll, reps[j], OnProjSubspaces));
	end;

	shadline := function( l )
		return List(Points(ElementToElement(AmbientSpace(l),l)),x->Wrap(l!.geo,1,x!.obj));
	end;

    shadpoint := function( pt )
        local planevec, flag, plane, f, frob;
        f := BaseField( pt );
        frob := FrobeniusAutomorphism(f);
        planevec := TwistedTrialityHexagonPointToPlaneByTwoTimesTriality( Unpack(pt!.obj), frob, f );
        plane := VectorSpaceToElement(PG(7,f),planevec);
        flag := FlagOfIncidenceStructure(PG(7,f),[pt,plane]);
        # we have q^3+1 lines and have to select q+1 from them. Following can probably done more efficient,
        # but I need more mathematics then.
        return List(Filtered(ShadowOfFlag(PG(7,f),flag,2),x->x in pt!.geo), y-> Wrap(pt!.geo,2,Unwrap(y)));
    end;

    dist := function(el1,el2)
		local x,y;
        if el1 = el2 then
			return 0;
		elif el1!.type = 1 and el2!.type = 1 then
			y := VectorSpaceToElement(PG(7,f), 
				TwistedTrialityHexagonPointToPlaneByTwoTimesTriality(Unpack(el2!.obj),frob,f)); #PG(7,f): avoids some unnecessary checks
			if el1 in y then
				return 2;
			else
				x := VectorSpaceToElement(PG(7,f), 
					TwistedTrialityHexagonPointToPlaneByTwoTimesTriality(Unpack(el1!.obj),frob,f));
				if ProjectiveDimension(Meet(x,y)) = 0 then
					return 4;
				else
					return 6;
				fi;
			fi;
		elif el1!.type = 2 and el2!.type = 2 then
			if ProjectiveDimension(Meet(el1,el2)) = 0 then
				return 2;
			fi;
			x := TangentSpace(ps,el1);
			if ProjectiveDimension(Meet(x,el2)) = 0 then
				return 4;
			else
				return 6;
			fi;
		elif el1!.type = 1 and el2!.type = 2 then
			if el1 in el2 then
				return 1;
			fi;
			x := VectorSpaceToElement(PG(7,f), 
				TwistedTrialityHexagonPointToPlaneByTwoTimesTriality(Unpack(el1!.obj),frob,f));
			if ProjectiveDimension(Meet(x,el2)) = 0 then
				return 3;
			else
				return 5;
			fi;
		else
			return dist(el2,el1);
		fi;
	end;

    geo := rec( pointsobj := [], linesobj := [], incidence:= \*, listelements := listels, shadowofpoint := shadpoint, 
        shadowofline := shadline, basefield := BaseField(ps), dimension := Dimension(ps),
        vectorspace := UnderlyingVectorSpace(ps), polarspace := ps, distance := dist );
    ty := NewType( GeometriesFamily, IsClassicalGeneralisedHexagon and IsGeneralisedPolygonRep ); #change by jdb 7/12/11
    Objectify( ty, geo );
    SetAmbientSpace(geo, AmbientSpace(ps));
    SetAmbientPolarSpace(geo,ps);

	#now we are ready to pack the representatives of the elements, which are also elements of a polar space.
	#recall that reppointvect and replinevect are triangulized.
	#now come the cvec/cmat ing of reppointvect and repplinevect.
   	
	reppointvect := CVec(reppointvect,f);
   	replinevect := NewMatrix(IsCMatRep,f,Length(reppointvect),replinevect);

	w := rec(geo := geo, type := 1, obj := reppointvect);
    reppoint := Objectify( NewType( SoPSFamily, IsElementOfIncidenceStructure and IsElementOfIncidenceStructureRep and
							IsElementOfGeneralisedPolygon and IsSubspaceOfClassicalPolarSpace ), w );
    w := rec(geo := geo, type := 2, obj := replinevect);
    repline := Objectify( NewType( SoPSFamily, IsElementOfIncidenceStructure and IsElementOfIncidenceStructureRep and
	 						IsElementOfGeneralisedPolygon and IsSubspaceOfClassicalPolarSpace ), w );

    SetOrder(geo, [q^3, q]);
    SetTypesOfElementsOfIncidenceStructure(geo, ["point","line"]);
    SetRankAttr(geo, 2);
    SetRepresentativesOfElements(geo, [reppoint, repline]);
    #SetName(geo,Concatenation("Twisted Triality Hexagon of order ", String([q^3, q])));
	SetName(geo,Concatenation("T(",String(q^3),", ",String(q),")"));
   	return geo;
  end );

#############################################################################
#O  TwistedTrialityHexagon( <q> )
# shortcut to previous method.
##
InstallMethod( TwistedTrialityHexagon, 
	"input is a prime power", 
	[ IsPosInt ],
	function( q )
		return TwistedTrialityHexagon(GF(q));
	end );

# 24/3/2014. cmat changes. Same principle as SplitCayleyHexagon
#############################################################################
#O  TwistedTrialityHexagon( <ps> )
# returns the twisted triality hexagon over <f>
##
InstallMethod( TwistedTrialityHexagon, 
	"for a classical polar space",
	[ IsClassicalPolarSpace ],
	function( ps )
    local geo, ty, points, lines, repline, hvm, orblen, hvmc, c, listels, eq, naampje,
          hvmform, form, q, pps, reppoint, reppointvect, replinevect, w, shadline, f,
          shadpoint, c1, c2, change, dist, frob;
       ## Field must be GF(q^3);
    if not (IsHyperbolicQuadric(ps) and ps!.dimension = 7) then
        Error("No embedding of twisted triality hexagon possible in <ps>");
    fi;
    f := BaseField(ps);
	frob := FrobeniusAutomorphism(f);
    q := RootInt(Size(f), 3);
	if not q^3 = Size(f) then
       Error("Field order must be a cube of a prime power");
    fi;
    pps := PrimePowersInt( Size(f) );

       ## Hendrik's form
    hvm := List([1..8], i -> [0,0,0,0,0,0,0,0]*One(f));
    hvm{[1..4]}{[5..8]} := IdentityMat(4, f);
    hvmform := QuadraticFormByMatrix(hvm, f);
    hvm := PolarSpace(hvmform);
	c1 := BaseChangeToCanonical(hvmform);
	if not IsCanonicalPolarSpace(ps) then
		c2 := BaseChangeToCanonical(QuadraticForm(ps));
		change := c1^-1*c2;
	else
		change := c1^-1;
	fi;

	## Hendrik's canonical point is <(1,0,0,0,0,0,0,0)>	
    reppointvect := ([1,0,0,0,0,0,0,0] * One(f)) * change;
    MultRowVector(reppointvect,Inverse( reppointvect[PositionNonZero(reppointvect)] ));
	#ConvertToVectorRep(reppointvect, f); #useless now.

	## Hendrik's canonical line is <(1,0,0,0,0,0,0,0), (0,0,0,0,0,0,1,0)>
    replinevect := ([[1,0,0,0,0,0,0,0], [0,0,0,0,0,0,1,0]] * One(f)) * change;
	TriangulizeMat(replinevect);

	#ConvertToMatrixRep(replinevect, f); #useless now.

	listels := function(gp,j)
		local coll,reps;
		coll := CollineationGroup(gp);
		reps := RepresentativesOfElements( gp );
		return Enumerate(Orb(coll, reps[j], OnProjSubspaces));
	end;

	shadline := function( l )
		return List(Points(ElementToElement(AmbientSpace(l),l)),x->Wrap(l!.geo,1,x!.obj));
	end;

    shadpoint := function( pt )
        local planevec, flag, plane, f, frob;
        f := BaseField( pt );
        frob := FrobeniusAutomorphism(f);
        planevec := TwistedTrialityHexagonPointToPlaneByTwoTimesTriality( Unpack(pt!.obj) * change^-1, frob, f ) * change;
        plane := VectorSpaceToElement(PG(7,f),planevec);
        flag := FlagOfIncidenceStructure(PG(7,f),[pt,plane]);
        # we have q^3+1 lines and have to select q+1 from them. Following can probably done more efficient,
        # but I need more mathematics then.
        return List(Filtered(ShadowOfFlag(PG(7,f),flag,2),x->x in pt!.geo), y-> Wrap(pt!.geo,2,Unwrap(y)));
    end;
    
	dist := function(el1,el2)
		local x,y;
        if el1 = el2 then
			return 0;
		elif el1!.type = 1 and el2!.type = 1 then
			y := VectorSpaceToElement(PG(7,f), TwistedTrialityHexagonPointToPlaneByTwoTimesTriality(
				Unpack(el2!.obj) * change^-1,frob,f) * change); #PG(7,f): avoids some unnecessary checks
			if el1 in y then
				return 2;
			else
				x := VectorSpaceToElement(PG(7,f), TwistedTrialityHexagonPointToPlaneByTwoTimesTriality(
					Unpack(el1!.obj) * change^-1,frob,f) * change);
				if ProjectiveDimension(Meet(x,y)) = 0 then
					return 4;
				else
					return 6;
				fi;
			fi;
		elif el1!.type = 2 and el2!.type = 2 then
			if ProjectiveDimension(Meet(el1,el2)) = 0 then
				return 2;
			fi;
			x := TangentSpace(ps,el1);
			if ProjectiveDimension(Meet(x,el2)) = 0 then
				return 4;
			else
				return 6;
			fi;
		elif el1!.type = 1 and el2!.type = 2 then
			if el1 in el2 then
				return 1;
			fi;
			x := VectorSpaceToElement(PG(7,f), TwistedTrialityHexagonPointToPlaneByTwoTimesTriality(
				Unpack(el1!.obj) * change^-1,frob,f) * change);
			if ProjectiveDimension(Meet(x,el2)) = 0 then
				return 3;
			else
				return 5;
			fi;
		else
			return dist(el2,el1);
		fi;
	end;

    geo := rec( pointsobj := [], linesobj := [], incidence:= \*, listelements := listels, shadowofpoint := shadpoint, 
        shadowofline := shadline, basefield := BaseField(ps), dimension := Dimension(ps), basechange := change,
        vectorspace := UnderlyingVectorSpace(ps), polarspace := ps, distance := dist );
    ty := NewType( GeometriesFamily, IsClassicalGeneralisedHexagon and IsGeneralisedPolygonRep ); #change by jdb 7/12/11
    Objectify( ty, geo );
    SetAmbientSpace(geo, AmbientSpace(ps));
    SetAmbientPolarSpace(geo,ps);

	#now we are ready to pack the representatives of the elements, which are also elements of a polar space.
	#recall that reppointvect and replinevect are triangulized.
	#now come the cvec/cmat ing of reppointvect and repplinevect.
   	
	#reppointvect := CVec(reppointvect,f);
	reppointvect :=  NewMatrix(IsCMatRep,f,Length(reppointvect),[reppointvect])[1];
    replinevect := NewMatrix(IsCMatRep,f,Length(reppointvect),replinevect);

	w := rec(geo := geo, type := 1, obj := reppointvect);
    reppoint := Objectify( NewType( SoPSFamily, IsElementOfIncidenceStructure and IsElementOfIncidenceStructureRep and
							IsElementOfGeneralisedPolygon and IsSubspaceOfClassicalPolarSpace ), w );
    w := rec(geo := geo, type := 2, obj := replinevect);
    repline := Objectify( NewType( SoPSFamily, IsElementOfIncidenceStructure and IsElementOfIncidenceStructureRep and
	 						IsElementOfGeneralisedPolygon and IsSubspaceOfClassicalPolarSpace ), w );

    SetOrder(geo, [q^3, q]);
    SetTypesOfElementsOfIncidenceStructure(geo, ["point","line"]);
    SetRepresentativesOfElements(geo, [reppoint, repline]);
    SetRankAttr(geo, 2);
    #SetName(geo,Concatenation("Twisted Triality Hexagon of order ", String([q^3, q])));
	#SetName(geo,Concatenation("T(",String(q^3),", ",String(q),")"));
   	if not IsCanonicalPolarSpace(ps) then
		eq := Concatenation(": ",String(EquationForPolarSpace(ps)));
	else
		eq := "";
	fi;
	naampje := Concatenation("Q+(7, ",String(Size(f)),")",eq);
	SetName(geo,Concatenation("T(",String(q^3),", ",String(q),")", " in ",naampje));
    return geo;
  end );

##################################################################################
# Groups: we follow the same approach as for polar spaces. There is an operation
# that returns the groups as fining groups, which is used when needed by e.g.
# CollineationGroup( <gh> )
##################################################################################

#############################################################################
#O  G2fining( <d>, <f> )
## returns the Chevalley group G_2(q) (also known as Dickson's group.
# <f> is a finite field. For <d> equals 6, the returned group is a will be a 
# subgroup of PGL(7,<f>). When <f> has characteristic 2, <d> equals 5 is allowed, 
# then the returned group will be a subgroup of PGL(6,<f>).
##
InstallMethod( G2fining,
	"for a dimension and a field",
	[ IsPosInt, IsField and IsFinite ],
	function(d, f)
	local m, mp, ml, g, gens, nonzerof, newgens;
	if d=6 then
		 m:=[[ 0, 0, 0, 0, 0, 1, 0],
             [ 0, 0, 0, 0, 0, 0, 1],
             [ 0, 0, 0, 0, 1, 0, 0],
             [ 0, 0, 0, -1, 0, 0, 0],               ## **
             [ 0, 1, 0, 0, 0, 0, 0],
             [ 0, 0, 1, 0, 0, 0, 0],
             [ 1, 0, 0, 0, 0, 0, 0]]*One(f);  
         #ConvertToMatrixRep(m, f);
         mp := d -> 
			[[1,  0,  0,  0,  0,  d,  0],  
             [0,  1,  0,  0, -d,  0,  0],  
             [0,  0,  1,  0,  0,  0,  0],  
             [0,  0,  -2*d,  1,  0,  0,  0],         ## **
             [0,  0,  0,  0,  1,  0,  0],  
             [0,  0,  0,  0,  0,  1,  0],  
             [0,  0,d^2,  -d,  0,  0,  1]]*One(f);   ## **
         ml := d ->
			[[1, -d,  0,  0,  0,  0,  0],  
             [0,  1,  0,  0,  0,  0,  0],  
             [0,  0,  1,  0,  0,  0,  0],  
             [0,  0,  0,  1,  0,  0,  0],  
             [0,  0,  0,  0,  1,  0,  0],  
             [0,  0,  0,  0,  d,  1,  0],  
             [0,  0,  0,  0,  0,  0,  1]]*One(f);
		nonzerof := AsList(f){[2..Size(f)]};
		gens := Union([m], List(nonzerof, mp), List(nonzerof, ml));
        #for x in gens do
        #   ConvertToMatrixRep(x, f);
        #od;
	elif d=5 then
		if not IsEvenInt(Characteristic(f)) then
			Error("embedding of G_2(q) in PGL(6,q) is only possible for even q");
		fi;
		m:=[[ 0, 0, 0, 0, 1, 0],
		   [ 0, 0, 0, 0, 0, 1],
           [ 0, 0, 0, 1, 0, 0],
           [ 0, 1, 0, 0, 0, 0],
           [ 0, 0, 1, 0, 0, 0],
           [ 1, 0, 0, 0, 0, 0]]*One(f);  
		mp := d ->
			[[1,  0,  0,  0,  d,  0],  
             [0,  1,  0,  d,  0,  0],  
             [0,  0,  1,  0,  0,  0],  
             [0,  0,  0,  1,  0,  0],  
             [0,  0,  0,  0,  1,  0],  
             [0,  0,d^2,  0,  0,  1]]*One(f);  
		ml := d ->
			[[1,  d,  0,  0,  0,  0],  
             [0,  1,  0,  0,  0,  0],  
             [0,  0,  1,  0,  0,  0],  
             [0,  0,  0,  1,  0,  0],  
             [0,  0,  0,  d,  1,  0],  
             [0,  0,  0,  0,  0,  1]]*One(f);
		nonzerof := AsList(f){[2..Size(f)]};
		gens := Union([m], List(nonzerof,mp), List(nonzerof,ml));
	else
		Error("<d> should be 5 or 6");
	fi;
    newgens := List(gens, x -> CollineationOfProjectiveSpace(x, f));  
	g := GroupWithGenerators( newgens );
	#SetCollineationAction(coll, OnProjSubspaces);
	SetName(g, Concatenation("G_2(",String(Size(f)),")") );
    return g;
  end );

#############################################################################
#O  3D4fining( <d>, <f> )
##
InstallMethod( 3D4fining,
	"for a finite field",
	[ IsField and IsFinite ],
	function(f)
		local q, pps, frob, sigma, m, mp, ml, nonzerof, nonzeroq, gens, g, newgens;
		q := RootInt(Size(f), 3);
		if not q^3 = Size(f) then
			Error("Field order must be a cube of a prime power");
		fi;
		pps := Characteristic(f);
		frob := FrobeniusAutomorphism(f);
		sigma := frob^LogInt(q,pps); 
		# The generators of 3D4(q) were taken from Hendrik 
    	# Van Maldeghem's book: "Generalized Polygons".

       m:=[[ 0, 0, 0, 0, 0, 1, 0, 0],
           [ 0, 0, 0, 0, 0, 0, 1, 0],
           [ 0, 0, 0, 0, 1, 0, 0, 0],
           [ 0, 0, 0, 0, 0, 0, 0, 1],   
           [ 0, 1, 0, 0, 0, 0, 0, 0],
           [ 0, 0, 1, 0, 0, 0, 0, 0],
           [ 1, 0, 0, 0, 0, 0, 0, 0],
           [ 0, 0, 0, 1, 0, 0, 0, 0]]*One(f);  
       ConvertToMatrixRep(m, f);
       mp:=d->[[1,  0,  0,  0,  0,  d,  0,  0],  
               [0,  1,  0,  0, -d,  0,  0,  0],  
               [0,  0,  1,  0,  0,  0,  0,  0],  
               [0,  0,  -d^sigma,  1,  0,  0,  0,  0],
               [0,  0,  0,  0,  1,  0,  0,  0],  
               [0,  0,  0,  0,  0,  1,  0,  0],  
               [0,0,d^sigma*d^(sigma^2),-d^(sigma^2),0,0,1,d^sigma],
               [0,0,d^(sigma^2),0,0,0,0,1]]*One(f);   
       ml:=d->[[1, -d,  0,  0,  0,  0,  0,  0],  
               [0,  1,  0,  0,  0,  0,  0,  0],  
               [0,  0,  1,  0,  0,  0,  0,  0],  
               [0,  0,  0,  1,  0,  0,  0,  0],  
               [0,  0,  0,  0,  1,  0,  0,  0],  
               [0,  0,  0,  0,  d,  1,  0,  0],  
               [0,  0,  0,  0,  0,  0,  1,  0],
               [0,  0,  0,  0,  0,  0,  0,  1]]*One(f);

		nonzerof := AsList(f){[2..Size(f)]};
		nonzeroq := AsList(GF(q)){[2..q]};
		gens := Union([m], List(nonzerof, mp), List(nonzeroq, ml));
		newgens := List(gens, x -> CollineationOfProjectiveSpace(x,f));
		g := GroupWithGenerators(newgens);
		SetName(g, Concatenation("3D_4(",String(Size(f)),")") );
		return g;
	end );

#############################################################################
#A  CollineationGroup( <hexagon> )
# computes the collineation group of a (classical) generalised hexagon
##
InstallMethod( CollineationGroup,
	"for a generalised hexagon",
	[ IsClassicalGeneralisedHexagon],
	function( hexagon )
		local group, coll, f, gens, newgens, change, d, q, rep, domain, orblen, hom, frob, t,
		
		pps, sigma, m, mp, ml, nonzerof, nonzeroq,  x;
		f := hexagon!.basefield;
		q := Size(f);
		d := hexagon!.dimension;
		if Size(Set(Order(hexagon))) > 1 then
			f := hexagon!.basefield;
       ## field must be GF(q^3);
			group := 3D4fining(f);
            if IsBound(hexagon!.basechange) then
				change := hexagon!.basechange;
				gens := List(GeneratorsOfGroup(group),x->Unpack(x!.mat));
				newgens := List(gens,x->CollineationOfProjectiveSpace(change^-1 * x * change,f));
            else
				gens := GeneratorsOfGroup(group);
				newgens := ShallowCopy(gens);
            fi;
			coll := GroupWithGenerators(newgens);
			Info(InfoFinInG, 1, "Computing nice monomorphism...");
       		t := RootInt(q, 3);
			orblen := (t+1)*(t^8+t^4+1);
			rep := RepresentativesOfElements(hexagon)[2];
			domain := Orb(coll, rep, OnProjSubspaces, 
                    rec(orbsizelimit := orblen, hashlen := 2*orblen, storenumbers := true));
			Enumerate(domain);
			Info(InfoFinInG, 1, "Found permutation domain...");
			hom := OrbActionHomomorphism(coll, domain);   
			SetIsBijective(hom, true);
			SetNiceObject(coll, Image(hom) );
			SetNiceMonomorphism(coll, hom );
			SetCollineationAction(coll, OnProjSubspaces);
			return coll;
		else 
			Info(InfoFinInG, 1, "for Split Cayley Hexagon");
			group := G2fining(d,f);
			if IsBound(hexagon!.basechange) then
				change := hexagon!.basechange;
				gens := List(GeneratorsOfGroup(group),x->Unpack(x!.mat));
				newgens := List(gens,x->CollineationOfProjectiveSpace(change^-1 * x * change,f));
			    if not IsPrimeInt(q) then
					frob := FrobeniusAutomorphism(f); 
					Add(newgens, CollineationOfProjectiveSpace( change^-1 * IdentityMat(d+1,f) * change^(frob^-1), frob, f )); 
				fi; 
			else
				gens := GeneratorsOfGroup(group);
				newgens := ShallowCopy(gens);
				if not IsPrimeInt(q) then 
					frob := FrobeniusAutomorphism(f); 
					Add(newgens, CollineationOfProjectiveSpace( IdentityMat(d+1,f), frob, f )); 
				fi;
			fi;
			coll := GroupWithGenerators(newgens);
			Info(InfoFinInG, 1, "Computing nice monomorphism...");
			orblen := (q+1)*(q^4+q^2+1);
			rep := RepresentativesOfElements(hexagon)[1];
			domain := Orb(coll, rep, OnProjSubspaces, 
                  rec(orbsizelimit := orblen, hashlen := 2*orblen, storenumbers := true));
			Enumerate(domain);
			Info(InfoFinInG, 1, "Found permutation domain...");
			hom := OrbActionHomomorphism(coll, domain);    
			SetIsBijective(hom, true);
			SetNiceObject(coll, Image(hom) );
			SetNiceMonomorphism(coll, hom );
			SetCollineationAction(coll, OnProjSubspaces);
			if not IsBound(hexagon!.basechange) then
				if IsPrime(Size(f)) then
					SetName(coll, Concatenation("G_2(",String(Size(f)),")") );
				else
					SetName(coll, Concatenation("G_2(",String(Size(f)),").", String(Order(frob))) );
				fi;
			fi;
			return coll;
		fi;
	end );

#############################################################################
# Incidence graph for classical generalised hexagons.
#############################################################################

#############################################################################
#O  IncidenceGraphOfGeneralisedPolygon( <gp> )
###
InstallMethod( IncidenceGraphOfGeneralisedPolygon,
    "for an ElationGQ in generic representation",
    [ IsClassicalGeneralisedHexagon and IsGeneralisedPolygonRep ],
    function( gp )
    local points, lines, graph, adj, group, coll, act,sz;
    if not "grape" in RecNames(GAPInfo.PackagesLoaded) then
       Error("You must load the GRAPE package\n");
    fi;
    if IsBound(gp!.IncidenceGraphOfGeneralisedPolygonAttr) then
       return gp!.IncidenceGraphOfGeneralisedPolygonAttr;
    fi;
    if not HasCollineationGroup(gp) then
        Error("No collineation group computed. Please compute collineation group before computing incidence graph\,n");
    else
        points := AsList(Points(gp));
        lines := AsList(Lines(gp));
        Setter( HasGraphWithUnderlyingObjectsAsVertices )( gp, false );

        Info(InfoFinInG, 1, "Computing incidence graph of generalised polygon...");
    
        adj := function(x,y)
            if x!.type <> y!.type then
                return IsIncident(x,y);
            else
                return false;
            fi;
        end;
		group := CollineationGroup(gp);
		act := CollineationAction(group);
		graph := Graph(group,Concatenation(points,lines),act,adj,true);
        Setter( IncidenceGraphOfGeneralisedPolygonAttr )( gp, graph );
        return graph;
    fi;
  end );

#############################################################################
# Dealing with elements: constructor operations and membership test.
#############################################################################

# Added 02/08/2014 jdb
#############################################################################
#O  VectorSpaceToElement( <geom>, <v> ) returns the elements in <geom> determined
# by the vectorspace <v>. 
##
InstallMethod( VectorSpaceToElement, 
	"for a polar space and a cvec",
	[ IsClassicalGeneralisedHexagon, IsCVecRep],
	function( geom, v )
		return VectorSpaceToElement(geom,Unpack(v));
	end );

# Added 02/08/2014 jdb
#############################################################################
#O  VectorSpaceToElement( <geom>, <v> ) returns the element in <geom> determined
# by the rowvector <v>. <geom> is a generalised hexagon, so an ambient polar space
# ps is available. A point of geom is necessary a point of ps, but for T(q^3,q) we need
# to check whether the point of Q+(7,q) is absolute. This method is base on VectorSpaceToElement
# for polar spaces and a row vector.
##
InstallMethod( VectorSpaceToElement,
    "for a generalised hexagon and a row vector",
    [ IsClassicalGeneralisedHexagon, IsRowVector ],
    function(geom,vec)
		local x,y, ps, el, onespace, f, frob;
		## dimension should be correct
		if Length(vec) <> geom!.dimension + 1 then
			Error("Dimensions are incompatible");
		fi;
		x := ShallowCopy(vec);
		if IsZero(x) then
			return EmptySubspace(geom);
		fi;
		MultRowVector(x,Inverse( x[PositionNonZero(x)] ));
		y := NewMatrix(IsCMatRep,geom!.basefield,Length(x),[x]);
		ps := AmbientPolarSpace(geom);
		if geom!.dimension = 5 then
			return Wrap(geom, 1, y);
		elif geom!.dimension = 6 then
			if not IsSingularVector(QuadraticForm(ps),x) then
				Error("<v> does not generate an element of <geom>");
			else
				return Wrap(geom, 1, y);
			fi;
		else
			if not IsSingularVector(QuadraticForm(ps),x) then
				Error("<v> does not generate an element of <geom>");
			fi;
			el := VectorSpaceToElement(ps,y);
			f := geom!.basefield;
			frob := FrobeniusAutomorphism(f);
			onespace := VectorSpaceToElement(AmbientSpace(ps), ZeroPointToOnePointsSpaceByTriality(x,frob,f));
			if el in onespace then
				return Wrap(geom,1,y);
			else
				Error("<v> generates an element of the ambient polar space but not of <geom>");
			fi;
		fi;
end );

# Added 02/08/2014 jdb
#############################################################################
#O  VectorSpaceToElement( <geom>, <v> ) returns the elements in <geom> determined
# by the rowvector <v>. Several checks are built in.
##
InstallMethod( VectorSpaceToElement, 
	"for a polar space and an 8-bit vector",
	[ IsClassicalGeneralisedHexagon, Is8BitVectorRep ],
    function(geom,vec)
		local x,y, ps, el, onespace, f, frob;
		## dimension should be correct
		if Length(vec) <> geom!.dimension + 1 then
			Error("Dimensions are incompatible");
		fi;
		x := ShallowCopy(vec);
		if IsZero(x) then
			return EmptySubspace(geom);
		fi;
		MultRowVector(x,Inverse( x[PositionNonZero(x)] ));
		y := NewMatrix(IsCMatRep,geom!.basefield,Length(x),[x]);
		ps := AmbientPolarSpace(geom);
		if geom!.dimension = 5 then
			return Wrap(geom, 1, y);
		elif geom!.dimension = 6 then
			if not IsSingularVector(QuadraticForm(ps),x) then
				Error("<v> does not generate an element of <geom>");
			else
				return Wrap(geom, 1, y);
			fi;
		else
			if not IsSingularVector(QuadraticForm(ps),x) then
				Error("<v> does not generate an element of <geom>");
			fi;
			el := VectorSpaceToElement(ps,y);
			f := geom!.basefield;
			frob := FrobeniusAutomorphism(f);
			onespace := VectorSpaceToElement(AmbientSpace(ps), ZeroPointToOnePointsSpaceByTriality(x,frob,f));
			if el in onespace then
				return Wrap(geom,1,y);
			else
				Error("<v> generates an element of the ambient polar space but not of <geom>");
			fi;
		fi;
end );

# Added 02/08/2014 jdb
#############################################################################
#O  VectorSpaceToElement( <geom>, <v> ) returns the elements in <geom> determined
# by the vectorspace <v>. Code based on VectorSpaceToElement for polar spaces
# and IsPlistRep.
## 
InstallMethod( VectorSpaceToElement, 
	"for a polar space and a Plist",
	[ IsClassicalGeneralisedHexagon, IsPlistRep],
	function( geom, v )
		local  x, n, i, y, ps, f, onespace1, onespace2, p1, p2, change, frob;
		## when v is empty... 
		if IsEmpty(v) then
			Error("<v> does not represent any element");
		fi;
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
        if Length(x) = 1 then
            return VectorSpaceToElement(geom, x[1]);
        fi;
		ps := AmbientPolarSpace(geom);
		y := NewMatrix(IsCMatRep,geom!.basefield,Length(x[1]),x);
		f := geom!.basefield;
		if IsBound(geom!.basechange) then
			change := geom!.basechange;
		else
			change := IdentityMat(geom!.dimension+1,f);
		fi;
		if geom!.dimension = 5 then
			if not IsTotallyIsotropicSubspace(SesquilinearForm(ps),x) then
				Error("<x> does not generate an element of the ambient polar space of <geom>");
			fi;
			p1 := Wrap(AmbientSpace(ps),1,y[1]);
			onespace1 := VectorSpaceToElement(AmbientSpace(ps),SplitCayleyPointToPlane5(x[2] * change^-1,f) * change);
			if p1 in onespace1 then
				return Wrap(geom,2,y);
			else 
				Error("<x> does not generate an element of <geom>");
			fi;
		elif geom!.dimension = 6 then
			if not IsTotallySingularSubspace(QuadraticForm(ps),x) then
				Error("<x> does not generate an element of the ambient polar space of <geom>");
			fi;
			p1 := Wrap(AmbientSpace(ps),1,y[1]);
			onespace1 := VectorSpaceToElement(AmbientSpace(ps),SplitCayleyPointToPlane(x[2] * change^-1,f) * change);
			if p1 in onespace1 then
				return Wrap(geom,2,y);
			else 
				Error("<x> does not generate an element of <geom>");
			fi;
		else
			frob := FrobeniusAutomorphism(f);
			if not IsTotallySingularSubspace(QuadraticForm(ps),x) then
				Error("<x> does not generate an element of the ambient polar space of <geom>");
			fi;
			p1 := Wrap(AmbientSpace(ps),1,y[1]);
			onespace1 := VectorSpaceToElement(AmbientSpace(ps), 
					ZeroPointToOnePointsSpaceByTriality(x[1] * change^-1,frob,f) * change);
			p2 := Wrap(AmbientSpace(ps),1,y[2]);
			onespace2 := VectorSpaceToElement(AmbientSpace(ps), 
					ZeroPointToOnePointsSpaceByTriality(x[2] * change^-1,frob,f) * change);
			if p1 in onespace1 and p2 in onespace2 and p2 in onespace1 then
				return Wrap(geom,2,y);
			else
				Error("<x> does not generate an element of <geom>");
			fi;
		fi;
	end );

# Added 02/08/2014 jdb
#############################################################################
#O  VectorSpaceToElement( <geom>, <v> ) 
# if mat is in IsGF2MatrixRep, then Unpack(mat) is in IsPlistRep.
## 
InstallMethod( VectorSpaceToElement, 
	"for a polar space and a compressed GF(2)-matrix",
	[ IsClassicalGeneralisedHexagon, IsGF2MatrixRep],
	function(geom, mat)
		return VectorSpaceToElement(geom,Unpack(mat));
	end );
	
# Added 02/08/2014 jdb
#############################################################################
#O  VectorSpaceToElement( <geom>, <v> ) 
# if mat is in Is8BitMatrixRep, then Unpack(mat) is in IsPlistRep.
## 
InstallMethod( VectorSpaceToElement, 
	"for a polar space compressed basis of a vector subspace",
	[ IsClassicalGeneralisedHexagon, Is8BitMatrixRep],
	function(geom, mat)
		return VectorSpaceToElement(geom,Unpack(mat));
	end );

# Added 02/08/2014 jdb
#############################################################################
#O  VectorSpaceToElement( <geom>, <v> ) returns the elements in <geom> determined
# by the vectorspace <v>. 
##
InstallMethod( VectorSpaceToElement, 
	"for a polar space and a cmat",
	[ IsClassicalGeneralisedHexagon, IsCMatRep],
	function( geom, v )
		return VectorSpaceToElement(geom,Unpack(v));
	end );

#############################################################################
#O  \in( <w>, <gp> ) true if the element <w> is contained in <gp>
# We can base this method on VectorSpaceToElement, some checks can be avoided since we
# start from an element already.
InstallMethod( \in,
	"for an element of an incidencestructure a classical generalised hexagon",
	[ IsElementOfIncidenceStructure, IsClassicalGeneralisedHexagon ],
	function( el, gp )
        local vec, onespace, f, frob, p1, p2, onespace1, onespace2, change;
        vec := Unpack(UnderlyingObject(el));
        if not AmbientSpace(el) = AmbientSpace(gp) then
            return false;
        fi;
        if el!.type = 1 then #dealing with a point
            if gp!.dimension = 5 then
                return true;
            elif gp!.dimension = 6 then
                if not IsSingularVector(QuadraticForm(AmbientPolarSpace(gp)),vec) then
                    return false;
                else
                    return true;
                fi;
            else
                if not IsSingularVector(QuadraticForm(AmbientPolarSpace(gp)),vec) then
                    return false;
                fi;
                f := gp!.basefield;
                frob := FrobeniusAutomorphism(f);
                onespace := VectorSpaceToElement(AmbientSpace(gp), ZeroPointToOnePointsSpaceByTriality(vec,frob,f));
                if el in onespace then
                    return true;
                else
                    return false;
                fi;
            fi;
        elif el!.type = 2 then #dealing with a line
            f := gp!.basefield;
            if IsBound(gp!.basechange) then
                change := gp!.basechange;
            else
                change := IdentityMat(gp!.dimension+1,f);
            fi;
            if gp!.dimension = 5 then
                if not IsTotallyIsotropicSubspace(SesquilinearForm(AmbientPolarSpace(gp)),vec) then
                    return false;
                fi;
                p1 := VectorSpaceToElement(AmbientSpace(gp),vec[1]);
                onespace1 := VectorSpaceToElement(AmbientSpace(gp),SplitCayleyPointToPlane5(vec[2] * change^-1,f) * change);
                if el in onespace1 then
                    return true;
                else
                    return false;
                fi;
            elif gp!.dimension = 6 then
                if not IsTotallySingularSubspace(QuadraticForm(AmbientPolarSpace(gp)),vec) then
                    return false;
                fi;
                p1 := VectorSpaceToElement(AmbientSpace(gp),vec[1]);
                onespace1 := VectorSpaceToElement(AmbientSpace(gp),SplitCayleyPointToPlane(vec[2] * change^-1,f) * change);
                if p1 in onespace1 then
                    return true;
                else
                    return false;
                fi;
            else
                frob := FrobeniusAutomorphism(f);
                if not IsTotallySingularSubspace(QuadraticForm(AmbientPolarSpace(gp)),vec) then
                    return false;
                fi;
                p1 := VectorSpaceToElement(AmbientSpace(gp),vec[1]);
                onespace1 := VectorSpaceToElement(AmbientSpace(gp),
					ZeroPointToOnePointsSpaceByTriality(vec[1] * change^-1,frob,f) * change);
                p2 := VectorSpaceToElement(AmbientSpace(gp),vec[2]);
                onespace2 := VectorSpaceToElement(AmbientSpace(gp),
					ZeroPointToOnePointsSpaceByTriality(vec[2] * change^-1,frob,f) * change);
                if p1 in onespace1 and p2 in onespace2 and p2 in onespace1 then
                    return true;
                else
                    return false;
                fi;
            fi;
        else
            return false;
        fi;
    end );

#############################################################################
#
#  Kantor Families and associated EGQ's
#  
#  The setup is a bit different than the standard one. 
#  IsElationGQ is a subcategory of IsGeneralisedQuadrangle. IsElationGQByKantorFamily
#  is a subcategory of IsElationGQ. For historical (?) reasons, the elements of a 
#  IsElationGQByKantorFamily-GP are in a category called IsElementOfKantorFamily,
#  which is a subcategory of IsElementOfGeneralisedPolygon. Contrary to all other
#  instances of elements of an incidence geometry, an IsElementOfKantorFamily contains
#  also its class (and of course its embient geometry, type and underlying object). 
#  This makes typical operations like Wrap different. For IsElationGQByKantorFamily,
#  there is currently also no ObjectToElement and UnderlyingObject method available.
#  
#
#############################################################################

#############################################################################
# Very particular display methods.
#############################################################################

InstallMethod( ViewObj, 
	"for an element of a Kantor family",
	[ IsElementOfKantorFamily ],
	function( v )
		if v!.type = 1 then
			Print("<a point of class ", v!.class," of ",v!.geo,">");
		else 
			Print("<a line of class ", v!.class," of ",v!.geo,">");
		fi;
	end );

InstallMethod( PrintObj, 
	"for an element of a Kantor family",
	[ IsElementOfKantorFamily ],
	function( v )
		if v!.type = 1 then
			Print("<a point of class ", v!.class," of ",v!.geo,">\n");
		else
			Print("<a line of class ", v!.class," of ",v!.geo,">\n");
		fi;
		Print(v!.obj);
	end );

#############################################################################
#O  Wrap( <geo>, <type>, <class>, <o>  )
# returns the element of <geo> represented by <o>
##
InstallMethod( Wrap, 
	"for an EGQ (Kantor family), and an object",
	[IsElationGQByKantorFamily, IsPosInt, IsPosInt, IsObject],
	function( geo, type, class, o )
		local w;
		w := rec( geo := geo, type := type, class := class, obj := o );
		Objectify( NewType( ElementsOfIncidenceStructureFamily,   #ElementsFamily,
			IsElementOfKantorFamilyRep and IsElementOfKantorFamily ), w );
		return w;
	end );

#############################################################################
#O  \=( <a>, <b>  )
# for thwo elements of a Kantor family.
##
InstallMethod( \=,
	"for two elements of a Kantor family",
	[IsElementOfKantorFamily, IsElementOfKantorFamily], 
	function( a, b ) 
		return a!.obj = b!.obj; 
	end );

#############################################################################
#O  \<( <a>, <b>  )
# for thwo elements of a Kantor family.
##
InstallMethod( \<, 
	"for two elements of a Kantor family",
	[IsElementOfKantorFamily, IsElementOfKantorFamily], 
	function( a, b ) 
		if a!.type <> b!.type then return a!.type < b!.type;
		else
			if a!.class <> b!.class then return a!.class < b!.class;
			else return a!.obj < b!.obj; 
			fi;
		fi;
	end );

#############################################################################
#O  \<( <a>, <b>  )
# for a group and two lists.
##
InstallMethod( IsKantorFamily,
	"for a group and two lists of subgroups",
	[IsGroup, IsList, IsList],
	function( g, f, fstar)
		local flag, a, b, c, ab, astar, tplus1;
		tplus1 := Size(f);
		flag := true;
		if not ForAll([1..Size(fstar)], x -> IsSubgroup(fstar[x], f[x])) then
			Error( "second and third arguments are incompatile");
		fi;
		if not ForAll(fstar, x -> IsSubgroup(g, x)) then
			Error( "elements of second argument are not subgroups of first argument" );
		fi;

		Info(InfoFinInG, 1, "Checking tangency condition...");
    
		## K2 tangency condition
		for a in [1..tplus1-1] do
			for astar in [a+1..tplus1] do
				flag := IsTrivial(Intersection(fstar[astar], f[a]));
				if not flag then 
					Print("Failed tangency condition\n");
					Print(a,"  ",astar,"\n"); 
					return flag;
				fi;
			od;
		od;

		Info(InfoFinInG, 1, "Checking triple condition...");

		## K1 triple condition
		for a in [1..tplus1-2] do
			for b in [a+1..tplus1-1] do
				for c in [b+1..tplus1] do
					ab := DoubleCoset(f[a], One(g), f[b]);
					flag := IsTrivial(Intersection(ab, f[c]));
					if not flag then
						Print("Failed triple condition\n"); 
						Print(a,"  ",b,"  ",c,"\n"); 
						return flag;
					fi;
				od;
			od;
		od;
		return flag;
	end );

#############################################################################
#F  OnKantorFamily( <v>, <el> ): action function for elation groups on elements.
##
InstallGlobalFunction( OnKantorFamily,
  function( v, el )
    local geo, type, class, new; 
    geo := v!.geo;
    type := v!.type;
    class := v!.class;
    if (type = 1 and class = 3) or (type = 2 and class = 2) then 
       return v;
    elif (type = 1 and class = 2) or (type = 2 and class = 1) then
       new := [v!.obj[1], CanonicalRightCosetElement(v!.obj[1],v!.obj[2]*el)];  
    else 
       new := OnRight(v!.obj, el);
    fi;  
    return Wrap(geo, type, class, new); 
  end );

#############################################################################
#O  EGQByKantorFamily(<g>, <f>, <fstar>)
# for a group and two lists.
# Note: for this model, the underlying objects are IsElementOfKantorFamily.
##
InstallMethod( EGQByKantorFamily, 
	"for a group, a list and a list",
	[IsGroup, IsList, IsList],
	function( g, f, fstar)
    local pts1, pts2, pts3, ls1, ls2, inc, listels, shadpoint, shadline,
          x, y, geo, ty, points, lines, pointreps, linereps;
    ## Some checks first.
    ## We do not check if it's a Kantor family though (this can be rather slow)

    if not ForAll([1..Size(fstar)], x -> IsSubgroup(fstar[x], f[x])) then
       Error( "second and third arguments are incompatible");
       return;
    fi;
    if not ForAll(fstar, x -> IsSubgroup(g, x)) then
       Error( "elements of second argument are not subgroups of first argument" );
       return;
    fi;

    inc := function(x, y)
             if x!.type = y!.type then
                return x = y;
             elif x!.type = 1 and y!.type = 2 then
                if x!.class = 1 and y!.class = 1 then
                   return x!.obj*y!.obj[2]^-1 in y!.obj[1];
                elif x!.class = 2 and y!.class = 1 then
                   return IsSubset(x!.obj[1], RightCoset(y!.obj[1], y!.obj[2]*x!.obj[2]^-1));
                elif x!.class = 2 and y!.class = 2 then
                   return x!.obj[1] = y!.obj; 
                elif x!.class = 3 and y!.class = 2 then
                   return true;
                else return false;
                fi;
             else 
                return inc(y, x);
             fi;   
           end;

    geo := rec( pointsobj := [], linesobj := [], incidence := inc );
    ty := NewType( GeometriesFamily, IsElationGQByKantorFamily and IsGeneralisedPolygonRep );  
    Objectify( ty, geo );

    Info(InfoFinInG, 1, "Computing points from Kantor family...");

    ## wrapping
    pts1 := List(g, x -> Wrap(geo,1,1,x));
    pts2 := Set(fstar, b -> Set(RightCosets(g,b),x->[b,CanonicalRightCosetElement(b, Representative(x))]));
    pts2 := Concatenation(pts2);
    pts2 := List(pts2, x -> Wrap(geo,1,2,x));

    Info(InfoFinInG, 1, "Computing lines from Kantor family...");

    ls1 := Set(f, a -> Set(RightCosets(g,a), x -> [a,CanonicalRightCosetElement(a, Representative(x))]));
    ls1 := Concatenation(ls1); 
    ls1 := List(ls1, x -> Wrap(geo,2,1,x)); ## this is a strictly sorted list

    ## symbols (note that we're making incidence easier here)
    ls2 := Set(fstar, x -> Wrap(geo, 2, 2, x)); 
    pts3 := [ Wrap(geo, 1, 3, 0) ];

    points := Concatenation(pts1,pts2,pts3); 
    lines := Concatenation(ls1, ls2);
    pointreps := Concatenation( [pts1[1]], Set(fstar, b -> Wrap(geo,1,2,[b, One(b)])), pts3);
    linereps := Concatenation(Set(f, a -> Wrap(geo,2,1,[a, One(g)])), ls2);
    
    geo!.points := points;
    geo!.lines := lines;
    
	listels := function(gp,i)
		if i = 1 then
			return gp!.points; #saves memory :-)
		else
			return gp!.lines;
		fi;
	end;
	
	shadpoint := function(pt)
		return Filtered(lines,x->inc(pt,x));
	end;
	
	shadline := function(line)
		return Filtered(points,x->inc(line,x));
	end;
	
	geo!.listelements := listels;
	geo!.shadowofpoint := shadpoint;
	geo!.shadowofline := shadline;
	SetBasePointOfEGQ( geo, pts3[1] );
    SetAmbientSpace(geo, geo);
    SetOrder(geo, [Index(g,fstar[1]), Size(f)-1]);
    SetCollineationAction(g, OnKantorFamily);
    SetElationGroup(geo, g);
    SetTypesOfElementsOfIncidenceStructure(geo, ["point","line"]);
    ## Orbit reps:
    SetRepresentativesOfElements(geo, Concatenation(pointreps,linereps));
    SetName(geo,Concatenation("<EGQ of order ",String([Index(g,fstar[1]), Size(f)-1])," and basepoint 0>"));
	return geo;
  end );

#Iterator and IsIncident: replaced by generic methods now.

#############################################################################
#
#   q-Clans and EGQ's made from them
#
#############################################################################

#############################################################################
#O  IsAnisotropic( <m>, <f> )
# simply checks if a matrix is anisotropic.
##
InstallMethod( IsAnisotropic, 
	"for a matrix and a finite field",
	[IsFFECollColl,  IsField and IsFinite],
	function( m, f )
		local pairs, o;
		o := Zero(f);
		pairs := Difference(AsList(f^2),[[o,o]]);
		return ForAll(pairs, x -> x * m * x <> o);
	end );

#############################################################################
#O  IsAnisotropic( <clan>, <f> )
# simply checks if all differences of elements in a set of 2 x 2 matrices is are
# anisotropic.
##
InstallMethod( IsqClan, 
	"input are 2x2 matrices", 
    [ IsFFECollCollColl,  IsField and IsFinite],
	function( clan, f )
		return ForAll(Combinations(clan,2), x -> IsAnisotropic(x[1]-x[2], f));
	end );

#############################################################################
#O  qClan( <clan>, <f> )
# returns a qClan object from a suitable list of matrices.
##
InstallMethod( qClan, 
	"for a list of 2x2 matrices",
	[ IsFFECollCollColl, IsField ],
	function( m, f ) 
		local qclan;
		## test to see if it is a qClan
		if not ForAll(Combinations(m, 2), x -> IsAnisotropic(x[1]-x[2], f)) then
			Error("These matrices do not form a q-clan");
		fi;
		qclan := rec( matrices := m, basefield := f );
		Objectify( NewType( qClanFamily, IsqClanObj and IsqClanRep ), qclan );
		return qclan;
	end );

InstallMethod( ViewObj, 
	"for a qClan",
	[ IsqClanObj and IsqClanRep ],
	function( x )
		Print("<q-clan over ",x!.basefield,">");
	end );

InstallMethod( PrintObj, 
	"for a qClan",
	[ IsqClanObj and IsqClanRep ],
	function( x )
		Print("qClan( ", x!.matrices, ", ", x!.basefield , ")");
	end );

#############################################################################
#O  AsList( <clan> )
# returns the matrices defining a qClan
##
InstallOtherMethod( AsList,
	"for a qClan",
	[IsqClanObj and IsqClanRep],
	function( qclan )
		return qclan!.matrices;
	end );

#############################################################################
#O  AsList( <clan> )
# returns the matrices defining a qClan
##
InstallOtherMethod( AsSet, 
	"for a qClan",
	[IsqClanObj and IsqClanRep],
	function( qclan )
		return Set(qclan!.matrices);
	end );

#############################################################################
#O  BaseField( <clan> )
# returns the BaseField of the qClan
##
InstallMethod( BaseField, 
	"for a qClan",
	[IsqClanObj and IsqClanRep],
	function( qclan )
		return qclan!.basefield;
	end );

#############################################################################
#O  BaseField( <clan> )
# checks if the qClan is linear.
##
InstallMethod( IsLinearqClan, 
	"for a qClan",
	[ IsqClanObj ],
	function( qclan )
		local blt;
		blt := BLTSetByqClan( qclan ); 
		return ProjectiveDimension(Span(blt)) = 2;
	end );

#############################################################################
#O  LinearqClan( <clan> )
# returns a linear qClan.
##
InstallMethod( LinearqClan,
	"for a prime power",
	[ IsPosInt ],
	function(q)
		local f, g, clan, n;
		if not IsPrimePowerInt(q) then
			Error("Argument must be a prime power");
		fi;
		n := First(GF(q), t -> not IsZero(t) and LogFFE(t, Z(q)^2) = fail);
		if n = fail then
			Error("Couldn't find nonsquare");
		fi;
		f := t -> 0 * Z(q)^0;
		g := t -> -n * t;
		clan := List(GF(q), t -> [[t, f(t)], [f(t), g(t)]]);
		clan := qClan(clan, GF(q));
		SetIsLinearqClan(clan, true);
		return clan;
	end );

#############################################################################
#O  FisherThasWalkerKantorBettenqClan( <q> )
# returns the Fisher Thas Walker Kantor Betten qClan
##
InstallMethod( FisherThasWalkerKantorBettenqClan, 
	"for a prime power",
	[ IsPosInt ],
	function(q)
		local f, g, clan;
		if not IsPrimePowerInt(q) then
			Error("Argument must be a prime power");
		fi;
		if q mod 3 <> 2 then
			Error("q must be congruent to 2 mod (3)");
		fi;
		f := t -> 3/2 * t^2;
		g := t -> 3 * t^3;
		clan := List(GF(q), t -> [[t, f(t)], [f(t), g(t)]]);
		return qClan(clan, GF(q));
	end );

#############################################################################
#O  KantorMonomialqClan( <q> )
# returns the Kantor Monomial qClan
##
InstallMethod( KantorMonomialqClan, 
	"for a prime power",
	[ IsPosInt ],
	function(q)
		local f, g, clan;
		if not IsPrimePowerInt(q) then
			Error("Argument must be a prime power");
		fi;
		if not q mod 5 in [2, 3] then
			Error("q must be congruent to 2 mod (3)");
		fi;
		f := t -> 5/2 * t^3;
		g := t -> 5 * t^5;
		clan := List(GF(q), t -> [[t, f(t)], [f(t), g(t)]]);
	return qClan(clan, GF(q));
end );

#############################################################################
#O  KantorKnuthqClan( <q> )
# returns the Kantor Knuth qClan
##
InstallMethod( KantorKnuthqClan, 
	"for a prime power",
	[ IsPosInt ],
	function(q)
		local f, g, clan, n, sigma;
		if not IsPrimePowerInt(q) then
			Error("Argument must be a prime power");
		fi;
		if IsPrime(q) then
			Error("q is a prime");
		fi;
		sigma := FrobeniusAutomorphism(GF(q));
		n := First(GF(q), t -> not IsZero(t) and LogFFE(t, Z(q)^2) = fail);
		if n = fail then
			Error("Couldn't find nonsquare");
		fi;
		f := t -> 0 * Z(q)^0;
		g := t -> -n * t^sigma;
		clan := List(GF(q), t -> [[t, f(t)], [f(t), g(t)]]);
		return qClan(clan, GF(q));
	end );

#############################################################################
#O  FisherqClan( <q> )
# returns the Fisher qClan
##
InstallMethod( FisherqClan,
	"for a prime power",
	[ IsPosInt ],
	function(q)
		local f, g, clan, n, zeta, omega, squares, nonsquares, i, z, a, t, j;
		if not IsPrimePowerInt(q) or IsEvenInt(q) then
			Error("Argument must be an odd prime power");
    fi;
	squares := ShallowCopy(AsList(Group(Z(q)^2)));; Add(squares, 0*Z(q));
	nonsquares := Difference(AsList(GF(q)),squares);;
	n := First(nonsquares, t -> t-1 in squares);

	zeta := PrimitiveRoot(GF(q^2));
	omega := zeta^(q+1);
	i := zeta^((q+1)/2);
	z := zeta^(q-1);
	a := (z+z^q)/2;
	clan := [];  
	for t in GF(q) do
	    if t^2-2/(1+a) in squares then 
	       Add(clan, [[t, 0],[0,-omega*t]] * Z(q)^0);
	    fi;
	od;

	for j in [0..(q-1)/2] do
	    Add(clan, [[-(z^(2*j+1)+z^(-2*j))/(z+1), i*(z^(2*j+1)-z^(-2*j))/(z+1)],
	       [i*(z^(2*j+1)-z^(-2*j))/(z+1), -omega*(z^(2*j+1)+z^(-2*j))/(z+1)]] * Z(q)^0 );
	od;

  return qClan(clan, GF(q));
end );

#############################################################################
#O  KantorFamilyByqClan( <clan> )
# returns the Kantor familyt corresponding with the q-Clan <clan>
##
InstallMethod( KantorFamilyByqClan, 
	"for a q-Clan",
    [ IsqClanObj and IsqClanRep ],
	function( clan )
    local g, q, f, i, omega, mat, at, ainf, ainfstar, clanmats,
          ainfgens, centregens, as, astars, k;
    f := clan!.basefield;
    clanmats := clan!.matrices;
    q := Size(f);
    i := One(f); 
    omega := PrimitiveElement(f);
    mat := function(a1,a2,c,b1,b2) 
             return i * [[1, a1, a2,  c], [0,  1,  0, b1],
                         [0,  0,  1, b2], [0,  0,  0,  1]];
           end;
    centregens := [mat(0,0,1,0,0), mat(0,0,omega,0,0)];
    ainfgens := [mat(0,0,0,1,0),mat(0,0,0,0,1),mat(0,0,0,omega,0),mat(0,0,0,0,omega)];
    ainf := Group(ainfgens); 
    ainfstar := Group(Union(ainfgens,centregens));

    at := function( m )
       ## returns generators for Kantor family element defined by q-Clan element m
       local a1, a2, k, gens, bas, zero;
       gens := [];
       bas := AsList(Basis(f));
       zero := Zero(f);
       for a1 in bas do
           k := [a1,zero] * (m+TransposedMat(m));
           Add(gens, mat(a1,zero,[a1,zero]*m*[a1,zero],k[1],k[2]) );
       od;

       for a2 in bas do
           k := [zero,a2] * (m+TransposedMat(m));
           Add(gens, mat(zero,a2,[zero,a2]*m*[zero,a2],k[1],k[2]) );
       od;    
       return gens;
    end;

    g := Group(Union( ainfgens, centregens, at(clanmats[1]) ));
    as := List(clanmats, m -> Group( at(m) ));
    Add(as, ainf);
    astars := List(clanmats, m -> Group(Union(at(m), centregens)));
    Add(astars, ainfstar);
    return [g, as, astars];
  end );

#############################################################################
#O  EGQByqClan( <clan> )
# returns the EGQ constructed from the q-Clan, using the corresponding Kantor family.
##
InstallMethod( EGQByqClan, 
	"for a q-Clan",
	[ IsqClanObj and IsqClanRep ],
	function( clan )
		local kantor;
		kantor := KantorFamilyByqClan( clan );
    
		Info(InfoFinInG, 1, "Computed Kantor family. Now computing EGQ...");
			return EGQByKantorFamily(kantor[1], kantor[2], kantor[3]);
  end );

#############################################################################
#O  IncidenceGraphOfGeneralisedPolygon( <gp> )
###
InstallMethod( IncidenceGraphOfGeneralisedPolygon,
    "for an ElationGQ in generic representation",
    [ IsElationGQ and IsGeneralisedPolygonRep ],
    function( gp )
    local points, lines, graph, adj, elationgroup, coll, act,sz;
    if not "grape" in RecNames(GAPInfo.PackagesLoaded) then
       Error("You must load the GRAPE package\n");
    fi;
    if IsBound(gp!.IncidenceGraphOfGeneralisedPolygonAttr) then
       return gp!.IncidenceGraphOfGeneralisedPolygonAttr;
    fi;
    points := AsList(Points(gp));  
    lines := AsList(Lines(gp));   
    Setter( HasGraphWithUnderlyingObjectsAsVertices )( gp, false);

    Info(InfoFinInG, 1, "Computing incidence graph of generalised polygon...");
    
	adj := function(x,y)
		if x!.type <> y!.type then
			return IsIncident(x,y);
		else
			return false;
		fi;
	end;
    sz := Size(points);

	if HasElationGroup(gp) then
		elationgroup := ElationGroup(gp);
		act := CollineationAction(elationgroup);
		graph := Graph(elationgroup,Concatenation(points,lines),act,adj,true);
	else
	   graph := Graph( Group(()), [1..sz+Size(lines)], OnPoints, adj );  
	fi;

    Setter( IncidenceGraphOfGeneralisedPolygonAttr )( gp, graph );
    return graph;
  end );


#############################################################################
#
#	BLT sets and q-Clans.
#
#############################################################################

#############################################################################
#O  BLTSetByqClan( <clan> )
# returns the BLT set corresponding with the q-Clan <clan>
##
InstallMethod( BLTSetByqClan, 
	"for a q-Clan",
	[ IsqClanObj and IsqClanRep ],
	function( clan )
    ##
    ## The q-clan must consist only of symmetric matrices
    ##
    local q, i, f,  blt, m, sesq, c1, c2, change, w, ps, x;
    f := clan!.basefield;
    q := Size(f);
    i := One(f); 
    blt := List(clan!.matrices, t -> [i, t[2][2], -t[1][2], t[1][1],  t[1][2]^2 -t[1][1]*t[2][2]]);
    Add(blt, [0,0,0,0,1]*i);  ## last point is distinguished point.
    for x in blt do
		ConvertToVectorRepNC(x,f);
	od;
	
    ## This BLT-set is in Q(4,q) defined by Gram matrix
    w := PrimitiveRoot(f);
    m := [[0,0,0,0,1],[0,0,0,1,0],[0,0,w^((q+1)/2),0,0],[0,1,0,0,0],[1,0,0,0,0]]*i;
    sesq := BilinearFormByMatrix(m, f);
    ps := PolarSpace( sesq );    
    return List(blt, x -> VectorSpaceToElement(ps, x)); 
end );

#############################################################################
#O  EGQByBLTSet( <blt>, <p>, <solid> )
# not documented yet.
##
InstallMethod( EGQByBLTSet, 
	"constructs an EGQ from a BLT-set of lines of W(3,q) via the Knarr construction",
	[IsList, IsSubspaceOfProjectiveSpace, IsSubspaceOfProjectiveSpace],
	function( blt, p, solid)
	## The point p is a point of W(5,q).
	## "solid" is a 3-space contained in P^perp
	## blt is a BLT-set of lines of W(3,q)

	local w3q, f, q, w5q, perp, pperp, res, x, pg5, gqpoints, gqpoints2,
         projpoints, gqlines, gqlines2, em, blt2, pis, info,
         geo, points, lines, ty, listels, inc, shadpoint, shadline;

	w3q := blt[1]!.geo;
	f := w3q!.basefield;
	q := Size(f);
	w5q := SymplecticSpace(5, f);
	perp := PolarMap(w5q);
	pperp := perp(p);
   
	## check everything is kosher
	if not solid in pperp then
		Error("Solid is not contained in perp of point");
	fi;
	if p in solid then
		Error("Chosen point is contained in the chosen solid");
	fi;

	pg5 := AmbientSpace( w5q );
	projpoints := ElementsOfIncidenceStructure(pg5, 1);
   
	Info(InfoFinInG, 1, "Computing points(1) of Knarr construction...");
   
	gqpoints := Filtered(projpoints, x -> not x in pperp);;
	Add(gqpoints, p);

	em := NaturalEmbeddingBySubspace(w3q, w5q, solid);
	blt2 := List(blt,t->t^em);

	Info(InfoFinInG, 1, "Computing lines(1) of Knarr construction...");
  
	pis := List(blt2, l -> Span(p, l));
	gqlines := pis;
	gqpoints2 := [];

	Info(InfoFinInG, 1, "Computing points(2) of Knarr construction...");

	for x in pis do
		res := ShadowOfElement(pg5, x, 2);
		res := Filtered(res, t -> not p in t);
		Append(gqpoints2, res);
	od;
	gqpoints2 := Set(gqpoints2); 

	Info(InfoFinInG, 1, "Computing lines(2) of Knarr construction... please wait");

	gqlines2 := [];
	#info := InfoLevel( InfoFinInG );
	#SetInfoLevel(InfoFinInG, 0);

	for x in gqpoints2 do
		res := Planes(w5q, x);
		res := Filtered(res, t -> not t in pperp);
		Append(gqlines2, res); 
	od;
	#SetInfoLevel(InfoFinInG, info);
 
	points := Concatenation(gqpoints, gqpoints2);
	lines := Concatenation(gqlines, gqlines2);
	
	inc := function(x,y)
		return IsIncident(x!.obj,y!.obj); #underlying objects are elements of a projective space
	end;
	
	listels := function(gp,i)
		if i = 1 then
			return List(gp!.pointsobj,x->Wrap(gp,i,x)); #saves memory :-)
		else
			return List(gp!.linesobj,x->Wrap(gp,i,x));
		fi;
	end;

	shadpoint := function(pt)
		return List(Filtered(lines,x->IsIncident(pt!.obj,x)),y->Wrap(pt!.geo,2,y));
	end;
	
	shadline := function(line)
		return List(Filtered(points,x->IsIncident(line!.obj,x)),y->Wrap(line!.geo,1,y));
	end;

	geo := rec( pointsobj := points, linesobj := lines, incidence := inc, listelements := listels, 
				shadowofpoint := shadpoint, shadowofline := shadline );
	ty := NewType( GeometriesFamily, IsElationGQ and IsGeneralisedPolygonRep);
	Objectify( ty, geo );

	SetBasePointOfEGQ( geo, Wrap(geo, 1, p) );  
	#SetAmbientSpace(geo, geo);
	SetOrder(geo, [q^2, q]);
	SetTypesOfElementsOfIncidenceStructure(geo, ["point","line"]);
    SetName(geo,Concatenation("<EGQ of order ",String([q^2,q])," and basepoint in W(5, ",String(q)," ) >"));
	return geo;
end );

#############################################################################
#O  EGQByBLTSet( <blt> )
##
InstallMethod( EGQByBLTSet, 
     "constructs an EGQ from a BLT-set of points of Q(4,q) via the Knarr construction",
     [ IsList ], 
  function( blt )   
   local q4q, f, w3q, duality, w5q, p, pg5, solid, 
         q4qcanonical, iso, bltdual, geo, bas, 
         mat, elations, a, gens, zero, action, b;
   q4q := AmbientGeometry( blt[1] );
   f := q4q!.basefield;
   w3q := SymplecticSpace(3, f);
   duality := NaturalDuality( w3q );
   w5q := SymplecticSpace(5, f);
   p := VectorSpaceToElement(w5q, [1,0,0,0,0,0] * One(f));
   pg5 := AmbientSpace( w5q );
   solid := VectorSpaceToElement(pg5, [[1,0,0,0,0,1],[0,0,1,0,0,0],
                                       [0,0,0,1,0,0],[0,0,0,0,1,0]]*One(f));
   q4qcanonical := Range(duality)!.geometry;                 
   iso := IsomorphismPolarSpaces(q4q, q4qcanonical);
   bltdual := PreImagesSet(duality, ImagesSet(iso, blt));

   Info(InfoFinInG, 1, "Now embedding dual BLT-set into W(5,q)...");

   geo := EGQByBLTSet( bltdual, p, solid);

   ## Now we construct the elation group. See Maska Law's Thesis for details 
   ## (we have a different form though, so we need to apply a base change).

   Info(InfoFinInG, 1, "Computing elation group...");

   mat := function(a,b,c,d,e)
            local m;
            m := IdentityMat(6, f);
            m[6]{[1..5]} := [e,d,c,-b,-a];
            m[2][1] := a; m[3][1] := b; m[4][1] := c; m[5][1] := d;
            return m;
          end;
   bas := AsList(Basis(f));
   gens := [];
   zero := Zero(f);
   for a in bas do
       Add(gens, mat(a,zero,zero,zero,zero) );
       Add(gens, mat(zero,a,zero,zero,zero) );
       Add(gens, mat(zero,zero,a,zero,zero) );
       Add(gens, mat(zero,zero,zero,a,zero) );
       Add(gens, mat(zero,zero,zero,zero,a) );
   od;
   ## base change 
   b := [ [ 1, 0, 0, 0, 0, 0 ], [ 0, 0, 0, 0, 0, 1 ], 
          [ 0, 1, 0, 0, 0, 0 ], [ 0, 0, 0, 0, 1, 0 ], 
          [ 0, 0, 1, 0, 0, 0 ], [ 0, 0, 0, 1, 0, 0 ] ];
   gens := List(gens, t-> b*t*b^-1);
   gens := List(gens, t -> CollineationOfProjectiveSpace(t,f));
   elations := Group( gens ); 
   SetElationGroup( geo, elations );

   action := function(el, x)
               return Wrap( geo, el!.type, OnProjSubspaces(el!.obj, x));
             end;
   SetCollineationAction( elations, action );
   return geo;
 end );

#############################################################################
#O  FlockGQByqClan( <clan> )
# returns the BLT set corresponding with the q-Clan <clan>
# not documented yet.
##
InstallMethod( FlockGQByqClan, [ IsqClanObj ],
 function( qclan )
  local f, q, mat, form, w5, p, blt, x, perp, pperp, pg5, a, bas, gens, zero, elations, action,
        projpoints, gqpoints, gqlines, gqpoints2, gqlines2, res, geo, ty, points, lines, clan,
		pgammasp, stabp, stabblt, hom, omega, imgs, bltvecs;
  f := qclan!.basefield;
  clan := qclan!.matrices; 
  q := Size(f);
  if not IsOddInt(q) then 
       Error("Invalid input"); return;
  fi;

  mat := [[0,0,0,0,0,1],[0,0,0,0,1,0],[0,0,0,1,0,0],
          [0,0,-1,0,0,0],[0,-1,0,0,0,0],[-1,0,0,0,0,0]] * Z(q)^0;
  form := BilinearFormByMatrix(mat, GF(q));
  w5 := PolarSpace( form );
  p := VectorSpaceToElement(w5, [1,0,0,0,0,0] * Z(q)^0);

  blt := [ VectorSpaceToElement(w5, [[1,0,0,0,0,0], [0,0,0,1,0,0],[0,0,0,0,1,0]]*One(f)) ];
  
	bltvecs := List(clan,x->[[1,0,0,0,0,0], [0,1,0,x[1][2],x[1][1],0], [0,0,1,x[2][2],x[1][2],0]] * One(f));
	for x in bltvecs do
		ConvertToMatrixRepNC(x,f);
	od;
  
  #for x in clan do
  #    Add(blt, VectorSpaceToElement(w5, [[1,0,0,0,0,0], [0,1,0,x[1][2],x[1][1],0], [0,0,1,x[2][2],x[1][2],0]] * One(f)));
  #od;
		
	for x in bltvecs do
		Add(blt,VectorSpaceToElement(w5,x));
	od;
    Info(InfoFinInG, 1, "Making flock GQ...");

  perp := PolarMap(w5);;
  pperp := perp(p);
  pg5 := AmbientSpace( w5 );;
  projpoints := Points(pg5);;

	Info(InfoFinInG, 1, "...points outside of perp of P...");

  gqpoints := Filtered(projpoints, x -> not x in pperp);;
  Add(gqpoints, p);

  gqlines := ShallowCopy(blt);;
  gqpoints2 := [];;

    Info(InfoFinInG, 1, "...lines contained in some BLT-set element...");

  for x in gqlines do
      res := ShadowOfElement(pg5, x, 2);
      res := Filtered(res, t -> not p in t);
      Append(gqpoints2, res);
  od;
  gqpoints2 := Set(gqpoints2);;
  gqlines2 := [];;
  
    Info(InfoFinInG, 1, "...planes meeting some BLT-set element in a line...");
  for x in gqpoints2 do 
      res := ShadowOfFlag(pg5, [x,perp(x)], 3);
      res := Filtered(res, t -> not p in t);  
      Append(gqlines2, res); 
  od;

    Info(InfoFinInG, 1, "...sorting the points and lines...");  

  points := SortedList( Concatenation(gqpoints, gqpoints2) );;
  lines := SortedList( Concatenation(gqlines, gqlines2) );;

  geo := rec( points := points, lines := lines, incidence := IsIncident);;

  ty := NewType( GeometriesFamily, IsElationGQ and IsGeneralisedPolygonRep);
  Objectify( ty, geo );
  SetBasePointOfEGQ( geo, Wrap(geo, 1, p) );  
  SetAmbientSpace(geo, w5);
  SetOrder(geo, [q^2, q]);
  SetTypesOfElementsOfIncidenceStructure(geo, ["point","line"]);

  Info(InfoFinInG, 1, "Computing collineation group in PGammaSp(6,q)...");
  pgammasp := CollineationGroup( w5 );
  stabp := SetwiseStabilizer(pgammasp, OnProjSubspaces, [p])!.setstab;

  Info(InfoFinInG, 1, "..computed stabiliser of P");

  ## compute the stabiliser of the BLT-set differently...

  hom := ActionHomomorphism(stabp, AsList(Planes(p)), OnProjSubspaces, "surjective"); 
  omega := HomeEnumerator(UnderlyingExternalSet(hom));;
  imgs := Filtered([1..Size(omega)], x -> omega[x] in blt);;
  stabblt := Stabilizer(Image(hom), imgs, OnSets);
  gens := GeneratorsOfGroup(stabblt);
  gens := List(gens, x -> PreImagesRepresentative(hom, x));
  stabblt := GroupWithGenerators(gens);

  Info(InfoFinInG, 1, "..computed stabiliser of BLT set");

###  stabblt := SetwiseStabilizer(stabp, OnProjSubspaces, blt)!.setstab;  

  SetCollineationGroup( geo, stabblt );
  action := function(el, x)
               return Wrap( geo, el!.type, OnProjSubspaces(el!.obj, x));
             end;
  SetCollineationAction( stabblt, action );

  ## Now we construct the elation group. See Maska Law's Thesis for details 

  Info(InfoFinInG, 1, "Computing elation group...");
  mat := function(a,b,c,d,e)
            local m;
            m := IdentityMat(6, f);
            m[6]{[1..5]} := [e,d,c,-b,-a];
            m[2][1] := a; m[3][1] := b; m[4][1] := c; m[5][1] := d;
            return m;
         end;
  bas := AsList(Basis(f));
  gens := [];
  zero := Zero(f);
  for a in bas do
       Add(gens, mat(a,zero,zero,zero,zero) );
       Add(gens, mat(zero,a,zero,zero,zero) );
       Add(gens, mat(zero,zero,a,zero,zero) );
       Add(gens, mat(zero,zero,zero,a,zero) );
       Add(gens, mat(zero,zero,zero,zero,a) );
  od;
  gens := List(gens, t -> CollineationOfProjectiveSpace(t,f));
  elations := SubgroupNC( stabblt, gens ); 
  SetElationGroup( geo, elations );
  SetCollineationAction( elations, action );

  return geo;
end );

