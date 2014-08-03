#############################################################################
##
##  gpolygons.gd              FinInG package
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
##  Declaration stuff for generalised polygons.
##
#############################################################################


# see .gi file for comments on the representation.
DeclareRepresentation( "IsGeneralisedPolygonRep", IsGeneralisedPolygon, [ "incidence", "pointsobj", "linesobj", "listelements", "shadpoint", "shadline", "distance" ]);

DeclareCategory( "IsElementOfGeneralisedPolygon", IsElementOfIncidenceGeometry );

DeclareRepresentation( "IsElementsOfGeneralisedPolygonRep", IsElementsOfIncidenceStructureRep, [ "geometry", "type", "obj" ] );
DeclareCategory( "IsElementsOfGeneralisedPolygon", IsElementsOfIncidenceGeometry );
DeclareCategory( "IsAllElementsOfGeneralisedPolygon", IsAllElementsOfIncidenceGeometry );

DeclareCategory( "IsShadowElementsOfGeneralisedPolygon", IsElementsOfIncidenceStructure );
DeclareRepresentation( "IsShadowElementsOfGeneralisedPolygonRep", IsElementsOfIncidenceStructure, [ "geometry", "type", "element", "func" ]);

DeclareCategory( "IsElationGQ", IsGeneralisedQuadrangle );
DeclareCategory( "IsElationGQByKantorFamily", IsElationGQ ); #needed?

#############################################################################
# Constructor operations:
#############################################################################

DeclareOperation( "GeneralisedPolygonByBlocks", [ IsHomogeneousList ] );
DeclareOperation( "GeneralisedPolygonByIncidenceMatrix", [ IsMatrix ] );
DeclareOperation( "GeneralisedPolygonByElements", [ IsSet, IsSet, IsFunction ] );
DeclareOperation( "GeneralisedPolygonByElements", [ IsSet, IsSet, IsFunction, IsGroup, IsFunction ] );

#############################################################################
# Operations, Functions, Attributes 
#############################################################################

DeclareOperation( "DistanceBetweenElements", [IsElementOfGeneralisedPolygon, IsElementOfGeneralisedPolygon ] );

DeclareAttribute( "CollineationAction", IsGroup);

#############################################################################
# Attributes
#############################################################################

# normal ones

DeclareAttribute( "Order", IsGeneralisedPolygon);
DeclareAttribute( "IncidenceMatrixOfGeneralisedPolygon", IsGeneralisedPolygon);

# mutable attributes

if not IsBound( BlockDesign ) then 
   BlockDesign := function(arg) return 1; end;
fi;


BlockDesignOfGeneralisedPolygonAttr := NewAttribute( "BlockDesignOfGeneralisedPolygonAttr", 
                    IsGeneralisedPolygon, "mutable" );
IncidenceGraphOfGeneralisedPolygonAttr := NewAttribute( "IncidenceGraphOfGeneralisedPolygonAttr", 
					IsGeneralisedPolygon, "mutable" );

DeclareOperation( "BlockDesignOfGeneralisedPolygon", [ IsGeneralisedPolygon ] );
DeclareOperation( "IncidenceGraphOfGeneralisedPolygon", [ IsGeneralisedPolygon ]);

#############################################################################
# Classical Generalised Hexagons
#############################################################################

# helper functions for triality

DeclareGlobalFunction( "SplitCayleyPointToPlane" );
DeclareGlobalFunction( "SplitCayleyPointToPlane5" );
DeclareGlobalFunction( "ZeroPointToOnePointsSpaceByTriality" );
DeclareGlobalFunction( "TwistedTrialityHexagonPointToPlaneByTwoTimesTriality" );

# constructor operations for the hexagons

DeclareOperation( "SplitCayleyHexagon", [IsField and IsFinite] );
DeclareOperation( "SplitCayleyHexagon", [IsPosInt] );
DeclareOperation( "SplitCayleyHexagon", [IsClassicalPolarSpace] );
DeclareOperation( "TwistedTrialityHexagon", [IsField and IsFinite] );
DeclareOperation( "TwistedTrialityHexagon", [IsPosInt] );

# attributes

DeclareAttribute( "AmbientPolarSpace", IsGeneralisedHexagon);

# groups

DeclareOperation("G2fining", [IsPosInt, IsField and IsFinite] );
DeclareOperation("3D4fining", [IsField and IsFinite] );


#############################################################################
# Elation Generalised Quadrangles
#############################################################################

# Kantor families

DeclareOperation( "IsKantorFamily", [IsGroup, IsList, IsList]);

