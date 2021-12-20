include "globals.mzn";

% Input
array[0..511] of bool: rules;
array[int, int] of bool: input;

% Data

function array[int, int] of bool: pad(array[int, int] of bool: base, int: amount) = 
    let {
        set of int: bis1 = index_set_1of2(base),
        set of int: bis2 = index_set_2of2(base),
        set of int: ois1 = 1..(card(bis1)+2*amount),
        set of int: ois2 = 1..(card(bis2)+2*amount),
        set of int: padding1 = 1..amount union (card(bis1)+amount+1)..max(ois1),
        set of int: padding2 = 1..amount union (card(bis1)+amount+1)..max(ois2),
        array[ois1, ois2] of bool: padded = array2d(ois1, ois2, [
            if o1 in padding1 \/ o2 in padding2 then
                false
            else
                base[o1-amount, o2-amount]
            endif
          | o1 in ois1, o2 in ois2
        ]);
    } in
    padded;

array[int, int] of bool: padded = pad(input, 4);

function 0..511: index(array[1..9] of bool: base) =
    256*base[1] + 128*base[2] + 64*base[3] + 32*base[4] + 16*base[5] + 8*base[6] + 4*base[7] + 2*base[8] + base[9];

function array[int, int] of bool: step(array[int, int] of bool: base) =
    let {
        set of int: bis1 = index_set_1of2(base),
        set of int: bis2 = index_set_2of2(base),
        set of int: boundary1 =  { 1 }  union { max(bis1) },
        set of int: boundary2 =  { 1 } union { max(bis2) },
        array[bis1, bis2] of bool: stepped = array2d(bis1, bis2, [
            if b1 in boundary1 \/ b2 in boundary2 then
                false
            else
                let {
                    array[1..9] of bool: around = array1d(base[b1-1..b1+1, b2-1..b2+1]),
                    0..511: output_index = index(around),                   
                } in
                rules[output_index]
            endif
          | b1 in bis1, b2 in bis2
        ]);
    } in
    stepped;
    
function array[int, int] of bool: clear_rim(array[int, int] of bool: base) =
    let {
        set of int: bis1 = index_set_1of2(base),
        set of int: bis2 = index_set_2of2(base),
        int: max1 = max(bis1),
        int: max2 = max(bis2),
        set of int: boundary1 =  1..2 union max1-1..max1,
        set of int: boundary2 =  1..2 union max2-1..max2,
        array[bis1, bis2] of bool: cleared = array2d(bis1, bis2, [
            if b1 in boundary1 \/ b2 in boundary2 then
                false
            else
                base[b1, b2]
            endif
          | b1 in bis1, b2 in bis2  
        ]),    
    } in
    cleared;

array[int, int] of bool: once = step(padded);
array[int, int] of bool: twice = step(step(padded));
array[int, int] of bool: result = clear_rim(twice);

int: checksum = sum(result);

% Variables

% Constraints

% Solve and output
solve satisfy;

function string: s(array[int, int] of bool: base) =
    let {
        set of int: bis1 = index_set_1of2(base),
        set of int: bis2 = index_set_2of2(base),        
    } in
    concat([
        concat([
            if base[b1, b2] then
                "#"
            else
                "."
            endif
          | b2 in bis2
        ]) ++ "\n"
      | b1 in bis1
    ]);

output [
    "Input:\n", s(padded), "\n",
    "Once:\n", s(once), "\n",
    "Twice:\n", s(twice), "\n",
    "Result:\n", s(result), "\n",
    "checksum: ", show(checksum), "\n",
];
