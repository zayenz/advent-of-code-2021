include "globals.mzn";

% Input
int: n_starting_fish;
array[StartingFish] of int: starting_fish;

% Data
set of int: StartingFish = 1..n_starting_fish;


function array[int] of int: evolve(array[int] of int: fish, int: time_left) = 
    if time_left = 0 then
        fish
    else
        let {
            array[int] of int: updated_fish = [ if t=0 then 6 else t-1 endif | t in fish ],
            array[int] of int: new_fish = [ 8 | t in fish where t = 0 ],            
        } in
        evolve(updated_fish ++ new_fish, time_left-1)
    endif;

array[int] of int: final_fish = evolve(starting_fish, 80);

int: checksum = card(index_set(final_fish));

% Variables

% Constraints

% Solve and output
solve satisfy;

output [
  "starting_fish: ", show(starting_fish), "\n",
  "checksum:      ", show(checksum), "\n",
];