DeclareCategory( "IsElementOfKantorFamily", IsElementOfGeneralisedPolygon );
DeclareRepresentation( "IsElementOfKantorFamilyRep", IsElementOfKantorFamily, [ "geo", "type", "class", "obj" ]);

DeclareGlobalFunction( "OnKantorFamily" );

DeclareOperation( "EGQByKantorFamily", [IsGroup, IsList, IsList] );
DeclareOperation( "Wrap", [IsElationGQByKantorFamily, IsPosInt, IsPosInt, IsObject] );

# q-clans

DeclareCategory( "IsqClanObj", IsComponentObjectRep and IsAttributeStoringRep );
DeclareRepresentation( "IsqClanRep", IsqClanObj, [ "matrices", "basefield" ] ); 

BindGlobal( "qClanFamily", NewFamily( "qClanFamily" ) );

DeclareAttribute( "IsLinearqClan", IsqClanObj );

#particular q-clans

DeclareOperation( "IsAnisotropic", [IsFFECollColl,  IsField and IsFinite]);
DeclareOperation( "IsqClan", [ IsFFECollCollColl, IsField and IsFinite ]);
DeclareOperation( "qClan", [ IsFFECollCollColl, IsField ] );
DeclareOperation( "LinearqClan", [ IsPosInt ] );
DeclareOperation( "FisherThasWalkerKantorBettenqClan", [ IsPosInt ] );
DeclareOperation( "KantorMonomialqClan", [ IsPosInt ] );
DeclareOperation( "KantorKnuthqClan", [ IsPosInt ] );
DeclareOperation( "FisherqClan", [ IsPosInt ] );

# switching between q-clans, Kantor families and BLT sets

DeclareOperation( "BLTSetByqClan", [ IsqClanObj and IsqClanRep ] );
DeclareOperation( "KantorFamilyByqClan", [ IsqClanObj and IsqClanRep ] );
DeclareOperation( "EGQByqClan", [ IsqClanObj and IsqClanRep ] );

# constructor operations

DeclareOperation( "EGQByBLTSet", [IsList, IsSubspaceOfProjectiveSpace, IsSubspaceOfProjectiveSpace] );
DeclareOperation( "EGQByBLTSet", [IsList] );

DeclareOperation( "FlockGQByqClan", [ IsqClanObj ] );

DeclareAttribute( "ElationGroup", IsElationGQ);
DeclareAttribute( "BasePointOfEGQ", IsElationGQ);















#DeclareCategory( "IsAllElementsOfProjectivePlane", IsAllElementsOfGeneralisedPolygon );
#DeclareRepresentation( "IsAllElementsOfProjectivePlaneRep", IsAllElementsOfGeneralisedPolygonRep, [ "geometry", "type" ] );

#DeclareCategory( "IsAllElementsOfGeneralisedQuadrangle", IsAllElementsOfGeneralisedPolygon );
#DeclareRepresentation( "IsAllElementsOfGeneralisedQuadrangleRep", IsAllElementsOfGeneralisedPolygonRep, [ "geometry", "type" ] );


#DeclareCategory( "IsAllElementsOfGeneralisedHexagon", IsAllElementsOfGeneralisedPolygon );
#DeclareRepresentation( "IsAllElementsOfGeneralisedHexagonRep", IsAllElementsOfGeneralisedPolygonRep, [ "geometry", "type" ] );

#DeclareCategory( "IsAllElementsOfKantorFamily", IsAllElementsOfGeneralisedPolygon );

### new stuff





#############################################################################
# Attributes:
#############################################################################

#DeclareAttribute( "AmbientSpace", IsGeneralisedPolygon);



#############################################################################
# Operations and functions 
#############################################################################


#DeclareOperation("Span",[IsElementOfGeneralisedPolygon, IsElementOfGeneralisedPolygon]);




## q-clans

## Elation Generalised Quadrangles


#---------------------
## obselete operations
# DeclareOperation( "EGQByqClan", [ IsFFECollCollColl, IsField and IsFinite ]);
# DeclareOperation( "KantorFamilyByqClan", [ IsFFECollCollColl, IsField and IsFinite ]); 
# DeclareOperation( "BLTSetByqClan", [ IsFFECollCollColl, IsField and IsFinite ]);
#---------------------

#############################################################################
# Operations and functions for projective planes
#############################################################################

#DeclareOperation( "ProjectivePlaneByBlocks", [ IsHomogeneousList ] );
#DeclareOperation( "ProjectivePlaneByIncidenceMatrix", [ IsMatrix ] );

