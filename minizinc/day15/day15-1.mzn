include "globals.mzn";

% Input
int: nx;
array[N, N] of int: grid;

% Data
set of int: N = 1..nx;

function array[N, N] of int: flood(array[N, N] of int: curr) = 
    let {
        array[N, N] of int: next = array2d(N, N, [
            min(
                curr[n1, n2], 
                min(o1, o2 in {-1, 0, 1} where abs(o1)+abs(o2) = 1 /\ n1+o1 in N /\ n2+o2 in N) (
                    curr[n1+o1, n2+o2] + grid[n1, n2]
                )
            )
          | n1, n2 in N
        ])
    } in 
    if curr = next then
        curr
    else
        flood(next)
    endif;

int: total = sum(grid);

array[N, N] of int: cost = flood(array2d(N, N, [
    if n1 = 1 /\ n2 = 1 then
        0
    else
        total
    endif
  | n1, n2 in N
]));

int: checksum = cost[nx, nx];

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
  "cost:\n", show2d(cost), "\n",
  "checksum: ", show(checksum), "\n",
];
