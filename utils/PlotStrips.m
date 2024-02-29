function PlotStrips(SIGNALS,Ts,layer)

% PLOTSTRIPS - Plot signals in strip chart format.
% PlotStrips(Signals,Ts [,layer])
% PlotStrips(SIGNALS,Ts [,layer])
%
% Plots signals in the provided signal group or signal group array 
% in "strip chart" form within the current axes.  If an array is 
% provided, plot lines for successive signal groups are overlaid 
% on lines from the first group. Input 'Ts' specifies the sample 
% time, which must be uniform. Input 'layer' specifies the name 
% layer from which to draw names for labeling the lines; if not 
% provided, the names are obtained using "GetDefaultNames". 
%
% P.G. Bonanni
% 7/26/22

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


if nargin < 3
  layer = '';
end

% Check first input
[flag,valid,errmsg] = IsSignalGroupArray(SIGNALS);
if ~flag
  error('Input is not a signal group or signal group array: %s',errmsg)
elseif ~valid
  error('Input is not a valid signal group or signal group array: %s  See "IsSignalGroup" or "IsSignalGroupArray".',errmsg)
end

% Check other inputs
if ~isnumeric(Ts) || ~isscalar(Ts)
  error('Input ''Ts'' is not valid.')
elseif Ts <= 0
  error('Sample time ''Ts'' must be positive.')
elseif ~ischar(layer)
  error('Input ''layer'' is not valid.')
end

% Generate 'names' list
if isempty(layer)
  names = GetDefaultNames(SIGNALS);
else
  names = GetNames(SIGNALS(1),layer);
end

% Ensure common signal length
if numel(SIGNALS) > 1
  SIGNALS = PadSignalsToLength(SIGNALS,nan);
end

% Get signal length
N = GetDataLength(SIGNALS(1));

% Plot signals as strips
strips(SIGNALS(1).Values(:),N*Ts,1/Ts)
hold on
for k = 2:numel(SIGNALS)
  strips(SIGNALS(k).Values(:),N*Ts,1/Ts)
end
hold off
names1 = strrep(names,'_','\_');
set(gca,'YTickLabel',flipud(names1))
