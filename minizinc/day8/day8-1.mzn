include "globals.mzn";

% Input
int: ndisplays;
set of int: Displays = 1..ndisplays;
array[Displays, Patterns] of set of Segments: patterns;
array[Displays, Outputs] of set of Segments: outputs;

% Data
set of int: Patterns = 1..10;
set of int: Outputs = 1..4;
set of int: Digits = 0..9;
enum Segments = {a, b, c, d, e, f, g};

array[Digits] of set of Segments: lit = [
  0: {a, b, c, e, f, g},
  1: {c, f},
  2: {a, c, d, e, g},
  3: {a, c, d, f, g},  
  4: {b, c, d, f},
  5: {a, b, d, f, g},
  6: {a, b, d, e, f, g},
  7: {a, c, f},
  8: {a, b, c, d, e, f, g},
  9: {a, b, c, d, f, g},
];

array[Displays, Digits] of int: output_potential_counts = array2d(Displays, Digits, [
    sum(out in Outputs) (card(outputs[display, out]) == card(lit[digit]))
  | display in Displays, digit in Digits
]);

int: result = sum(display in Displays, digit in {1, 4, 7, 8}) (
    output_potential_counts[display, digit]
);

% Variables


% Constraints


% Solve and output


solve satisfy;

output [
  "potential counts:\n", show2d(output_potential_counts), "\n",
  "result: ", show(result), "\n",
];
