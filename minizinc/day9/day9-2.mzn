include "globals.mzn";

% Input
int: nx;
int: ny;
array[X, Y] of int: depth;

% Data
set of int: X = 1..nx;
set of int: Y = 1..ny;

array[X, Y] of bool: local_min = array2d(X, Y, [
    depth[x, y] < min([
        depth[x+1, y] default 10,
        depth[x-1, y] default 10,
        depth[x, y+1] default 10,
        depth[x, y-1] default 10,
    ])
  | x in X, y in Y
]);

int: ridge = -2;
int: basin = -1;
array[X, Y] of int: source = array2d(X, Y, [
    if depth[x, y] = 9 then
        ridge
    elseif local_min[x, y] then
        1 + x + y * ny
    else
        basin
    endif
  | x in X, y in Y
]);

set of int: Markers = { 0 } union { v | v in array1d(source) where v > 0 };
int: nbasins = card(Markers)-1;

% Variables
array[X, Y] of var Markers: basins;

array[int] of var int: counts = [
    count(basins, m)
  | m in Markers where m > 0
];
array[int] of var int: sorted_counts = sort(counts);


var int: checksum = sorted_counts[nbasins] * sorted_counts[nbasins-1] * sorted_counts[nbasins-2];

% Constraints
constraint forall (x in X, y in Y) (
    if source[x, y] = ridge then 
        basins[x, y] = 0
    elseif source[x, y] > 0 then
        basins[x, y] = source[x, y]
    else
        forall (ox, oy in {-1, 0, +1} 
                    where abs(ox) + abs(oy) = 1 /\ 
                          x+ox in X /\ 
                          y + oy in Y /\
                          source[x+ox, y+oy] != ridge
               ) (
            basins[x, y] = basins[x+ox, y+oy]
        )
    endif    
);




% Solve and output
solve satisfy;

output [
%  "source:\n", show2d(source), "\n",
%  "local_min:\n", show2d(local_min), "\n",
%  "basins:\n", show2d(basins), "\n",
  "sorted counts:\n", show(sorted_counts), "\n",
  "checksum: ", show(checksum), "\n",
];
