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

int: checksum = sum (x in X, y in Y where local_min[x, y]) (
    1 + depth[x, y]
);

% Variables

% Constraints

% Solve and output
solve satisfy;

output [
  "depth:\n", show2d(depth), "\n",
  "local_min:\n", show2d(local_min), "\n",
  "checksum: ", show(checksum), "\n",
];
