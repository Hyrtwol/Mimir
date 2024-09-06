package fft

import "base:runtime"
import "core:fmt"
import "core:math"

integer :: i32
single :: f32
double :: f64
TFloat :: single
//TComplex :: complex32
TComplex :: complex64

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


// case complex32:  r, i = f64(real(z)), f64(imag(z))

// Factorise the series with length Count into FactorCount factors, stored in Fact
Factorize :: proc(CCount: integer, FactorCount: ^integer, Fact: ^TIdx1FactorArray) {

	Count := CCount
	i: integer
	Factors: TIdx1FactorArray

	// Define specific FFT lengths (radices) that we can process with optimised routines
	cRadixCount: integer = 6
	//cRadices: [1..6]integer = (2, 3, 4, 5, 8, 10);
	cRadices: [7]integer = {0, 2, 3, 4, 5, 8, 10}

	if Count == 1 {
		FactorCount^ = 1
		Factors[1] = 1
	} else {
		FactorCount^ = 0
	}

	// Factorise the original series length Count into known factors and rest value
	i = cRadixCount
	for (Count > 1) && (i > 0) {
		if Count % cRadices[i] == 0 {
			Count /= cRadices[i]
			FactorCount^ += 1
			Factors[FactorCount^] = cRadices[i]
		} else {
			i -= 1
		}
	}

	// substitute factors 2*8 with more optimal 4*4
	if Factors[FactorCount^] == 2 {
		i = FactorCount^ - 1
		for ((i > 0) && (Factors[i] != 8)) {
			i -= 1
		}
		if i > 0 {
			Factors[FactorCount^] = 4
			Factors[i] = 4
		}
	}

	// Analyse the rest value and see if it can be factored in primes
	if Count > 1 {
		c := integer(math.trunc(math.sqrt(f32(Count))))
		for i in 2 ..= c {
			for (Count % i) == 0 {
				Count /= i
				FactorCount^ += 1
				Factors[FactorCount^] = i
			}
		}

		if (Count > 1) {
			FactorCount^ += 1
			Factors[FactorCount^] = Count
		}
	}

	// Reverse factors so that primes are first
	for i in 1 ..= FactorCount^ {
		Fact[i] = Factors[FactorCount^ - i + 1]
	}
}

// Reorder the series in X to a permuted sequence in Y so that the later step can
// be done in place, and the final FFT result is in correct order.
// The series X and Y must be different series!
ReorderSeries :: proc(Count: integer, Factors: ^TIdx1FactorArray, Remain: ^TIdx0FactorArray, X: ^[]TComplex, Y: ^[]TComplex) {

	i, j, k: integer
	Counts: TIdx1FactorArray

	//FillChar(Counts, SizeOf(Counts), 0);
	runtime.memset(&Counts, 0, size_of(Counts))

	k = 0
	for i in 0 ..= Count - 2 {
		Y[i] = X[k]
		j = 1
		k = k + Remain[j]
		Counts[1] = Counts[1] + 1
		for Counts[j] >= Factors[j] {
			Counts[j] = 0
			k = k - Remain[j - 1] + Remain[j + 1]
			j += 1
			Counts[j] += 1
		}
	}

	Y[Count - 1] = X[Count - 1]
}

FFT_2 :: proc(Z: ^[]TComplex) {
	T1 := Z[0] + Z[1]
	Z[1] = Z[0] - Z[1]
	Z[0] = T1
}

FFT_3 :: proc(Z: ^[]TComplex) {
	T1, M1, M2, S1: TComplex

	T1 = Z[1] + Z[2]
	Z[0] = Z[0] + T1

	//M1 = T1 * c31
	M1 = complex(c31 * real(T1), c31 * imag(T1))
	// M2.Re = c32 * (Z[1].Im - Z[2].Im)
	// M2.Im = c32 * (Z[2].Re - Z[1].Re)
	M2 = complex(c32 * (imag(Z[1]) - imag(Z[2])), c32 * (real(Z[2]) - real(Z[1])))

	S1 = Z[0] + M1
	Z[1] = S1 + M2
	Z[2] = S1 - M2
}

FFT_4 :: proc(Z: ^[^]TComplex) {
	T1, T2, M2, M3: TComplex

	T1 = Z[0] + Z[2]
	T2 = Z[1] + Z[3]

	M2 = Z[0] - Z[2]
	// M3.Re = Z[1].Im - Z[3].Im
	// M3.Im = Z[3].Re - Z[1].Re
	M3 = complex(imag(Z[1]) - imag(Z[3]), real(Z[3]) - real(Z[1]))

	Z[0] = T1 + T2
	Z[2] = T1 - T2
	Z[1] = M2 + M3
	Z[3] = M2 - M3
}

