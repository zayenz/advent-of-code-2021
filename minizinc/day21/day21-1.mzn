include "globals.mzn";

% Input
array[State] of int: initial_state;

% Data
enum RollData = { RollValue, TimesRolled, NextRoll };

enum State = {
  P1Position,
  P2Position,
  P1Score,
  P2Score,
  Roll,
  RollsCount,
  Player,
};

function int: next_player(int: player) = if player = 1 then 2 else 1 endif;
function State: pos(int: player) = if player = 1 then P1Position else P2Position endif;
function State: score(int: player) = if player = 1 then P1Score else P2Score endif;
function array[RollData] of int: roll(int: die) = 
    [
      RollValue: 
          ((die + 0 - 1) mod 100) + 1 + 
          ((die + 1 - 1) mod 100) + 1 + 
          ((die + 2 - 1) mod 100) + 1,
      TimesRolled: 3,
      NextRoll: 
          ((die + 3 - 1) mod 100) + 1,
    ];

function array[State] of int: step(array[State] of int: state) =
    let {
        array[RollData] of int: roll_value = roll(state[Roll]),
        int: player = state[Player],
        int: next_player = next_player(player),
        int: new_pos = (state[pos(player)] - 1 + roll_value[RollValue]) mod 10 + 1,
        array[State] of int: next_state = [
            pos(player): new_pos,
            pos(next_player): state[pos(next_player)],
            score(player): state[score(player)] + new_pos,
            score(next_player): state[score(next_player)],
            Roll: roll_value[NextRoll],
            RollsCount: state[RollsCount] + roll_value[TimesRolled],
            Player: next_player,
        ]
    } in
    next_state;
    
function array[State] of int: play_game(array[State] of int: state) =
    if max(state[P1Score], state[P2Score]) >= 1000 then
        state
    else
        play_game(step(state))
    endif;


array[State] of int: final = play_game(initial_state);

int: checksum = final[RollsCount] * min(final[P1Score], final[P2Score]);

% Variables

% Constraints

% Solve and output
solve satisfy;

output [
  "initial state: ", show(initial_state), "\n",
  "final:         ", show(final), "\n",
  "checksum:      ", show(checksum), "\n",
];
