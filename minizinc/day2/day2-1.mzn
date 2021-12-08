% Input
int: steps;
set of int: Steps = 1..steps;
array[Steps] of Direction: direction;
array[Steps] of int: amount;

% Data
enum Direction = {forward, up, down};
enum Coordinates = {X, Y};
array[Direction] of int: aim_factor = [
  forward:  0,
  up:      -1,
  down:     1,
];

array[Steps] of int: aim_changes = [
    aim_factor[direction[step]] * amount[step]
  | step in Steps
];

% Variables
array[Steps] of var int: aim;
constraint forall (step in Steps) (
    aim[step] = if step = 1 then 0 else aim[step-1] endif + aim_changes[step]
);

array[Steps, Coordinates] of var int: position_changes;
constraint forall (step in Steps) (
    if direction[step] = forward then
        position_changes[step, X] = amount[step] /\
        position_changes[step, Y] = amount[step] * aim[step]
    else
        position_changes[step, X] = 0 /\
        position_changes[step, Y] = 0    
    endif
);

array[Steps, Coordinates] of var int: position;

constraint forall (step in Steps) (
    position[step, X] = if step = 1 then 0 else position[step-1, X] endif + position_changes[step, X] /\
    position[step, Y] = if step = 1 then 0 else position[step-1, Y] endif + position_changes[step, Y]
);

var int: checksum = product(position[steps, ..]);

% Constraints

% Solve and output
solve satisfy;

output [
  "  x: ", show(position[.., X]), "\n",
  "  y: ", show(position[.., Y]), "\n",
  "aim: ", show(aim), "\n",
  "checksum: ", show(checksum), "\n",
];
