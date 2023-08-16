clear all
close all
clc

%% Define model and functions
import casadi.*
load_parameters  %"par" struct

% define optimization horizon
h = par.s_step;           % [m] sampling distance % h = par.s_step
N = par.N_horizon;        % [-] prediction horizon % N = par.N_horizon
sim_distance = par.s_tot; % Maximum simulation distance

% states: velocity, state of charge, state.time

state.v = SX.sym('state.v');
state.E_bat = SX.sym('state.E_bat');
state.time = SX.sym('state.time');

states = [state.v; state.E_bat; state.time];
n_states = length(states);

% control input: electric motor power
control.u = SX.sym('u');
controls = [control.u]; 
n_controls = length(controls);

% additional parameters (space dependent disturbances) : road inclination,
var.alpha = SX.sym('var.alpha');                % road inclination
var.G = SX.sym('var.G');                        % irradiation
var.v_front = SX.sym('var.v_front');            % front wind velocity
var.v_side = SX.sym('var.v_side');              % side wind velocity
var.theta_amb = SX.sym('var.theta_amb');        % ambient temperature
variables = [var.alpha; var.G; var.v_front; var.v_side; var.theta_amb];
n_vars = length(variables);

% right hand side of dynamics
rhs = [dv_rhs(par,states,controls,variables); dE_bat_rhs_ext(par,states,controls,variables); 1]; % [dv, dE_bat, dt]

% nonlinear mapping
f = Function('f', {states, controls, variables},{rhs});          % define function, "states" and "controls" are argument defined in "rhs"
U = SX.sym('U', n_controls, N);                                  % Decision variables (controls)
P = SX.sym('P', n_states + N*n_vars +1 +1 + 1 +1);                        % parameters: [x0, variables(n_vars*N), U(0)(1), SoC_target(1), X(2,0)(1), X(3,0)(1)]

X = SX.sym('X', n_states, (N+1));                   % A Matrix that represents the states over the optimization problem.

% initialize objective function and constraints vector
obj = 0;                                            % Objective function
g_nlp = [];                                             % constraints vector


%% Define constraints lhs via casaDi
% discretize using 4th order Runge Kutta
% define plant constraints (multiple shooting)
% define overall objective function over entire horizon

% E_bat_ref = 0.9;      % state.E_bat reference to track (TO BE CHANGED WITH DYNAMIC TRAJECTORY)

% objective functions and multishooting equality constraints
st  = X(:,1); % initial state
g.x0 = st-P(1:3); % initial condition constraints

g.st_next = [];
for k = 1:N
    st = X(:,k);  
    con = U(:,k);  
    
    % recall P is a vector P = [x0(n_states); var.alpha(N); G(N); var.v_front(N); var.v_side(N), temperature(N)]
    w = [P(n_states+ k);               % inclination    
           P(n_states+N + k);            % irradiation
           P(n_states+N+N + k);          % front wind
           P(n_states+N+N+N + k);        % side wind
           P(n_states+N+N+N+N + k)];     % temperature

%   obj = obj +  1/st(1) + 0.003 * (E_bat_ref - st(2));               % recall X = [velocity, state.E_bat, state.time]
    obj = obj + (con(1)-par.P_el_max)^2;                                                  % recall X = [velocity, state.E_bat, state.time]
    st_next = X(:,k+1);                                                   % "next state"  
    k1 = f(st, con, w);                                                   % RK weights 
    k2 = f(st + h/2*k1, con, w);          
    k3 = f(st + h/2*k2, con, w);         
    k4 = f(st + h*k3, con, w);           
    st_next_RK4= st + (h/st(1))/6*(k1 +2*k2 +2*k3 +k4);   % update next state using RK 4th order    % recall dt = ds/state.v, here dt = h/st(1) 
    g.st_next = [g.st_next; st_next-st_next_RK4];                         % compute constraints of updating states 

    %   f_value = f(st,con);
%   st_next_euler = st+ ((h/st(1))*f_value);              % update next stage using euler forward
%   g = [g;st_next-st_next_euler];                        % compute constraints
end

% input constraints
g.u_rate = [];
g.u_rate = [g.u_rate; P(n_states+n_vars*N+1) - U(:,1)] ;   %U(0) - U(1)     % P = [x_0(n_states);grade(N);inclination(N);var.v_front(N);var.v_side(N); amb_temp(N); U(k-1)(1); SoC_target_lastN(1);X(2,k-1)(1)]
for k = 1:N-1
    g.u_rate = [g.u_rate; U(:,k) - U(:,k+1)];
end

