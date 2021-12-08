#!/bin/bash

mkdir $1

cat << EOF > $1/$1-1.mzn
% Input
array[int] of int: x;

% Data
set of int: X = index_set(x);

% Variables

% Constraints

% Solve and output
solve satisfy;

output [
  "x: ", show(x), "\n",
];
EOF

cat << EOF > $1/$1-input.dzn
x = [];
EOF

cat << EOF > $1/$1-test.dzn
x = [];
EOF
