include "globals.mzn";

% Input
array[Creature] of Room: initial_positions;

array[AllSides] of Type: final_configuration = array1d(AllSides, [Amber, Amber, Bronze, Bronze, Copper, Copper, Desert, Desert]);

% Data
%set of int: Steps = 1..(card(Creature) * 2);
set of int: Steps = 1..7;
set of int: ExtendedSteps = min(Steps)-1..max(Steps);
ExtendedSteps: start = min(ExtendedSteps);
ExtendedSteps: final = max(ExtendedSteps);

enum Room = {
  H01,H02,H03,H04,H05,H06,H07,H08,H09,H10,H11,
          S11,    S21,    S31,    S41,
          S12,    S22,    S32,    S42,  
};

enum Creature = {A1, A2, B1, B2, C1, C2, D1, D2};
enum Type = { Amber, Bronze, Copper, Desert };
enum Content = C(Creature) ++ { Empty };
enum ContentType = T(Type) ++ { None };

enum MoveContent = { IsNotUsed, IsUsed, Start, End, Occupied, Free, Separator };

enum MoveType = { HomeRight, HomeLeft, OutRight, OutLeft, Done };
enum CollapsedMoveType = { Home, Out, NoMove };
array[MoveType] of CollapsedMoveType: collapse = [ Home, Home, Out, Out, NoMove ];

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
array[ExtendedSteps, Room] of var Content: rooms;
array[Steps] of var MoveType: move_types;
array[Steps] of var CollapsedMoveType: collapsed_move_type = [ collapse[move_types[step]] | step in Steps ];
array[Steps] of var Content: moved;

% Constraints


% Moves are connected and follow the rules

% Done is same as Empty, and they are to the end
constraint forall (step in Steps) (
    ((move_types[step] = Done) <-> (moved[step] = Empty)) /\
    regular(move_types, "( HomeRight | HomeLeft | OutRight | OutLeft )* Done*") /\
    regular(moved, "[^Empty]* Empty*")
);
% The number to times a creature can move is at most two
constraint global_cardinality_low_up_closed(
        moved, 
        Content, 
        [ 0 | _ in Creature ] ++ [ 0 ],
        [ 2 | _ in Creature ] ++ [ final ],
    );
% A creature can move once out from a side, and once into a side. Uses 
%     * positive value for moving a creature home, 
%     * negative value for moving out, 
%     * and 0 value when no moves are done
constraint all_different_except_0([
        moved[step] * [1, 1, -1, -1, 0][move_types[step]]
      | step in Steps
    ]);
% No stops are made in the entries just outside of rooms
constraint forall (entry in { H03, H05, H07, H09 }) (
    forall (r in rooms[.., entry]) (
        r = Empty
    )
);
% Only the moved creature changes position
constraint forall (step in Steps) (
    if move_types[step] = Done then
        forall (r in Room) (rooms[step-1, r] = rooms[step, r])
    else
        forall (r in Room) (
            if rooms[step-1, r] = moved[step] then
                rooms[step, r] = Empty
            elseif rooms[step, r] = moved[step] then
                rooms[step-1, r] = Empty
            else
                rooms[step-1, r] = rooms[step, r]
            endif
        )
    endif
);

% Initial configuration
constraint 
    forall (c in Creature) (
        rooms[start, initial_positions[c]] = C(c)
    ) /\
    forall (h in Hallways) (
        rooms[start, h] = Empty
    );

% Always the right number of creatures
constraint 
    let {
        array[Content] of int: amount = [ 1 | c in Creature ] ++ [ 11 ];
    } in
    forall (step in Steps) (
        global_cardinality_low_up_closed(
            rooms[step, ..],
            Content,
            amount,
            amount
        )
    );

% Final configuration
%constraint 
%    true \/
%    creature_type[C^-1(rooms[final, S11])] = Amber  /\
%    creature_type[C^-1(rooms[final, S12])] = Amber  /\
%    creature_type[C^-1(rooms[final, S21])] = Bronze /\
%    creature_type[C^-1(rooms[final, S22])] = Bronze /\
%    creature_type[C^-1(rooms[final, S31])] = Copper /\
%    creature_type[C^-1(rooms[final, S32])] = Copper /\
%    creature_type[C^-1(rooms[final, S41])] = Desert /\
%    creature_type[C^-1(rooms[final, S42])] = Desert /\
%    forall (h in Hallways) (
%        rooms[start, h] = Empty
%    );


