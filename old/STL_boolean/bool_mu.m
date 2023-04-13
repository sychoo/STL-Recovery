% This file construct the binary variables and MILP constraints for the linear STL predicates
% constr: the list of constraints encoded
% z: satisfaction of the atomic proposition at each time step
function [constr, z] = bool_mu(x, a, b)
% ax_t >= b 
% therefore, ax - b >= 0
% a, b \in R
% x is (part of) the system state
M = 1e4;   % M cannot be too large, or use sdpvar for z
eps = 1e-8;

N = size(x, 1);
z = binvar(N, 1,'full');
% z = sdpvar(N, 1,'full');

constr=[];
for k = 1:N
    constr = [constr; M*(z(k)-1) <= a*x(k) - b]; % case analysis 1: if the 
    %                                                 statement is true, ax - b >= 0
                                                 % case analysis 2: if the
                                                 % statement is false, ax -
                                                 % b >= -infinity
                                         
    constr = [constr; a*x(k) - b <= (M)*z(k) - eps]; % case analysis 1: if the statement is true,
                                                     % ax - b <= inf
                                                     % case analysis 2: if
                                                     % the statement is
                                                     % false, ax - b <=
                                                     % -infinitely 
end

end
