% Input
int: ndiagnostics;
int: nbits;
array[Diagnostics, Bits] of Bit: diagnostics;

% Data

set of int: Bits = 1..nbits;
set of int: Bit  = 0..1;
set of int: Diagnostics = 1..ndiagnostics;

array[Bits] of Bit: gamma = [
    count(diagnostics[.., b], 1) >= ndiagnostics / 2
  | b in Bits
];
array[Bits] of Bit: epsilon = [
    count(diagnostics[.., b], 1) < ndiagnostics / 2
  | b in Bits
];

function int: value_helper(array[Bits] of Bit: word, Bits: pos, int: base) =
    word[pos] * pow(2, base) +
    if pos-1 in Bits then
        value_helper(word, pos-1, base+1)
    else
        0
    endif;

function int: value(array[Bits] of Bit: word) = 
    value_helper(word, nbits, 0);

int: gamma_value = value(gamma);
int: epsilon_value = value(epsilon);
int: checksum = gamma_value * epsilon_value;

% Variables

% Constraints

% Solve and output
solve satisfy;

output [
%  "diagnostics: ", show2d(diagnostics), "\n",
  "gamma:         ", show(gamma), "\n",
  "gamma value:   ", show(gamma_value), "\n",
  "epsilon:       ", show(epsilon), "\n",
  "epsilon value: ", show(epsilon_value), "\n",
  "checksum:      ", show(checksum), "\n",
];
