#############################################################################
##
##  projectivespace.gd        FinInG package
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
##  Declaration stuff for projective spaces.
##
#############################################################################

#############################################################################
#
# Subspaces of projective spaces -  categories and representations:
#
#############################################################################

DeclareCategory( "IsSubspaceOfProjectiveSpace", IsElementOfLieGeometry );
DeclareCategory( "IsSubspacesOfProjectiveSpace", IsElementsOfLieGeometry );
DeclareCategory( "IsAllSubspacesOfProjectiveSpace", IsAllElementsOfLieGeometry );

DeclareCategory( "IsFlagOfProjectiveSpace", IsFlagOfLieGeometry );

#DeclareRepresentation( "IsFlagOfProjectiveSpaceRep", IsFlagOfProjectiveSpace, [ "geo", "types", "els" ] );

DeclareCategory( "IsShadowSubspacesOfProjectiveSpace", IsShadowElementsOfLieGeometry );

DeclareRepresentation( "IsSubspacesOfProjectiveSpaceRep", IsElementsOfLieGeometryRep, [ "geometry", "type" ] );
DeclareRepresentation( "IsAllSubspacesOfProjectiveSpaceRep", IsAllElementsOfLieGeometryRep, [ "geometry", "type" ] );
     	       
DeclareRepresentation( "IsShadowSubspacesOfProjectiveSpaceRep", IsShadowElementsOfLieGeometryRep, [ "geometry", "type", "inner", "outer", "factorspace" ]);

# The following allows us to have recognisable lists of subspaces
# from projective spaces etc.

DeclareCategoryCollections("IsSubspaceOfProjectiveSpace");
BindGlobal( "SoPSFamily", 
  NewFamily( "SoPSFamily", IsSubspaceOfProjectiveSpace, IsSubspaceOfProjectiveSpace));
BindGlobal( "SoPSCollFamily", CollectionsFamily(SoPSFamily) );


BindGlobal( "FlagsOfPS", NewFamily( "FlagsOfPSFamily", IsObject ));  

BindGlobal( "IsFlagOfPSType", NewType( FlagsOfPS,
                                    IsFlagOfProjectiveSpace and IsFlagOfIncidenceStructureRep) );
									
#############################################################################
#
# Constructor operations, and attributes
#
#############################################################################

DeclareOperation( "ProjectiveSpace", [IsInt, IsField] );
DeclareOperation( "ProjectiveSpace", [IsInt, IsPosInt] );
DeclareAttribute( "ProjectivityGroup", IsProjectiveSpace );
DeclareAttribute( "SpecialProjectivityGroup", IsProjectiveSpace );
#DeclareAttribute( "ProjectiveDimension", IsProjectiveSpace ); #next three: more general decl in liegeometry.gd
#DeclareAttribute( "ProjectiveDimension", IsSubspaceOfProjectiveSpace );
#DeclareAttribute( "ProjectiveDimension", IsEmpty );

DeclareAttribute( "Dimension", IsSubspaceOfProjectiveSpace );
DeclareAttribute( "Dimension", IsEmpty );

DeclareAttribute( "Coordinates", IsSubspaceOfProjectiveSpace );
DeclareAttribute( "CoordinatesOfHyperplane", IsSubspaceOfProjectiveSpace );
DeclareAttribute( "EquationOfHyperplane", IsSubspaceOfProjectiveSpace );

DeclareAttribute( "StandardFrame", IsProjectiveSpace );
DeclareAttribute( "StandardFrame", IsSubspaceOfProjectiveSpace );

DeclareOperation( "IsIncident", [IsSubspaceOfProjectiveSpace, IsProjectiveSpace] );
DeclareOperation( "IsIncident", [IsProjectiveSpace, IsSubspaceOfProjectiveSpace] );
#DeclareOperation( "IsIncident", [IsEmptySubspace, IsSubspaceOfProjectiveSpace]);
#DeclareOperation( "IsIncident", [IsSubspaceOfProjectiveSpace, IsEmptySubspace]);
#DeclareOperation( "IsIncident", [IsEmptySubspace, IsProjectiveSpace]);
#DeclareOperation( "IsIncident", [IsProjectiveSpace, IsEmptySubspace]);
DeclareOperation( "IsIncident", [IsProjectiveSpace, IsProjectiveSpace]);
#DeclareOperation( "IsIncident", [IsEmptySubspace, IsEmptySubspace]);

