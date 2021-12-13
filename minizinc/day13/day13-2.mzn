include "globals.mzn";

% Input
int: npoints;
array[Points] of int: points_x;
array[Points] of int: points_y;
int: ninstructions;
array[Instructions] of Coordinates: direction;
array[Instructions] of int: position;

% Data
array[Points, Coordinates] of int: points = array2d(Points, Coordinates, [
    [points_x[p], points_y[p]][c]
  | p in Points, c in Coordinates
]);
enum Coordinates = {x, y};
set of int: Points = 1..npoints;
set of int: Instructions = 1..ninstructions;

function array[Points, 1..2] of int: folding(array[Points, 1..2] of int: input, Instructions: ins) =
    let {
        array[Points, 1..2] of int: folded = array2d(Points, 1..2, [
            [
              if direction[ins] = x then
                  min(input[p, x], position[ins]) - max(0, input[p, x] - position[ins])
              else
                  input[p, x]
              endif,
              if direction[ins] = y then
                  min(input[p, y], position[ins]) - max(0, input[p, y] - position[ins])
             else
                 input[p, y]
              endif,
            ][c]
          | p in Points, c in Coordinates
        ])
    } in
    if ins+1 in Instructions then
        folding(folded, ins+1)
    else
        folded
    endif;

array[Points, 1..2] of int: folded = folding(points, 1);

enum Display = {o, X};
set of int: Xs = 0..max(folded[.., x]);
set of int: Ys = 0..max(folded[.., y]);
array[Ys, Xs] of Display: matrix = array2d(Ys, Xs, [
    if exists(p in Points) (folded[p,x]=xp /\ folded[p,y]=yp) then
        X
    else
        o      
    endif
  | yp in Ys, xp in Xs
]);

int: max_folded_x = max(folded[.., x]) + 1;
int: max_folded_y = max(folded[.., y]) + 1;
array[Points] of int: point_values = [
    folded[p, x] + folded[p, y] * max_folded_x
  | p in Points
];
set of int: unique_point_values = array2set(point_values);

int: checksum = card(unique_point_values);


% Variables

% Constraints

% Solve and output
solve satisfy;

output [
%  "points:\n", show2d(points), "\n",
%  "folded:\n", show2d(folded), "\n",
%  "point values: ", show(point_values), "\n",
  "matrix:\n", show2d(matrix), "\n",
  "checksum: ", show(checksum), "\n",
];
