include "globals.mzn";

% Input
int: player1_initial_position;
int: player2_initial_position;

% Data
enum RollData = { Value, Combinations };

enum State = {
  P1Position,
  P2Position,
  P1Score,
  P2Score,
  Occurences,
  Player,
};

array[1..1, State] of int: initial_state = [|
      P1Position:               P2Position:               P1Score:    P2Score:    Occurences:    Player:
    | player1_initial_position, player2_initial_position, 0,          0,          1,             1,
|];


function int: next_player(int: player) = if player = 1 then 2 else 1 endif;
function State: pos(int: player) = if player = 1 then P1Position else P2Position endif;
function State: score(int: player) = if player = 1 then P1Score else P2Score endif;
array[Rolls, RollData] of int: rolls = 
    [|  Value: Combinations:
     |      3,            1,
     |      4,            3,
     |      5,            6,
     |      6,            7,
     |      7,            6,
     |      8,            3,
     |      9,            1,
    |];
set of int: Rolls = 1..7;
    
function array[Rolls, State] of int: step_one(array[State] of int: state) =
    let {
        int: player = state[Player],
        int: next_player = next_player(player),
        array[Rolls, State] of int: next_states = array2d(Rolls, State, [
            [
                pos(player): next_pos,
                pos(next_player): state[pos(next_player)],
                score(player): state[score(player)] + next_pos,
                score(next_player): state[score(next_player)],
                Occurences: state[Occurences] * rolls[r, Combinations],
                Player: next_player,
            ][s]
          | r in Rolls,
            next_pos in { (state[pos(player)] - 1 + rolls[r, Value]) mod 10 + 1 },
            s in State,
        ])
    } in
    next_states;
    
function array[int, State] of int: step(array[int, State] of int: states) =
    let {
        set of int: ins = index_set_1of2(states),
        set of int: total = 1..(card(ins) * card(Rolls)),
        array[total, State] of int: next_states = array2d(total, State, [
            v
          | i in ins,
            v in array1d(step_one(states[i, ..]))
        ]),
        %array[int, State] of int: merged_next_states = merge(next_states)
    } in
    next_states;
    %merged_next_states;

enum Players = { P1, P2 };

function array[int] of int: play_game_limited(array[int, State] of int: data, int: remaining) =
    let {
        array[int, State] of int: all_next = step(data),
        set of int: anis = index_set_1of2(all_next),
        set of anis: won_indexes_p1 = { i | i in anis where all_next[i, P1Score] >= 21 },
        set of anis: won_indexes_p2 = { i | i in anis where all_next[i, P2Score] >= 21 },
        set of anis: won_indexes = won_indexes_p1 union won_indexes_p2,
        set of anis: other_indexes = anis diff won_indexes,
        set of anis: others_set = 1..card(other_indexes),
        array[int] of int: partial_result = 
            if others_set != {} /\ remaining > 0 then 
                play_game_limited(array2d(others_set, State, [ all_next[o, ..][s] | o in others_set, s in State]), remaining - 1) 
            elseif others_set != {} /\ remaining = 0 then
                [ all_next[o, ..][s] | o in others_set, s in State] ++ [ 0, 0 ]
            else
                [ 0, 0 ]
            endif,
        int: l = length(partial_result),
    } in
        partial_result[1..l-2] ++ 
        [
            partial_result[l-1] + card(won_indexes_p1), 
            partial_result[l]   + card(won_indexes_p2)
        ];
        
function array[Players] of int: play_game_smart(array[int, State] of int: states) =
    let {
        array[int] of int: some_steps = play_game_limited(states, 4),
        int: l = length(some_steps),
        set of int: some_states = 1..floor((l-2) / card(State)),
        constraint trace("Current count is P1 \(some_steps[l-1]) and P2 \(some_steps[l]) with some_states \(some_states)\n", true)
    } in
    if l = 2 then
        [ P1: some_steps[1], P2: some_steps[2] ]
    else
        let {
            array[Players] of int: partial_result = play_game_smart(array2d(some_states, State, some_steps[1..l-2]))
        } in
        [ P1: some_steps[l-1] + partial_result[P1], P2: some_steps[l] + partial_result[P2] ]
    endif;

function array[Players] of int: play_game(array[int, State] of int: states) =
    let {
        array[int, State] of int: all_next = step(states),
        set of int: anis = index_set_1of2(all_next),
        set of anis: won_indexes_p1 = { i | i in anis where all_next[i, P1Score] >= 21 },
        set of anis: won_indexes_p2 = { i | i in anis where all_next[i, P2Score] >= 21 },
        set of anis: won_indexes = won_indexes_p1 union won_indexes_p2,
        set of anis: other_indexes = anis diff won_indexes,
        set of anis: others_set = 1..card(other_indexes),
        array[Players] of int: other_wins = if others_set != {} then play_game(array2d(others_set, State, [ all_next[o, ..][s] | o in others_set, s in State])) else [ P1: 0, P2: 0 ] endif
    } in
        [
          P1: card(won_indexes_p1) + other_wins[P1],
          P2: card(won_indexes_p2) + other_wins[P2],
        ];

array[Players] of int: final = play_game_smart(initial_state);

int: checksum1 = final[P1];
int: checksum2 = final[P2];

% Variables

% Constraints

% Solve and output
solve satisfy;

output [
  "initial state: ", show(initial_state), "\n",
  "checksum1:      ", show(checksum1), "\n",
  "checksum2:      ", show(checksum2), "\n",
];
