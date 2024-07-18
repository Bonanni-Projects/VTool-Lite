function PlotConcatenatedArrays(varargin)

% PLOTCONCATENATEDARRAYS - Plot concatenated signal group arrays.
% PlotConcatenatedArrays(TIMES,SIGNALS)
% PlotConcatenatedArrays(TIMES,SIGNALS1,SIGNALS2,...,'NanSeparators',['on'|'off'])
% PlotConcatenatedArrays(...,<Option1>,<Value>,<Option2>,<Value>,...)
%
% Plots one or more signal group arrays after concatenation into 
% contiguous sequences.  Signal group arrays must be equal in size, 
% compatible in their data length distributions, and homogeneous 
% (see "IsSignalGroupArray".)  A 'TIMES' array is optional. Each 
% concatenated array is represented by a single color in the 
% generated plots. 
%
% The function accepts all option/value pairs defined in function 
% "PlotSignalGroup", which allow selection of signal names, and 
% additional control over plotting (e.g., legends, title strings, 
% number of rows per figure window, etc.) In addition, if provided 
% first, the following option is available: 
%   'NanSeparators' - 'on' or 'off' (default). If 'on', NaN 
%                     values are placed at the signal endpoints 
%                     before concatenation, to force spatial 
%                     separation between successive sequences, 
%                     allowing signals from individual array 
%                     elements to be distinguished. 
%
% Note: The 'NanSeparators' option should not be employed with 
% 'OptionPSD', 'OptionPSDE' or 'OptionCOH', i.e., when specifying 
% plotting of power spectral density or coherence plots. 
%
% P.G. Bonanni
% 8/28/21

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% Check calling syntax
args = varargin;  % initialize
mask = cellfun(@isstruct,args);  if all(~mask), error('Invalid usage.'); end
i = find(mask,1,'first');  if i~=1,             error('Invalid usage.'); end
j = find(mask,1,'last');   if ~all(mask(i:j)),  error('Invalid usage.'); end

% Check structure inputs
for k = i:j
  [flag,valid,errmsg] = IsSignalGroupArray(args{k});
  if ~flag
    error('Input #%d is not a signal group or signal group array: %s',k,errmsg)
  elseif ~valid
    args{k} = ReconcileUnits(args{k});  % in case of missing units, attempt to reconcile
    [~,valid] = IsSignalGroupArray(args{k});
    if ~valid
      error('Input #%d is not a valid signal group or signal group array: %s  See "IsSignalGroupArray".',k,errmsg)
    end
  end
  % Get array size
  if isempty(args{k})
    error('Empty signal group array(s) are not valid inputs.')
  end
  if k == i
    size0 = size(args{k});
  elseif ~isequal(size(args{k}),size0)
    error('The provided signal groups arrays are unequal in size.')
  end
  % Get element-wise data lengths
  nvec = arrayfun(@(x)size(x.Values,1),args{k});
  if any(nvec==0)
    error('Plotting requires all data lengths be greater than zero.')
  end
  if k == i
    nvec0 = nvec;
  elseif ~isequal(nvec,nvec0)
    error('Data lengths in the provided signal groups arrays do not match.')
  end
  % Get name layers
  if k == i
    Layers0 = GetLayers(args{k});
  elseif ~isequal(GetLayers(args{k}),Layers0)
    error('Name layers in the provided signal groups arrays do not match.')
  end
end

% Separate 'TIMES' array if present
if j > i && IsSignalGroupArray(args{i},'Time')
  TIMES = args{i};
  C_SIGNALS = args(i+1 : j);
else
  TIMES = [];
  C_SIGNALS = args(i : j);
end

% Check compatibility of 'SIGNALS1', 'SIGNALS2', ...
SIGNALS = cat(1, C_SIGNALS{:});
[~,valid,errmsg] = IsSignalGroupArray(SIGNALS);
if ~valid
  error('The provided signal group arrays are not compatible: %s".',errmsg)
end

% Build 'TIMES' input as sequenced index vectors if missing
if isempty(TIMES)
  TIMES = BuildTimeArray(C_SIGNALS{1},'Index',[1,1],'catenate','','Index vector');
end

% Remaining arguments
args(i:j) = [];
if rem(length(args),2) ~= 0
  error('Invalid option/value pairs.')
end

% Check for 'NanSeparators' option, process accordingly, and update arguments list
if ~isempty(args) && ischar(args{1}) && strcmpi(args{1},'NanSeparators')
  if ~ismember(args{2},{'on','off'})
    error('Invalid ''NanSeparators'' value: Specify ''on'' or ''off''.')
  end
  if strcmp(args{2},'on')
    for k = 1:length(C_SIGNALS)
      C_SIGNALS{k} = ApplyMask(C_SIGNALS{k},'last',nan);
    end
  end
  args(1:2) = [];
end

% Concatenate all signal group arrays
Time = ConcatSignalGroups(TIMES);
C_Signals = cellfun(@ConcatSignalGroups,C_SIGNALS,'Uniform',false);

% Set a tag string with a timestamp, and add to 'args' list
tag = sprintf('PlotConcatenatedArrays: %s', datestr(now));
args = [args,'tag',tag];

% Plot concatenated sequences
SIGNALS = cat(1,C_Signals{:});
PlotSignalGroup(Time,SIGNALS,args{:})
