include "globals.mzn";

% Input
int: nlines;
int: length;
array[Lines, Length] of Tokens: lines;

% Data
enum Tokens = {
  LParen, RParen,     % ( )
  LBracket, RBracket, % [ ]
  LBrace, RBrace,     % { }
  LAngle, RAngle,     % < >
  Empty,              % 
};

set of Tokens: Starts = {LParen, LBracket, LBrace, LAngle};
set of Tokens: Ends = {RParen, RBracket, RBrace, RAngle};

set of int: Length = 1..length;
set of int: Lines = 1..nlines;

function bool: matches(Tokens: t1, Tokens: t2) =
    (t1 = LParen   /\ t2 = RParen) \/
    (t1 = LBracket /\ t2 = RBracket) \/
    (t1 = LBrace   /\ t2 = RBrace) \/
    (t1 = LAngle   /\ t2 = RAngle);

function int: token_cost(Tokens: token) =
    if token = LParen then
        1
    elseif token = LBracket then
        2
    elseif token = LBrace then
        3
    elseif token = LAngle then
        4
    else
        trace(
            "Unexpected token \(token)\n", 
            0
        )
    endif;

function int: compute_cost(array[int] of Tokens: stack, int: current) =
    %let {
    %    constraint trace("Computing cost, current value \(current) and stack \(stack)\n", true);
    %} in
    if length(stack) = 0 then
        current
    else
        compute_cost(
            array1d(stack[2..length(stack)]),
            5 * current + token_cost(stack[1])
        )
    endif;

function int: parse(array[int] of Tokens: line, array[int] of Tokens: stack) =
    let {
        Tokens: top = line[1],
        array[int] of Tokens: rest = array1d(line[2..length(line)])
    } in
    if top in Starts then
        parse(rest, [top] ++ stack)
    elseif top in Ends then
        if matches(stack[1], top) then
            parse(rest, array1d(stack[2..length(stack)]))
        else
            % Error, skip this
            0
        endif
    else
        compute_cost(stack, 0)
    endif;

array[Lines] of int: all_costs = [
    parse(lines[line, ..], [])
  | line in Lines
];

array[int] of int: non_zero_costs = [
    cost
  | cost in all_costs where cost > 0
];

array[int] of int: sorted_costs = sort(non_zero_costs);
int: mid = ceil(length(sorted_costs) / 2);

int: checksum = sorted_costs[mid];

% Variables

% Constraints

% Solve and output
solve satisfy;

output [
  "costs:        ", show(non_zero_costs), "\n",
  "sorted costs: ", show(sorted_costs), "\n",
  "checksum:     ", show(checksum), "\n",
];
