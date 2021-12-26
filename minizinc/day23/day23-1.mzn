include "globals.mzn";

% Input

% Data
set of int: Steps = 1..16;
Steps: final = 16;

enum Room = {
  H01,H02,H03,H04,H05,H06,H07,H08,H09,H10,H11,
          S11,    S21,    S31,    S41,
          S12,    S22,    S32,    S42,  
};
enum Creature = {A1, A2, B1, B2, C1, C2, D1, D2};
enum Type = { Amber, Bronze, Copper, Desert };
enum Content = C(Creature) ++ { Empty };
enum ContentType = T(Type) ++ { None };

enum MoveType = { FromSide, ToSide, Done };

set of Room: Hallways = { 
  H01,H02,H03,H04,H05,H06,H07,H08,H09,H10,H11 
};
set of Room: AllSides = {
          S11,    S21,    S31,    S41,
          S12,    S22,    S32,    S42,  
};
array[int] of set of AllSides: sides = [{S11, S12}, {S21, S22}, {S31, S32}, {S41, S42}];

array[Creature] of Type: creature_type = [Amber, Amber, Bronze, Bronze, Copper, Copper, Desert, Desert];
array[Creature] of string: creature_symbol = ["A", "A", "B", "B", "C", "C", "D", "D"];
function string: to_string(Content: content) =
    if content = Empty then 
        "."
    else
        creature_symbol[C^-1(content)]        
    endif;

int: checksum = 0;

% Variables
array[Steps, Room] of var Content: rooms;
array[Steps] of var MoveType: move_types;
array[Steps] of var Content: moved;

% Constraints


% Moves are connected and follow the rules

% Done is same as Empty, and they are to the end
constraint forall (step in Steps) (
    ((move_types[step] = Done) <-> (moved[step] = Empty)) /\
    regular(move_types, "( FromSide | ToSide )* Done*") /\
    regular(moved, "[^Empty]* Empty*")
);
% The number to times a creature can move is at msot two
constraint global_cardinality_low_up_closed(
        moved, 
        Content, 
        [ 0 | _ in Creature ] ++ [ 0 ],
        [ 2 | _ in Creature ] ++ [ final ],
    );
    % A creature can move once out from a side, and once into a side
constraint all_different_except_0([
        moved[step] * [1, -1, 0][move_types[step]]
      | step in Steps
    ]);



% Final configuration valid
constraint forall (side in sides) (
    let {
        array[int] of var ContentType: side_types = [
            T(creature_type[C^-1(rooms[final, s])]) default None
          | s in side
        ];
    } in
    all_equal(side_types)
);

% Solve and output
solve satisfy;

output [
  "move types: ", show(move_types), "\n",
  "moved:      ", show(moved), "\n",
  "checksum:   ", show(checksum), "\n",
];
