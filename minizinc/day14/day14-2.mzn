%include "globals.mzn";

% Input
array[int] of Elements: start;
array[int, 1..3] of Elements: rule_list;

% Data
set of int: Elements = 1..11;
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
int: End = 11;

array[int] of Elements: start_with_end = start ++ [ End ];

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

array[Elements, Elements] of int: start_pairs = array2d(Elements, Elements, [
    count(i in 1..(length(start_with_end)-1)) ( start_with_end[i] = e1 /\ start_with_end[i+1] = e2 )
  | e1, e2 in Elements
]);

function bool: is_reagent(Elements: e1, Elements: e2) =
    occurs(rules[e1, e2]);

function array[Elements, Elements] of int: step(array[Elements, Elements] of int: input) =
    array2d(Elements, Elements, [
        if is_reagent(e1, e2) then
            % When (e1, e2) is a reagent, all pairs in the input will disappear
            0
        else
            % When (e1, e2) is not a reagent, all pais in the input will stay
            input[e1, e2]
        endif 
        +
        % Find all reagents such that the output will make a new pair (e1, e2) with the first part
        sum (r in Elements where rules[e1, r] = e2) (
            input[e1, r]
        )
        +
        % Find all reagents such that the output will make a new pair (e1, e2) with the second part
        sum (r in Elements where rules[r, e2] = e1) (
            input[r, e2]
        )
      | e1, e2 in Elements
    ]);
    
%array[Elements, Elements] of int: step10 = step(step(step(step(step(step(step(step(step(step(start_pairs))))))))));

array[Elements, Elements] of int: step40 = step(step(step(step(step(step(step(step(step(step(step(step(step(step(step(step(step(step(step(step(step(step(step(step(step(step(step(step(step(step(step(step(step(step(step(step(step(step(step(step(start_pairs))))))))))))))))))))))))))))))))))))))));


array[Elements] of int: counts = [
    sum (next in Elements) (
        step40[e, next]
    )
  | e in Elements
];

array[int] of int: non_zero_counts = [
    counts[e]
  | e in Elements where counts[e] > 0 /\ e != End
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
  "counts: ", show(counts), "\n",
  "checksum: ", show(checksum), "\n",
];
