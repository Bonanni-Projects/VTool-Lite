function Zoom(option)

% ZOOM - Zoom all docked figures.
% Zoom on
% Zoom off
% Zoom xon
% Zoom yon
% Zoom(option)
%
% Sets the specified zoom option ('on','off','xon','yon',...) 
% for all docked figures. 
%
% P.G. Bonanni
% 8/12/20

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% Get handles to docked figures
hfig = get(0,'Children');
C = get(hfig,'WindowStyle');
mask = strcmp(C,'docked');
hfig = hfig(mask);

% Loop over figures
for k = 1:length(hfig)
  zoom(hfig(k),option)
end
