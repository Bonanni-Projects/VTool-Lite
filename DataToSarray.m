function S = DataToSarray(Data,layer)

% DATATOSARRAY - Convert a dataset to S-array form.
% S = DataToSarray(Data [,layer])
%
% Constructs an S-array from a VTool dataset.  Output 'S' is a 
% structure array, with each S(i) having fields: 
%   'name'         -  signal name string
%   'data'         -  data vector
%   'dt'           -  sample time (constant or vector)
%   'unitsT'       -  time units string
%   'units'        -  signal units string
%   'description'  -  signal description string
%   'trigger'      -  start time
% Type "help formats" and see function "IsSarray" for additional 
% information on S-array format. 
%
% Optional input 'layer' specifies the name layer from which to 
% extract signal names.  If missing or empty, the default names 
% are extracted (see "GetDefaultNames"). 
%
% Note that fields 'dt', 'unitsT' and 'trigger' derive from the 
% same dataset time vector, and are thus uniform for all signals.  
% The 'dt' field is a constant for uniform sampling, and a vector 
% of length(data)-1 otherwise.  The 'trigger' field is set to a 
% numerical scalar start time value for real-valued time, or to 
% an absolute start time representation if Data.Time has absolute 
% time units. 
%
% See also "BuildDatasetFromData". 
%
% P.G. Bonanni
% 10/27/19

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


if nargin < 2
  layer = '';
end

% Check 'Data' argument
if numel(Data) > 1
  error('Works for scalar datasets only.')
end
[flag,valid] = IsDataset(Data);
if ~flag || ~valid
  error('Input ''Data'' is not a valid dataset.  See "IsDataset".')
end

% Compute sampling
if strcmp(Data.Time.Units{1},'datetime')
  dt = diff(Data.Time.Values);  dt=seconds(dt);  % sec
  unitsT = 'sec';
elseif strcmp(Data.Time.Units{1},'datenum')
  dt = diff(Data.Time.Values)*86400;  % sec
  unitsT = 'sec';
else  % if real-valued ('sec','min',..., or '')
  dt = diff(Data.Time.Values);
  unitsT = Data.Time.Units{1};
end

% Warn if sampling is not monotonic
if any(dt <= 0)
  fprintf('Warning: Sampling is not monotonic.\n')
end

% Reduce 'dt' to scalar, if possible
if (max(dt) - min(dt))/min(dt) < 1e-6
  dt = dt(1);
end

% Get start time
start = Data.Time.Values(1);

% Collect signals into a master group
Signals = CollectSignals(Data);

% Extract signal names
if ~isempty(layer)
  layer = Source2Layer(layer);
  Names = Signals.(layer);
else
  Names = GetDefaultNames(Signals);
end

% Extract data and remaining attributes
Data         = num2cell(Signals.Values,1);
Units        = Signals.Units;
Descriptions = Signals.Descriptions;

% Make S-array from signal data
S = MakeSarray('Sampling',    dt, ...
               'Data',        Data, ...
               'Names',       Names, ...
               'Units',       Units, ...
               'Descriptions',Descriptions, ...
               'timeunits',   unitsT, ...
               'start',       start);