FFT_5 :: proc(Z: ^[^]TComplex) {
	T1, T2, T3, T4, T5: TComplex
	M1, M2, M3, M4, M5: TComplex
	S1, S2, S3, S4, S5: TComplex

	T1 = Z[1] + Z[4]
	T2 = Z[2] + Z[3]
	T3 = Z[1] - Z[4]
	T4 = Z[3] - Z[2]

	T5 = T1 + T2
	Z[0] = Z[0] + T5
	//M1 = c51 * T5 // M1   := ComplexScl(c51, T5);
	M1 = complex(c51, 0) * T5
	M2 = complex(c52, 0) * (T1 - T2)

	// M3.Re = -c53 * (T3.Im + T4.Im)
	// M3.Im = c53 * (T3.Re + T4.Re)
	M3 = complex(-c53 * (imag(T3) + imag(T4)), c53 * (real(T3) + real(T4)))
	// M4.Re = -c54 * T4.Im
	// M4.Im = c54 * T4.Re
	M4 = complex(-c54 * imag(T4), c54 * real(T4))
	// M5.Re = -c55 * T3.Im
	// M5.Im = c55 * T3.Re
	M5 = complex(-c55 * imag(T3), c55 * real(T3))

	S3 = M3 - M4
	S5 = M3 + M5
	S1 = Z[0] + M1
	S2 = S1 + M2
	S4 = S1 - M2

	Z[1] = S2 + S3
	Z[2] = S4 + S5
	Z[3] = S4 - S5
	Z[4] = S2 - S3
}

FFT_8 :: proc(Z: ^[]TComplex) {
	A, B: [4]TComplex
	Gem: TFloat

	A[0] = Z[0];B[0] = Z[1]
	A[1] = Z[2];B[1] = Z[3]
	A[2] = Z[4];B[2] = Z[5]
	A[3] = Z[6];B[3] = Z[7]

	FFT_4(&A[:])
	FFT_4(&B[:])

	Gem = c8 * (real(B[1]) + imag(B[1]))
	//B[1].Im = c8 * (imag(B[1]) - B[1].Re)
	//B[1].Re = Gem
	B[1] = complex(c8 * (imag(B[1]) - real(B[1])), Gem)
	Gem = imag(B[2])
	// B[2].Im = -real(zB[2])
	// B[2].Re = Gem
	B[2] = complex(-real(B[2]), Gem)
	Gem = c8 * (imag(B[3]) - real(B[3]))
	// B[3].Im = -c8 * (real(B[3]) + imag(B[3]))
	// B[3].Re = Gem
	B[2] = complex(-c8 * (real(B[3]) + imag(B[3])), Gem)

	Z[0] = A[0] + B[0];Z[4] = A[0] - B[0]
	Z[1] = A[1] + B[1];Z[5] = A[1] - B[1]
	Z[2] = A[2] + B[2];Z[6] = A[2] - B[2]
	Z[3] = A[3] + B[3];Z[7] = A[3] - B[3]
}

FFT_10 :: proc(Z: ^[]TComplex) {
	A, B: [5]TComplex

	A[0] = Z[0];B[0] = Z[5]
	A[1] = Z[2];B[1] = Z[7]
	A[2] = Z[4];B[2] = Z[9]
	A[3] = Z[6];B[3] = Z[1]
	A[4] = Z[8];B[4] = Z[3]

	FFT_5(cast(^[]TComplex)&A)
	FFT_5(cast(^[]TComplex)&B)

	Z[0] = A[0] + B[0];Z[5] = A[0] - B[0]
	Z[6] = A[1] + B[1];Z[1] = A[1] - B[1]
	Z[2] = A[2] + B[2];Z[7] = A[2] - B[2]
	Z[8] = A[3] + B[3];Z[3] = A[3] - B[3]
	Z[4] = A[4] + B[4];Z[9] = A[4] - B[4]
}