g.SoC_lb = [];
% for k = 1:N
    g.SoC_lb = [g.SoC_lb; X(2,k) - P(n_states+n_vars*N+1+ 1)];     %SoC - SoC_lowerbound_predicted
% end

% acceleration constraint
g.acc = [];
g.acc = [g.acc; (X(2,1) - P(n_states+n_vars*N+1+1 + 1))] ;   %V(1) - V(0)     % P = [x_0(n_states);grade(N);inclination(N);var.v_front(N);var.v_side(N); amb_temp(N); U(k-1)(1); SoC_target_lastN(1);X(2,k-1)(1);X(3,k-1)(1)]
for k = 1:N-1
    g.acc = [g.acc; (X(2,k+1) - X(2,k))];
end

% compose final constraints vector 
g_nlp = [g_nlp; g.x0; g.st_next; g.u_rate; g.SoC_lb; g.acc];

% make the decision variable one column vector
% optimization variable has to be given as a vector
OPT_variables = [reshape(X,n_states*(N+1),1);reshape(U,n_controls*N,1)];           % OPT_variables = [x1, x2, x3, ... xN, u1, u2, u3, ..., uN-1]

% create symbolic non linear problem
nlp_prob = struct('f', obj, 'x', OPT_variables, 'g', g_nlp, 'p', P); 

opts = struct;
opts.ipopt.max_iter = 2000;
opts.ipopt.print_level = 3;     %0,3,5
opts.print_time = 0;
opts.ipopt.acceptable_tol =1e-6; %1e-8
opts.ipopt.acceptable_obj_change_tol = 1e-6;

solver = nlpsol('solver', 'ipopt', nlp_prob, opts);

%% define constraints rhs value
args = struct;

% define constraints vector right hand side (left hand side);
% the indexes of the struct args.l/ubg(.) are related to the "g" vector
args.lbg(1:n_states*(N+1)) = 0;                                                 % -1e-20  % Equality constraints of the differences x(k+1) - f(x(k), u(k)) = 0 (lifting), g = [x0,]
args.ubg(1:n_states*(N+1)) = 0;                                                 % -> the lower and upper bound of vector g from index 1 to 3*(N+1) is 0 (equality)

% constraints
args.lbg(n_states*(N+1)+1: n_states*(N+1)+1 + n_controls*(N-1)) = -Inf;       % input rate boundary for P_el
args.ubg(n_states*(N+1)+1: n_states*(N+1)+1 + n_controls*(N-1)) =  Inf;

args.lbg(n_states*(N+1)+1+n_controls*(N-1)+1) =  -Inf;       % SoC - SoC_lowerbound > 0! at last time step of horizon N!
args.ubg(n_states*(N+1)+1+n_controls*(N-1)+1) =  Inf;

args.lbg(n_states*(N+1)+1+n_controls*(N-1)+1+1: n_states*(N+1)+1+n_controls*(N-1)+1+1 + (N-1)) =  -Inf;       % v(k)-v(k-1)
args.ubg(n_states*(N+1)+1+n_controls*(N-1)+1+1: n_states*(N+1)+1+n_controls*(N-1)+1+1 + (N-1)) =  Inf;       % 



% define boundary decision variables "OPT_variables"
% the indexes are
args.lbx(1:n_states:n_states*(N+1),1) = -Inf;         %state velocity lower bound 
args.ubx(1:n_states:n_states*(N+1),1) = Inf;         %state velocity upper bound
args.lbx(2:n_states:n_states*(N+1),1) = -Inf; %state state.E_bat lower bound
args.ubx(2:n_states:n_states*(N+1),1) = Inf;   %state state.E_bat upper bound
args.lbx(3:n_states:n_states*(N+1),1) = -Inf;          %state state.time lower bound
args.ubx(3:n_states:n_states*(N+1),1) = Inf;        %state state.time upper bound

args.lbx(n_states*(N+1)+1:n_controls:n_states*(N+1)+n_controls*N,1) = 0; % P_el_mot lower bound ATTENTION TO CHANGE
args.ubx(n_states*(N+1)+1:n_controls:n_states*(N+1)+n_controls*N,1) = 0; % P_el_mot upper bound

%----------------------------------------------
% ALL OF THE ABOVE IS JUST A PROBLEM SET UP

%%

% THE SIMULATION LOOP SHOULD START FROM HERE
%-------------------------------------------
prompt = "Initial velocity [m/s]: ";
v_0 = input(prompt);
%v_0 = 16.5;
prompt = "Initial SoC [m/s]: ";
SoC_0 = input(prompt);
%SoC_0 = 0.9;
prompt = "Initial time [m/s]: ";
t_0 = input(prompt);
%t_0 = 0;

