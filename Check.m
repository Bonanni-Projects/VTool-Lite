function Check(obj)

% CHECK - Identify input type and check for validity.
% Check(obj)
%
% Identifies the VTool object supplied as input, and 
% checks it for validity.  Recognized types are: 
%    - datasets
%    - dataset arrays
%    - signal groups
%    - signal group arrays
%
% Also calls "CheckNames" to check for repeated name 
% instances.  See function help for more information. 
%
% See also "CheckNames", "IsDataset", "IsSignalGroup". 
%
% P.G. Bonanni
% 9/24/18

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% Identify input type, and check validity
if IsDataset(obj)
  IsDataset(obj)
elseif IsSignalGroup(obj)
  IsSignalGroup(obj)
elseif IsDatasetArray(obj)
  IsDatasetArray(obj)
elseif IsSignalGroupArray(obj)
  IsSignalGroupArray(obj)
else
  vsize = size(obj);
  vclass = class(obj);
  str = sprintf('%d',vsize(1));
  str = [str, sprintf('x%d',vsize(2:end))];
  str = [str, sprintf(' %s',vclass)];
  fprintf('Input is a ''%s'' and not a recognized VTool object.\n',str)
  return
end

fprintf('\n');
fprintf('Checking for repeated names:\n');
CheckNames(obj)
