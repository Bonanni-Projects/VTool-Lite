function color = gcacolor(k)

% GCACOLOR - Select a color from axis 'colororder' list.
% color = gcacolor(k)
%
% Selects the 'k'th color from the 'colororder' list for 
% the current axis.  Uses remainder arithmetic for 'k' 
% values that exceed the length of the list. 
%
% P.G. Bonanni
% 10/21/99

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% Get color list from current axis
colors = get(gca,'ColorOrder');

% Number of colors
n = size(colors,1);

% Ensure 'k' is in range
k = mod(k-1,n)+1;

% Return selected color
color = colors(k,:);
