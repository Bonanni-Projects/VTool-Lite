function PlotSignalsFromArray(obj,names,varargin)

% PLOTSIGNALSFROMARRAY - Plot one or more grouped signals from an array.
% PlotSignalsFromArray(DATA,names)
% PlotSignalsFromArray(SIGNALS,names)
% PlotSignalsFromArray(DATA,names,    <Option1>,<Value>,<Option2>,<Value>,...)
% PlotSignalsFromArray(SIGNALS,names, <Option1>,<Value>,<Option2>,<Value>,...)
% PlotSignalsFromArray(Data,names, ...)
% PlotSignalsFromArray(Signals,names, ...)
%
% Plots a mixed set of named signals as a grouping within subplots, 
% each subplot containing the given signal set drawn from successive 
% elements of a dataset or signal group array. The first input 
% ('DATA' or 'SIGNALS') specifies the input array, and the second 
% input ('names') specifies the list of signals to appear within 
% each subplot. Additional figures are opened as needed to accommodate 
% the full number of array elements. (Note that a length-1 array, 
% i.e., a scalar dataset 'Data' or scalar signal group 'Signals', 
% is also permissible.) 
%
% The signals within successive subplots are annotated using either 
% "source" strings from the dataset array, if present, or a generated 
% numerical sequence (e.g., '001','002', ...). If the input array 
% is multidimensional, the indexing into the array is ordered in 
% columnwise fashion. 
%
% Additional control over the plotting, including number of rows 
% per figure window, specification of power spectral density or 
% coherence plots, etc., can be realized by providing any of the 
% option/value pairs defined in function "PlotSignalGroup". Note 
% that if a 'Legend' option is specified, the specified legend 
% strings will be understood to apply to the elements of the 
% 'names' list. 
%
% See also "PlotSignalsInDataset". 
%
% P.G. Bonanni
% 7/18/24

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% Return immediately if 'obj' is empty or devoid of signals
if isempty(obj) || GetNumSignals(obj(1))==0
  fprintf('Nothing to plot!\n');
end

% Check 'names' list
if ~iscellstr(names)
  error('The ''names'' list is invalid.')
elseif isempty(names)
  error('The ''names'' list is empty.')
elseif any(cellfun(@isempty,regexp(names(:),'^[A-Za-z]\w*$')))
  error('One or more specified names is invalid.')
end

% If dataset array provided, Time groups must match
if IsDatasetArray(obj)
  C = {obj.Time};
  if ~isscalar(C) && ~isequal(C{:})
    error('Time groups within the dataset array must match.')
  end
end

% Collect all instances of the named signals within cells of a cell array
[C_Signals,C_IDs] = cellfun(@(x)GroupSignalFromArray(x,obj),names(:),'Uniform',false);

% Check for success
if any(cellfun(@isempty,C_IDs))
  error('One or more signal names was not found.')
end

% Consolidate the collected results
SIGNALS = cat(1, C_Signals{:});  % each signal group represents a single 'name' entry
IDs = C_IDs{1};                  % 'IDs' are same for each call

% Ensure 'IDs' are devoid of spaces and special characters
IDs = regexprep(IDs,'\s+',          '_');  % replace space characters by '_'
IDs = regexprep(IDs,'[^a-zA-Z_0-9]','_');  % replace special characters by '_'

% Collect and consolidate 'Units' strings
C = arrayfun(@(x)x.Units,SIGNALS,'Uniform',false);  C=cat(2,C{:});
Units = num2cell(C,2);  % initialize as a cell array of cells
for k = 1:length(Units)
  % --- Remove repeats, and string the remaining entries together
  Units{k} = unique(Units{k},'stable');
  if length(Units{k}) > 1
    C1 = strcat('~',Units{k}(2:end));
    C2 = [Units{k}{1}; C1(:)];
    Units{k} = {strcat(C2{:})};
  end
  % --- Extract result from cell
  Units{k} = Units{k}{1};
end

% Define generic name layers
layers = arrayfun(@(x)sprintf('Layer%dNames',x),1:numel(names),'Uniform',false);

% Replace name layers in 'SIGNALS', making use of 'IDs' for additional annotation
NAMES = repmat(names(:)',numel(obj),1);  % matrix with uniform columns corresponding to name entries
for k = 1:size(NAMES,2)                  % append 'IDs' to provide annotation for original source
  NAMES(:,k) = strcat(NAMES(:,k),'_',IDs);
end
SIGNALS = rmfield(SIGNALS,GetLayers(SIGNALS(1)));
for k = 1:length(layers)
  layer = layers{k};
  [SIGNALS.(layer)] = deal(NAMES(:,k));
end
fields = [layers,'Values','Units','Descriptions'];
SIGNALS = orderfields(SIGNALS,fields);

% Assign 'Units' and 'Descriptions'
[SIGNALS.Units]        = deal(Units);
[SIGNALS.Descriptions] = deal(repmat({''},size(Units)));

% Build 'TIMES' array
if IsDatasetArray(obj)
  TIMES = repmat(obj(1).Time,size(SIGNALS));
else
  % Build generic time array as in "PlotSignalGroup" (with initial value 0)
  fun = @(x)BuildTimeGroup(x,'Index',1,'','Time vector');
  TIMES = arrayfun(fun,SIGNALS);
end

% Set a tag string with current timestamp
tag = sprintf('PlotSignalsFromArray: %s', datestr(now));

% Plot the signal group array, passing all options
PlotSignalGroup(TIMES,SIGNALS,varargin{:},'tag',tag)
