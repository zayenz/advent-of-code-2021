% Input
array[int] of int: sweeps;

% Data
set of int: Sweeps = index_set(sweeps);

int: increases = sum(i, j in Sweeps where i+1 = j /\ j+2 in Sweeps) (
  sum(sweeps[i..i+2]) < sum(sweeps[j..j+2])
);

% Solve and output
output [
  "Increases: ", show(increases), "\n",
];