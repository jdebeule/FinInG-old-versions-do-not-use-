#############################################################################
##
##  group.gi              FinInG package
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
##  Copyright 2008 University of Western Australia, Perth
##                 Lehrstuhl D fuer Mathematik, RWTH Aachen
##                 Ghent University
##                 Colorado State University
##                 Vrije Universiteit Brussel
##
##  Implementation stuff for some new group representations
##
#############################################################################

########################################
#
# Things To Do:
#
# - Order for a projective semlinear element
# - GammaOminus (q even)
# - Optimise the action operations/functions
# - Have ProjEl, ProjElWithFrob, and ProjElWithFrobWithVSIsom
#   all compatible (can multiply them etc)
# - homography groups need only have ProjEl, it will make them quicker
# - testing
#
########################################

## helping function. came from projectivespace.gi

InstallGlobalFunction( MakeAllProjectivePoints, 
function(f,d)

  # f is a finite field
  # d an integer >= 1
  # This function is used for computing the permutation representation (NiceMonomorphism)
  # quickly and with the least memory used as possible, for a projective group.
  # Later, we will convert everything here to CVec's, which should give us an
  # improved permutation representation. For example:
  #   gap> pg:=PG(5,5);
  #   ProjectiveSpace(5, 5)
  #   gap> g:=ProjectivityGroup(pg);
  #   PGL(6,5)
  #   gap> hom := NiceMonomorphism(g);
  #   <action isomorphism>
  #   gap> omega:=UnderlyingExternalSet(hom);;
  #   gap> Random(omega);
  #   ## returns a compressed vector

  local els,i,j,l,q,sp,v,vs,w,ww,x;
  els := Elements(f);
  q := Length(els);
  v := ListWithIdenticalEntries(d+1,Zero(f));
  if q <= 256 then ConvertToVectorRep(v,q); fi;
  vs := EmptyPlist(q^d);
  sp := EmptyPlist((q^(d+1)-1)/(q-1));
  for x in els do
    w := ShallowCopy(v);
    w[d+1] := x;
    Add(vs,w);
  od;
  w := ShallowCopy(v);
  w[d+1] := One(f);
  Add(sp,w);
  for i in [d,d-1..1] do
    l := Length(vs);
    for j in [1..l] do
      ww := ShallowCopy(vs[j]);
      ww[i] := One(f);
      Add(sp,ww);
      Add(vs,ww);
    od;
    if i > 1 then
        for x in els do
          if not(IsZero(x)) and not(IsOne(x)) then
            for j in [1..l] do
              ww := ShallowCopy(vs[j]);
              ww[i] := x;
              Add(vs,ww);
            od;
          fi;
        od;
    fi;
  od;
  return Set(sp);
end);


###################################################################
# Use friendly code which makes projectivities and collineations
# these user fiendly functions do some checks.
###################################################################

InstallMethod( Projectivity, [ IsMatrix and IsFFECollColl, IsField],
  function( mat, gf )
    local el, m2;
    
    ## A bug was found here, during a nice August afternoon involving pigeons,
    ## where the variable m2 was assigned to the size of the field.
    ## jdb 13/12/08, Giessen, cold saturday afternoon. I still remember the
    ## pigeons, so does my computer. I add some lines now to check whether the
    ## matrix is non singular. 
    m2 := ShallowCopy( mat );
    if Rank(m2) <> Size(m2) then
      Error("<mat> must not be singular");
    fi;
    ConvertToMatrixRepNC( m2, gf );
    el := rec( mat := m2, fld := gf );
    Objectify( NewType( ProjElsFamily,
                        IsProjGrpEl and
                        IsProjGrpElRep ), el );
    return el;  
  end );
  

InstallMethod( ProjectivityByImageOfStandardFrameNC, [ IsProjectiveSpace, IsList ],
	function(pg,image)
	# If the dimension of the projective space is n, then
	# given a frame, there is a 
	# unique projectivity mapping the standard frame to this set of points
	# THERE IS NO CHECK TO SEE IF THE GIVEN IMAGE CONSISTS OF N+2 POINTS NO N+1 L.D.
	local d,i,x,vlist,mat,coeffs,mat2;
	if not Length(image)=Dimension(pg)+2 then 
	Error("The argument does not have the required length to be the image of a frame");
	fi;
	d:=Dimension(pg);
	vlist:=List(image,x->x!.obj);
	mat:=List([1..d+1],i->vlist[i]);
	coeffs:=vlist[d+2]*(mat^-1);
	mat2:=List([1..d+1],i->coeffs[i]*mat[i]);
	return CollineationOfProjectiveSpace(mat2,pg!.basefield);
end );




InstallMethod( ProjectiveSemilinearMap, 
  [ IsMatrix and IsFFECollColl, IsField],
  function( mat, gf )
    if Rank(mat) <> Size(mat) then
      Error("<mat> must not be singular");
    fi;
    return ProjElWithFrob( mat, IdentityMapping(gf), gf);
  end );
  
InstallMethod( ProjectiveSemilinearMap,  
  [ IsMatrix and IsFFECollColl, IsRingHomomorphism and
    IsMultiplicativeElementWithInverse, IsField], 
  function( mat, frob, gf )
    if Rank(mat) <> Size(mat) then
      Error("<mat> must not be singular");
    fi;
    return ProjElWithFrob( mat, frob, gf);
  end );

InstallMethod( UnderlyingMatrix, [ IsProjGrpEl and IsProjGrpElRep],
  c -> c!.mat );
  
InstallMethod( UnderlyingMatrix, [ IsProjGrpElWithFrob and 
                                   IsProjGrpElWithFrobRep],
  c -> c!.mat );
  
InstallMethod( FieldAutomorphism, [ IsProjGrpElWithFrob and 
                                    IsProjGrpElWithFrobRep],
  c -> c!.frob );


###################################################################
# Code for "projective elements", that is matrices modulo scalars:
###################################################################

## A lot of the following is now obselete. We should consider
## deleting some of it.

InstallMethod( ProjEl, "for a ffe matrix",
  [IsMatrix and IsFFECollColl],
  function( m )
    local el, m2, f;
    f := DefaultFieldOfMatrix(m);
    m2 := ConvertToMatrixRepNC( m, f );
    el := rec( mat := m2, fld := f );
    Objectify( NewType( ProjElsFamily,
                        IsProjGrpEl and
                        IsProjGrpElRep ), el );
    return el;
  end );

InstallMethod( ProjEls, "for a list of ffe matrices",
  [IsList],
  function( l )
    local el,fld,ll,m,ty,m2;
    fld := FieldOfMatrixList(l);
    ll := [];
    ty := NewType( ProjElsFamily,
                   IsProjGrpEl and
                   IsProjGrpElRep );
    for m in l do
        m2 := ConvertToMatrixRepNC( m, fld );
        el := rec( mat := m, fld := fld );
        Objectify( ty, el );
        Add(ll,el);
    od;
    return ll;
  end );

InstallMethod( ViewObj, "for a projective group element",
  [IsProjGrpEl and IsProjGrpElRep],
  function(el)
    Print("<projective element ");
    ViewObj(el!.mat);
    Print(">");
  end);

InstallMethod( Display, "for a projective group element",
  [IsProjGrpEl and IsProjGrpElRep],
  function(el)
    Print("<projective element, underlying matrix:\n");
    Display(el!.mat);
    Print(">\n");
  end );

InstallMethod( PrintObj, "for a projective group element",
  [IsProjGrpEl and IsProjGrpElRep],
  function(el)
    Print("ProjEl(");
    PrintObj(el!.mat);
    Print(")");
  end );
  
InstallOtherMethod( Representative, "for a projective group element",
  [IsProjGrpEl and IsProjGrpElRep],
  function( el )
    return el!.mat;
  end );

InstallMethod( BaseField, "for a projective group element",
  [IsProjGrpEl and IsProjGrpElRep],
  function( el )
    return el!.fld;
  end );

