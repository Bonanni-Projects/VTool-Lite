function ActivateEvents

% ACTIVATEEVENTS - Toggle event activation for Timeseries axes.
% ActivateEvents
%
% Toggles event activation for all current "Timseries" axes. 
% This includes initialization of ROI bounding lines on the 
% time axis and assignment of the button-press "callback_axes" 
% action to the axes regions.
%
% P.G. Bonanni
% 10/5/19

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% Get Timeseries handles
h = findobj('Tag','Timeseries');

% Initialize ROI bounding lines and set callback, 
% or undo same if events are already enabled
if isempty(get(h(1),'ButtonDownFcn'))
  for ax = h'
    x = xlim(ax);
    line(ax,[x(1),x(1)],ylim(ax),'Color','w','Tag','lineL');
    line(ax,[x(2),x(2)],ylim(ax),'Color','w','Tag','lineR');
    set(ax,'ButtonDownFcn',@callback_axes)
  end
  fprintf('Event activation ON.\n');
else
  hL = findobj('Tag','lineL');  delete(hL)
  hR = findobj('Tag','lineR');  delete(hR)
  set(h,'ButtonDownFcn','')
  fprintf('Event activation OFF.\n');
end
