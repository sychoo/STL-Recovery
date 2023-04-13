% This file construct the binary variables and MILP constraints for the linear STL predicates
% constr: the list of constraints encoded
% z: satisfaction of the atomic proposition at each time step
% rho: robustness decision variable of the particular STL expression 

% a should be Nx1
% b should be Nx1

function [constraints, satisfaction_list, robustness_list] = robust_mu(x, a, b)
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

constr=[];
for k = 1:N
    constraints = [constraints; M*(z(k)-1) <= a*x(k) - b]; 
                                                 % case analysis 1: if the 
                                                 % statement is true, ax - b >= 0
                                                 % case analysis 2: if the
                                                 % statement is false, ax -
                                                 % b >= -infinity
                                         
    constraints = [constraints; a*x(k) - b <= (M) * satisfaction_list(k) - eps]; % case analysis 1: if the statement is true,
                                                     % ax - b <= inf
                                                     % case analysis 2: if
                                                     % the statement is
                                                     % false, ax - b <=
                                                     % -eps (nearly 0)
                                                     
    constraints = [constraints; robustness_list(k) == a * x(k) - b];
                                                    % this is to calculate
                                                    % the list of
                                                    % robustness based on
                                                    % the state and atomic
                                                    % proposition
end

end