InstallMethod( \=, "for two projective group elements",
  [IsProjGrpEl and IsProjGrpElRep, IsProjGrpEl and IsProjGrpElRep],
  function( a, b )
    local aa,bb,p,s,i;
    if a!.fld <> b!.fld then Error("different base fields"); fi;
    aa := a!.mat;
    bb := b!.mat;
    p := PositionNonZero(aa[1]);
    s := bb[1][p] / aa[1][p];
    for i in [1..Length(aa)] do
        if s*aa[i] <> bb[i] then return false; fi;
    od;
    return true;
  end );

InstallMethod(\<,
  [IsProjGrpEl, IsProjGrpEl],
  function(a,b)
    local aa,bb,pa,pb,sa,sb,i,va,vb;
    if a!.fld <> b!.fld then Error("different base fields"); fi;
    aa := a!.mat;
    bb := b!.mat;
    pa := PositionNonZero(aa[1]);
    pb := PositionNonZero(bb[1]);
    if pa > pb then 
        return true;
    elif pa < pb then
        return false;
    fi;
    sa := aa[1][pa]^-1;
    sb := bb[1][pb]^-1;
    for i in [1..Length(aa)] do
        va := sa*aa[i];
        vb := sb*bb[i];
        if va < vb then return true; fi;
        if vb < va then return false; fi;
    od;
    return false;
  end);

InstallMethod( Order, "for a projective group element",
  [IsProjGrpEl and IsProjGrpElRep],
  function( a )
    return ProjectiveOrder(a!.mat)[1];
  end );

InstallMethod( IsOne, "for a projective group element",
  [IsProjGrpEl and IsProjGrpElRep],
  function( el )
    local s;
    s := el!.mat[1][1];
    if IsZero(s) then return false; fi;
    s := s^-1;
    return IsOne( s*el!.mat );
  end );

InstallMethod( \*, "for two projective group elements",
  [IsProjGrpEl and IsProjGrpElRep, IsProjGrpEl and IsProjGrpElRep],
  function( a, b )
    local el;
    el := rec( mat := a!.mat * b!.mat, fld := a!.fld );
    Objectify( ProjElsType, el );
    return el;
  end );

InstallMethod( InverseSameMutability, "for a projective group element",
  [IsProjGrpEl and IsProjGrpElRep],
  function( el )
    local m;
    m := rec( mat := InverseSameMutability(el!.mat), fld := el!.fld );
    Objectify( ProjElsType, m );
    return m;
  end );

InstallMethod( InverseMutable, "for a projective group element",
  [IsProjGrpEl and IsProjGrpElRep],
  function( el )
    local m;
    m := rec( mat := InverseMutable(el!.mat), fld := el!.fld );
    Objectify( ProjElsType, m );
    return m;
  end );

InstallOtherMethod( DegreeFFE, "for projective group element",
  [IsProjGrpEl and IsProjGrpElRep],
  function( el )
    return DegreeOverPrimeField( el!.fld );
  end );

InstallMethod( Characteristic, "for projective group element",
  [IsProjGrpEl and IsProjGrpElRep],
  function( el )
    return Characteristic( el!.fld );
  end );

InstallMethod( OneImmutable, "for a projective group",
  [IsGroup and IsProjectiveGroup],
  function( g )
    local gens, o;
    gens := GeneratorsOfGroup(g);
    if Length(gens) = 0 then
        if HasParent(g) then
            gens := GeneratorsOfGroup(Parent(g));
        else
            Error("sorry, no generators, no one");
        fi;
    fi;
    o := rec( mat := OneImmutable( gens[1]!.mat ), fld := gens[1]!.fld );
    Objectify( NewType(FamilyObj(gens[1]), IsProjGrpElRep), o );
    return o;
  end );

InstallMethod( OneImmutable, "for a projective group element",
  [IsProjGrpEl and IsProjGrpElRep],
  function( el )
    local o;
    o := rec( mat := OneImmutable( el!.mat ), fld := el!.fld );
    Objectify( NewType(FamilyObj(el), IsProjGrpElRep), o );
    return o;
  end );

InstallMethod( OneSameMutability, "for a projective group element",
  [IsProjGrpEl and IsProjGrpElRep],
  function( el )
    local o;
    o := rec( mat := OneImmutable( el!.mat ), fld := el!.fld );
    Objectify( NewType(FamilyObj(el), IsProjGrpElRep), o );
    return o;
  end );

InstallMethod( ViewObj, "for a projective group",
  [IsProjectiveGroup],
  function( g )
    Print("<projective group>");
  end );

InstallMethod( ViewObj, "for a trivial projective group",
  [IsProjectiveGroup and IsTrivial],
  function( g )
    Print("<trivial projective group>");
  end );

InstallMethod( ViewObj, "for a projective group with gens",
  [IsProjectiveGroup and HasGeneratorsOfGroup],
  function( g )
    local gens;
    gens := GeneratorsOfGroup(g);
    if Length(gens) = 0 then
        Print("<trivial projective group>");
    else
        Print("<projective group with ",Length(gens),
              " generators>");
    fi;
  end );

InstallMethod( ViewObj, 
  "for a projective group with size",
  [IsProjectiveGroup and HasSize],
  function( g )
    if Size(g) = 1 then
        Print("<trivial projective group>");
    else
        Print("<projective group of size ",Size(g),">");
    fi;
  end );

InstallMethod( ViewObj, 
  "for a projective group with gens and size",
  [IsProjectiveGroup and HasGeneratorsOfGroup and HasSize],
  function( g )
    local gens;
    gens := GeneratorsOfGroup(g);
    if Length(gens) = 0 then
        Print("<trivial projective group>");
    else
        Print("<projective group of size ",Size(g)," with ",
              Length(gens)," generators>");
    fi;
  end );

InstallMethod( BaseField, "for a projective group",
  [IsProjectiveGroup],
  function( g )
    local f,gens;
    if IsBound(g!.basefield) then
        return g!.basefield;
    fi;
    if HasParent(g) then
        f := BaseField(Parent(g));
        g!.basefield := f;
        return f;
    fi;
    # Now start to investigate:
    gens := GeneratorsOfGroup(g);
    if Length(gens) > 0 then
        g!.basefield := gens[1]!.fld;
        return g!.basefield;
    fi;
    # Now we have to give up:
    Error("base field could not be determined");
  end );

InstallMethod( Dimension, "for a projective group",
  [IsProjectiveGroup],
  function( g )
    local gens;
    if HasParent(g) then
        return Dimension(Parent(g));
    fi;
    # Now start to investigate:
    gens := GeneratorsOfGroup(g);
    if Length(gens) > 0 then
        return Length(gens[1]!.mat);
    fi;
    Error("dimension could not be determined");
  end );

InstallMethod( CanComputeActionOnPoints, "for a projective group",
  [IsProjectiveGroup],
  function( g )
    local d,q;
    d := Dimension( g );
    q := Size( BaseField( g ) );
    if (q^d - 1)/(q-1) > DESARGUES.LimitForCanComputeActionOnPoints then
        return false;
    else
        return true;
    fi;
  end );

InstallGlobalFunction( OnProjPoints,
  function( line, el )
    return OnLines(line,el!.mat);
  end );

InstallGlobalFunction( OnProjSubspacesNoFrob,
  function( subspace, el )
    return OnSubspacesByCanonicalBasis(subspace,el!.mat);
  end );

InstallGlobalFunction( NiceMonomorphismByOrbit,
  function(g,x,op,orblen)
    # g a funny group, Size attribute set!
    # x an element
    # op an operation suitable for x and g
    # It is guaranteed that g acts faithfully on the orbit.
    local cand,h,iso,nr,orb,pgens;
    if orblen <> false then
        orb := Orb(g,x,op,rec(orbsizelimit := orblen, hashlen := 2*orblen,
                              storenumbers := true));
        Enumerate(orb);
    else
        orb := Orb(g,x,op,rec(storenumbers := true));
        Enumerate(orb);
    fi;
    pgens := ActionOnOrbit(orb,GeneratorsOfGroup(g));
    h := GroupWithGenerators(pgens);
    SetSize(h,Size(g));
    nr := Minimum(100,Length(orb));
    cand := rec( points := orb{[1..nr]}, used := 0,
                 ops := ListWithIdenticalEntries(nr,op) );
    iso := GroupHomomorphismByImagesNCStabilizerChain(g,h,pgens,
              rec( Cand := cand ), rec( ) );
    SetIsBijective(iso,true);
    return iso;
  end );

