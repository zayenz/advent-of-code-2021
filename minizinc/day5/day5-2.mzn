include "globals.mzn";

% Input
int: nlines;
array[Lines, FourCoordinates] of int: lines;

array[Lines] of int: x_starts = [lines[line, x_start] | line in Lines];
array[Lines] of int: x_ends   = [lines[line, x_end]   | line in Lines];
array[Lines] of int: y_starts = [lines[line, y_start] | line in Lines];
array[Lines] of int: y_ends   = [lines[line, y_end]   | line in Lines];

array[Lines] of int: ox_starts = [ min(x_starts[line], x_ends[line]) | line in Lines];
array[Lines] of int: ox_ends   = [ max(x_starts[line], x_ends[line]) | line in Lines];
array[Lines] of int: oy_starts = [ min(y_starts[line], y_ends[line]) | line in Lines];
array[Lines] of int: oy_ends   = [ max(y_starts[line], y_ends[line]) | line in Lines];

% Starts for y lines that match the ox_starts
array[Lines] of int: my_starts = [ if ox_starts[line] = x_starts[line] then y_starts[line] else y_ends[line] endif | line in Lines];


% Data
set of int: FourCoordinates = 1..4;
FourCoordinates: x_start = 1;
FourCoordinates: x_end = 3;
FourCoordinates: y_start = 2;
FourCoordinates: y_end = 4;
set of int: Lines = 1..nlines;

int: minx = min(min(x_starts), min(x_ends));
int: miny = min(min(y_starts), min(y_ends));
int: maxx = max(max(x_starts), max(x_ends));
int: maxy = max(max(y_starts), max(y_ends));

set of int: X = minx..maxx;
set of int: Y = miny..maxy;

set of Lines: HorizontalLines = { 
    line 
  | line in Lines 
      where x_starts[line] = x_ends[line] \/ y_starts[line] = y_ends[line]
};
set of Lines: DiagonalLines = Lines diff HorizontalLines;

array[X] of set of HorizontalLines: usable_horizontal_lines_for_x = array1d(X, [
    {   line
      | line in HorizontalLines
          where ox_starts[line] <= x /\ x <= ox_ends[line]
    }
  | x in X
]);
array[X] of set of DiagonalLines: usable_diagonal_lines_for_x = array1d(X, [
    {   line
      | line in DiagonalLines
          where ox_starts[line] <= x /\ x <= ox_ends[line]
    }
  | x in X
]);

array[Y, X] of int: crossing = array2d(Y, X, [
    sum (line in usable_horizontal_lines_for_x[x]) (
        oy_starts[line] <= y /\ y <= oy_ends[line] 
    ) + 
    sum (line in usable_diagonal_lines_for_x[x]) (
        oy_starts[line] <= y /\ y <= oy_ends[line] /\
        (x - ox_starts[line]) = abs((y - my_starts[line]))
    )
  | y in Y, x in X
]);

int: checksum = sum(x in X, y in Y) (
    crossing[y, x] >= 2
);

% Variables

% Constraints

% Solve and output
solve satisfy;

output [
  "crossing: \n", show2d(crossing), "\n",
  "checksum:   ", show(checksum), "\n",
];
