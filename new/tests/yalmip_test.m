% test a simple constraint solving using yalmip solver with gurobi
% this requires installation fo gurobi solver which is separate from yalmip
% installation

% for details, refer to
% https://yalmip.github.io/tutorial/basics/

clear;
yalmip('clear');

% declare a 1x1 decision var
x = sdpvar(1,1);

% add constraint to restrict x to be between -10 ~ 10
Constraints = [x(1) >= -10; x(1) <= 10];

% define an objective
Objective = x(1);

% options for the solver
% to display verbose or debug information, set 'verbose' and 'debug' flag
% to 1
options = sdpsettings('verbose',0,'solver','gurobi','quadprog.maxiter',100);

% invoke the solver
optimize(Constraints, Objective, options);

disp("========================")
disp("Executing yalmip_test.m");
fprintf('The solution of x = %d\n',value(x));
disp("========================")