InstallGlobalFunction( NiceMonomorphismByDomain,
  function(g,dom,op)
    # g a funny group, Size attribute set!
    # dom an orbit of g
    # op the operation suitable for x and g
    # It is guaranteed that g acts faithfully on the orbit.
    local cand,gens,h,ht,i,iso,nr,pgens;
    ht := NewHT(dom[1],Length(dom)*2);
    for i in [1..Length(dom)] do
      AddHT(ht,dom[i],i);
    od;
    pgens := [];
    gens := GeneratorsOfGroup(g);
    for i in [1..Length(gens)] do
        Add(pgens,PermList( List([1..Length(dom)],
                                 j->ValueHT(ht,op(dom[j],gens[i]))) ));
    od;
    h := GroupWithGenerators(pgens);
    SetSize(h,Size(g));
    nr := Minimum(100,Length(dom));
    cand := rec( points := dom{[1..nr]}, used := 0,
                 ops := ListWithIdenticalEntries(nr,op) );
    iso := GroupHomomorphismByImagesNCStabilizerChain(g,h,pgens,
              rec( Cand := cand ), rec( ) );
    SetIsBijective(iso,true);
    return iso;  
  end );

InstallMethod( ActionOnAllProjPoints, "for a projective group",
  [ IsProjectiveGroup ],
  function( pg )
    local a,d,f,orb;
    f := BaseField(pg);
    d := Dimension(pg);
    orb := MakeAllProjectivePoints(f,d);
    a := ActionHomomorphism(pg,orb,OnProjPoints,"surjective");
    SetIsInjective(a,true);
    return a;
  end );

## Is this operation ever used? I think it obselete (JB: 26/09/08)

InstallMethod( SetAsNiceMono, "for a projective group and an action hom",
  [IsProjectiveGroup, IsGroupHomomorphism and IsInjective],
  function( pg, a )
    SetNiceMonomorphism(pg,a);
    SetNiceObject(pg,Image(a));
  end );

InstallMethod( NiceMonomorphism, 
  "for a projective group (feasible case)",
  [IsProjectiveGroup and CanComputeActionOnPoints and
   IsHandledByNiceMonomorphism], 50,
  function( pg )
    local hom, dom;
  
    dom := MakeAllProjectivePoints( BaseField(pg), Dimension(pg) - 1);

    if DESARGUES.Fast then
       hom := NiceMonomorphismByDomain( pg, dom, OnProjPointsWithFrob );
    else 
       hom := ActionHomomorphism(pg, dom, OnProjPointsWithFrob, "surjective");    
       SetIsBijective(hom, true);
    fi;
  
    return hom;
  end );
  
InstallMethod( NiceMonomorphism, 
  "for a projective group (nasty case)",
  [IsProjectiveGroupWithFrob and IsHandledByNiceMonomorphism], 50,
  function( pg )
    local can, dom, hom;
    can := CanComputeActionOnPoints(pg);
    if not(can) then
        Error("action on projective points not feasible to calculate");
    else
        dom := MakeAllProjectivePoints( BaseField(pg), Dimension(pg) - 1 );

        if DESARGUES.Fast then
           hom := NiceMonomorphismByDomain( pg, dom, OnProjPointsWithFrob );
        else 
           hom := ActionHomomorphism(pg, dom, OnProjPointsWithFrob, "surjective");    
           SetIsBijective(hom, true);
        fi;
        return hom; 
    fi;
  end );
 
#################################################
# Frobenius automorphisms and groups using them:
#################################################

InstallOtherMethod( \^, "for a FFE vector and a Frobenius automorphism",
  [ IsVector and IsFFECollection, IsFrobeniusAutomorphism ],
  function( v, f )
    return List(v,x->x^f);
  end );

InstallOtherMethod( \^, "for a FFE vector and a trivial Frobenius automorphism",
  [ IsVector and IsFFECollection, IsMapping and IsOne ],
  function( v, f )
    return v;
  end );

InstallOtherMethod( \^, 
  "for a compressed GF2 vector and a Frobenius automorphism",
  [ IsVector and IsFFECollection and IsGF2VectorRep, IsFrobeniusAutomorphism ],
  function( v, f )
    local w;
    w := List(v,x->x^f);
    ConvertToVectorRepNC(w,2);
    return w;
  end );

InstallOtherMethod( \^, 
  "for a compressed GF2 vector and a trivial Frobenius automorphism",
  [ IsVector and IsFFECollection and IsGF2VectorRep, IsMapping and IsOne ],
  function( v, f )
    return v;
  end );

InstallOtherMethod( \^, 
  "for a compressed 8bit vector and a Frobenius automorphism",
  [ IsVector and IsFFECollection and Is8BitVectorRep, IsFrobeniusAutomorphism ],
  function( v, f )
    local w;
    w := List(v,x->x^f);
    ConvertToVectorRepNC(w,Q_VEC8BIT(v));
    return w;
  end );

InstallOtherMethod( \^, 
  "for a compressed 8bit vector and a trivial Frobenius automorphism",
  [ IsVector and IsFFECollection and Is8BitVectorRep, IsMapping and IsOne ],
  function( v, f )
    return v;
  end );

InstallOtherMethod( \^, "for a FFE matrix and a Frobenius automorphism",
  [ IsMatrix and IsFFECollColl, IsFrobeniusAutomorphism ],
  function( m, f )
    return List(m,v->List(v,x->x^f));
  end );

InstallOtherMethod( \^, "for a FFE matrix and a trivial Frobenius automorphism",
  [ IsMatrix and IsFFECollColl, IsMapping and IsOne ],
  function( m, f )
    return m;
  end );

InstallOtherMethod( \^, 
  "for a compressed GF2 matrix and a Frobenius automorphism",
  [ IsMatrix and IsFFECollColl and IsGF2MatrixRep, IsFrobeniusAutomorphism ],
  function( m, f )
    local w,l,i;
    l := [];
    for i in [1..Length(m)] do
        w := List(m[i],x->x^f);
        ConvertToVectorRepNC(w,2);
        Add(l,w);
    od;
    ConvertToMatrixRepNC(l,2);
    return l;
  end );

InstallOtherMethod( \^, 
  "for a compressed GF2 matrix and a trivial Frobenius automorphism",
  [ IsMatrix and IsFFECollColl and IsGF2MatrixRep, IsMapping and IsOne ],
  function( m, f )
    return m;
  end );

InstallOtherMethod( \^, 
  "for a compressed 8bit matrix and a Frobenius automorphism",
  [ IsMatrix and IsFFECollColl and Is8BitMatrixRep, IsFrobeniusAutomorphism ],
  function( m, f )
    local w,l,i,q;
    l := [];
    q := Q_VEC8BIT(m[1]);
    for i in [1..Length(m)] do
        w := List(m[i],x->x^f);
        ConvertToVectorRepNC(w,q);
        Add(l,w);
    od;
    ConvertToMatrixRepNC(l,q);
    return l;
  end );

InstallOtherMethod( \^, 
  "for a compressed 8bit matrix and a trivial Frobenius automorphism",
  [ IsMatrix and IsFFECollColl and Is8BitMatrixRep, IsMapping and IsOne ],
  function( m, f )
    return m;
  end );


