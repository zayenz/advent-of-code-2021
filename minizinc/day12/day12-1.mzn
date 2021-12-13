include "globals.mzn";

% Input
int: nedges;
array[Edges, 1..2] of Nodes: edges;

% Data
enum Rooms;
enum Nodes = { start, end } ++ Room(Rooms);
set of int: Edges = 1..nedges;
set of Rooms: single_visit_rooms;
set of Nodes: single_visit = { start, end } union Room(single_visit_rooms);

function 1..2: other(1..2: value) =
    if value = 1 then 2 else 1 endif;

array[Nodes] of set of Nodes: graph = [
    { edges[edge, this] | edge in Edges, this in 1..2 where edges[edge, other(this)] = node }
  | node in Nodes
];

int: checksum = 0;

% Variables

% Constraints

% Solve and output
solve satisfy;

output [
  "graph: ", show(graph), "\n",
  "checksum: ", show(checksum), "\n",
];
