function units1 = PsdUnits(units)

% PSDUNITS - PSD units generator.
% units1 = PsdUnits(units)
%
% Generates the units string that applies to the output 
% of a PSD calculation, given input 'units' string. 
%
% P.G. Bonanni
% 8/17/18

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% Generate PSD units string
if isempty(units)
  units1 = 'Hz^{-1}';
elseif ~isempty(regexp(units,'^[a-z]$','once')) || length(units)==1
    units1 = sprintf('%s^2/Hz',units);
else  % if more complex
    units1 = sprintf('(%s)^2/Hz',units);
  end
end