InstallMethod( ProjElWithFrob, 
  "for a ffe matrix and a Frobenius automorphism, and a field",
  [IsMatrix and IsFFECollColl,
	  IsRingHomomorphism and IsMultiplicativeElementWithInverse,
	  IsField],
  function( m, frob, f )
    local el, m2;
    m2 := ConvertToMatrixRepNC( m, f );
    el := rec( mat := m, fld := f, frob := frob );
    Objectify( ProjElsWithFrobType, el );
    return el;
  end );

InstallMethod( ProjElWithFrob, 
  "for a ffe matrix and a Frobenius automorphism",
  [IsMatrix and IsFFECollColl,
	  IsRingHomomorphism and IsMultiplicativeElementWithInverse],
	function ( m, frob )
	  local matrixfield, frobfield, mchar, fchar, dim;
		
		matrixfield := DefaultFieldOfMatrix(m);
		mchar := Characteristic(matrixfield);
		frobfield := Range(frob);
		fchar := Characteristic(frobfield);
		if mchar <> fchar then
		  Error("the matrix and automorphism do not agree on the characteristic");
		fi;
		
		# figure out a field which contains the matrices and admits the
		# automorphisms (nontrivially)
		dim := Lcm(
		  LogInt(Size(matrixfield),mchar),
			LogInt(Size(frobfield),fchar)
			);
	  return ProjElWithFrob( m, frob, GF(mchar^dim) );
  end);
 
InstallMethod( ProjElWithFrob, 
  "for a ffe matrix and a trivial Frobenius automorphism",
  [IsMatrix and IsFFECollColl, IsMapping and IsOne],
  function( m, frob )
    local el, m2;
    m2 := ConvertToMatrixRepNC( m );
    el := rec( mat := m, fld := DefaultFieldOfMatrix(m), frob := frob );
    Objectify( ProjElsWithFrobType, el );
    return el;
  end );

InstallMethod( ProjElsWithFrob,
"for a list of pairs of ffe matrices and frobenius automorphisms, and a field",
	[IsList, IsField],
	function( l, f )
	  local objectlist, m;
		objectlist := [];
		for m in l do
		  Add(objectlist, ProjElWithFrob(m[1],m[2],f));
		od;
		return objectlist;
	end );

InstallMethod( ProjElsWithFrob, 
  "for a list of pairs of ffe matrices and Frobenius automorphisms",
  [IsList],
  function( l )
    local matrixfield, frobfield, mchar, fchar, oldchar,
		      f, dim, m, objectlist;

    if(IsEmpty(l)) then
		  return [];
		fi;
		
		dim := 1;

		# get the characteristic of the field that we want to work in.
		# it should be the same for every matrix and every automorphism --
		# if not we will raise an error.
		oldchar := Characteristic(l[1][1]);
		
		for m in l do
  		matrixfield := DefaultFieldOfMatrix(m[1]);
  		mchar := Characteristic(matrixfield);
  		frobfield := Range(m[2]);
  		fchar := Characteristic(frobfield);
  		if mchar <> fchar or mchar <> oldchar then
  		  Error("matrices and automorphisms do not agree on the characteristic");
  		fi;
		
  		# at each step we increase the dimension of the desired field
		# so that it contains all the matrices and admits all the automorphisms
		# (nontrivially.)
  
  		dim := Lcm(
			  dim,
  		  LogInt(Size(matrixfield),mchar),
  			LogInt(Size(frobfield),fchar)
  			);
  	od;

		f := GF(oldchar ^ dim);
		objectlist := [];
		for m in l do
		  Add(objectlist, ProjElWithFrob(m[1],m[2],f));
		od;
		return objectlist;
  end );

InstallMethod( ViewObj, "for a projective group element with Frobenius",
  [IsProjGrpElWithFrob and IsProjGrpElWithFrobRep],
  function(el)
    Print("<projective semilinear element: ");
    ViewObj(el!.mat);
    if IsOne(el!.frob) then
        Print(", F^0>");
    else
        Print(", F^",el!.frob!.power,">");
    fi;
  end);

InstallMethod( Display, "for a projective group element with Frobenius",
  [IsProjGrpElWithFrob and IsProjGrpElWithFrobRep],
  function(el)
    Print("<projective semilinear element, underlying matrix:\n");
    Display(el!.mat);
    if IsOne(el!.frob) then
        Print(", F^0>\n");
    else
        Print(", F^",el!.frob!.power,">\n");
    fi;
  end );

InstallMethod( PrintObj, "for a projective group element",
  [IsProjGrpElWithFrob and IsProjGrpElWithFrobRep],
  function(el)
    Print("ProjElWithFrob(");
    PrintObj(el!.mat);
    Print(",");
    PrintObj(el!.frob);
    Print(")");
  end );
  
InstallOtherMethod( Representative, 
  "for a projective group element with Frobenius",
  [IsProjGrpElWithFrob and IsProjGrpElWithFrobRep],
  function( el )
    return [el!.mat,el!.frob];
  end );

InstallMethod( BaseField, "for a projective group element with Frobenius",
  [IsProjGrpElWithFrob and IsProjGrpElWithFrobRep],
  function( el )
    return el!.fld;
  end );

InstallMethod( \=, "for two projective group elements with Frobenius",
  [IsProjGrpElWithFrob and IsProjGrpElWithFrobRep,
   IsProjGrpElWithFrob and IsProjGrpElWithFrobRep],
  function( a, b )
    local aa,bb,p,s,i;
    if a!.fld <> b!.fld then Error("different base fields"); fi;
    if a!.frob <> b!.frob then return false; fi;
    aa := a!.mat;
    bb := b!.mat;
    p := PositionNonZero(aa[1]);
    s := bb[1][p] / aa[1][p];
    for i in [1..Length(aa)] do
        if s*aa[i] <> bb[i] then return false; fi;
    od;
    return true;
  end );

InstallMethod(\<,
  [IsProjGrpElWithFrob, IsProjGrpElWithFrob],
  function(a,b)
    local aa,bb,pa,pb,sa,sb,i,va,vb;
    if a!.fld <> b!.fld then Error("different base fields"); fi;
    if a!.frob < b!.frob then
        return true;
    elif b!.frob < a!.frob then
        return false;
    fi;
    aa := a!.mat;
    bb := b!.mat;
    pa := PositionNonZero(aa[1]);
    pb := PositionNonZero(bb[1]);
    if pa > pb then 
        return true;
    elif pa < pb then
        return false;
    fi;
    sa := aa[1][pa]^-1;
    sb := bb[1][pb]^-1;
    for i in [1..Length(aa)] do
        va := sa*aa[i];
        vb := sb*bb[i];
        if va < vb then return true; fi;
        if vb < va then return false; fi;
    od;
    return false; 
  end);

## make this a global function?

IsScalarMatrix := function( a )
  local n;
  n := a[1][1];
  if IsZero(n) then 
     return false;
  else
     return IsOne(a/n);
  fi;
end;

InstallMethod( Order, "for a projective group element with Frobenius",
  [IsProjGrpElWithFrob and IsProjGrpElWithFrobRep],

# This algorithm could be improved by using the ideas of
# Celler and Leedham-Green.

  function( a )
     local b, frob, bfrob, i;
  b := a!.mat;
  frob := a!.frob;
  if IsOne(frob) then 
     return ProjectiveOrder(b)[1];
  fi;
  if not IsOne(b) then
     bfrob := b; i := 1;
     repeat
       bfrob := bfrob^frob;
       b := b * bfrob;
       i := i + 1;
     until IsScalarMatrix( b );
     return i;
  else
     return Order(frob);
  fi;
  return 1;
  end );

InstallMethod( IsOne, "for a projective group element with Frobenius",
  [IsProjGrpElWithFrob and IsProjGrpElWithFrobRep],
  function( el )
    local s;
    if not(IsOne(el!.frob)) then return false; fi;
    s := el!.mat[1][1];
    if IsZero(s) then return false; fi;
    s := s^-1;
    return IsOne( s*el!.mat );
  end );

