function [Y,Xf,Af] = neuralnetwork_1(X,~,~)
%NEURALNETWORK_1 neural network simulation function.
%
% Generated by Neural Network Toolbox function genFunction, 23-May-2017 13:44:17.
% 
% [Y] = neuralnetwork_1(X,~,~) takes these arguments:
% 
%   X = 1xTS cell, 1 inputs over TS timesteps
%   Each X{1,ts} = 1xQ matrix, input #1 at timestep ts.
% 
% and returns:
%   Y = 1xTS cell of 1 outputs over TS timesteps.
%   Each Y{1,ts} = 6xQ matrix, output #1 at timestep ts.
% 
% where Q is number of samples (or series) and TS is the number of timesteps.

%#ok<*RPMT0>

% ===== NEURAL NETWORK CONSTANTS =====

% Input 1
x1_step1.xoffset = -1.59218685178728;
x1_step1.gain = 0.622524189943261;
x1_step1.ymin = -1;

% Layer 1
b1 = [-9.5994359266433786;-2.2380493816844167;-17.195744581068482;-2.346733783233367;5.1427479486075898;5.2666872619071112];
IW1_1 = [10.587657020053832;1.8468417995043909;51.264787072295036;-0.42326634794505918;5.8410416008275874;5.97667096196807];

% Layer 2
b2 = [105.75900510455989;93.07358621397141;100.85246749481867;169.49680757155755;71.791294252571362;16.089750393224399];
LW2_1 = [-0.29926666834267229 1.7681292315758657 -0.14847546069201223 107.51964512574956 22.864949830261661 -21.88457093007279;-0.18910718079413838 1.094268446344171 -0.11793151688277094 94.910488150105778 18.979808265730799 -18.193918499980132;-0.38843353780506851 1.858289398132277 -0.14053990142423761 102.42413782913441 25.032557727900731 -24.135604186991529;-2.4969311239675194 11.557779410302755 -0.43915500397273377 166.71524854235747 96.135914113302789 -93.708348989488897;-1.9640891097213073 9.2683595428465324 -0.35504312423784784 68.145386320042221 61.648202921706847 -60.205854366826017;-1.2165369380990616 6.0771372637202061 -0.24789914726762605 12.802269143660016 35.196005895344321 -34.43912841180601];

% Output 1
y1_step1.ymin = -1;
y1_step1.gain = [13.0672124275017;9.6959555591072;10.5271523146009;22.6550001369906;16.4627327705887;9.82117267845499];
y1_step1.xoffset = [-0.0441061960949636;-0.0698645619942322;-0.0628637523956493;-0.0177333234815849;-0.011182214865988;-0.0534563698635557];

% ===== SIMULATION ========

% Format Input Arguments
isCellX = iscell(X);
if ~isCellX, X = {X}; end;

% Dimensions
TS = size(X,2); % timesteps
if ~isempty(X)
  Q = size(X{1},2); % samples/series
else
  Q = 0;
end

% Allocate Outputs
Y = cell(1,TS);

% Time loop
for ts=1:TS

    % Input 1
    Xp1 = mapminmax_apply(X{1,ts},x1_step1);
    
    % Layer 1
    a1 = tansig_apply(repmat(b1,1,Q) + IW1_1*Xp1);
    
    % Layer 2
    a2 = repmat(b2,1,Q) + LW2_1*a1;
    
    % Output 1
    Y{1,ts} = mapminmax_reverse(a2,y1_step1);
end

% Final Delay States
Xf = cell(1,0);
Af = cell(2,0);

% Format Output Arguments
if ~isCellX, Y = cell2mat(Y); end
end

% ===== MODULE FUNCTIONS ========

% Map Minimum and Maximum Input Processing Function
function y = mapminmax_apply(x,settings)
  y = bsxfun(@minus,x,settings.xoffset);
  y = bsxfun(@times,y,settings.gain);
  y = bsxfun(@plus,y,settings.ymin);
end

% Sigmoid Symmetric Transfer Function
function a = tansig_apply(n,~)
  a = 2 ./ (1 + exp(-2*n)) - 1;
end

% Map Minimum and Maximum Output Reverse-Processing Function
function x = mapminmax_reverse(y,settings)
  x = bsxfun(@minus,y,settings.ymin);
  x = bsxfun(@rdivide,x,settings.gain);
  x = bsxfun(@plus,x,settings.xoffset);
end
