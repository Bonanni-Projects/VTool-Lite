function Data = ChangeTimeUnits(Data,factor,units)

% CHANGETIMEUNITS - Change the time units in a dataset.
% Data = ChangeTimeUnits(Data,factor,units)
% DATA = ChangeTimeUnits(DATA,factor,units)
% Data = ChangeTimeUnits(Data)
% DATA = ChangeTimeUnits(DATA)
%
% Converts the time units employed in a dataset or dataset 
% array, provided the existing units are real-valued* (see 
% function "ConvertToElapsedTime" if otherwise).  Input 
% 'factor' specifies the conversion factor to apply, and 
% input string 'units' specifies the units to assign after 
% the conversion. 
%
% *If 'factor' and 'units' are not provided, time in each 
% dataset is converted to a unitless index vector starting 
% from 1.  This option does not require real-valued time 
% units. 
%
% See also "ChangeSignalUnits". 
%
% P.G. Bonanni
% 7/3/19

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


if nargin == 1
  factor = [];
  units = [];
end

% Handle dataset arrays
if isstruct(Data) && numel(Data) > 1
  fun = @(x)ChangeTimeUnits(x,factor,units);
  Data = arrayfun(fun,Data);
  return
end

% Check 'Data' argument
[flag,valid] = IsDataset(Data);
if ~flag || ~valid
  error('Input ''Data'' is not a valid dataset.  See "IsDataset".')
end

% If conversion to 'index' is specified
if isempty(factor) && isempty(units)
  n = length(Data.Time.Values);
  Data.Time.Values = (1:n)';   % index starting from 1
  Data.Time.Units = {''};      % unitless
  Data.Time.Descriptions = {'Index vector'};
  layers = GetLayers(Data);
  for k = 1:length(layers)     % signal name 'Index'
    layer = layers{k};         % ... on all layers
    Data.Time.(layer) = {'Index'};
  end
  return
end

% Check 'factor' argument
if ~isscalar(factor) || ~isnumeric(factor)
  error('Invalid ''factor'' input.')
end

% Check 'units' argument
if ~ischar(units)
  error('Invalid ''units'' input.')
end

% Reject if dataset has absolute time
if strcmp(Data.Time.Units,'datetime') || strcmp(Data.Time.Units,'datenum')
  error('Input dataset has absolute time units.  See function "ConvertToElapsedTime".')
end

% Ensure 'Time' name (e.g., when applying scaling to an 'Index' vector)
Layers = GetLayers(Data);
Names = GetNamesMatrix(Data.Time);
if ~ismember('Time',Names)
  for k = 1:length(Layers)
    layer = Layers{k};
    Data.Time.(layer) = {'Time'};
  end
end

% Perform the conversion
Data.Time.Values = factor * Data.Time.Values;
Data.Time.Units = cellstr(units);
