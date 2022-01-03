include "globals.mzn";

% Input
array[int, int] of Cell: initial_grid;

% Data
enum Cell = { D, R, E };

set of int: X = index_set_1of2(initial_grid);
set of int: Y = index_set_2of2(initial_grid);

X: max_x = card(X);
Y: max_y = card(Y);

function X: down_x(X: x)  = ((x - 1 + 1) mod max_x) + 1;
function X: up_x(X: x)    = ((x - 1 - 1 + max_x) mod max_x) + 1;
function Y: right_y(Y: y) = ((y - 1 + 1) mod max_y) + 1;
function Y: left_y(Y: y)  = ((y - 1 - 1 + max_y) mod max_y) + 1;

function Cell: next_value_function(Cell: c, Cell: r, Cell: u, Cell: d, Cell: l, Cell: dl, Cell: dr) =
    if c = E /\ l = R then
        R
    elseif c = E /\ l != R /\ u = D then 
        D
    elseif c = R /\ r = E /\ u = D then
        D    
    elseif c = R /\ r = E then
        E
    elseif c = D /\ d = E /\ dl != R then
        E
    elseif c = D /\ d = R /\ dr = E then
        E
    else
        c
    endif;

% %    Curr  Right Up    Down  Left  DL    DR
%array[Cell, Cell, Cell, Cell, Cell, Cell, Cell] of Cell: next_value = arrayXd([Cell, Cell, Cell, Cell, Cell, Cell, Cell], [
%    next_value_function(c, r, u, d, l, dl, dr)
%  | c, r, u, d, l, dl, dr in Cell
%]);

function array[X, Y] of Cell: step(array[X, Y] of Cell: grid) =
    array2d(X, Y, [
 %       next_value[grid[x, y], grid[x, right_y(y)], grid[up_x(x), y], grid[down_x(x), y], grid[x, right_y(y)], grid[down_x(x), left_y(y)], grid[down_x(x), right_y(y)]]
         next_value_function(grid[x, y], grid[x, right_y(y)], grid[up_x(x), y], grid[down_x(x), y], grid[x, left_y(y)], grid[down_x(x), left_y(y)], grid[down_x(x), right_y(y)])
        | x in X, y in Y
    ]);

function int: fixpoint(array[X, Y] of Cell: grid, int: steps) =
    let {
        array[X, Y] of Cell: next = step(grid)
    } in
    if grid = next then
        steps
    else
        fixpoint(next, steps+1)  
    endif; 

int: checksum = fixpoint(initial_grid, 1);

% Variables

% Constraints

% Solve and output
solve satisfy;

array[Cell] of string: symbol = [ "v", ">", "." ];
function string: to_string(array[X, Y] of Cell: grid) =
    concat([
        concat([
            symbol[grid[x, y]]
          | y in Y
        ]) ++ "\n"
      | x in X
    ]);

output [
  "initial grid:\n", to_string(initial_grid), "\n",
  "one step:    \n", to_string(step(initial_grid)), "\n",
  "checksum: ", show(checksum), "\n",
];