% Regular expressions for the moves. Always starts with control sequence to check if the expression is used (encoding reification into the expression)
% For home and out moves, one of the sequences between separators need to follow a certain pattern, that starts with the Start symbol, 
% a sequence of Free spaces (always at least one, since no stops are made outside hallways), and then an End expression. 
% Additionally, depending on if the start of end is in a side next to the hallway, the inner must be occupied.
array[MoveType] of string: move_expressions = [
    %     1   2   3   4   5   6   7   8   9   10  11  12  13  14  15  16  17  18  19  20  21  22  23  24  25  26  27  28  29  30  31  32  33  34  35  36  37  38
    % Control Sep H01 H02 H03 S11 S12 Sep H01 H02 H03 H04 H05 S21 S22 Sep H01 H02 H03 H04 H05 H06 H07 S31 S32 Sep H01 H02 H03 H04 H05 H06 H07 H08 H09 S41 S42 Sep 
    HomeRight: "IsNotUsed .* | IsUsed ( (Occupied | Free | Start | Separator)* Separator (Occupied | Free)*  Start Free+ (Free End | End Occupied) Separator (Occupied | Free | Start | Separator)* )",
    %     1   2   3   4   5   6   7   8   9   10  11  12  13  14  15  16  17  18  19  20  21  22  23  24  25  26  27  28  29  30  31  32  33  34  35  36  37  38
    % Control Sep H11 H10 H09 S41 S42 Sep H11 H10 H09 H08 H07 S31 S32 Sep H11 H10 H09 H08 H07 H06 H05 S31 S32 Sep H11 H10 H09 H08 H07 H06 H05 H04 H03 S41 S42 Sep 
    HomeLeft:  "IsNotUsed .* | IsUsed ( (Occupied | Free | Start | Separator)* Separator (Occupied | Free)*  Start Free+ (Free End | End Occupied) Separator (Occupied | Free | Start | Separator)* )",
    %     1   2   3   4   5   6   7   8   9   10  11  12  13  14  15  16  17  18  19  20  21  22  23  24  25  26  27  28  29  30  31  32  33  34  35  36  37  38
    % Control Sep S12 S11 H03 H04 H05 H06 H07 H08 H09 H10 H11 Sep S22 S21 H05 H06 H07 H08 H09 H10 H11 Sep S32 S31 H07 H08 H09 H10 H11 Sep S42 S41 H09 H10 H11 Sep
    OutRight:  "IsNotUsed .* | IsUsed ( (Occupied | Free | End | Separator)* Separator (Start Free | Occupied Start) Free+ End (Occupied | Free)* Separator (Occupied | Free | End | Separator)* )", 
    %     1   2   3   4   5   6   7   8   9   10  11  12  13  14  15  16  17  18  19  20  21  22  23  24  25  26  27  28  29  30  31  32  33  34  35  36  37  38
    % Control Sep S42 S41 H09 H08 H07 H06 H05 H04 H03 H02 H01 Sep S32 S31 H07 H06 H05 H04 H03 H02 H01 Sep S22 S21 H05 H04 H03 H02 H01 Sep S12 S11 H03 H02 H01 Sep
    OutLeft:   "IsNotUsed .* | IsUsed ( (Occupied | Free | End | Separator)* Separator (Start Free | Occupied Start) Free+ End (Occupied | Free)* Separator (Occupied | Free | End | Separator)* )", 
    % When no movement is done, all squares are either occupied or free
    % Control H01 H02 H03 H04 H05 H06 H07 H08 H09 H10 H11 S11 S21 S31 S41 S12 S22 S32 S42, 
    Done:      "(IsNotUsed (Free | Occupied){19}) | (IsUsed Free{11} Occupied{8})"
];
%enum Room = {
%  H01,H02,H03,H04,H05,H06,H07,H08,H09,H10,H11,
%          S11,    S21,    S31,    S41,
%          S12,    S22,    S32,    S42,  
%};
% These indices are the same as shown above for the move_expressions, lifted to the RoomOrSep enum.
array[SomeMove, 1..37] of RoomOrSep: move_indices = [| 
    HomeRight: Sep, R(H01), R(H02), R(H03), R(S11), R(S12), 
               Sep, R(H01), R(H02), R(H03), R(H04), R(H05), R(S21), R(S22), 
               Sep, R(H01), R(H02), R(H03), R(H04), R(H05), R(H06), R(H07), R(S31), R(S32), 
               Sep, R(H01), R(H02), R(H03), R(H04), R(H05), R(H06), R(H07), R(H08), R(H09), R(S41), R(S42), 
               Sep,
  | HomeLeft:  Sep, R(H11), R(H10), R(H09), R(S41), R(S42), 
               Sep, R(H11), R(H10), R(H09), R(H08), R(H07), R(S31), R(S32), 
               Sep, R(H11), R(H10), R(H09), R(H08), R(H07), R(H06), R(H05), R(S21), R(S22), 
               Sep, R(H11), R(H10), R(H09), R(H08), R(H07), R(H06), R(H05), R(H04), R(H03), R(S11), R(S12), 
               Sep,

  | OutRight:  Sep, R(S12), R(S11), R(H03), R(H04), R(H05), R(H06), R(H07), R(H08), R(H09), R(H10), R(H11), 
               Sep, R(S22), R(S21), R(H05), R(H06), R(H07), R(H08), R(H09), R(H10), R(H11), 
               Sep, R(S32), R(S31), R(H07), R(H08), R(H09), R(H10), R(H11), 
               Sep, R(S42), R(S41), R(H09), R(H10), R(H11), 
               Sep,
  | OutLeft:   Sep, R(S42), R(S41), R(H09), R(H08), R(H07), R(H06), R(H05), R(H04), R(H03), R(H02), R(H01), 
               Sep, R(S32), R(S31), R(H07), R(H06), R(H05), R(H04), R(H03), R(H02), R(H01), 
               Sep, R(S22), R(S21), R(H05), R(H04), R(H03), R(H02), R(H01), 
               Sep, R(S12), R(S11), R(H03), R(H02), R(H01), 
               Sep
|];

