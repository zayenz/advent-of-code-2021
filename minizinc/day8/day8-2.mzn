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

% Variables

% Mapping from input labels to actual output labels
array[Displays, Segments] of var Segments: mapping;
% The digit for each pattern
array[Displays, Patterns] of var Digits: pattern_digit;
% The digit on each output display
array[Displays, Outputs] of var Digits: output_digit;
% The total value for each output display
array[Displays] of var int: output_value = [
    1000 * output_digit[display, 1] +
     100 * output_digit[display, 2] +
      10 * output_digit[display, 3] +
       1 * output_digit[display, 4]
  | display in Displays
];
% The requested sum of the outputs
var int: summed_values = sum(output_value);

% Constraints
% All mappings are bijections
constraint forall (display in Displays) (
    all_different(mapping[display, ..]) :: domain
);
% All inputs have one example for each digit
constraint forall (display in Displays) (
   all_different(pattern_digit[display, ..]) :: domain
);

% Given an input segment on a display, map it to 
% the real set of segments to light up using the mapping function
function var set of Segments: map(Displays: display, set of Segments: input) = 
    { mapping[display, s] | s in input };

% Connect patters and outputs to the actual digits using the mapping
constraint forall(display in Displays) (
    forall (pattern in Patterns) (
        lit[pattern_digit[display, pattern]] = map(display, patterns[display, pattern])
    ) /\
    forall (out in Outputs) (
        lit[output_digit[display, out]] = map(display, outputs[display, out])
    )
);


% Solve and output

solve satisfy;

output [
%  "mapping:       ", show2d(mapping), "\n",
  "outputs:       ", show(output_value), "\n",
  "summed values: ", show(summed_values), "\n",
];
