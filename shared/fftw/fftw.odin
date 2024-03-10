package fftw

import "core:fmt"
import "core:math"

integer :: i32
single :: f32
TFloat :: single;

cMinFloat :: 1.5E-45
cMaxFloat :: 3.4E38

cMaxPrimeFactor :: 1021
cMaxPrimeFactorDiv2 :: (cMaxPrimeFactor + 1) / 2
cMaxFactorCount :: 20

sErrPrimeTooLarge :: "Prime factor for FFT length too large. Change value for cMaxPrimeFactor in FFTs unit"

// implementation

c31: f32 = -1.5000000000000E+00 //  cos(2*pi / 3) - 1;
c32: f32 = 8.6602540378444E-01 //  sin(2*pi / 3);

u5: f32 = 1.2566370614359E+00 //  2*pi / 5;
c51: f32 = -1.2500000000000E+00 // (cos(u5) + cos(2*u5))/2 - 1;
c52: f32 = 5.5901699437495E-01 // (cos(u5) - cos(2*u5))/2;
c53: f32 = -9.5105651629515E-01 //- sin(u5);
c54: f32 = -1.5388417685876E+00 //-(sin(u5) + sin(2*u5));
c55: f32 = 3.6327126400268E-01 // (sin(u5) - sin(2*u5));
c8: f32 = 7.0710678118655E-01 //  1 / sqrt(2);

TIdx0FactorArray :: [cMaxFactorCount + 1]integer
TIdx1FactorArray :: [cMaxFactorCount]integer