% Set of types of moves that move a creature
set of MoveType: SomeMove = MoveType diff { Done };

% At each step, the moved creature needs to follow it's move types pattern.
constraint forall (step in Steps) (
    forall (m in SomeMove) (
    %forall (m in { HomeLeft, HomeRight }) (
        regular(get_values(m, step), move_expressions[m])
    ) 
    /\
    regular(get_done_values(step), move_expressions[Done])
);

enum RoomOrSep = R(Room) ++ { Sep };

function array[int, $$C] of $V: make_matrix(set of $$C: cols, array[int] of $V: values) =
    let {
        set of int: rows = 1..(length(values) div card(cols))
    } in
    array2d(rows, cols, values);

array[int, 1..4] of int: move_content_table = make_matrix(1..4,
    % Starting position
    [
        [C(c), C(c), Empty, Start][i]
      | c in Creature, i in 1..4
    ] ++
    % Ending position
    [
        [C(c), Empty, C(c), End][i]
      | c in Creature, i in 1..4
    ] ++
    % Empty positions
    [
        [C(c), Empty, Empty, Free][i]
      | c in Creature, i in 1..4
    ] ++
    % Occupied positions
    [
        [C(moved_creature), C(other), C(other), Occupied][i]
      | moved_creature in Creature, other in Creature where moved_creature != other, i in 1..4
    ]
);

array[SomeMove, 1..38] of var MoveContent: move_content_vars = array2d(SomeMove, 1..38,
    get_values(HomeRight, 1) ++
    get_values(HomeLeft, 1) ++
    get_values(OutRight, 1) ++
    get_values(OutLeft, 1)
);
array[1..20] of var MoveContent: move_content_final = get_done_values(final);
    
        
function array[1..38] of var MoveContent: get_values(SomeMove: m, Steps: step) =
    let {        
        var Content: moved_creature = moved[step],
    } in
    [
        if move_types[step] = m then
            IsUsed
        else
            IsNotUsed
        endif
    ] ++
    [   if i = Sep then
            Separator
        else
            let {
                var Content: prev = rooms[step-1, R^-1(i)],
                var Content: curr = rooms[step,   R^-1(i)],
                var MoveContent: res,
                constraint table([moved_creature, prev, curr, res], move_content_table)
            } in
            res
        endif
      | i in move_indices[m, ..]
    ];
    
function array[1..20] of var MoveContent: get_done_values(Steps: step) =
    [
        if move_types[step] = Done then
            IsUsed
        else
            IsNotUsed
        endif
    ] ++
    [
        if rooms[step, r] = Empty then
            Free
        else
            Occupied
        endif
      | r in set2array(Hallways) ++ set2array(AllSides)
    ];

% Final configuration valid
%constraint forall (side in AllSides) (
%    final_configuration[side] = creature_type[C^-1(rooms[final, side])]
%;

% Solve and output
solve :: int_search([ [moved[step], move_types[step]][i] | step in Steps, i in 1..2 ], input_order, indomain_min) satisfy;

array[MoveType] of string: display_move_type = ["HomeR", "HomeL", "OutR", "OutL", "Done"];
array[Content] of string: display_move_content = [" A", " a", " B", " b", " C", " c", " D", " d", ""];
array[Content] of string: display_content = ["A", "a", "B", "b", "C", "c", "D", "d", "."];
function string: d(ExtendedSteps: step, Room: room) = display_content[fix(rooms[step, room])];
function string: show_rooms(ExtendedSteps: s) =
    "#############\n" ++
    "#" ++ concat([d(s, h) | h in Hallways]) ++ "#  " ++ if s in Steps then display_move_type[fix(move_types[s])] ++ display_move_content[fix(moved[s])] else "Initial" endif ++ "\n" ++
    "###"++d(s, S11)++"#"++d(s, S21)++"#"++d(s, S31)++"#"++d(s, S41)++"###\n" ++
    "###"++d(s, S12)++"#"++d(s, S22)++"#"++d(s, S32)++"#"++d(s, S42)++"###\n" ++
    "  ##########  \n";

output 
[
  "move content vars:\n", show2d(move_content_vars), "\n",
  "move content final:\n", show(move_content_final), "\n",
] ++
[
    show_rooms(step)
  | step in ExtendedSteps
] ++
[
  "moves:      ", show([
      display_move_type[fix(move_types[step])] ++ display_move_content[fix(moved[step])]
    | step in Steps]), "\n",
  "move types: ", show(move_types), "\n",
  "moved:      ", show(moved), "\n",
  "checksum:   ", show(checksum), "\n",
];
