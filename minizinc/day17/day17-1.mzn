include "globals.mzn";

% Input
int: minx;
int: maxx;
int: miny;
int: maxy;

% Data
set of int: X = minx..maxx;
set of int: Y = miny..maxy;

int: nsteps = 300;
set of int: Steps = 1..nsteps;


% Variables

array[Steps] of var int: x;
array[Steps] of var int: y;

array[Steps] of var int: xv;
array[Steps] of var int: yv;

array[Steps] of var int: xvsign;

% Constraints

% Initial position
constraint x[1] = 0 /\ y[1] = 0;

% Hitting target zone
constraint exists (step in Steps) (
    x[step] in X /\ y[step] in Y
);

% Constraining initial velocities
constraint (
    % Target is in front of starting position
    xv[1] > 0 /\
    % Assumption, shoot upwards?
    yv[1] > 0
);

% Sign of velocity?
constraint forall (step in Steps) (
    let {
      var bool: xvnegative = xv[step] < 0,
      var bool: xvpositive= xv[step] > 0,
    } in
    xvsign[step] = (-1 * xvnegative) + (1 * xvpositive)
);

% Process
predicate relate(Steps: s1, Steps: s2) = (
    x[s2] = x[s1] + xv[s1] /\
    y[s2] = y[s1] + yv[s1] /\
    xv[s2] = xv[s1] - xvsign[s1] /\
    yv[s2] = yv[s1] - 1
);
    
constraint forall (s1 in 1..<nsteps) (
    relate(s1, s1+1)
);

var int: checksum = max(y);

% Solve and output
solve 
  :: int_search([xv[1], yv[1]], input_order, indomain_min)
  maximize checksum;

bool: plot = false;

output [
  "Initial x velocity \(xv[1]) and initial y velocity \(yv[1])\n",
  "x:      ", concat([show_int(3, xp) ++ if fix(xp) in X then "<" else " " endif | xp in x]), "\n",
  "y:      ", concat([show_int(3, yp) ++ if fix(yp) in Y then "<" else " " endif | yp in y]), "\n",
  "xvsign: ", show(xvsign), "\n",
  "xv:     ", show(xv), "\n",
  "yv:     ", show(yv), "\n",
  "checksum: ", show(checksum), "\n",
  if plot then
      concat([
          concat([
              if xp = 0 /\ yp = 0 then
                  "S"
              elseif exists(step in Steps) ( fix(x[step]) = xp /\ fix(y[step]) = yp ) then
                  "#"
              elseif xp in X /\ yp in Y then
                  "T"
              else
                  "."
              endif
            | xp in 0..maxx
          ]) ++ "\n"
        | yp in reverse(miny..fix(checksum))
      ])
  else
      ""
  endif
];
