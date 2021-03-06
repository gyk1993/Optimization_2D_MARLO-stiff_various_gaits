%% generateConstraintFunctions.m
% -------------------------------------------------------------------------
% This script will generate the necessary functions to run the direct
% collocation  optimization code
%
% Author:   Ross Hartley
% Date:     8/19/2015
% -------------------------------------------------------------------------

% load in symbolic model

% base attached to hip
 load('Work_Symbolic_2D_ATRIAS_Lagrange_JWG_flight20161110T154059.mat')

% base attached to stance foot
% load('Work_Symbolic_2D_ATRIAS_Lagrange_JWG_dynamicreduced_20150824T104338.mat')

% ---------------------------------------------------------------------------
AUTOGEN_PATH = 'AutoGeneratedFiles';
BUILD_SIM_PATH = [AUTOGEN_PATH, '\build_sim'];
BUILD_OPT_PATH = [AUTOGEN_PATH, '\build_opt'];

domainName = '2DSS';
nNodes = 15;
DOF = length(q);
DOA = 4;
DOUA = DOF - DOA; % degree of underactuation
M = 5; % order of bezier
x = [q;dq];


q1=sym('q1', [7, 1]);
dq1=sym('dq1', [7, 1]);
q2=sym('q2', [7, 1]);
dq2=sym('dq2', [7, 1]);
x1 = [q1;dq1];
x2 = [q2;dq2];

holConstraints = p4R; % stack all the holonomic constraits here
holConstraints_desired = [0;0]; % desired values for holonomic constraints

J = jacobian(holConstraints,q);
E = jacobian(p4L,q);
Jdot = jacobian(J*dq,q); % not sure if correct

% define optimization parameters
ddq = sym('ddq', [7, 1]);
u = sym('u', [4, 1]);
F = sym('F', [size(J,1), 1]);
alpha = sym('alpha', [DOA, M+1]);
alpha = reshape(alpha,(M+1)*DOA,1);
beta = sym('beta', [2,1]);
syms T

% stack optimization parameters
z = [T;q;dq;ddq;u;F;alpha;beta];

%% Define Outputs
% [LAR, LAL, KAR, KAL]
H0 =  [0, 0, 1, 0, 0,  0,  0;...
       0, 0, 0,  0,  0, .5, .5;...
       0, 0, 0, -1,  1,  0,  0;...
       0, 0, 0,  0,  0, -1,  1];
 
h0 = H0*q;
dh0 = jacobian(h0,q)*dq;
ddh0 = jacobian(dh0,dq)*ddq;

% Find gait timing variable
T_theta = [0,0,-1,-.5,-.5,0,0];
Tb = 3*pi/2;
theta = T_theta*q + Tb;

% Bezier curve based virtual contraints
syms s
hd = VirtualConstraints_Bezier(M, DOA);

% Compute s (between 0 and 1)
syms t T N index
s = t/T;
ds = 1/T;

% outputs
hd = subs(hd);
y = h0 - hd; 
dy = jacobian(h0,q)*dq - jacobian(hd,t);
ddy = jacobian(jacobian(h0,q)*dq,[q;dq])*[dq;ddq] - jacobian(jacobian(hd,t),t);
       
% Substitute nodes in
deltaT = T/(N-1);
t = (index-1)*deltaT;
s = subs(s);

y = subs(y);
dy = subs(dy);
ddy = subs(ddy);

% y = 0
constraint = y;
vars = [q;T;alpha].';
extra = [N;index].';
J_constraint = jacobian(y, vars);
matlabFunction(constraint, 'file', [BUILD_OPT_PATH ,'\f_y_', domainName], 'vars', {vars,extra});
matlabFunction(J_constraint, 'file', [BUILD_OPT_PATH ,'\J_y_', domainName], 'vars', {vars,extra});

% dy = 0
constraint = dy; 
vars = [q;dq;T;alpha].';
extra = [N;index].';
J_constraint = jacobian(dy, vars);
matlabFunction(constraint, 'file', [BUILD_OPT_PATH ,'\f_dy_', domainName], 'vars', {vars,extra});
matlabFunction(J_constraint, 'file', [BUILD_OPT_PATH ,'\J_dy_', domainName], 'vars', {vars,extra});

