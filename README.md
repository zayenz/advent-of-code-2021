# Advent of Code 2021 solutions

This repository contains some solutions to the [Advent of Code 2021](http://adventofcode.com/2021) 
advent calendar.

The solutions are writte in the [MiniZinc](https://www.minizinc.org/)
modelling language. As this is not a language that is made for general
programming, the input data is processed beforehand into suitable
format. The code is located in the **minizinc/** folder, and the file
**minizinc/advent-of-code-2021.mzp** is a project file that includes all
the solutions.


## Warning

MiniZinc is as mentioned not a normal general purpose programming
language, and thus the solutions are solved with the features that
are available. The solutions should not be viewed as good MiniZinc
code at all; they are written to solve the problem at hand and
as a way to have fun.

## Coding in MiniZinc

While MiniZinc is a modelling language foremost, it does have a pure
functional part that can be used for general computations. Some
notable limits on using MiniZinc for computation are
* No higher order functions (so no map, filter, fold)
* Limited data-types: values (ints, floats, and enums) and
  multi-dimensional arrays of values or sets of values only.
* Only declarative construction of data.
* No tail recursion and no garbage collection.

These limits are usually not that bad when writing a model, but get
problematic as soon as any large amount of data needs to be processed.

Some very nice parts when using MinZinc for coding are
* Set and array comprehensions
* Generator expressions with where clauses
* Set operations and relations
* Enum definitions
* Enum array indexing

In general, using enums for indexing into arrays is a very powerful
technique similar to newtypes in for example Haskell, as it also gives
good type-safety which is very useful when juggling several array
indices.


## Highlights and comments

Some aspeects solutions are more interresting than others. Here is a collection
of notes on days and solutions. Note that these comments may include
spoilers, so if you plan to solve any of these Advent of Code 2021
problems, do so first.

### Input handling

As MiniZinc has no parsing, the input has each day been modified
slightly in Emacs to fit into a suitable format for use as a MiniZinc
data file. 

Using data-files for the test data and the input data has worked very
well, especially in conjunction with the MiniZinc IDE.

### [Day 8](https://adventofcode.com/2021/day/8) Seven Segment Search

The problem in part 2 involves finding permutations as a way to match
input lines to segment names. This matched very well with a classic
constraint programming set-up, with `all_different` constaints over
the mappings for each display and the resulting digits. See the
details [in the model](minizinc/day8/day8-2.mzn).

### [Day 17](https://adventofcode.com/2021/day/17) Trick shot

With a simple model for how a projectile moves in 2 dimensions, and a
target to hit, Day 17 had two interesting parts. The first asked for the
maximum y coordinate possible while still hitting the target, while the
latter asked for how many initial velocities would hit the target at
all.

The first was easy to model as a 
[standard optimization problem](minizinc/day17/day17-1.mzn). 
One interesting feature of the
model is that only the two initial velocities are actually relevant to
search on, as the remaining coordinates are functionally determined. 

The second problem asked for the number of ways to hit the target. To
speed up the process, [the model](minizinc/day17/day17-2.mzn) uses a
direct computation instead, with a variable `hit` that represents
a time-step at which point the target is hit.

I used an inline variable construction in the search taking the absolute
value of the `y` velocity, in order to center th search around 0 to get
a resonable value ordering. The full search was defined as
```
solve 
  :: int_search([xv[1], abs(yv[1]), yv[1]], input_order, indomain_min)
  satisfy;
```
Somewhat interesitng, I had first added also the variable `hit` to the
search. This found too many solutions, as the set of unique solutions
is defined in MiniZinc by the solutions to the search variables, and
equal initial velocities can have multiple hit times. Since I had only
output the initial `x` and `y` values, MiniZinc actually showed me
both the number of solutions found, and the number of solutions with
different output.

Adding some simple ASCII plotting makes the solution very intuitive as
well.
```
Initial x velocity 6 and initial y velocity 2
...........#...#...............
......#...........#............
...............................
S...................#..........
...............................
...............................
.....................#.........
...............................
....................TTTTTTTTTTT
....................TTTTTTTTTTT
....................T#TTTTTTTTT
....................TTTTTTTTTTT
....................TTTTTTTTTTT
....................TTTTTTTTTTT
```

### [Day 15](https://adventofcode.com/2021/day/15) Shortest path

Implementing algorithms is fun, and implementing Dijkstra is something
I'v done many times. But implementing Dijkstra in MiniZinc turnd out
to be a bit of a challenge, since the language lacks the relevant
building blocks to build a reasonable priority queue. 
[My solution](minizinc/day15/day15-2.mzn) is not the most elegant
solution. In particular, it suffers from the problems mentioned above,
with no tail recursion optimization and all stack variables
staying around as long as the frame stays. This means that all
variants of the queue stay in memory until the search is complete,
which takes a bit of time and memory.

### [Day 21](https://adventofcode.com/2021/day/21) Game play

[Modelling the game play](minizinc/day21/day21-1.mzn) for part 1 was
quite elegant. In particular, I used the upcoming possibility in
MiniZinc to use labels in an array combined with an enum to model the
state update. Since the labels can be computed, the update function
became quite nice.

```
enum RollData = { RollValue, TimesRolled, NextRoll };

enum State = {
  P1Position,
  P2Position,
  P1Score,
  P2Score,
  Roll,
  RollsCount,
  Player,
};

function int: next_player(int: player) = if player = 1 then 2 else 1 endif;
function State: pos(int: player) = if player = 1 then P1Position else P2Position endif;
function State: score(int: player) = if player = 1 then P1Score else P2Score endif;
function array[RollData] of int: roll(int: die) = 
    [
      RollValue: 
          ((die + 0 - 1) mod 100) + 1 + 
          ((die + 1 - 1) mod 100) + 1 + 
          ((die + 2 - 1) mod 100) + 1,
      TimesRolled: 3,
      NextRoll: 
          ((die + 3 - 1) mod 100) + 1,
    ];

function array[State] of int: step(array[State] of int: state) =
    let {
        array[RollData] of int: roll_value = roll(state[Roll]),
        int: player = state[Player],
        int: next_player = next_player(player),
        int: new_pos = (state[pos(player)] - 1 + roll_value[RollValue]) mod 10 + 1,
        array[State] of int: next_state = [
            pos(player): new_pos,
            pos(next_player): state[pos(next_player)],
            score(player): state[score(player)] + new_pos,
            score(next_player): state[score(next_player)],
            Roll: roll_value[NextRoll],
            RollsCount: state[RollsCount] + roll_value[TimesRolled],
            Player: next_player,
        ]
    } in
    next_state;
```

### Accepting defeat and bad code

Some coding problems ar not suited at all for MiniZinc. In particular,
anything that requires efficiently updated data-structures is hard to
do. A prime example of this is 
[Day 16](https://adventofcode.com/2021/day/16) where a packet format is
decoded. While possible to do in MiniZinc, it is just not the right
tool.

As Advent of Code is a challenge to find the right answer, it is easy
to sometimes take short-cuts. For example, in 
[Day 14](https://adventofcode.com/2021/day/14) part 2, an operation is
repeatd 40 times. Instead of writing a rcursive function that takes an
argument and counts down, I simply wrote the below code instead. 

```
array[Elements, Elements] of int: step40 = 
    step(step(step(step(step(step(step(step(step(step(
        step(step(step(step(step(step(step(step(step(step(
            step(step(step(step(step(step(step(step(step(step(
                step(step(step(step(step(step(step(step(step(step(start_pairs)
                ))))))))))
            ))))))))))
        ))))))))))
    )))))))));
```