#DeclareAttribute( "AmbientSpace", IsProjectiveSpace ); #next two: more general decl in liegeometry.gd
#DeclareAttribute( "AmbientSpace", IsSubspaceOfProjectiveSpace );


DeclareSynonymAttr( "HomographyGroup", ProjectivityGroup );
DeclareSynonymAttr( "SpecialHomographyGroup", SpecialProjectivityGroup );

DeclareSynonym( "PG", ProjectiveSpace ); 

DeclareOperation( "Hyperplanes", [IsProjectiveSpace] );

#
# This does not need to be declared, as "Size" is already declared for
# higher order filers (e.g., IsCollection)
#
#DeclareAttribute( "Size", IsSubspacesOfProjectiveSpace);
  
#############################################################################
#
# Some user operations.
#
#############################################################################

DeclareOperation( "BaerSublineOnThreePoints", 
  [ IsSubspaceOfProjectiveSpace, IsSubspaceOfProjectiveSpace, IsSubspaceOfProjectiveSpace] );
DeclareOperation( "BaerSubplaneOnQuadrangle", 
  [ IsSubspaceOfProjectiveSpace, IsSubspaceOfProjectiveSpace, 
    IsSubspaceOfProjectiveSpace, IsSubspaceOfProjectiveSpace ] );

#DeclareOperation("RandomSubspace",[IsVectorSpace,IsInt]); #is for vector spaces -> moves to liegeometry.gd
DeclareOperation("RandomSubspace",[IsProjectiveSpace,IsInt]);
DeclareOperation("RandomSubspace",[IsSubspaceOfProjectiveSpace,IsInt]);

DeclareOperation("RandomSubspace",[IsProjectiveSpace]);

DeclareOperation("Span",[IsProjectiveSpace, IsSubspaceOfProjectiveSpace]);
DeclareOperation("Span",[IsSubspaceOfProjectiveSpace, IsProjectiveSpace]);
DeclareOperation("Span",[IsSubspaceOfProjectiveSpace, IsSubspaceOfProjectiveSpace, IsBool]);

#DeclareOperation("Span",[IsHomogeneousList and IsSubspaceOfProjectiveSpaceCollection ]);
DeclareOperation("Span",[IsList]);
DeclareOperation("Span",[IsList, IsBool]);


DeclareOperation( "Meet", [IsSubspaceOfProjectiveSpace, IsProjectiveSpace] );
DeclareOperation( "Meet", [IsProjectiveSpace, IsSubspaceOfProjectiveSpace] );
DeclareOperation( "Meet", [IsList]);

DeclareOperation( "DualCoordinatesOfHyperplane", [IsSubspaceOfProjectiveSpace] );
DeclareOperation( "HyperplaneByDualCoordinates", [IsProjectiveSpace,IsList] );

#############################################################################
# A useful non-user operation.
#############################################################################

DeclareOperation( "ComplementSpace", [IsVectorSpace, IsFFECollColl]);

#############################################################################
# Elations/Homologies of projective spaces
#############################################################################

DeclareOperation( "ElationOfProjectiveSpace", [ IsSubspaceOfProjectiveSpace, IsSubspaceOfProjectiveSpace, IsSubspaceOfProjectiveSpace ] );
DeclareOperation( "ProjectiveElationGroup", [ IsSubspaceOfProjectiveSpace, IsSubspaceOfProjectiveSpace ] );
DeclareOperation( "ProjectiveElationGroup", [ IsSubspaceOfProjectiveSpace ] );

DeclareOperation( "HomologyOfProjectiveSpace", [ IsSubspaceOfProjectiveSpace, IsSubspaceOfProjectiveSpace, 
	IsSubspaceOfProjectiveSpace, IsSubspaceOfProjectiveSpace ] );
DeclareOperation( "ProjectiveHomologyGroup", [ IsSubspaceOfProjectiveSpace, IsSubspaceOfProjectiveSpace ] );



