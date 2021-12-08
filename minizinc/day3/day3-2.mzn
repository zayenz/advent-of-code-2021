include "globals.mzn";

% Input
int: ndiagnostics;
int: nbits;
array[Diagnostics, Bits] of Bit: diagnostics;

% Data

set of int: Diagnostics = 1..ndiagnostics;
set of int: Bit  = 0..1;
set of int: Bits = 1..nbits;
set of int: ExtendedBits = 0..nbits;

function int: value_helper(array[Bits] of Bit: word, Bits: pos, int: base) =
    word[pos] * pow(2, base) +
    if pos-1 in Bits then
        value_helper(word, pos-1, base+1)
    else
        0
    endif;

function int: value(array[Bits] of Bit: word) = 
    value_helper(word, nbits, 0);

function Diagnostics: gamma_filter(set of Diagnostics: candidates, int: bit) = 
    if card(candidates) = 1 then
        min(candidates)
    else
        let {
            Bit: gamma = count([diagnostics[c, bit] | c in candidates], 1) >= card(candidates) / 2
        } in
            gamma_filter({c | c in candidates where diagnostics[c, bit] = gamma}, bit + 1)
    endif;

function Diagnostics: epsilon_filter(set of Diagnostics: candidates, int: bit) = 
    if card(candidates) = 1 then
        min(candidates)
    else
        let {
            Bit: epsilon = count([diagnostics[c, bit] | c in candidates], 1) < card(candidates) / 2
        } in
            epsilon_filter({c | c in candidates where diagnostics[c, bit] = epsilon}, bit + 1)
    endif;

Diagnostics: ogr_diagnostic = gamma_filter(Diagnostics, 1);
array[Bits] of Bit: ogr = diagnostics[ogr_diagnostic, ..];
int: ogr_value = value(ogr);
Diagnostics: co2_diagnostic = epsilon_filter(Diagnostics, 1);
array[Bits] of Bit: co2 = diagnostics[co2_diagnostic, ..];
int: co2_value = value(co2);

int: checksum = ogr_value * co2_value;

% Variables

% Constraints

% Solve and output
solve satisfy;

output [
%  "diagnostics: ", show2d(diagnostics), "\n",
  "ogr diagnostic: ", show(ogr_diagnostic), "\n",
  "ogr:            ", show(ogr), "\n",
  "ogr value:      ", show(ogr_value), "\n",
  "co2 diagnostic: ", show(co2_diagnostic), "\n",
  "co2:            ", show(co2), "\n",
  "co2 value:      ", show(co2_value), "\n",
  "checksum:      ", show(checksum), "\n",
];
