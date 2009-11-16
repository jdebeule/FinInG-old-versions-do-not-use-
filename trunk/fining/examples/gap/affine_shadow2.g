# example: affine_shadow2.g
as := AffineSpace(3, 3);
l := Random( Lines( as ) );
x := Random( Points( as ) );
flag := [x, l];
shadow := ShadowOfFlag( as, flag, 3 );
AsList(shadow);
quit;
