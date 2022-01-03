include "globals.mzn";

% Input
array[int] of Instructions: ins;
array[int, Pos] of Args: args;

% Data
enum Pos = { Arg1, Arg2 };

set of int: Steps = index_set(ins);
int: first_step = min(Steps);
int: last_step = max(Steps);

set of int: Inputs = 1..count(ins, inp);
int: first_input = min(Inputs);
int: last_input = max(Inputs);

enum Instructions = {
    inp,
    iadd,
    imul,
    idiv,
    imod,
    eql
};

set of int: Immediates = -127..127;
enum Registers = { w, x, y, z };
enum Args = R(Registers) ++ Imm(Immediates) ++ { None };
set of int: Digits = 0..9;

set of int: ExtendedSteps = first_step-1..last_step;
set of int: ExtendedInputs = first_input..last_input+1;

% Variables

% The input digits
array[Inputs] of var Digits: inputs;
% Time-stepped matrix of register values
array[ExtendedSteps, Registers] of var int: regs;


% Constraints

% Before program start, all registers are set to 0
constraint forall (r in Registers) (
     regs[min(ExtendedSteps), r] = 0
);

% The set of registers that are not set by the instruction at step
function set of Registers: unaffected(Steps: step) = {
    r
  | r in Registers
    where R(r) != args[step, Arg1]
};

% The argument at pos for the argument_step, when read from registers at register_step
function var int: arg(Steps: register_step, Steps: argument_step, Pos: pos) = 
    if args[argument_step, pos] in R(Registers) then
        regs[register_step, R^-1(args[argument_step, pos])]
    elseif args[argument_step, pos] in Imm(Immediates) then
        Imm^-1(args[argument_step, pos])
    else
        assert(false, "No value for arg of type None at argument step \(argument_step) in position \(pos) with register step \(register_step)\n")
    endif;

% The write argument for the step
function var int: writearg(Steps: step) = arg(step, step, Arg1);

% The read argument at position pos for the step 
function var int: readarg(Steps: step, Pos: pos) = arg(step-1, step, pos);

% Intepret the program
predicate interpret(Steps: step, ExtendedInputs: next_input) = (
    % Interpret instruction
    if ins[step] = inp then
        writearg(step) = inputs[next_input] 
    else
        let {
            % Symbolic names for the read arguments and write argument
            var int: a = readarg(step, Arg1),
            var int: b = readarg(step, Arg2),
            var int: r = writearg(step),
        } in    
        if ins[step] = iadd then
            r = a + b
        elseif ins[step] = imul then
            r = a * b 
        elseif ins[step] = idiv then
            b != 0 /\ % Safety requirement for ALU programs
            r * b = a - (a mod b)
        elseif ins[step] = imod then
            a >= 0 /\ % Safety requirement for ALU programs
            b >  0 /\ % Safety requirement for ALU programs
            r = a mod b 
        elseif ins[step] = eql then
            r = (a = b) 
        else
            assert(false, "Unknown instruction \(ins[step]) at step \(step)\n")
        endif
    endif /\
    % Maintain all non-output registers between steps
    forall (r in unaffected(step)) (
      regs[step-1, r] = regs[step, r]
    ) /\
    % Continue with next step if there is one
    if step+1 in Steps then
        interpret(step+1, next_input + (ins[step] = inp))
    else
        true
    endif
);

% Interpret the program from the start
constraint interpret(first_step, first_input);

% A valid run leaves a 0 in the last z register
constraint regs[last_step, z] = 0;

% No input digit should be 0
constraint forall (i in Inputs) (
    inputs[i] != 0
);

% Solve and output

% By selecting the input digits in order and choosing the maximum value, the first solution found in DFS order will be the maximum value
solve :: int_search(inputs, input_order, indomain_max) satisfy;

output [
  "inputs:          ", show(inputs), "\n",
  "final registers: ", show(regs[max(Steps), ..]), "\n",
];