SynthesizeFFT :: proc(Sofar, Radix, Remain: integer, Y: ^[]TComplex) {

	GroupOffset, DataOffset, Position: integer
	GroupNo, DataNo, BlockNo, SynthNo: integer
	Omega: double
	S, CosSin: TComplex
	Synth, Trig, Z: [cMaxPrimeFactor]TComplex

	InitializeTrigonomials :: proc(Radix: integer) {
		// Initialize trigonomial coefficients
		W: double = 2 * math.PI / f64(Radix)
		Trig[0] = complex(1.0, 0.0)
		X: TComplex = complex(math.cos(W), -math.sin(W))
		Trig[1] = X
		for i in 2 ..< Radix {
			//Trig[i] := ComplexMul(X, Trig[i - 1])
			Trig[i] = X * Trig[i - 1]
		}
	}

	FFT_Prime :: proc(Radix: integer) {
		// This is the general DFT, which can't be made any faster by factoring because
		// Radix is a prime number
		i, j, k, N, AMax: integer
		Re, Im: TComplex
		V, W: [cMaxPrimeFactorDiv2]TComplex

		N = Radix
		AMax = (N + 1) / 2
		for j in 1 ..< AMax {
			// V[j].Re := Z[j].Re + Z[n - j].Re
			// V[j].Im := Z[j].Im - Z[n - j].Im
			V[j] = complex(real(Z[j]) + real(Z[n - j]), imag(Z[j]) - imag(Z[n - j]))
			// W[j].Re := Z[j].Re - Z[n - j].Re
			// W[j].Im := Z[j].Im + Z[n - j].Im
			W[j] = complex(real(Z[j]) - real(Z[n - j]), imag(Z[j]) + imag(Z[n - j]))
		}

		for j in 1 ..< AMax {
			Z[j] = Z[0]
			Z[N - j] = Z[0]
			k = j
			for i in 1 ..< AMax {
				// Re.Re := Trig[k].Re * V[i].Re
				// Re.im := Trig[k].Re * W[i].Im
				Re = complex(Trig[k].Re * V[i].Re, Trig[k].Re * W[i].Im)
				// Im.Re := Trig[k].Im * W[i].Re
				// Im.Im := Trig[k].Im * V[i].Im
				Im = complex(Trig[k].Im * W[i].Re, Trig[k].Im * V[i].Im)

				// Z[N - j].Re = Z[N - j].Re + Re.Re + Im.Im
				// Z[N - j].Im = Z[N - j].Im + Re.Im - Im.Re
				Z[N - j] = complex(Z[N - j].Re + Re.Re + Im.Im, Z[N - j].Im + Re.Im - Im.Re)
				// Z[j].Re = Z[j].Re + Re.Re - Im.Im
				// Z[j].Im = Z[j].Im + Re.Im + Im.Re
				Z[j] = complex(Z[j].Re + Re.Re - Im.Im, Z[j].Im + Re.Im + Im.Re)

				k = k + j
				if k >= N {
					k = k - N
				}
			}
		}

		for j in 1 ..< AMax {
			// Z[0].Re := Z[0].Re + V[j].Re
			// Z[0].Im := Z[0].Im + W[j].Im
			Z[0] += W[j]
		}
	}

	// Initialize trigonomial coefficients
	InitializeTrigonomials(Radix)

	Omega = 2 * math.PI / f64(Sofar * Radix)
	CosSin = complex(math.cos(Omega), -math.sin(Omega))
	S = complex(1.0, 0.0)
	DataOffset = 0
	GroupOffset = 0
	Position = 0

	for DataNo in 0 ..< Sofar {
		if Sofar > 1 {
			Synth[0] = complex(1.0, 0.0)
			Synth[1] = S
			for SynthNo in 2 ..< Radix {
				Synth[SynthNo] = S * Synth[SynthNo - 1]
			}
			S = CosSin * S
		}

		for GroupNo in 0 ..< Remain {

			if (Sofar > 1) && (DataNo > 0) {
				Z[0] = Y[Position]
				//BlockNo = 1
				//repeat
				for BlockNo in 1 ..< Radix {
					Position += Sofar
					Z[BlockNo] = Synth[BlockNo] * Y[Position]
				}
				//   BlockNo += 1
				//until BlockNo >= Radix
			} else {
				for BlockNo in 0 ..< Radix {
					Z[BlockNo] = Y[Position]
					Position += Sofar
				}
			}

			switch Radix {
			case 2:
				FFT_2(cast(^[]TComplex)&Z)
			case 3:
				FFT_3(cast(^[]TComplex)&Z)
			case 4:
				FFT_4(cast(^[]TComplex)&Z)
			case 5:
				FFT_5(cast(^[]TComplex)&Z)
			case 8:
				FFT_8(cast(^[]TComplex)&Z)
			case 10:
				FFT_10(cast(^[]TComplex)&Z)
			case:
				FFT_Prime(Radix) // Any larger prime number than 5 (so 7, 11, 13, etc, up to cMaxPrimeFactor)
			}

			Position = GroupOffset
			for BlockNo in 0 ..< Radix {
				Y[Position] = Z[BlockNo]
				Position += Sofar
			}
			GroupOffset = GroupOffset + Sofar * Radix
			Position = GroupOffset
		}
		DataOffset += 1
		GroupOffset = DataOffset
		Position = DataOffset
	}
}


