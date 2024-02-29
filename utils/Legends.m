function Legends(option)

% Legends - Apply a legend option to all docked figures.
% Legends hide
% Legends show
% Legends off
% Legends(option)
%
% Sets the specified legend option ('hide','show','off', 
% 'boxon','boxoff',...) for axes in all docked figures. 
%
% P.G. Bonanni
% 11/14/20

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% Get handles to docked figures
hfig = get(0,'Children');
C = get(hfig,'WindowStyle');
mask = strcmp(C,'docked');
hfig = hfig(mask);

% Loop over figures
for k = 1:length(hfig)

  % Get handles to axes
  hax = get(hfig(k),'Children');
  mask = strcmp(get(hax,'Type'),'axes');
  hax = hax(mask);

  % Loop over axes
  for j = 1:length(hax)
    legend(hax(j),option)
  end
end
