%include "globals.mzn";

% Input
array[int] of Elements: start;
array[int, 1..3] of Elements: rule_list;

% Data
set of int: Elements = 1..10;
int: B =  1;
int: C =  2;
int: F =  3;
int: H =  4;
int: K =  5;
int: N =  6;
int: O =  7;
int: P =  8;
int: S =  9;
int: V = 10;

function opt int: rule_list_output(Elements: e1, Elements: e2, int: i) = 
    if rule_list[i, 1] = e1 /\ rule_list[i, 2] = e2 then
        rule_list[i, 3]
    elseif i+1 in index_set_1of2(rule_list) then
        rule_list_output(e1, e2, i+1)
    else
        <>
    endif;
      

array[Elements, Elements] of opt Elements: rules = array2d(Elements, Elements, [
    let {
        opt int: res = rule_list_output(e1, e2, 1)
    } in
    if occurs(res) then
        to_enum(Elements, deopt(res))
    else
        <>
    endif
  | e1, e2 in Elements
]);

function bool: is_reagent(Elements: e1, Elements: e2) =
    occurs(rules[e1, e2]);

function array[int] of Elements: step(array[int] of Elements: input) =
    [
        deopt(
            [input[i], rules[input[i], input[i+1]]][j]
        )
      | i in 1..(length(input)-1), j in 1..(1+is_reagent(input[i], input[i+1]))
    ] ++ [ input[length(input)] ];

array[int] of Elements: step10 = step(step(step(step(step(step(step(step(step(step(start))))))))));

array[Elements] of int: counts = [
    count(step10, e)
  | e in Elements
];
array[int] of int: non_zero_counts = [
    counts[e]
  | e in Elements where counts[e] > 0
];
array[int] of int: sorted_counts = sort(non_zero_counts);

int: checksum = sorted_counts[length(sorted_counts)] - sorted_counts[1];

% Variables

% Constraints

% Solve and output
solve satisfy;

output [
  "rules:    \n", show2d(rules), "\n",
  "start: ", show(start), "\n",
  "checksum: ", show(checksum), "\n",
];
