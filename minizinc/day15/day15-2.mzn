include "globals.mzn";

% Input
int: nx;
array[N, N] of int: grid;

% Data
int: factor = 5;
set of int: N = 1..nx;
int: m = factor*nx;
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
        int: base_risk = grid[((ix-1) mod nx) + 1, ((iy-1) mod nx) + 1],
        int: risk_increase = floor((ix-1) / nx) + floor((iy-1) / nx),
        int: risk = base_risk + risk_increase,
    } in
    ((risk - 1) mod 9) + 1;

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
    
function opt int: first_index_of_or_opt(array[int] of int: values, int: value) =
    let {
        set of int: candidates = { i | i in index_set(values) where values[i] = value },
    } in
    if candidates = {} then
        <>
    else
        min(candidates)
    endif;

function int: first_index_of(array[int] of int: values, int: value) =
    min({ i | i in index_set(values) where values[i] = value });

function opt int: dijkstra(set of I: visited, array[$$B] of I: boundary_nodes, array[$$B] of int: boundary_cost) =
    let {
        set of int: Boundary = index_set(boundary_nodes),
        int: best_cost = boundary_cost[1],
        set of Boundary: best_indices = { b | b in Boundary where boundary_cost[b] = best_cost },
        set of I: best_nodes = { boundary_nodes[b] | b in best_indices },
        array[int] of I: extension_nodes = [ e | node in best_nodes, e in around(node) where not (e in visited) ],
        array[int] of int: extension_cost = [ best_cost + cost(e) | e in extension_nodes ],
        array[int] of I: all_next_boundary_nodes = [ boundary_nodes[j] | j in Boundary where not (j in best_indices) ] ++ extension_nodes,
        array[int] of int: all_next_boundary_cost = [ boundary_cost[j] | j in Boundary where not (j in best_indices) ] ++ extension_cost,
        array[int] of I: sorted_all_next_boundary_nodes = sort_by(all_next_boundary_nodes, all_next_boundary_cost),
        array[int] of int: sorted_all_next_boundary_cost = sort(all_next_boundary_cost),
        set of int: next_to_keep = { b | b in index_set(sorted_all_next_boundary_nodes) where first_index_of(sorted_all_next_boundary_nodes[1..b], sorted_all_next_boundary_nodes[b]) = b},
        array[int] of I: next_boundary_nodes = [ sorted_all_next_boundary_nodes[b] | b in next_to_keep ],
        array[int] of int: next_boundary_cost = [ sorted_all_next_boundary_cost[b] | b in next_to_keep ],        
        %constraint trace("|visited|=\(card(visited)) |Boundary|=\(card(Boundary)) |best nodes|=\(card(best_nodes)) Best nodes=\(best_nodes)\n", true)
    } in
    if goal in best_nodes then 
        min({ boundary_cost[b] | b in best_indices where boundary_nodes[b] = goal })
    else
        dijkstra(visited union best_nodes, next_boundary_nodes, next_boundary_cost)
    endif;

int: checksum = deopt(dijkstra({xy(1, 1)}, [xy(1, 1)], [0]));

% Variables

% Constraints

% Solve and output
solve satisfy;

output [
  "checksum: ", show(checksum), "\n",
];
