function layer = Source2Layer(source)

% SOURCE2LAYER - Name layer corresponding to a source string.
% layer = Source2Layer(source)
%
% Produces the name layer string 'layer' corresponding to 
% the given 'source' string.  If a 'layer' string is 
% provided, it passes through unchanged. 
%
% P.G. Bonanni
% 3/31/18

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% Check for correct format
if ~ischar(source)
  error('Function is not defined for ''%s'' inputs.',class(source))
elseif isempty(regexp(source,'^[A-Za-z]\w*$','once'))
  error('Input ''%s'' is not a valid source or name layer string.',source)
end

% Append "Names" to source string
layer = source;  % initialize
if isempty(regexp(layer,'Names$','once'))
  layer = [layer,'Names']; 
end
