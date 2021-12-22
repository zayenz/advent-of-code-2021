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

function bool: same(array[State] of int: state1, array[State] of int: state2) =
    state1[P1Position] = state2[P1Position] /\
    state1[P2Position] = state2[P2Position] /\
    state1[P1Score] = state2[P1Score] /\
    state1[P2Score] = state2[P2Score] /\
    state1[Player] = state2[Player];

function array[int, State] of int: merge(array[int, State] of int: states) =
    let {
        set of int: ins = index_set_1of2(states),
        array[ins] of set of ins: uniques = [
            if not exists(j in ins where i > j) (same(states[i, ..], states[j, ..])) then
                { i } union { j | j in ins where i < j /\ same(states[i, ..], states[j, ..]) }
            else
                {}
            endif
          | i in ins
        ],
        set of int: unique_indexes = { i | i in ins where uniques[i] != {} },
        set of int: out_worlds = 1..card(unique_indexes),
        %constraint trace("|ins| \(card(ins)) vs |uniques| \(card(unique_indexes))\n", true)
    } in
    array2d(out_worlds, State, [
        [
          P1Position: states[rep, P1Position],
          P2Position: states[rep, P2Position],
          P1Score: states[rep, P1Score],
          P2Score: states[rep, P2Score],
          Occurences: occurences,
          Player: states[rep, Player],
        ][s]
      | ui in unique_indexes, % The index of the set of similar worlds to construct state for
        rep in { min(uniques[ui]) }, % A single representative for the set of indexes to merge
        occurences in { product(world in uniques[ui]) ( states[world, Occurences] ) }, % The sum of the world occurences for this set of worlds
        s in State, % The part of state we are computing this round
    ]);
    
function array[Rolls, State] of int: step_one(array[State] of int: state) =
    let {
        int: player = state[Player],
        int: next_player = next_player(player),
        array[Rolls, State] of int: next_states = array2d(Rolls, State, [
            [
                pos(player): (state[pos(player)] - 1 + rolls[r, Value]) mod 10 + 1,
                pos(next_player): state[pos(next_player)],
                score(player): state[score(player)] + ((state[pos(player)] - 1 + rolls[r, Value]) mod 10 + 1),
                score(next_player): state[score(next_player)],
                Occurences: state[Occurences] * rolls[r, Combinations],
                Player: next_player,
            ][s]
          | r in Rolls,
            s in State,
        ])
    } in
    next_states;

function array[int, State] of int: step_bad_version(array[int, State] of int: states) =
    let {
        set of int: ins = index_set_1of2(states),
        set of int: total = 1..(card(ins) * card(Rolls)),
        array[int, State] of int: next_states = array2d(total, State, [
            % Re-evaluating this every round-trip is way to expensive.
            % Use array concatenation instead
            step_one(states[i, ..])[r, s]
          | i in ins,
            r in Rolls,
            s in State
        ]);
        array[int, State] of int: merged_next_states = merge(next_states)
    } in
    merged_next_states;
    
function array[int, State] of int: step(array[int, State] of int: states) =
    let {
        set of int: ins = index_set_1of2(states),
        set of int: total = 1..(card(ins) * card(Rolls)),
        array[total, State] of int: next_states = array2d(total, State, [
            v
          | i in ins,
            v in array1d(step_one(states[i, ..]))
        ]),
        array[int, State] of int: merged_next_states = merge(next_states)
    } in
    merged_next_states;

function array[int, State] of int: play_game(array[int, State] of int: states) =
    let {
        set of int: ins = index_set_1of2(states)
    } in
    if ins = {} then
        states
    else
        let {
            set of ins: won_indexes = { i | i in ins where max(states[i, P1Score], states[i, P2Score]) >= 21 },
            set of ins: ongoing_indexes = ins diff won_indexes,          
            array[int] of int: won_data = [states[w, s] | w in won_indexes, s in State];
            array[int, State] of int: ongoing = array2d(1..card(ongoing_indexes), State, [states[o, s] | o in ongoing_indexes, s in State]);
            array[int, State] of int: result =play_game(step(ongoing)),
            set of int: outs = 1..(card(won_indexes) + card(index_set_1of2(result)))
        } in
        array2d(outs, State, won_data ++ array1d(result))
    endif;

array[int, State] of int: final = play_game(initial_state);

set of int: outcomes = index_set_1of2(final);

array[int] of int: checksums1 = [final[o, Occurences] | o in outcomes where final[o, P1Score] >= 21];
array[int] of int: checksums2 = [final[o, Occurences] | o in outcomes where final[o, P2Score] >= 21];
int: checksum1 = sum (o in outcomes where final[o, P1Score] >= 21) (final[o, Occurences]);
int: checksum2 = sum (o in outcomes where final[o, P2Score] >= 21) (final[o, Occurences]);

% Variables

% Constraints

% Solve and output
solve satisfy;

output [
  "initial state: ", show(initial_state), "\n",
  "final:       \n", show2d(final), "\n",
  "checksum1:      ", show(checksum1), "\n",
  "checksum2:      ", show(checksum2), "\n",
];