% ddy = 0
syms Kp Kd
constraint = ddy + Kd*dy + Kp*y; 
vars = [q;dq;ddq;T;alpha].';
extra = [Kp;Kd;N;index].';
J_constraint = jacobian(ddy, vars);
matlabFunction(constraint, 'file', [BUILD_OPT_PATH ,'\f_ddy_', domainName], 'vars', {vars,extra});
matlabFunction(J_constraint, 'file', [BUILD_OPT_PATH ,'\J_ddy_', domainName], 'vars', {vars,extra});


%% Generate Dynamics Constraint function
% D(q)*ddq + H(q,dq) - Bu - J'(q)*F = 0
constraint = D*ddq + C*dq + G - B*u - J.'*F;
vars = [q;dq;ddq;u;F].';
J_constraint = jacobian(constraint, vars);
matlabFunction(constraint, 'file', [BUILD_OPT_PATH ,'\f_dynamics_', domainName], 'vars', {vars});
matlabFunction(J_constraint, 'file', [BUILD_OPT_PATH ,'\J_dynamics_', domainName], 'vars', {vars});


%% Generate Holonomic Constraints
% acceleration
% J*ddq + Jdot*dq = 0
constraint = J*ddq + Jdot*dq;
vars = [q;dq;ddq].';
J_constraint = jacobian(constraint,vars);
matlabFunction(constraint, 'file', [BUILD_OPT_PATH ,'\f_holonomicAcc_', domainName], 'vars', {vars});
matlabFunction(J_constraint, 'file', [BUILD_OPT_PATH ,'\J_holonomicAcc_', domainName], 'vars', {vars});

% velociy
% J*dq = 0
constraint = J*dq;
vars = [q;dq].';
J_constraint = jacobian(constraint,vars);
matlabFunction(constraint, 'file', [BUILD_OPT_PATH ,'\f_holonomicVel_', domainName], 'vars', {vars});
matlabFunction(J_constraint, 'file', [BUILD_OPT_PATH ,'\J_holonomicVel_', domainName], 'vars', {vars});

% position
% holConstraints - hd = 0
syms h1 h2
h = [h1;h2];
constraint = p4R - h;
vars = [q;h].';
J_constraint = jacobian(constraint,vars);
matlabFunction(constraint, 'file', [BUILD_OPT_PATH ,'\f_holonomicPos_', domainName], 'vars', {vars});
matlabFunction(J_constraint, 'file', [BUILD_OPT_PATH ,'\J_holonomicPos_', domainName], 'vars', {vars});

% position
% holConstraints - hd = 0
syms h1 h2
h = [h1;h2];
constraint = h;
vars = [h].';
J_constraint = jacobian(constraint,vars);
matlabFunction(constraint, 'file', [BUILD_OPT_PATH ,'\f_hInit_', domainName], 'vars', {vars});
matlabFunction(J_constraint, 'file', [BUILD_OPT_PATH ,'\J_hInit_', domainName], 'vars', {vars});


%% Guard Constraint
% trajectory hits guard when the swing foot height goes to 0
constraint = p4L(2);
vars = q.';
J_constraint = jacobian(constraint,vars);
matlabFunction(constraint, 'file', [BUILD_OPT_PATH ,'\f_swingFoot_guard_', domainName], 'vars', {vars});
matlabFunction(J_constraint, 'file', [BUILD_OPT_PATH ,'\J_swingFoot_guard_', domainName], 'vars', {vars});

%% Reset Map
R = eye(DOF);
R_tmp = R;
R(:,4) = R_tmp(:,6); % swap q1R and q1L
R(:,5) = R_tmp(:,7);
R(:,6) = R_tmp(:,4);
R(:,7) = R_tmp(:,5);

q0p = sym('q0p_', [DOF,1]);
dq0p = sym('dq0p_', [DOF,1]);
qN = sym('qN_', [DOF,1]);
dqN = sym('dqN_', [DOF,1]);
Fimp = sym('Fimp_', [2,1]);

% finding J(qN) using swing foot jacobian
JqN = E;
JqN = subs(JqN,qT,qN(3));
JqN = subs(JqN,q1R,qN(4));
JqN = subs(JqN,q2R,qN(5));
JqN = subs(JqN,q1L,qN(6));
JqN = subs(JqN,q2L,qN(7));

