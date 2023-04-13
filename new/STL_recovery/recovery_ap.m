% This file construct the binary variables and MILP constraints for the linear STL predicates
%
% params
% x: state variable
% a: ax >= b
% b: ax >= b
%
% returns
% constraint_list   : the list of constraints encoded
% satisfaction_list : satisfaction of the atomic proposition at each time step
% robustness_list   : robustness decision variable of the particular STL expression 

% a should be Nx1
% b should be Nx1

% note that the function name have to be consistent with the file name
% note that atomic proposition follows the form ax >= b

% define recoverability
% @params x a b : ax >= b
% @return recoverability
function [constraint_list, recoverability, satisfaction_list, robustness_list] = recovery_ap(x, a, b)
% ax >= b
% 
% ax - b >= 0
% a, b \in R
% x is (part of) the system state

M = 1e4;    % M is a large enough number - M cannot be too large, or use sdpvar for z
eps = 1e-8; % eps (epsilon) is a small enough number

N = size(x, 1);
satisfaction_list = binvar(N, 1,'full');
robustness_list = sdpvar(N, 1,'full');

recoverability = sdpvar(1, 1, 'full');

% initialize empty constraints
constraint_list = [];

for k = 1:N
    constraint_list = [constraint_list; M*(satisfaction_list(k)-1) <= a*x(k) - b]; 
                                                 % case analysis 1: if the 
                                                 % statement is true, ax - b >= 0
                                                 % case analysis 2: if the
                                                 % statement is false, ax -
                                                 % b >= -infinity
                                         
    constraint_list = [constraint_list; a*x(k) - b <= (M) * satisfaction_list(k) - eps]; % case analysis 1: if the statement is true,
                                                     % ax - b <= inf
                                                     % case analysis 2: if
                                                     % the statement is
                                                     % false, ax - b <=
                                                     % -eps (nearly 0)
                                                     
    constraint_list = [constraint_list; robustness_list(k) == a * x(k) - b];
                                                    % this is to calculate
                                                    % the list of
                                                    % robustness based on
                                                    % the state and atomic
                                                    % proposition
end

% recoverability is (satifaction_list(k) - 1) * robustness_list(k)
% TODO: if there are multiple negative states, choose the first recovery episode 

% area under the curve
recoverability = (satisfaction_list - 1)' * robustness_list;

end
