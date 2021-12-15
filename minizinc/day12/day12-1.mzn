include "globals.mzn";

% Input
int: nedges;
array[int, 1..2] of Rooms: edges;

% Data
enum Rooms;
Rooms: start_room;
Rooms: end_room;
set of int: Edges = index_set_1of2(edges);
set of Rooms: single_visit;
%set of Nodes: single_visit = { start, end } union Room(single_visit_rooms);

function 1..2: other(1..2: value) =
    if value = 1 then 2 else 1 endif;

array[Rooms] of set of Rooms: graph = [
    { edges[edge, this] | edge in Edges, this in 1..2 where edges[edge, other(this)] = room }
  | room in Rooms
];

function int: traverse(array[$$N] of set of Rooms: visited, array[$$N] of int: counts, array[$$N] of Rooms: room) =
    let {
        set of int: N = index_set(visited)
    } in
    0;

int: checksum = traverse([{start_room}], [1], [start_room]);

% Variables

% Constraints

% Solve and output
solve satisfy;

output [
  "graph: ", show(graph), "\n",
  "checksum: ", show(checksum), "\n",
];