% finding D(qN)
DN = D;
DN = subs(DN,qT,qN(3));
DN = subs(DN,q1R,qN(4));
DN = subs(DN,q2R,qN(5));
DN = subs(DN,q1L,qN(6));
DN = subs(DN,q2L,qN(7));

% subbing p4L
p4L_end = p4L(1);
p4L_end = subs(p4L_end,yH,qN(1));

p4L_end = subs(p4L_end,zH,qN(2));
p4L_end = subs(p4L_end,qT,qN(3));
p4L_end = subs(p4L_end,q1R,qN(4));
p4L_end = subs(p4L_end,q2R,qN(5));
p4L_end = subs(p4L_end,q1L,qN(6));
p4L_end = subs(p4L_end,q2L,qN(7));

% q Reset - C15
constraint = R*q0p - qN + [p4L_end;0;0;0;0;0;0];
vars = [qN;q0p].';
J_constraint = jacobian(constraint,vars);
matlabFunction(constraint, 'file', [BUILD_OPT_PATH ,'\f_qResetMap_', domainName], 'vars', {vars});
matlabFunction(J_constraint, 'file', [BUILD_OPT_PATH ,'\J_qResetMap_', domainName], 'vars', {vars});

% dq Reset - C16, C17
constraint = [JqN*R*dq0p; ...
          DN*(R*dq0p - dqN) - JqN.'*Fimp];
dq0p = sym('dq0p_', [DOF,1]);
vars = [qN;dqN;Fimp;dq0p].';
J_constraint = jacobian(constraint,vars);
matlabFunction(constraint, 'file', [BUILD_OPT_PATH ,'\f_dqResetMap_', domainName], 'vars', {vars});
matlabFunction(J_constraint, 'file', [BUILD_OPT_PATH ,'\J_dqResetMap_', domainName], 'vars', {vars});


%% Collocation Constraints

syms T N i
deltaT = T/(N-1);
q1 = sym('q1_',[DOF,1]); % i-1
dq1 = sym('dq1_',[DOF,1]); 
ddq1 = sym('ddq1_',[DOF,1]); % *bug fix* this was dq1

q2 = sym('q2_',[DOF,1]); % i+1
dq2 = sym('dq2_',[DOF,1]); % i
ddq2 = sym('ddq2_',[DOF,1]); 

q3 = sym('q3_',[DOF,1]); % i+1
dq3 = sym('dq3_',[DOF,1]);
ddq3 = sym('ddq3_',[DOF,1]); 

% C2
% integration constraints (position level)
constraint = q3 - q1 - (1/6)*deltaT*(dq1 + 4*dq2 + dq3);
vars = [T;q1;dq1;dq2;q3;dq3].';
extra = [N].';
J_constraint = jacobian(constraint,vars);
matlabFunction(constraint, 'file', [BUILD_OPT_PATH ,'\f_intPos_', domainName], 'vars', {vars,extra});
matlabFunction(J_constraint, 'file', [BUILD_OPT_PATH ,'\J_intPos_', domainName], 'vars', {vars,extra});

% integration constraints (velocity level)
constraint = dq3 - dq1 - (1/6)*deltaT*(ddq1 + 4*ddq2 + ddq3);
vars = [T;dq1;ddq1;ddq2;dq3;ddq3].';
extra = [N].';
J_constraint = jacobian(constraint,vars);
matlabFunction(constraint, 'file', [BUILD_OPT_PATH ,'\f_intVel_', domainName], 'vars', {vars,extra});
matlabFunction(J_constraint, 'file', [BUILD_OPT_PATH ,'\J_intVel_', domainName], 'vars', {vars,extra});

% C1
% midPoint constraints (position level)
constraint = q2 - (1/2)*(q3 + q1) - (1/8)*deltaT*(dq1 - dq3);
vars = [T;q1;dq1;q2;q3;dq3].';
extra = [N].';
J_constraint = jacobian(constraint,vars);
matlabFunction(constraint, 'file', [BUILD_OPT_PATH ,'\f_midPointPos_', domainName], 'vars', {vars,extra});
matlabFunction(J_constraint, 'file', [BUILD_OPT_PATH ,'\J_midPointPos_', domainName], 'vars', {vars,extra});

% midPoint constraints (velocity level)
constraint = dq2 - (1/2)*(dq3 + dq1) - (1/8)*deltaT*(ddq1 - ddq3);
vars = [T;dq1;ddq1;dq2;dq3;ddq3].';
extra = [N].';
J_constraint = jacobian(constraint,vars);
matlabFunction(constraint, 'file', [BUILD_OPT_PATH ,'\f_midPointVel_', domainName], 'vars', {vars,extra});
matlabFunction(J_constraint, 'file', [BUILD_OPT_PATH ,'\J_midPointVel_', domainName], 'vars', {vars,extra});

%% Parameter Constraints between nodes

% Time Consistancy Constraint - C10
syms T1 T2
constraint = T1-T2;
vars = [T1;T2].';
J_constraint = jacobian(constraint,vars);
matlabFunction(constraint, 'file', [BUILD_OPT_PATH ,'\f_timeCont_', domainName], 'vars', {vars});
matlabFunction(J_constraint, 'file', [BUILD_OPT_PATH ,'\J_timeCont_', domainName], 'vars', {vars});

% p (beta/thetaLimits) Consistancy Constraint - C9
p1 = sym('p1',[2,1]);
p2 = sym('p2',[2,1]);
constraint = p1 - p2;
vars = [p1;p2].';
J_constraint = jacobian(constraint,vars);
matlabFunction(constraint, 'file', [BUILD_OPT_PATH ,'\f_pCont_', domainName], 'vars', {vars});
matlabFunction(J_constraint, 'file', [BUILD_OPT_PATH ,'\J_pCont_', domainName], 'vars', {vars});

% a (alpha/h_alpha) Consistancy Constraint - C7
a1 = sym('a1',[length(alpha),1]);
a2 = sym('a2',[length(alpha),1]);
constraint = a1 - a2;
vars = [a1;a2].';
J_constraint = jacobian(constraint,vars);
matlabFunction(constraint, 'file', [BUILD_OPT_PATH ,'\f_aCont_', domainName], 'vars', {vars});
matlabFunction(J_constraint, 'file', [BUILD_OPT_PATH ,'\J_aCont_', domainName], 'vars', {vars});

% h Consistancy Constraint - C7
h1 = sym('h1',[2,1]);
h2 = sym('h2',[2,1]);
constraint = h1 - h2;
vars = [h1;h2].';
J_constraint = jacobian(constraint,vars);
matlabFunction(constraint, 'file', [BUILD_OPT_PATH ,'\f_hCont_', domainName], 'vars', {vars});
matlabFunction(J_constraint, 'file', [BUILD_OPT_PATH ,'\J_hCont_', domainName], 'vars', {vars});



%% Other Constraints

% swing foot clearance > 0
constraint = p4L(2);
vars = q.';
J_constraint = jacobian(constraint,vars);
matlabFunction(constraint, 'file', [BUILD_OPT_PATH ,'\f_footClearance_', domainName], 'vars', {vars});
matlabFunction(J_constraint, 'file', [BUILD_OPT_PATH ,'\J_footClearance_', domainName], 'vars', {vars});

% vertical ground reaction force > 0
constraint = F(2);
vars = [F].';
J_constraint = jacobian(constraint,vars);
matlabFunction(constraint, 'file', [BUILD_OPT_PATH ,'\f_GRF_', domainName], 'vars', {vars});
matlabFunction(J_constraint, 'file', [BUILD_OPT_PATH ,'\J_GRF_', domainName], 'vars', {vars});

% knee angles 
constraint = [-q(4) + q(5); -q(6) + q(7)];
vars = [q].';
J_constraint = jacobian(constraint,vars);
matlabFunction(constraint, 'file', [BUILD_OPT_PATH ,'\f_kneeAngles_', domainName], 'vars', {vars});
matlabFunction(J_constraint, 'file', [BUILD_OPT_PATH ,'\J_kneeAngles_', domainName], 'vars', {vars});

% step length
constraint = p4L(1);
vars = [q].';
J_constraint = jacobian(constraint,vars);
matlabFunction(constraint, 'file', [BUILD_OPT_PATH ,'\f_steplength_', domainName], 'vars', {vars});
matlabFunction(J_constraint, 'file', [BUILD_OPT_PATH ,'\J_steplength_', domainName], 'vars', {vars});

% speed constraint
constraint = p4L(1)/T;
vars = [T;q].';
J_constraint = jacobian(constraint,vars);
matlabFunction(constraint, 'file', [BUILD_OPT_PATH ,'\f_speed_', domainName], 'vars', {vars});
matlabFunction(J_constraint, 'file', [BUILD_OPT_PATH ,'\J_speed_', domainName], 'vars', {vars});

% Friction constraint < 0.7
constraint = abs(F(1))/F(2);
vars = [F].';
J_constraint = jacobian(constraint,vars);
matlabFunction(constraint, 'file', [BUILD_OPT_PATH ,'\f_friction_', domainName], 'vars', {vars});
matlabFunction(J_constraint, 'file', [BUILD_OPT_PATH ,'\J_friction_', domainName], 'vars', {vars});

% Swing Leg Retraction
constraint = (dq(6) + dq(7))/2;
vars = [dq].';
J_constraint = jacobian(constraint,vars);
matlabFunction(constraint, 'file', [BUILD_OPT_PATH ,'\f_swingLegRetraction_', domainName], 'vars', {vars});
matlabFunction(J_constraint, 'file', [BUILD_OPT_PATH ,'\J_swingLegRetraction_', domainName], 'vars', {vars});

% adding torso angle
constraint=q(3);
vars=[q].';
J_constraint=jacobian(constraint,vars);
matlabFunction(constraint, 'file', [BUILD_OPT_PATH ,'\f_torso_', domainName], 'vars', {vars});
matlabFunction(J_constraint, 'file', [BUILD_OPT_PATH ,'\J_torso_', domainName], 'vars', {vars});

% Constrain to externally provided state
selected = sym('s',[2*DOF,1]);
constraint = selected.*(x1-x2);
vars = [x1].';
extra = [selected; x2].';
J_constraint = jacobian(constraint,vars);

matlabFunction(constraint, 'file', [BUILD_OPT_PATH ,'\f_xConstrainExternal_', domainName], 'vars', {vars,extra});
matlabFunction(J_constraint, 'file', [BUILD_OPT_PATH ,'\J_xConstrainExternal_', domainName], 'vars', {vars,extra});

%% Cost Functions

% torque
cost = norm(u);
vars = [u].';
J_cost = jacobian(cost, vars);
matlabFunction(cost, 'file', [BUILD_OPT_PATH ,'\f_torqueCost_', domainName], 'vars', {vars});
matlabFunction(J_cost, 'file', [BUILD_OPT_PATH ,'\J_torqueCost_', domainName], 'vars', {vars});

% torque per step
stepLength = abs(p4L(1));
cost = norm(u) / stepLength;
vars = [q;u].';
J_cost = jacobian(cost, vars);
matlabFunction(cost, 'file', [BUILD_OPT_PATH ,'\f_torquePerSteplengthCost_', domainName], 'vars', {vars});
matlabFunction(J_cost, 'file', [BUILD_OPT_PATH ,'\J_torquePerSteplengthCost_', domainName], 'vars', {vars});

% torque per steptime
stepLength = abs(p4L(1));
cost = norm(u) / T;
vars = [T;u].';
J_cost = jacobian(cost, vars);
matlabFunction(cost, 'file', [BUILD_OPT_PATH ,'\f_torquePerSteptimeCost_', domainName], 'vars', {vars});
matlabFunction(J_cost, 'file', [BUILD_OPT_PATH ,'\J_torquePerSteptimeCost_', domainName], 'vars', {vars});

% parameters constraint
syms coeff real
cost = coeff*norm(alpha);
vars = [alpha].';
extra = coeff.';
J_cost = jacobian(cost,vars);
matlabFunction(cost,'file',[BUILD_OPT_PATH ,'\f_bezierCost_',domainName], 'vars', {vars,extra});
matlabFunction(cost,'file',[BUILD_OPT_PATH ,'\J_bezierCost_',domainName], 'vars', {vars,extra});