#made a change, added ^-1 on march 8 2007, J&J
InstallMethod( \*, "for two projective group element with Frobenious",
  [IsProjGrpElWithFrob and IsProjGrpElWithFrobRep,
   IsProjGrpElWithFrob and IsProjGrpElWithFrobRep],
  function( a, b )
    local el;
    el := rec( mat := a!.mat * (b!.mat^(a!.frob^-1)), fld := a!.fld, 
               frob := a!.frob * b!.frob );
    Objectify( ProjElsWithFrobType, el);
    return el;
  end );

#found a bug 23/09/08 in st. andrews.
#J&J feel a great relief.
#C&P too.
#all after Max concluded that there was a big bug.
InstallMethod( InverseSameMutability, 
  "for a projective group element with Frobenius",
  [IsProjGrpElWithFrob and IsProjGrpElWithFrobRep],
  function( el )
    local m,f;
    f := el!.frob;
    m := rec( mat := (InverseSameMutability(el!.mat))^f, fld := el!.fld,
              frob := f^-1 );
    Objectify( ProjElsWithFrobType, m );
    return m;
  end );

InstallMethod( InverseMutable, 
  "for a projective group element with Frobenius",
  [IsProjGrpElWithFrob and IsProjGrpElWithFrobRep],
  function( el )
    local m,f;
    f := el!.frob;
    m := rec( mat := (InverseMutable(el!.mat))^f, fld := el!.fld,
              frob := f^-1 );
    Objectify( ProjElsWithFrobType, m );
    return m;
  end );

InstallOtherMethod( DegreeFFE, "for projective group element with Frobenius",
  [IsProjGrpElWithFrob and IsProjGrpElWithFrobRep],
  function( el )
    return DegreeOverPrimeField( el!.fld );
  end );

InstallMethod( Characteristic, "for projective group element with Frobenius",
  [IsProjGrpElWithFrob and IsProjGrpElWithFrobRep],
  function( el )
    return Characteristic( el!.fld );
  end );

InstallMethod( OneImmutable, "for a projective semilinear group",
  [IsGroup and IsProjectiveGroupWithFrob],
  function( g )
    local gens, o;
    gens := GeneratorsOfGroup(g);
    if Length(gens) = 0 then
        if HasParent(g) then
            gens := GeneratorsOfGroup(Parent(g));
        else
            Error("sorry, no generators, no one");
        fi;
    fi;
    o := rec( mat := OneImmutable( gens[1]!.mat ), fld := BaseField(g),
              frob := gens[1]!.frob^0 );
    Objectify( ProjElsWithFrobType, o);
    return o;
  end );

InstallMethod( OneImmutable, "for a projective group element with Frobenius",
  [IsProjGrpElWithFrob and IsProjGrpElWithFrobRep],
  function( el )
    local o;
    o := rec( mat := OneImmutable( el!.mat ), fld := el!.fld,
              frob := el!.frob^0 );
    Objectify( ProjElsWithFrobType, o);
    return o;
  end );

InstallMethod( OneSameMutability, 
  "for a projective group element with Frobenius",
  [IsProjGrpElWithFrob and IsProjGrpElWithFrobRep],
  function( el )
    local o;
    o := rec( mat := OneImmutable( el!.mat ), fld := el!.fld,
              frob := el!.frob^0 );
    Objectify( ProjElsWithFrobType, o);
    return o;
  end );

InstallMethod( ViewObj, "for a projective semilinear group",
  [IsProjectiveGroupWithFrob],
  function( g )
    Print("<projective semilinear group>");
  end );

InstallMethod( ViewObj, "for a trivial projective semilinear group",
  [IsProjectiveGroupWithFrob and IsTrivial],
  function( g )
    Print("<trivial projective semilinear group>");
  end );

InstallMethod( ViewObj, "for a projective semilinear group with gens",
  [IsProjectiveGroupWithFrob and HasGeneratorsOfGroup],
  function( g )
    local gens;
    gens := GeneratorsOfGroup(g);
    if Length(gens) = 0 then
        Print("<trivial projective semilinear group>");
    else
        Print("<projective semilinear group with ",Length(gens),
              " generators>");
    fi;
  end );

InstallMethod( ViewObj, 
  "for a projective semilinear group with size",
  [IsProjectiveGroupWithFrob and HasSize],
  function( g )
    if Size(g) = 1 then
        Print("<trivial projective semilinear group>");
    else
        Print("<projective semilinear group of size ",Size(g),">");
    fi;
  end );

InstallMethod( ViewObj, 
  "for a projective semilinear group with gens and size",
  [IsProjectiveGroupWithFrob and HasGeneratorsOfGroup and HasSize],
  function( g )
    local gens;
    gens := GeneratorsOfGroup(g);
    if Length(gens) = 0 then
        Print("<trivial projective semilinear group>");
    else
        Print("<projective semilinear group of size ",Size(g)," with ",
              Length(gens)," generators>");
    fi;
  end );

InstallMethod( BaseField, "for a projective semilinear group",
  [IsProjectiveGroupWithFrob],
  function( g )
    local f,gens;
    if IsBound(g!.basefield) then
        return g!.basefield;
    fi;
    if HasParent(g) then
        f := BaseField(Parent(g));
        g!.basefield := f;
        return f;
    fi;
    # Now start to investigate:
    gens := GeneratorsOfGroup(g);
    if Length(gens) > 0 then
        g!.basefield := gens[1]!.fld;
        return g!.basefield;
    fi;
    # Now we have to give up:
    Error("base field could not be determined");
  end );

InstallMethod( Dimension, "for a projective semilinear group",
  [IsProjectiveGroupWithFrob],
  function( g )
    local gens;
    if HasParent(g) then
        return Dimension(Parent(g));
    fi;
    # Now start to investigate:
    gens := GeneratorsOfGroup(g);
    if Length(gens) > 0 then
        return Length(gens[1]!.mat);
    fi;
    Error("dimension could not be determined");
  end );

InstallMethod( CanComputeActionOnPoints, "for a projective group with frob",
  [IsProjectiveGroupWithFrob],
  function( g )
    local d,q;
    d := Dimension( g );
    q := Size( BaseField( g ) );
    if (q^d - 1)/(q-1) > DESARGUES.LimitForCanComputeActionOnPoints then
        return false;
    else
        return true;
    fi;
  end );

InstallGlobalFunction( OnProjPointsWithFrob,
  function( line, el )
    local vec,c;
    vec := OnPoints(line,el!.mat)^el!.frob;
    c := PositionNonZero(vec);
    if c <= Length( vec )  then
        if not(IsMutable(vec)) then
            vec := ShallowCopy(vec);
        fi;
        MultRowVector(vec,Inverse( vec[c] ));
    fi;
    return vec;
  end );

InstallGlobalFunction( OnProjSubspacesWithFrob,
  function( line, el )
    local vec,c;
    vec := OnRight(line,el!.mat)^el!.frob;
    if not(IsMutable(vec)) then
        vec := MutableCopyMat(vec);
    fi;
    TriangulizeMat(vec);
    return vec;
  end );

InstallMethod( ActionOnAllProjPoints, "for a projective semilinear group",
  [ IsProjectiveGroupWithFrob ],
  function( pg )
    local a,d,f,o,on,orb,v,
		      zero, m, j;
    f := BaseField(pg);
    d := Dimension(pg);
    o := One(f);
    on := One(pg);
    v := ZeroMutable(on!.mat[1]);
    v[1] := o;
    # orb := Orbit(pg,v,OnProjPointsWithFrob);
    zero := Zero(f);
    orb := [];
    for m in f^d do
        j := PositionNot(m, zero);
	if j <= d and m[j] = o then
	   Add(orb, m);
	fi;
    od;
    a := ActionHomomorphism(pg,orb,OnProjPointsWithFrob,"surjective");
    SetIsInjective(a,true);
    return a;
  end );

InstallMethod( SetAsNiceMono, 
  "for a projective semilinear group and an action hom",
  [IsProjectiveGroupWithFrob, IsGroupHomomorphism and IsInjective],
  function( pg, a )
    SetNiceMonomorphism(pg,a);
    SetNiceObject(pg,Image(a));
  end );