ForwardFFT :: proc(Source: ^[]TComplex, Dest: ^[]TComplex, Count: integer) {
	// Perform a FFT on the data in Source, put result in Dest. This routine works best
	// for Count as a power of 2, but also works usually faster than DFT by factoring
	// the series. Only in cases where Count is a prime number will this method be
	// identical to regular DFT.
	PComplexArray :: ^TComplexArray
	TComplexArray :: [^]TComplex

	i: integer
	FactorCount: integer
	SofarRadix: TIdx1FactorArray
	ActualRadix: TIdx1FactorArray
	RemainRadix: TIdx0FactorArray
	//TmpDest: PComplexArray
	TmpDest: []TComplex

	if Count == 0 {return}

	// Decompose the series with length Count into FactorCount factors in ActualRadix
	Factorize(Count, &FactorCount, &ActualRadix)

	// Check if our biggest prime factor is not too large
	if ActualRadix[1] > cMaxPrimeFactor {panic(sErrPrimeTooLarge)}

	// Setup Sofar and Remain tables
	RemainRadix[0] = Count
	SofarRadix[1] = 1
	RemainRadix[1] = Count / ActualRadix[1]
	for i in 2 ..= FactorCount {
		SofarRadix[i] = SofarRadix[i - 1] * ActualRadix[i - 1]
		RemainRadix[i] = RemainRadix[i - 1] / ActualRadix[i]
	}

	// Make temp copy if dest = source (otherwise the permute procedure will completely
	// ruin the structure
	//if @Dest = @Source then begin
	if Dest == Source {
		//GetMem(TmpDest, SizeOf(TComplex) * Count);
		TmpDest = make([]TComplex, Count)
		//Move(Dest, TmpDest^, SizeOf(TComplex) * Count);
		runtime.memcpy(Dest, &TmpDest, size_of(TComplex) * Count)
	} else {
		TmpDest = Dest
	}

	// Reorder the series so that the elements are already in the right place for
	// synthesis
	ReorderSeries(
		Count,
		/*, FactorCount*/
		&ActualRadix,
		&RemainRadix,
		Source,
		&TmpDest,
	)

	// Free the temporary copy (if any)
	//if @Dest = @Source then begin
	if Dest == Source {
		//Move(TmpDest^, Dest, SizeOf(TComplex) * Count);
		runtime.memcpy(&TmpDest, Dest, size_of(TComplex) * Count)
		//FreeMem(TmpDest);
		// defer
		delete(TmpDest)
	}

	// Synthesize each of the FFT factored series
	for i in 1 ..= FactorCount {
		SynthesizeFFT(SofarRadix[i], ActualRadix[i], RemainRadix[i], Dest)
	}
}

InverseFFT :: proc(Source: ^[]TComplex, Dest: ^[]TComplex, Count: integer) {
	// Perform the inverse FFT on the Source data, and put result in Dest. It performs
	// the forward FFT and then divides elements by N
	if Count == 0 {return}

	// Since TmpSource is local, we do not have to free it again,
	// it will be freed automatically when out of scope
	//SetLength(TmpSource, Count);
	TmpSource := make([]TComplex, Count)
	defer delete(TmpSource)

	// Create a copy with inverted imaginary part.
	for i in 0 ..< Count {
		//with Source[i] do
		//  TmpSource[i] := Complex(Re, -Im);
		TmpSource[i] = complex(real(Source[i]), -imag(Source[i]))
	}
	ForwardFFT(TmpSource, Dest, Count)

	// Scale by 1/Count, and inverse the imaginary part
	S: f32 = 1.0 / f32(Count)
	for i in 0 ..< Count {
		//Dest[i].Re := S * Dest[i].Re
		//Dest[i].Im := -S * Dest[i].Im
		Dest[i] = complex(S * real(Dest[i]), -S * imag(Dest[i]))
	}
}
