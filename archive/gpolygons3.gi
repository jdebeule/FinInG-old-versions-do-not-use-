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

#############################################################################
#
# Construction of GPs
#
#############################################################################

InstallMethod( GeneralisedPolygonByBlocks,
    "for a homogeneous list",
    [ IsHomogeneousList ],
    function( blocks )
        local pts, gp, ty, i, graph, sz, adj, girth, shadpoint, shadline, s, t, dist, vn, 
		listels;
        pts := Union(blocks);
        s := Size(blocks[1]) - 1;
        if not ForAll(blocks, b -> Size(b) = s + 1 ) then
            Error("Not every block has size ", s + 1);
        fi;
        
        i := function( x, y )
        if IsSet( x ) and not IsSet( y ) then
            return y in x;
        elif IsSet( y ) and not IsSet( x ) then
            return x in y;
        else
            return false;
        fi;
        end;
        
        sz := Size(pts);
        
        adj := function(x,y)
             if x <= sz and y > sz then
                return x in blocks[y-sz];
             elif y <= sz and x > sz then
                return y in blocks[x-sz];
             else
                return false;
             fi;
        end;

        graph := Graph(Group(()), [1..sz+Size(blocks)], OnPoints, adj );
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
		t := Length(Adjacency(graph,1)); # number of linbes on a point minus 1.

        dist := function( el1, el2 )
            return Distance(graph,Position(vn,el1!.obj),Position(vn,el2!.obj));
        end;

        gp := rec( points := pts, lines := blocks, incidence := i, listelements := listels, 
					shadowofpoint := shadpoint, shadowofline := shadline, distance := dist );

        Objectify( ty, gp );
        SetTypesOfElementsOfIncidenceStructure(gp, ["point","line"]);
        SetOrder(gp, [s, t]);
        SetRankAttr(gp, 2);
        Setter( IncidenceGraphOfGeneralisedPolygonAttr )( gp, graph );
        return gp;
  end );

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

InstallMethod( GeneralisedPolygonByElements,
    "for two sets (points and lines), and an incidence function",
    [ IsSet, IsSet, IsFunction ],
    function( pts, lns, inc )
    local adj, act, graph, ty, girth, shadpoint, shadline, s, t, 
	gp, vn, dist, listels;

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

    graph := Graph(Group(()), Union(pts,lns), act, adj, true );
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
    
    gp := rec( points := pts, lines := lns, incidence := inc, listelements := listels, 
				shadowofpoint := shadpoint, shadowofline := shadline, distance := dist );

    Objectify( ty, gp );
	SetOrder(gp, [s,t] );
    SetTypesOfElementsOfIncidenceStructure(gp, ["point","line"]);
    Setter( IncidenceGraphOfGeneralisedPolygonAttr )( gp, graph );
    return gp;
end );

InstallMethod( GeneralisedPolygonByElements,
    "for two sets (points and lines), and an incidence function",
    [ IsSet, IsSet, IsFunction, IsGroup, IsFunction ],
    function( pts, lns, inc, group, act )
    local adj, graph, ty, girth, shadpoint, shadline, s, t, gp, vn, 
	dist, listels;

    adj := function(x,y)
    if x in pts and y in pts then
        return false;
    elif x in lns and y in lns then
        return false;
    else
        return inc(x,y);
    fi;
    end;

    graph := Graph(group, Union(pts,lns), act, adj, true );
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
    
    gp := rec( points := pts, lines := lns, incidence := inc, listelements := listels, 
				shadowofpoint := shadpoint, shadowofline := shadline, distance := dist );

    Objectify( ty, gp );
	SetOrder(gp, [s,t] );
    SetTypesOfElementsOfIncidenceStructure(gp, ["point","line"]);
    Setter( IncidenceGraphOfGeneralisedPolygonAttr )( gp, graph );
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
# Basic methods to construct elements and iterators
#
#############################################################################

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
#O  IsIncident( <vs>  )
# simply uses the incidence relation that is built in in the gp.
##
InstallMethod( IsIncident, 
	"for elements of a generalised polygon", 
    [IsElementOfGeneralisedPolygon, IsElementOfGeneralisedPolygon],
	function( x, y )
		local inc;
		inc := x!.geo!.incidence;
		return inc(x!.obj, y!.obj);
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
#O  Distance( <gp>, <el1>, <el2> )
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
#
##
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
    fi;
    points := AsList( Points( gp ) );;  
    lines := AsList( Lines( gp ) );;    

    Info(InfoFinInG, 1, "Computing incidence graph of generalised polygon...");
    
    sz := Size(points);
    adj := function(i,j)
             if i <= sz and j > sz then
                return points[i] * lines[j-sz];
             elif j <= sz and i > sz then
                return points[j] * lines[i-sz];
             else
                return false;
             fi;
           end;

	if HasCollineationGroup(gp) then
	   coll := CollineationGroup(gp);
	   gg := Action(coll, Concatenation(points, lines));  ## here we have not assumed an action!
	   graph := Graph( gg, [1..sz+Size(lines)], OnPoints, adj );  
	elif IsElationGQ(gp) and HasElationGroup( gp ) then
	   elations := ElationGroup(gp);
	   gg := Action(elations, Concatenation(points, lines), CollineationAction( elations ) );
	   graph := Graph( gg, [1..sz+Size(lines)], OnPoints, adj );  
	else
	   graph := Graph( Group(()), [1..sz+Size(lines)], OnPoints, adj );  
	fi;

    Setter( IncidenceGraphOfGeneralisedPolygonAttr )( gp, graph );
    return graph;
  end );


#############################################################################
#
# Part II: particular models of GPs.
#
#############################################################################

#############################################################################
#
#  Generalised Hexagons
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
	[IsGeneralisedHexagon and IsLieGeometry, IsPosInt, IsObject],
	function( geo, type, o )
		local w;
		w := rec( geo := geo, type := type, obj := o );
		Objectify( NewType( SoPSFamily, IsElementOfIncidenceStructureRep and IsElementOfGeneralisedPolygon 
			and IsSubspaceOfClassicalPolarSpace ), w );
		return w;
  end );

