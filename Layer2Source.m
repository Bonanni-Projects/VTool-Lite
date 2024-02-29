function source = Layer2Source(layer)

% LAYER2SOURCE - Source string corresponding to a name layer.
% source = Layer2Source(layer)
%
% Produces the 'source' string corresponding to the given 
% name layer string 'layer'. 
%
% P.G. Bonanni
% 3/31/18

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% Check for correct format
if ~ischar(layer)
  error('Function is not defined for ''%s'' inputs.',class(layer))
elseif isempty(regexp(layer,'^[A-Za-z]\w*Names$','once'))
  error('Input ''%s'' is not a valid name layer string.',layer)
end

% Remove 'Names' from string
source = strrep(layer,'Names','');
