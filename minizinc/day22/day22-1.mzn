include "globals.mzn";

% Input
array[int] of bool: flip;
array[int, Coordinate] of set of int: instructions;

% Data
enum Coordinate = { X, Y, Z };
bool: on = true;
bool: off = false;

set of int: Instructions = index_set_1of2(instructions);

int: noop = max(Instructions) + 1;

set of int: BootSector = -50..50;
set of int: BootInstructions = { 
    i 
  | i in Instructions 
    where instructions[i, X] subset BootSector /\ 
          instructions[i, Y] subset BootSector /\ 
          instructions[i, Z] subset BootSector 
};

set of int: BIN = BootInstructions union { noop };

array[BootSector, BootSector, BootSector] of bool: lights = array3d(BootSector, BootSector, BootSector, [
    let {
        BIN: bi = max({ 
            bi 
          | bi in BootInstructions 
              where x in instructions[bi, X] /\
                    y in instructions[bi, Y] /\
                    z in instructions[bi, Z]
        }) default noop;
    } in
      flip[bi] default false
  | x in BootSector, y in BootSector, z in BootSector
]);

int: checksum = sum(lights);

% Variables

% Constraints

% Solve and output
solve satisfy;

output [
  "checksum: ", show(checksum), "\n",
];