InstallGlobalFunction( SplitCayleyPointToPlane5,
    function(el)
        local z, hyps, q, y, planevec, basishyp, hyp, bs, invbasis, vec, w;
        q := Size(BaseField(el));
        w := Unpack(UnderlyingObject(el));
        y := w{[1..3]};
        y{[5..7]} := w{[4..6]};
        y[4] := (y[1]*y[5]+y[2]*y[6]+y[3]*y[7])^(q/2);
        y[8] := -y[4];
        z := [];
        z[1] := [0,y[3],-y[2],y[5],y[8],0,0,0]*Z(q)^0;
        z[2] := [-y[3],0,y[1],y[6],0,y[8],0,0]*Z(q)^0;
        z[3] := [y[2],-y[1],0,y[7],0,0,y[8],0]*Z(q)^0;
        z[4] := [0,0,0,-y[4],y[1],y[2],y[3],0]*Z(q)^0;
        z[5] := [y[4],0,0,0,0,y[7],-y[6],y[1]]*Z(q)^0;
        z[6] := [0,y[4],0,0,-y[7],0,y[5],y[2]]*Z(q)^0;
        z[7] := [0,0,y[4],0,y[6],-y[5],0,y[3]]*Z(q)^0;
        z[8] := [y[5],y[6],y[7],0,0,0,0,-y[8]]*Z(q)^0;
        z := Filtered(z,x->not IsZero(x));
        hyp := [0,0,0,1,0,0,0,1]*Z(q)^0;
        Add(z,[0,0,0,1,0,0,0,1]*Z(q)^0);
        planevec := NullspaceMat(TransposedMat(z));
        basishyp := NullspaceMat(TransposedMat([hyp]));
        bs := BaseSteinitzVectors(Basis(GF(q)^8), basishyp);
        invbasis := Inverse(Concatenation(bs!.subspace, bs!.factorspace));
        vec := planevec*invbasis;
        return vec{[1..3]}{[1,2,3,5,6,7]};
    end );


