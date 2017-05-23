function [Y,Xf,Af] = neuralnetwork_3(X,~,~)
%NEURALNETWORK_3 neural network simulation function.
%
% Generated by Neural Network Toolbox function genFunction, 23-May-2017 13:44:20.
% 
% [Y] = neuralnetwork_3(X,~,~) takes these arguments:
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
b1 = [2.7434302022495025;-2.2017815489936616;-2.6747525894955433;3.3493303301717616;-2.2103203706361829;-5.6373709366629425];
IW1_1 = [-3.2501258350451643;3.360533661397513;9.3116456224221604;11.944454534587436;-3.5073368096406665;-6.3418821908385379];

% Layer 2
b2 = [-0.67211121427037401;1.2768248468640533;2.2306439593957648;1.2082666066265391;1.2977215609699471;-0.83471719506024089];
LW2_1 = [-1.366861697465837 -1.7066235519977861 -0.44949978849408256 0.27587578469718882 -1.2917625584173513 0.59778702105294113;-1.1935532599044785 -0.15018682690376983 0.24152592765837869 -0.14747073230807009 0.43900706528433298 0.45050933206514088;-5.5440398246257283 -4.3482098884400679 0.55523999099540822 -0.2665510759607565 -1.2346874279821318 1.7841936177122519;-1.1671412003673218 0.092481968391823099 -0.65963386756709763 0.36583406145604414 0.025334845540064065 0.64831243464445765;-0.13544415783071287 0.99340841744254338 0.00083026368145949552 -0.059302643542682741 0.36182604558856102 0.775465384755058;-0.45787179624907681 -1.8225948408432291 0.98998547865862196 -0.74130846752139712 -1.6355180552078923 0.67139185381187039];

% Output 1
y1_step1.ymin = -1;
y1_step1.gain = [93.4046454010217;33.592567864649;33.6727666976159;40.7385814243909;22.9647886480377;31.9491917649867];
y1_step1.xoffset = [0.872664615945442;0.850404937737851;0.867393231251914;0.851720721640693;0.848034934777909;0.873244574072111];

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