InstallMethod( NiceMonomorphism, 
  "for a projective semilinear group (feasible case)",
  [IsProjectiveGroupWithFrob and CanComputeActionOnPoints and
   IsHandledByNiceMonomorphism], 50,
  function( pg )
    return ActionOnAllProjPoints( pg );
  end );
  
InstallMethod( NiceMonomorphism, 
  "for a projective semilinear group (nasty case)",
  [IsProjectiveGroupWithFrob and IsHandledByNiceMonomorphism], 50,
  function( pg )
    local can;
    can := CanComputeActionOnPoints(pg);
    if not(can) then
        Error("action on projective points not feasible to calculate");
    else
        return ActionOnAllProjPoints( pg );
    fi;
  end );

InstallMethod( FindBasePointCandidates,
  "for a projective group",
  [IsProjectiveGroup,IsRecord,IsInt],
  function(g,opt,i)
    local cand,d,f,gens;
    if IsBound(g!.basepointcandidates) and
       g!.basepointcandidates.used < Length(g!.basepointcandidates.points) then
        return g!.basepointcandidates;
    fi;
    gens := GeneratorsOfGroup(g);
    if IsObjWithMemory(gens[1]) then
        f := BaseField(gens[1]!.el);
        d := Length(gens[1]!.el!.mat);
    else
        f := BaseField(g);
        d := Dimension(g);
    fi;
    cand := rec( points := IdentityMat(d,f), used := 0,
                 ops := ListWithIdenticalEntries(d,OnProjPoints) );
    return cand;
  end );

InstallMethod( FindBasePointCandidates,
  "for a projective semilinear group",
  [IsProjectiveGroupWithFrob,IsRecord,IsInt],
  function(g,opt,i)
    local cand,d,f,gens;
    if IsBound(g!.basepointcandidates) and
       g!.basepointcandidates.used < Length(g!.basepointcandidates.points) then
        return g!.basepointcandidates;
    fi;
    gens := GeneratorsOfGroup(g);
    if IsObjWithMemory(gens[1]) then
        f := BaseField(gens[1]!.el);
        d := Length(gens[1]!.el!.mat);
    else
        f := BaseField(g);
        d := Dimension(g);
    fi;
    cand := rec( points := IdentityMat(d,f), used := 0,
                 ops := ListWithIdenticalEntries(d,OnProjPointsWithFrob) );
    if d > 1 then
        Add(cand.points,ShallowCopy(cand.points[1]));
        Add(cand.ops,OnProjPointsWithFrob);
        cand.points[d+1][2] := PrimitiveRoot(f);
    fi;
    return cand;
  end );



InstallMethod( FindBasePointCandidates,
  "for a projective semilinear group",
  [IsProjectiveGroupWithFrob,IsRecord,IsInt,IsObject],
#
# We need a four-argument version of this method for recent versions of GenSS.
# We don't use "parentS" at all here.
#
  function(g,opt,i,parentS)
    local cand,d,f,gens;
    if IsBound(g!.basepointcandidates) and
       g!.basepointcandidates.used < Length(g!.basepointcandidates.points) then
        return g!.basepointcandidates;
    fi;
    gens := GeneratorsOfGroup(g);
    if IsObjWithMemory(gens[1]) then
        f := BaseField(gens[1]!.el);
        d := Length(gens[1]!.el!.mat);
    else
        f := BaseField(g);
        d := Dimension(g);
    fi;
    cand := rec( points := IdentityMat(d,f), used := 0,
                 ops := ListWithIdenticalEntries(d,OnProjPointsWithFrob) );
    if d > 1 then
        Add(cand.points,ShallowCopy(cand.points[1]));
        Add(cand.ops,OnProjPointsWithFrob);
        cand.points[d+1][2] := PrimitiveRoot(f);
    fi;
    return cand;
  end );



#################################################
# Our classical groups:
#################################################

## bug, size IsometryGroup(ParabolicQuadric(6,2)) is wrong

InstallMethod( SOdesargues, [IsInt, IsPosInt, IsField and IsFinite],
  function(i, d, f)
    local s, m, frob, b, gens, g, q;
    if i = -1 then s := "elliptic";
    elif i = 0 then s := "parabolic";
    elif i = 1 then s := "hyperbolic";
    fi;
    q := Size(f);
    if IsEvenInt(q) then
      m := InvariantQuadraticForm(SO(i,d,q))!.matrix;
      b := BaseChangeOrthogonalQuadratic(m, f)[1];
    else 
      m := InvariantBilinearForm(SO(i,d,q))!.matrix;
      b := BaseChangeOrthogonalBilinear(m, f)[1]; 
    fi; 
    frob := FrobeniusAutomorphism(f);
 
    ## new group elements: x -> b^-1 x b (conjugation by base change)
    ## preserves form... (b x b^-1) (b m b^T) (b x b^-1)^T = x m x^T

    gens := GeneratorsOfGroup( SO(i,d,q) );
    gens := List( gens, y -> b * y * b^-1);
    gens := ProjElsWithFrob( List(gens, x -> [x,frob^0]), f );
    g := GroupWithGenerators( gens );
    SetName( g, Concatenation("PSO(",String(i),",",String(d),",",String(q),")") );
    if i = 0 then 
       SetSize( g, Size(SO(i, d, q)) );  ##/ 2); This might be a mistake in Kleidman and Liebeck!
    else
       SetSize( g, Size(SO(i, d, q)) / GCD_INT(2, q-1) ); 
    fi;

    return g;
  end );

InstallMethod( GOdesargues, [IsInt, IsPosInt, IsField and IsFinite],
  function(i, d, f)
    local m, frob, b, gens, s, g, q;
    if i = -1 then s := "elliptic";
    elif i = 0 then s := "parabolic";
    elif i = 1 then s := "hyperbolic";
    fi;
    q := Size(f);
    if IsEvenInt(q) then
      m := InvariantQuadraticForm(GO(i,d,q))!.matrix;
      b := BaseChangeOrthogonalQuadratic(m, f)[1];
    else 
      m := InvariantBilinearForm(SO(i,d,q))!.matrix;   
      b := BaseChangeOrthogonalBilinear(m, f)[1]; 
    fi; 
    frob := FrobeniusAutomorphism(f);

    ## new group elements: x -> b x b^-1 (conjugation by base change)
    ## preserves form... (b x b^-1) (b m b^T) (b x b^-1)^T = x m x^T

    gens := GeneratorsOfGroup( GO(i,d,q) );
    gens := List( gens, y -> b * y * b^-1);
    gens := ProjElsWithFrob( List(gens, x -> [x,frob^0]), f );
    g := GroupWithGenerators( gens );
    SetName( g, Concatenation("PGO(",String(i),",",String(d),",",String(q),")") );
    SetSize( g, Size(GO(i, d, q)) / GCD_INT(2,q-1) ); 
    return g;
  end );

InstallMethod( SUdesargues, [IsPosInt, IsField and IsFinite],
  function(d, f)
    local m, frob, b, gens, g, sqrtq;
    sqrtq := Sqrt(Size(f));
    m := InvariantSesquilinearForm(SU(d,sqrtq))!.matrix;        
    frob := FrobeniusAutomorphism(f);
    b := BaseChangeHermitian(m, f)[1];
    ## new group elements: x -> b x b^-1 (conjugation by base change)
    ## preserves form... (b x b^-1) (b m b^Tfrob) (b x b^-1)^Tfrob = x m x^Tfrob
    gens := GeneratorsOfGroup( SU(d,sqrtq) );
    gens := List( gens, y -> b * y * b^-1);
    gens := ProjElsWithFrob( List(gens, x -> [x,frob^0]), f );
    g := GroupWithGenerators( gens );
    SetName( g, Concatenation("PSU(",String(d),",",String(sqrtq),"^2)") );
    SetSize( g, Size( SU(d, sqrtq) ) / GCD_INT(sqrtq+1,d)  );
    return g;
  end );

