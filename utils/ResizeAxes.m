function ResizeAxes(factor,option)

% RESIZEAXES - Re-size axes after plotting.
% ResizeAxes(factor)
% ResizeAxes(factor,'time')
% ResizeAxes(factor,'freq')
%
% Re-sizes the x-axes of plots generated by "PlotSignalGroup", 
% "PlotDataset", and related functions by the specified 'factor'.  
% Optionally, specify 'time' to re-size the "Timeseries" plots 
% only, or 'freq' to re-size the "Spectrum" plots only. 
%
% P.G. Bonanni
% 2/11/21

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


if nargin < 2
  option = [];
end

% Re-size time axes
h = findobj('Tag','Timeseries');
if length(h) > 1 && (isempty(option) || strncmpi(option,'time',4))
  for k = 1:length(h)
    pos = get(h(k),'Position');
    pos(3) = pos(3)*factor;
    set(h(k),'Position',pos)
  end
end

% Re-size frequency axes
h = findobj('Tag','Spectrum');
if length(h) > 1 && (isempty(option) || strncmpi(option,'freq',4))
  for k = 1:length(h)
    pos = get(h(k),'Position');
    pos(3) = pos(3)*factor;
    set(h(k),'Position',pos)
  end
end
