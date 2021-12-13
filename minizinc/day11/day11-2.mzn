include "globals.mzn";

% Input
array[N, N] of int: input;

% Data
set of int: N = 1..10;

function array[N, N] of bool: find_flashing(array[N, N] of int: prev, array[N, N] of int: next) =
    array2d(N, N, [
        prev[n1, n2] <= 9 /\ next[n1, n2] > 9
      | n1, n2 in N
    ]);

function array[N, N] of int: propagate(array[N, N] of int: grid, array[N, N] of bool: flashing) =
    let {
        array[N, N] of int: next = array2d(N, N, [
            grid[n1, n2] + count(o1, o2 in {-1, 0, 1}) (flashing[n1+o1, n2+o2] default false)
          | n1, n2 in N
        ]),
        array[N, N] of bool: next_flashing = find_flashing(grid, next),        
    } in
    if exists(next_flashing) then
        propagate(next, next_flashing)
    else
        array2d(N, N, [
            if next[n1, n2] <= 9 then
                next[n1, n2]
            else
                0
            endif
          | n1, n2 in N
        ])
    endif;

function int: evolve(array[N, N] of int: grid, int: round) =
    let {
        array[N, N] of int: increased = array2d(N, N, [
            grid[n1, n2] + 1
          | n1, n2 in N
        ]),
        array[N, N] of bool: flashing = find_flashing(grid, increased),
        array[N, N] of int: next = propagate(increased, flashing),
        int: flashed = count(next, 0),
        %constraint trace("remaining_rounds=\(remaining_rounds), previous flashes=\(flashes), current flashes=\(flashed) next state=\n\(show2d(next))\n", true)
    } in
    if flashed = 100 then
        round
    else        
        evolve(next, round+1)
    endif;

function int: octopi_flashes(array[N, N] of int: grid) =
    evolve(grid, 1);

int: checksum = octopi_flashes(input);

% Variables

% Constraints

% Solve and output
solve satisfy;

output [
  "checksum: ", show(checksum), "\n",
];
