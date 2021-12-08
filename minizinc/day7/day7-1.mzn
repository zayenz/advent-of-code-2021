% Input
array[int] of int: crabs;

% Data
set of int: Crabs = index_set(crabs);
set of int: Positions = min(crabs)..max(crabs);

% Variables
var Positions: alignment;

var int: fuel = sum(crab in Crabs) (
    abs(alignment - crabs[crab])
);

% Data
solve minimize fuel;

output [
  "Alignment: ", show(alignment), "\n",
  "Fuel:      ", show(fuel), "\n",
];