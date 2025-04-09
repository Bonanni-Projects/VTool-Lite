function str = describe(v)

% DESCRIBE - Size and class descriptor string.
% str = describe(v)
%
% Returns a size/class descriptor string for input 'v', in 
% the form '50x1 double', '256x128x10 uint8', '1x1 cell', 
% etc.
%
% P.G. Bonanni
% 12/12/11

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% Get size and class
vsize = size(v);
vclass = class(v);

% Check for VTool-specific types
if IsDataset(v)
  vclass = 'dataset';
elseif IsDatasetArray(v)
  vclass = 'dataset array';
elseif IsSignalGroup(v)
  vclass = 'signal group';
elseif IsSignalGroupArray(v)
  vclass = 'signal group array';
elseif IsSarray(v)
  vclass = 'S-array';
end

% Build string
str = sprintf('%d',vsize(1));
str = [str, sprintf('x%d',vsize(2:end))];
str = [str, sprintf(' %s',vclass)];
