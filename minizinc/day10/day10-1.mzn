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

function opt Tokens: parse(array[int] of Tokens: line, array[int] of Tokens: stack) =
    let {
        Tokens: top = line[1],
        array[int] of Tokens: rest = array1d(line[2..length(line)])
    } in
    if {top} subset Starts then
        parse(rest, [top] ++ stack)
    elseif {top} subset Ends then
        if matches(stack[1], top) then
            parse(rest, array1d(stack[2..length(stack)]))
        else
            top
        endif
    else
        % Top is Empty token, and stack should be empty
        Empty
    endif;

array[Lines] of opt Tokens: mismatch = [
    parse(lines[line, ..], [])
  | line in Lines
];

int: checksum = sum (t in mismatch where occurs(t)) (
    if t = RParen then
        3
    elseif t = RBracket then
        57
    elseif t = RBrace then
        1197
    elseif t = RAngle then
        25137
    else
        0
    endif
);

% Variables

% Constraints

% Solve and output
solve satisfy;

output [
%  "x:        ", show(x), "\n",
  "checksum: ", show(checksum), "\n",
];