InstallMethod( GUdesargues, [IsPosInt, IsField and IsFinite],
  function(d, f)
    local m, frob, b, gens, g, sqrtq;
    sqrtq := Sqrt(Size(f));
    m := InvariantSesquilinearForm(GU(d,sqrtq))!.matrix;      
    frob := FrobeniusAutomorphism(f);
    b := BaseChangeHermitian(m, f)[1];
    ## new group elements: x -> b x b^-1 (conjugation by base change)
    gens := GeneratorsOfGroup( GU(d,sqrtq) );
    gens := List( gens, y -> b * y * b^-1);
    gens := ProjElsWithFrob( List(gens, x -> [x,frob^0]), f );
    g := GroupWithGenerators( gens );
    SetName( g, Concatenation("PGU(",String(d),",",String(sqrtq),"^2)") );
    SetSize( g, Size( GU(d, sqrtq) ) / (sqrtq+1) );
    return g;
  end );

InstallMethod( Spdesargues, [IsPosInt, IsField and IsFinite],
  function(d, f)
    local m, frob, b, gens, g, q, sp;
    q := Size(f);
    m := InvariantBilinearForm(Sp(d,q))!.matrix;   
    b := BaseChangeSymplectic(m, f)[1];  ## change made after new forms code
    frob := FrobeniusAutomorphism(f);
    ## new group elements: x -> b x b^-1 (conjugation by base change)
    sp := Sp(d,q);
    gens := GeneratorsOfGroup( sp );
    gens := List( gens, y -> b * y * b^-1);
    gens := ProjElsWithFrob( List(gens, x -> [x,frob^0]), f );
    g := GroupWithGenerators( gens );
    SetName( g, Concatenation("PSp(",String(d),",",String(q),")") );
    SetSize( g, Size( sp )/GCD_INT(2, q-1) );
    return g;
  end );


#################################################
# Semi-similarity and similarity groups:
#################################################

## to be done....
##    GammaOminus


###### Symplectic groups ######

InstallMethod( GeneralSymplecticGroup, [IsPosInt, IsField and IsFinite],
  function(d, f)

## The command "Sp" in the GAP library returns the symplectic 
## isometry group (see classical.gi). However, in odd characteristic,
## the symplectic isometries have index 2 in the symplectic similarity
## group. The preimage in the matrix group of the symplectic 
## similarities is the isometries extended by the cyclic
## group generated by the map which simply multiplies one half
## of the symplectic basis by the primitive element of the field
## and leaves the other half alone. 
  
  local sp, gens, z, delta, i, g, q;
  q := Size(f);
  if IsOddInt(d) then 
     Error("dimension must be an even");
  fi;
  sp := Sp(d, q);
  gens := GeneratorsOfGroup(sp);
  z := PrimitiveRoot( f );
  delta := ShallowCopy(IdentityMat(d, f));
  for i in [1..d/2] do delta[i][i] := z; od;
  gens := Concatenation(gens, [delta]);
  g := GroupWithGenerators( gens );
  SetName( g, Concatenation("GSp(",String(d),",",String(q),")") );
  SetSize( g, (q-1) * Size(sp) );
  return g;
  end );

InstallMethod( GSpdesargues, [IsPosInt, IsField and IsFinite],
  function(d, f)
    local m, frob, b, gens, g, q, gsp;
    q := Size(f);
    m := InvariantBilinearForm(Sp(d,q))!.matrix;     
    b := BaseChangeToCanonical( BilinearFormByMatrix(m, f) );
    frob := FrobeniusAutomorphism(f);
    ## new group elements: x -> b x b^-1 (conjugation by base change)
    gsp := GeneralSymplecticGroup(d,f);
    gens := GeneratorsOfGroup( gsp );
    gens := List( gens, y -> b * y * b^-1);
    gens := ProjElsWithFrob( List(gens, x -> [x,frob^0]), f );
    g := GroupWithGenerators( gens );
    SetName( g, Concatenation("PGSp(",String(d),",",String(q),")") );
    SetSize( g, Size(gsp) / (q-1) );    
    return g;
  end );

InstallMethod( GammaSp, [IsPosInt, IsField and IsFinite],
  function(d, f)
    local m, frob, b, gens, g, q, gsp;
    q := Size(f);
    m := InvariantBilinearForm(Sp(d,q))!.matrix;     
    b := BaseChangeToCanonical( BilinearFormByMatrix(m, f) );
    frob := FrobeniusAutomorphism(f);
    ## new group elements: x -> b x b^-1 (conjugation by base change)
    gsp := GeneralSymplecticGroup(d,f);
    gens := GeneratorsOfGroup( gsp );
    gens := List( gens, y -> b * y * b^-1);
    gens := List( gens, x -> [x, frob^0]);
    Add(gens, [IdentityMat(d, f), frob] );
    gens := ProjElsWithFrob( gens, f );
    g := GroupWithGenerators( gens );
    SetName( g, Concatenation("PGammaSp(",String(d),",",String(q),")") );
    SetSize( g, Order(frob) * Size(gsp) / (q - 1) );  
    return g;
  end );

###### Orthogonal (elliptic) groups ######

InstallMethod( DeltaOminus, [IsPosInt, IsField and IsFinite],
  function(d, f)
    local go, gens, g, q, one, mat, i, combs, two, a, b, 
          twobytwo, mu, z, zero;  

    ## Note here that for q even, the projective similarity group
    ## is equal to the projective isometry group. For q odd,
    ## the index of the projective isometry group in the projective
    ## similarity group is 2. Moreover, we have two cases modulo 4.
    ## For q = 3 mod 4, we adjoin the matrix (e.g., for d = 6)
    ##    a  b  .  .  .  .  
    ##    b -a  .  .  .  .  
    ##    .  .  .  1  .  .  
    ##    .  . -1  .  .  .  
    ##    .  .  .  .  .  1  
    ##    .  .  .  . -1  .
    ## where a^2+b^2 = Z(q)^((q-1)/2), 
    ## to the isometry group to obtain the similarity group (see
    ## Kleidman and Liebeck, Section 2.8). For q = 1 mod 4, we
    ## use the matrix
    ##    .  1  .  .  .  .  
    ##    z  .  .  .  .  .  
    ##    .  .  .  1  .  .  
    ##    .  .  z  .  .  .  
    ##    .  .  .  .  .  1  
    ##    .  .  .  .  z  .
    ## where z = Z(q).

    one := One(f);
    mat := NullMat(d,d,f);
    q := Size(f);
    z := Z(q);
    go := GOdesargues(-1,d,f);

    if q mod 4 = 3 then
       for i in [2..d/2] do
           mat[2*i-1][2*i] := one;   
           mat[2*i][2*i-1] := -one;  
       od;  
       mu := z^((q-1)/2);;
       combs := Combinations(AsList(f),2);;
       two := First(combs, t -> not IsZero(t[1]) and not IsZero(t[2])
                           and t[1]^2+t[2]^2=mu);
       a := two[1]; b:= two[2];
       twobytwo := [[a,b],[b,-a]];
       mat{[1,2]}{[1,2]} := twobytwo;
    elif q mod 4 = 1 then
       for i in [1..d/2] do
           z := Z(q);
           zero := Zero(f);
           mat{[2*i-1,2*i]}{[2*i-1,2*i]} := [[ zero, one ], [z, zero]];
       od;
    else 
       return go; 
    fi;

    gens := ShallowCopy(GeneratorsOfGroup( go ));
    Add(gens, ProjElWithFrob( mat, IdentityMapping(f), f) );
    g := GroupWithGenerators( gens );
    SetName( g, Concatenation("PDeltaO-(",String(d),",",String(Size(f)),")") );
       ## scalars are completely contained in matrix group, (q-1) cancels with (q-1)
    SetSize( g, Size(GO(-1,d,q)) ); 
    return g;
  end );	

