% Input
array[int] of int: crabs;

% Data
set of int: Crabs = index_set(crabs);
set of int: Positions = min(crabs)..max(crabs);

int: max_depth = max(crabs);
set of int: Steps = 0..max_depth;
array[Steps] of int: cost = array1d(Steps, [
    sum(1..steps)
  | steps in Steps
]);


% Variables
var Positions: alignment;

var int: fuel = sum(crab in Crabs) (
    cost[abs(alignment - crabs[crab])]
);

% Solve and output
solve minimize fuel;

output [
  "Alignment: ", show(alignment), "\n",
  "Fuel:      ", show(fuel), "\n",
];