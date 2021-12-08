% Input
array[int] of int: sweeps;

% Data
set of int: Sweeps = index_set(sweeps);

int: increases = sum(i, j in Sweeps where i+1 = j) (
  sweeps[i] < sweeps[j]
);

% Solve and output
output [
  "Increases: ", show(increases), "\n",
];