InstallGlobalFunction( SplitCayleyPointToPlane,
	function(el)
		local z, hyps, q, y, planevec, basishyp, hyp, bs, invbasis, vec;
		q := Size(BaseField(el));
		y := Unpack(UnderlyingObject(el));
		y[8] := -y[4];
		z := [];
		z[1] := [0,y[3],-y[2],y[5],y[8],0,0,0]*Z(q)^0;
		z[2] := [-y[3],0,y[1],y[6],0,y[8],0,0]*Z(q)^0;
		z[3] := [y[2],-y[1],0,y[7],0,0,y[8],0]*Z(q)^0;
		z[4] := [0,0,0,-y[4],y[1],y[2],y[3],0]*Z(q)^0;
		z[5] := [y[4],0,0,0,0,y[7],-y[6],y[1]]*Z(q)^0;
		z[6] := [0,y[4],0,0,-y[7],0,y[5],y[2]]*Z(q)^0;
		z[7] := [0,0,y[4],0,y[6],-y[5],0,y[3]]*Z(q)^0;
		z[8] := [y[5],y[6],y[7],0,0,0,0,-y[8]]*Z(q)^0;
		z := Filtered(z,x->not IsZero(x));
		hyp := [0,0,0,1,0,0,0,1]*Z(q)^0;
		Add(z,[0,0,0,1,0,0,0,1]*Z(q)^0);
		planevec := NullspaceMat(TransposedMat(z));
		basishyp := NullspaceMat(TransposedMat([hyp]));
		bs := BaseSteinitzVectors(Basis(GF(q)^8), basishyp);
		invbasis := Inverse(Concatenation(bs!.subspace, bs!.factorspace));
		vec := planevec*invbasis;
		return vec{[1..3]}{[1..7]};
	end );

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
    local geo, ty, repline, reppointvect, reppoint, replinevect,
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
            planevec := SplitCayleyPointToPlane( pt );
            plane := VectorSpaceToElement(PG(6,f),planevec);
            flag := FlagOfIncidenceStructure(PG(6,f),[pt,plane]);
            return List(ShadowOfFlag(PG(6,f),flag,2),x->Wrap(pt!.geo,2,Unwrap(x)));
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
            planevec := SplitCayleyPointToPlane5( pt );
            plane := VectorSpaceToElement(PG(5,f),planevec);
            flag := FlagOfIncidenceStructure(PG(5,f),[pt,plane]);
            return List(ShadowOfFlag(PG(5,f),flag,2),x->Wrap(pt!.geo,2,Unwrap(x)));
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
	geo := rec( points := [], lines := [], incidence:= \*, listelements := listels, basefield := BaseField(ps), 
		dimension := Dimension(ps), vectorspace := UnderlyingVectorSpace(ps), polarspace := ps, 
		shadowofpoint := shadpoint, shadowofline := shadline);
    ty := NewType( GeometriesFamily,
             IsGeneralisedHexagon and IsGeneralisedPolygonRep and IsLieGeometry ); #change by jdb 7/12/11
    Objectify( ty, geo );
    SetAmbientSpace(geo, AmbientSpace(ps));
    SetAmbientPolarSpace(geo,ps);
    SetOrder(geo, [Size(f), Size(f)]);
    SetTypesOfElementsOfIncidenceStructure(geo, ["point","line"]);

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
    SetName(geo,Concatenation("Split Cayley Hexagon of order ", String(Size(f))));
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

#############################################################################
#A  CollineationGroup( <hexagon> )
# computes the collineation group of a (classical) generalised hexagon
##

