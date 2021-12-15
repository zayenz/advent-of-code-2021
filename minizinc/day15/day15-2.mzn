include "globals.mzn";

% Input
int: nx;
array[N, N] of int: grid;

% Data
set of int: N = 1..nx;
int: m = 5*nx;
set of int: M = 1..m;
set of int: I = 1..(m * m);

int: goal = m*m;

function M: x(I: i) = ((i-1) mod m) + 1;
function M: y(I: i) = ceil(i / m);
function I: xy(int: x, int: y) = x + ((y-1) * m);

function int: cost(I: i) =
    let {
        M: ix = x(i),
        M: iy = y(i),
        int: risk = floor(ix / nx) + floor(iy / nx),
    } in
    (grid[(ix mod nx) + 1, (iy mod nx) + 1] + risk) mod 10;

function set of I: around(I: node) =
    let {
      int: x = x(node),
      int: y = y(node),
    } in
    { 
        xy(x + ox, y + oy)
      | ox, oy in {-1, 0, 1} 
            where abs(ox) + abs(oy) = 1 /\
                  x + ox in M /\
                  y + oy in M
    };
    
function opt int: first_index_of(array[int] of int: values, int: value) =
    let {
        set of int: candidates = { i | i in index_set(values) where values[i] = value },
    } in
    if candidates = {} then
        <>
    else
        min(candidates)
    endif;

function opt int: dijkstra(set of I: visited, array[$$B] of I: boundary_nodes, array[$$B] of int: boundary_cost) =
    let {
      set of int: Boundary = index_set(boundary_nodes),
      opt int: goal_index = first_index_of(boundary_nodes, goal),
    } in
    if Boundary = {} then
        <>
    elseif occurs(goal_index) then
        boundary_cost[deopt(goal_index)]
    else
        let {
            int: best_index = arg_min(boundary_cost),
            int: best_node = boundary_nodes[best_index],
            int: best_cost = boundary_cost[best_index],
            array[int] of I: extension_nodes = [ e | e in around(best_node) where not (e in visited) ],
            array[int] of int: extension_cost = [ best_cost + cost(e) | e in extension_nodes ],
            array[int] of I: next_boundary_nodes = [ boundary_nodes[j] | j in Boundary where j != best_index ] ++ extension_nodes,
            array[int] of int: next_boundary_cost = [ boundary_cost[j] | j in Boundary where j != best_index ] ++ extension_cost,
        } in
        dijkstra(visited union { best_node }, next_boundary_nodes, next_boundary_cost)
    endif;



int: checksum = deopt(dijkstra({xy(1, 1)}, [xy(1, 2), xy(2, 1)], [grid[1, 2], grid[2, 1]]));

% Variables
%int: m = nx;
%set of N: M = 1..m;
%array[M, M] of var int: cost;
%
%constraint cost[1, 1] = 0;
%
%constraint forall(n1, n2 in M where not (n1 = 1 /\ n2 = 1)) (
%    cost[n1, n2] = (grid[n1,n2] + min(o1, o2 in {-1, 0, 1} where abs(o1)+abs(o2) = 1 /\ n1+o1 in M /\ n2+o2 in M) (
%        trace_exp(cost[n1+o1, n2+o2])
%    ))
%);
%
%var int: checksum = cost[m, m];

% Constraints

% Solve and output
solve satisfy;

output [
  "checksum: ", show(checksum), "\n",
];
