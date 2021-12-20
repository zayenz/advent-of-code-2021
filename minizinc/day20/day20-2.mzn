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
    
function array[int, int] of bool: trim_to_inner(array[int, int] of bool: base) =
    let {
        set of int: bis1 = index_set_1of2(base),
        set of int: bis2 = index_set_2of2(base),
        int: max1 = max(bis1),
        int: max2 = max(bis2),
        set of int: boundary1 =  1..2 union max1-1..max1,
        set of int: boundary2 =  1..2 union max2-1..max2,
        set of int: inner1 =  bis1 diff boundary1,
        set of int: inner2 =  bis2 diff boundary2,
        set of int: lit1 = { i1 | i1 in inner1 where exists(i2 in inner2) (base[i1, i2]) },
        set of int: lit2 = { i2 | i2 in inner2 where exists(i1 in inner1) (base[i1, i2]) },
        set of int: span1 = min(lit1)..max(lit1),
        set of int: span2 = min(lit2)..max(lit2),
        set of int: ois1 = 1..card(span1),
        set of int: ois2 = 1..card(span2),
        array[ois1, ois2] of bool: cleared = array2d(ois1, ois2, [
            base[s1, s2]
          | s1 in span1, s2 in span2
        ]),    
    } in
    cleared;
    
function array[int, int] of bool: double_step(array[int, int] of bool: base) =
    trim_to_inner(step(step(pad(base, 4))));
    
function array[int, int] of bool: ten_steps(array[int, int] of bool: base) =
    double_step(double_step(double_step(double_step(double_step(base)))));

function array[int, int] of bool: fifty_steps(array[int, int] of bool: base) =
    ten_steps(ten_steps(ten_steps(ten_steps(ten_steps(base)))));

array[int, int] of bool: result = fifty_steps(input);

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
    "Result:\n", s(result), "\n",
    "checksum: ", show(checksum), "\n",
];
