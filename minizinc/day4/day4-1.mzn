include "globals.mzn";

% Input
array[int] of int: calls;

int: nboards;
set of int: N = 1..5;
array[int] of int: board_data;
array[Boards, N, N] of int: boards = array3d(Boards, N, N, board_data);

% Data
set of int: Boards = 1..nboards;
set of int: Calls = index_set(calls);
set of int: ECalls = {0} union index_set(calls);


% Variables
array[ECalls, Boards, N, N] of var bool: marks;
array[Calls, Boards] of var bool: win = array2d(Calls, Boards, [
    exists(n in N) (
        forall(marks[call, board, n, ..]) \/
        forall(marks[call, board, .., n])
    )
  | call in Calls, board in Boards
]);
array[Calls] of var bool: some_win = [exists(win[call, ..]) | call in Calls];
var Calls: first_win = arg_max(some_win);
var Boards: winner = sum(board in Boards) (win[first_win, board] * board);

var int: sum_winner_unmarked = sum(n1, n2 in N) (
    boards[winner, n1, n2] * not marks[first_win, winner, n1, n2]
);

var int: checksum = sum_winner_unmarked * calls[first_win];

% Constraints
constraint forall (b in Boards, n1, n2 in N) (marks[0, b, n1, n2] = false);
constraint forall (call in Calls, b in Boards, n1, n2 in N) (
    marks[call, b, n1, n2] = (marks[call-1, b, n1, n2] \/ boards[b, n1, n2] = calls[call])
);

% Solve and output
solve satisfy;

output [
  "win:          ", show2d(win), "\n",
  "some win:     ", show(some_win), "\n",
  "winner:       ", show(winner), "\n",
  "sum unmarked: ", show(sum_winner_unmarked), "\n",
  "checksum:     ", show(checksum), "\n",
];
