include "globals.mzn";

% Input
int: n_starting_fish;
array[StartingFish] of int: starting_fish;

% Data
set of int: StartingFish = 1..n_starting_fish;

set of int: Time = 0..8;

array[Time] of int: starting_fish_counts = array1d(Time, [
    count(starting_fish, t)
  | t in Time
]);

function array[Time] of int: evolve(array[Time] of int: fish, int: time_left) = 
    if time_left = 0 then
        fish
    else
        let {
            array[Time] of int: updated_fish = [
              0: fish[1],
              1: fish[2],
              2: fish[3],
              3: fish[4],
              4: fish[5],
              5: fish[6],
              6: fish[7] + fish[0],
              7: fish[8],
              8: fish[0],
            ];
        } in
        evolve(updated_fish, time_left-1)
    endif;

array[Time] of int: final_fish = evolve(starting_fish_counts, 256);

int: checksum = sum(final_fish);

% Variables

% Constraints

% Solve and output
solve satisfy;

output [
  "starting_fish: ", show(starting_fish), "\n",
  "checksum:      ", show(checksum), "\n",
];