h0 = 0;                                                 % initial start distance
x0 = [v_0 ; par.E_bat_max * SoC_0 ; t_0];               % initial condition.
% xs = [20 ; 0.9 ; 0.0];                                % Reference (not used).

xx(:,1) = x0;                    % xx contains the history of states
dist(1) = h0;

u0 = zeros(N,n_controls);        % 1 control input P_mot_el
X0 = repmat(x0,1,N+1)';          % initialization of the states decision variables


% variable inclination and variable irradiation; TO BE CHANGED WITH REAL
% VALUES
simvar.alpha = linspace(0.00, 0.00, 2*sim_distance/h)';          % continuosly uphill
%simvar.alpha = par.Route.incl';                                   % actual inclination 
simvar.G = linspace(1000, 1000, (par.s_tot+par.N_horizon*par.s_step)/h)';                 % rising sun  
simvar.v_front = linspace(0.00, 0.00, (par.s_tot+par.N_horizon*par.s_step)/h)';       % [m/s] front wind
simvar.v_side = linspace(0.00, 0.00, (par.s_tot+par.N_horizon*par.s_step)/h)';          % [m/s] side wind
simvar.theta_amb = linspace(25, 25, (par.s_tot+par.N_horizon*par.s_step)/h)';           % [°C] ambient temperature

%SoC_target = linspace(par.SoC_start*par.E_bat_max, par.SoC_end*par.E_bat_max, (par.s_tot+par.N_horizon*par.s_step)/h)';
SoC_target = par.E_bat_target_1000km;

% Start MPC
mpciter = 0;                     % mpc iterations
xx1 = [];                        % contains the the trajectory
u_cl=[];                         % control actions history
u_prev = 0;                      % initial input
v_prev = v_0;
t_prev = 0;
% the main simulaton loop... the number of mpc steps is less than its maximum
% value.
main_loop = tic;
while mpciter < sim_distance / h
    
    % update initial state, update meteo condition prediction
    vars_update = [simvar.alpha(1+mpciter:N+mpciter); 
                   simvar.G(1+mpciter:N+mpciter);
                   simvar.v_front(1+mpciter:N+mpciter);
                   simvar.v_side(1+mpciter:N+mpciter); 
                   simvar.theta_amb(1+mpciter:N+mpciter)];

    args.p = [x0; vars_update; u_prev; SoC_target(N+mpciter); v_prev; t_prev]; % set the values of the parameters vector, set the slope prediction = [x0; road_slope_over_horizon N]

    % update maximal velocity constraint
    %args.ubx(1:n_states:n_states*(N+1),1) = par.Route.max_v(1+mpciter:N+1+mpciter); %state velocity upper bound

    % initial value of the optimization variables
    % args.x0  = [reshape(X0',n_states*(N+1),1);reshape(u0',n_controls*N,1)];
    % sol = solver('x0', args.x0, 'lbx', args.lbx, 'ubx', args.ubx,...
    %     'lbg', args.lbg, 'ubg', args.ubg,'p',args.p);

    % save states and input
    if mpciter < 10
        u = 0;
    else
        u = 1;
    end

    % u = reshape(full(sol.x(n_states*(N+1)+1:end))',n_controls,N)';                  % get controls only from the solution
    % xx1(:,1:3,mpciter+1)= reshape(full(sol.x(1:n_states*(N+1)))',n_states,N+1)';    % get solution TRAJECTORY
    u_cl= [u_cl ; u(1,:)];

    u_prev = u(1,:);                % save u for the constraint of input rate (see args.P and P)
    dist(mpciter+1) = h0;
    
    % Apply the control and shift the solution
    [h0, x0, u0] = shift(h, h0, x0, u, f, [simvar.alpha(1+mpciter); ...
                                           simvar.G(1+mpciter); ...
                                           simvar.v_front(1+mpciter); ...
                                           simvar.v_side(1+mpciter); ...
                                           simvar.theta_amb(1+mpciter)]);      %update the states, 

    v_prev = x0(2);
    t_prev = x0(3);

    xx(:,mpciter+2) = x0;                                % +2 because x0 just shifted (mpciter starts at 0, x0 is in position 1 (x0(mpciter+1)), so x0 in position 2 is x0(mpciter+2), and so on
    % X0 = reshape(full(sol.x(1:n_states*(N+1)))',3,N+1)'; % get solution TRAJECTORY
   
    % Shift trajectory to initialize the next step
    % X0 = [X0(2:end,:);X0(end,:)];
    mpciter
    mpciter = mpciter + 1;
end

main_loop_time = toc(main_loop);
average_mpc_time = main_loop_time/(mpciter+1)

%%
%2083
xx(3,end)      % [s] total state.time
visualize_plot