InstallMethod( CollineationGroup,
	"for a generalised hexagon",
	[ IsGeneralisedHexagon ],
  function( hexagon )
    local f, q, pps, frob, sigma, m, mp, ml, nonzerof, nonzeroq, w, 
          gens, newgens, x, coll, orblen, hom, domain, rep;

    if Size(Set(Order(hexagon))) > 1 then
       Info(InfoFinInG, 1, "for Twisted Triality Hexagon");
       f := hexagon!.basefield;
       ## field must be GF(q^3);
       q := RootInt(Size(f), 3);
	 if not q^3 = Size(f) then
         Error("Field order must be a cube of a prime power");
       fi;
       pps := Characteristic(f);
       frob := FrobeniusAutomorphism(f);
       sigma := frob^LogInt(q,pps);    ## automorphism of order 3

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
       for x in gens do
           ConvertToMatrixRep(x, f);
       od;
       newgens := List(gens, x -> CollineationOfProjectiveSpace(x,f));
       coll := GroupWithGenerators(newgens);

       Info(InfoFinInG, 1, "Computing nice monomorphism...");
       orblen := (q+1)*(q^8+q^4+1);
       rep := RepresentativesOfElements(hexagon)[2];
	   domain := Orb(coll, rep, OnProjSubspaces, 
                    rec(orbsizelimit := orblen, hashlen := 2*orblen, storenumbers := true));
       Enumerate(domain);
       Info(InfoFinInG, 1, "Found permutation domain...");
	   hom := OrbActionHomomorphism(coll, domain);   
		
       #hom := NiceMonomorphismByOrbit(coll, rep,
	   #            OnProjSubspaces, orblen );
	 
 	   SetIsBijective(hom, true);
       ## for some reason, hom has not stored a prefun

	   SetNiceObject(coll, Image(hom) );
       SetNiceMonomorphism(coll, hom );
       SetCollineationAction(coll, OnProjSubspaces);
       SetName(coll, Concatenation("4D_3(",String(q),")") );
   else 
       Info(InfoFinInG, 1, "for Split Cayley Hexagon");

      # The generators of G2(q) were taken from Hendrik 
      # van Maldeghem's book: "Generalized Polygons".
      # Lines with ** are where there are mistake's in
      # Hendrik's book (see Alan Offer's thesis).
      
      f := hexagon!.basefield;
      q := Size(f);
      if IsOddInt(Size(f)) then
         m:=[[ 0, 0, 0, 0, 0, 1, 0],
             [ 0, 0, 0, 0, 0, 0, 1],
             [ 0, 0, 0, 0, 1, 0, 0],
             [ 0, 0, 0, -1, 0, 0, 0],               ## **
             [ 0, 1, 0, 0, 0, 0, 0],
             [ 0, 0, 1, 0, 0, 0, 0],
             [ 1, 0, 0, 0, 0, 0, 0]]*One(f);  
         ConvertToMatrixRep(m, f);
         mp:=d->[[1,  0,  0,  0,  0,  d,  0],  
             [0,  1,  0,  0, -d,  0,  0],  
             [0,  0,  1,  0,  0,  0,  0],  
             [0,  0,  2*d,  1,  0,  0,  0],         ## **
             [0,  0,  0,  0,  1,  0,  0],  
             [0,  0,  0,  0,  0,  1,  0],  
             [0,  0,d^2,  d,  0,  0,  1]]*One(f);   ## **
         ml:=d->[[1, -d,  0,  0,  0,  0,  0],  
             [0,  1,  0,  0,  0,  0,  0],  
             [0,  0,  1,  0,  0,  0,  0],  
             [0,  0,  0,  1,  0,  0,  0],  
             [0,  0,  0,  0,  1,  0,  0],  
             [0,  0,  0,  0,  d,  1,  0],  
             [0,  0,  0,  0,  0,  0,  1]]*One(f);
  
         nonzerof := AsList(f){[2..Size(f)]};
         gens := Union([m], List(nonzerof, mp), List(nonzerof, ml));
         for x in gens do
            ConvertToMatrixRep(x, f);
         od;
         frob := FrobeniusAutomorphism(f); 
         newgens := List(gens, x -> CollineationOfProjectiveSpace(x, f));  
         if not IsPrimeInt(Size(f)) then 
            Add(newgens, CollineationOfProjectiveSpace( IdentityMat(7,f), frob, f )); 
         fi; 
         coll := GroupWithGenerators(newgens);
       else
          ## Here we embed the hexagon in W(5,q)
          m:=[[ 0, 0, 0, 0, 1, 0],
              [ 0, 0, 0, 0, 0, 1],
              [ 0, 0, 0, 1, 0, 0],
              [ 0, 1, 0, 0, 0, 0],
              [ 0, 0, 1, 0, 0, 0],
              [ 1, 0, 0, 0, 0, 0]]*One(f);  
            ConvertToMatrixRep( m );
          mp:=d->[[1,  0,  0,  0,  d,  0],  
              [0,  1,  0,  d,  0,  0],  
              [0,  0,  1,  0,  0,  0],  
              [0,  0,  0,  1,  0,  0],  
              [0,  0,  0,  0,  1,  0],  
              [0,  0,d^2,  0,  0,  1]]*One(f);  
          ml:=d->[[1,  d,  0,  0,  0,  0],  
              [0,  1,  0,  0,  0,  0],  
              [0,  0,  1,  0,  0,  0],  
              [0,  0,  0,  1,  0,  0],  
              [0,  0,  0,  d,  1,  0],  
              [0,  0,  0,  0,  0,  1]]*One(f);
          nonzerof := AsList(f){[2..Size(f)]};
          gens := Union([m], List(nonzerof,mp), List(nonzerof,ml));

          for x in gens do
             ConvertToMatrixRep(x,f);
          od;
          frob := FrobeniusAutomorphism(f); 
          newgens := List(gens, x -> CollineationOfProjectiveSpace(x, f));  
          if not IsPrimeInt(Size(f)) then 
             Add(newgens, CollineationOfProjectiveSpace( IdentityMat(6,f), frob, f )); 
          fi;
          coll := GroupWithGenerators(newgens);

       fi; 

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
       if IsPrime(Size(f)) then
          SetName(coll, Concatenation("G_2(",String(Size(f)),")") );
       else
          SetName(coll, Concatenation("G_2(",String(Size(f)),").", String(Order(frob))) );
       fi;

   fi;
   return coll;
  end );




