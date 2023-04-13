clear;
yalmip('clear');

% 1 decision var without objectives
x = sdpvar(1,1);
Constraints = [x(1) == 0];
Objective = [];
options = sdpsettings('debug',1,'solver','gurobi','quadprog.maxiter',100);
optimize(Constraints, Objective, options);
disp("test 1");
disp(value(x));

%% 
y = sdpvar(10, 1); % inputs, with 10 step time horizon

% atomic proposition
% constraints and z_t for STL predicate 1*x>=2
% x - 2 >= 0
[c_p, z_p, rho] = robust_mu(y(:,1), 1, 2);
Constraints2 = [];
Constraints2 = [Constraints2; c_p];
optimize(Constraints2, Objective, options);
disp("states");
disp(value(y));

disp("z value (satisfaction at each time point)");
disp(value(z_p));

disp("robustess value");
v = value(rho);
disp(v(3));

%% TODO: change the optimization function to cumulative robustness