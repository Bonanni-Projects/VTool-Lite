function yrange = GetYrange(hvec)

% GetYrange - Get overall y-limits of included plots.
% yrange = GetYrange(hParent)
% yrange = GetYrange(hvec)
%
% Returns the global y-axis [min,max] for all plots that descend 
% from the parent handle 'hParent' or the vector of handles 'hvec'. 
%
% P.G. Bonanni
% 9/29/23

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% Find line objects under 'hvec'
hline = findobj(hvec,'Type','Line');

% Compute the y-axis range
if isscalar(hline)
  y = get(hline,'YData');
else
  C = get(hline,'YData');
  y = cat(2,C{:});
end
yrange = [min(y),max(y)];