InstallMethod( GammaOminus, [IsPosInt, IsField and IsFinite],
  function(d, f)
  local q, gram, mat, p, a, go, gens, coll, frob, block, mat2, i; 
  
  ## Works beautifully for odd q! Tested for possible output 
  ## (q,d) in {(4,9),(4,25),(4,27),(4,49),(6,9)}

  ## After some calculations using the information in Section 2.8
  ## of Kleidman and Liebeck, we find that the following matrix M 
  ## (n.b., you should extrapolate the dimension) together with
  ## the Frobenius automorphism of GF(q) defines a semisimilarity
  ## of our canonical form in FinInG:
  ##    a  .  .  .  .  .  
  ##    .  b  .  .  .  .  
  ##    .  .  .  l  .  .  
  ##    .  .  l  .  .  .  
  ##    .  .  .  .  .  l  
  ##    .  .  .  .  l  .
  ## where a = l * alpha^((1-p)/2) and b = l * beta^((1-p)/2), and 
  ## the first block of our Gram matrix is diag(alpha, beta).

  q := Size(f);
  p := Characteristic( f );
  go := DeltaOminus( d, f );

  if q = p then
     coll := go;
  elif IsOddInt(q) then
     gram := CanonicalGramMatrix("elliptic", d, f);
     mat := MutableCopyMat( gram );
	 mat[1][1] := gram[3][4] * gram[1][1]^((1-p)/2); 
	 mat[2][2] := gram[3][4] * gram[2][2]^((1-p)/2);
	 ConvertToMatrixRep( mat, f );
	 frob := FrobeniusAutomorphism( f );
	 a := ProjElWithFrob( mat, frob, f);
     gens := ShallowCopy( GeneratorsOfGroup(go) );
     Add(gens, a);
     coll := GroupWithGenerators( gens );
	 SetName( coll, Concatenation("PGammaO-(",String(d),",",String(q),")") );
	 SetSize( coll, Size(go) * Order(frob) );
  else
     ## We must find a semisimilarity for the first (2x2) block. Then
     ## simply extend it naturally to fit with the canonical form.

## bug: (d,q) = (4,16)
## No problem for q = 32.

     gram := CanonicalQuadraticForm("elliptic", d, f);
     block := RESET( MutableCopyMat( gram{[1,2]}{[1,2]} ), 2, q);
	 frob := FrobeniusAutomorphism( f );
     mat := First( GL(2,f), t -> RESET(t * block^frob *TransposedMat(t), 2, q) = block);
     mat2 := IdentityMat(d,f);  #NullMat(d,d,f);
    # for i in [1..d/2-1] do
    #     mat2{[2*i+1,2*i+2]}{[2*i+1,2*i+2]} := [[0,1],[1,0]] * One(f);
    # od;
     mat2{[1,2]}{[1,2]} := mat;
	 a := ProjElWithFrob( mat2, frob, f);
	 gens := ShallowCopy( GeneratorsOfGroup(go) );
     Add(gens, a);
     coll := GroupWithGenerators( gens );
	 SetName( coll, Concatenation("PGammaO-(",String(d),",",String(q),")") );
	 SetSize( coll, Size(go) * Order(frob) );
  fi;
  
  return coll;
  end );

###### Orthogonal (parabolic) groups ######

InstallMethod( GammaO, [IsPosInt, IsField and IsFinite],
  function(d, f)
    local q, p, go, gens, frob, m, b, lambda, g, w, one;
    one := One(f);
    q := Size(f);
    p := Characteristic(f);
    go := GO(0, d, q);
    gens := ShallowCopy(GeneratorsOfGroup(go));
    frob := FrobeniusAutomorphism( f );
    if IsOddInt(q) then
      m := InvariantBilinearForm(GO(0,d,q))!.matrix;
      b := BaseChangeOrthogonalBilinear(m, f)[1]; 
      gens := List(gens, t->b*t*b^-1);; 
    else 
      m := InvariantQuadraticForm(GO(0,d,q))!.matrix;
      b := BaseChangeOrthogonalQuadratic(m, f)[1];
      gens := List(gens, t->b*t*b^-1);;
    fi;
    if IsOddInt(p) then
       if q mod 8 in [5,7] then 
          w := Z(p) * ((p + 1) / 2);
       else
          w := one * ((p + 1) / 2);
       fi; 
    else
       w := one;
    fi; 
    lambda := First(AsList(f),t->t^2 = w^(p-1));
    gens := List(gens, x -> [x,frob^0]);
    Add(gens, [lambda * IdentityMat(d, f), frob] );
    gens := ProjElsWithFrob( gens, f );
    g := GroupWithGenerators( gens );
    SetName( g, Concatenation("PGammaO(",String(d),",",String(q),")") );
    SetSize( g, Order(frob) * Size(go) / 2 );
    return g;
  end );


###### Orthogonal (hyperbolic) groups ######

InstallMethod( DeltaOplus, [IsPosInt, IsField and IsFinite],
  function(d, f)
    local q, go, m, w, mu, i, gens, g, b;  
    q := Size(f);
    go := GO(1, d, q);
    gens := ShallowCopy(GeneratorsOfGroup(go));
  
    if IsOddInt(q) then
      m := InvariantBilinearForm(go)!.matrix;
      b := BaseChangeOrthogonalBilinear(m, f)[1]; 
      w := PrimitiveRoot( f );
    
    ## put primitive root on odd places of diagonal
    ## of identity matrix

      mu := IdentityMat(d,f);
      for i in [1..d/2] do
        mu[2*i-1][2*i-1] := w;
      od;

      gens := List(gens, t->b*t*b^-1);; 
      Add(gens, mu);
    else 
      m := InvariantQuadraticForm(go)!.matrix;
      b := BaseChangeOrthogonalQuadratic(m, f)[1];
      gens := List(gens, t->b*t*b^-1);;
    fi;

    gens := ProjElsWithFrob( List(gens, x -> [x,IdentityMapping(f)]), f );
    g := GroupWithGenerators( gens );
    SetName( g, Concatenation("PDeltaO+(",String(d),",",String(q),")") );
    SetSize( g, 2*q^(d*(d-2)/4)*(q^(d/2)-1)*Product(List([1..d/2-1],
                   i -> (q^(2*i)-1) )) );
    return g;
  end );

InstallMethod( GammaOplus, [IsPosInt, IsField and IsFinite],
  function(d, f)
    local q, deltao, gens, frob, lambda, g;
    q := Size(f);
    deltao := DeltaOplus(d, f);
    gens := ShallowCopy(GeneratorsOfGroup(deltao));
    frob := FrobeniusAutomorphism( f );
    Add(gens, ProjElWithFrob( IdentityMat(d, f), frob, f ));
    g := GroupWithGenerators( gens );
    SetName( g, Concatenation("PGammaO+(",String(d),",",String(q),")") );
    SetSize( g, Log(q, Characteristic(f)) * Size(deltao) );
    return g;
  end );

###### Hermitian groups ######

InstallMethod( GammaU, [IsPosInt, IsField and IsFinite],
  function(d, f)
    local m, frob, b, gens, g, q, sqrtq, gu;
    q := Size(f);
    sqrtq := Sqrt(Size(f));
    m := InvariantSesquilinearForm(GU(d,sqrtq))!.matrix;     
    b := BaseChangeHermitian(m, f)[1];
    frob := FrobeniusAutomorphism(f);
    gu := GU(d,sqrtq);
    gens := GeneratorsOfGroup( gu );
    gens := List( gens, y -> b * y * b^-1);
    gens := List( gens, x -> [x, frob^0]);
    Add(gens, [IdentityMat(d, f), frob] );
    gens := ProjElsWithFrob( gens, f );
    g := GroupWithGenerators( gens );
    SetName( g, Concatenation("PGammaU(",String(d),",",String(sqrtq),"^2)") );
    SetSize( g, Order(frob) * Size(gu) / (sqrtq+1) );
    return g;
  end );
