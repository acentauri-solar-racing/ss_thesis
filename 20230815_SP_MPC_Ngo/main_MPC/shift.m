% shift function: update the new initial conditions in the optimization
% INPUT 
% h [1x1]: spatial discretization step
% h0 [1x1]: actual spatial position at the moment of the function call
% x0 [1xn_states]: actual states at the moment of the function call
% u [1xn_controls]: actual input at the moment of the function call
% vars [n_varsx1]: actual variable states at the moment of the function call
function [h0, x0, u0] = shift(h, h0, x0, u, f, vars)
st = x0;
con = u(1,:)';

k1 = f(st, con, vars); 
k2 = f(st + h/2*k1, con, vars); 
k3 = f(st + h/2*k2, con, vars); 
k4 = f(st + h*k3, con, vars); 
st = st + (h/st(1))/6*(k1 +2*k2 +2*k3 +k4); %RK 4th order method    

% f_value = f(st,con);
% st = st+ (T*f_value);
x0 = full(st);                              % update x0 with new state

h0 = h0 + h;                                % update distance h0 with new state
u0 = [u(2:size(u,1),:);u(size(u,1),:)];         
end
