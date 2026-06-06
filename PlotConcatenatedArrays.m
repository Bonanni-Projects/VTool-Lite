function PlotConcatenatedArrays(varargin)

% PLOTCONCATENATEDARRAYS - Plot concatenated signal group or dataset arrays.
% PlotConcatenatedArrays(TIMES,SIGNALS)
% PlotConcatenatedArrays(DATA)
% PlotConcatenatedArrays(TIMES,SIGNALS1,SIGNALS2,...,'NanSeparators',['on'|'off'],...)
% PlotConcatenatedArrays(DATA1,DATA2,...,'NanSeparators',['on'|'off'],...)
% PlotConcatenatedArrays(...,<Option1>,<Value>,<Option2>,<Value>,...)
%
% Plots one or more signal group arrays after concatenation into 
% contiguous sequences.  Signal group arrays must be equal in size, 
% compatible in their data length distributions, and homogeneous 
% (see "IsSignalGroupArray".)  A 'TIMES' array is optional. Each 
% concatenated array is represented by a single color in the 
% generated plots. 
%
% Dataset array(s) are also accepted, provided their signal groups 
% satisfy the requirements above. Their 'Time' groups are ignored. 
% (If 'Time' is desired, use "PlotDataset(ConcatDatasets(.),...)".)
%
% The function accepts all option/value pairs defined in function 
% "PlotSignalGroup", which allow selection of signal names, and 
% additional control over plotting (e.g., legends, title strings, 
% number of rows per figure window, etc.) The following options are 
% available in addition: 
%   'NanSeparators' - 'on' or 'off' (default). If 'on', NaN 
%                     values are placed at the signal endpoints 
%                     before concatenation, to force spatial 
%                     separation between successive sequences, 
%                     allowing signals from individual array 
%                     elements to be distinguished. 
%   'CaseIndexing'  - 'on' or 'off' (default). If 'on', the arrays 
%                     are padded with NaNs to uniform length and
%                     x-axis labeling is used to indicate the index 
%                     of elements within the arrays. Any supplied 
%                     'TIMES' array is ignored in this case. 
%
% Note: The 'NanSeparators' or 'CaseIndexing' options should not be 
% employed with 'OptionPSD', 'OptionPSDE' or 'OptionCOH', i.e., when 
% specifying plotting of power spectral density or coherence plots. 
%
% P.G. Bonanni
% 8/28/21

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% Check overall calling syntax
args = varargin;  % initialize
mask = cellfun(@isstruct,args);  if all(~mask), error('Invalid usage.'); end
i = find(mask,1,'first');  if i~=1,             error('Invalid usage.'); end
j = find(mask,1,'last');   if ~all(mask(i:j)),  error('Invalid usage.'); end

% Determine if dataset array(s) provided, based on first input. 
% If so, extract signal group arrays, and proceed with same. 
if IsDatasetArray(args{1})  % Note: args{1} can still be ~valid
  for k = i:j
    [flag,valid,errmsg] = IsDatasetArray(args{k});
    if ~flag
      error('Input #%d is not a dataset or dataset array: %s',k,errmsg)
    elseif ~valid
      args{k} = ReconcileUnits(args{k});  % in case of missing units, attempt to reconcile
      [~,valid] = IsDatasetArray(args{k});
      if ~valid
        error('Input #%d is not a valid dataset or dataset array: %s  See "IsDatasetArray".',k,errmsg)
      end
    end
    args{k} = arrayfun(@CollectSignals,args{k});
  end
end

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

% Build 'TIMES' input as sequenced index vectors if missing. (Start 
% out here with indexing by "points". Modify later if 'CaseIndexing'.)
if isempty(TIMES)
  TIMES = BuildTimeArray(C_SIGNALS{1},'Index',[1,1],'catenate','','Index vector');
end

% Remaining arguments
args(i:j) = [];
if ~isempty(args)
  % ---
  if rem(length(args),2) ~= 0
    error('Invalid option/value pairs.')
  elseif ~iscellstr(args(1:2:end))
    error('Invalid option/value pairs.')
  elseif length(args(1:2:end)) ~= length(unique(args(1:2:end)))
    error('One or more options is repeated.')
  end
  % ---
  % Extract options and values
  Options = args(1:2:end);
  Values  = args(2:2:end);
  % ---
  % Check for 'CaseIndexing' option, process accordingly, and update arguments list
  [mask,i] = ismember('CaseIndexing',Options);
  if any(mask)
    if ~ischar(Values{i}) || ~ismember(Values{i},{'on','off'})
      error('Invalid ''CaseIndexing'' value: Specify ''on'' or ''off''.')
    end
    if strcmp(Values{i},'on')
      for k = 1:length(C_SIGNALS)
        C_SIGNALS{k} = PadSignalsToLength(C_SIGNALS{k},nan,'max');
      end
      len = height(C_SIGNALS{1}(1).Values);  % uniform data length
      TIMES = BuildTimeArray(C_SIGNALS{1},'Index',[1-(len-1)/(2*len), 1/len],'catenate','','Index vector');
    end
    Options(i) = [];
    Values(i)  = [];
  end
  % ---
  % Check for 'NanSeparators' option, process accordingly, and update arguments list
  [mask,i] = ismember('NanSeparators',Options);
  if any(mask)
    if ~ischar(Values{i}) || ~ismember(Values{i},{'on','off'})
      error('Invalid ''NanSeparators'' value: Specify ''on'' or ''off''.')
    end
    if strcmp(Values{i},'on')
      for k = 1:length(C_SIGNALS)
        C_SIGNALS{k} = ApplyMask(C_SIGNALS{k},'last',nan);
      end
    end
    Options(i) = [];
    Values(i)  = [];
  end
  % ---
  % Rebuild remaining arguments list
  args = reshape([Options;Values],1,[]);
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

% Force integer x-axis ticks if appropriate when indexing
if strcmp(TIMES(1).Descriptions{1},'Index vector')
  [~,~,~,hfig,hax] = GetHandles('current');
  xl = get(gca,'XLim');  % get current x-axis limits
  if floor(xl(2)) - ceil(xl(1)) <= 25
    set(hax,'XTick',ceil(xl(1)):floor(xl(2)))
    set(hax,'XMinorTick','off')
  end
  % --- Set zoom and pan callbacks
  for k = 1:length(hfig)
    z = zoom(hfig(k));
    z.ActionPostCallback = @(~,event)setIntegerTicks(event.Axes);
    p = pan(hfig(k));
    p.ActionPostCallback = @(~,event)setIntegerTicks(event.Axes);
  end
end



% ------------------------------------------------------------------------
% Callback function to set integer ticks
function setIntegerTicks(ax)

% Get x-axis limits
xl = get(ax,'XLim');

% Get handles to all axes
[~,~,~,~,hax] = GetHandles('current');

% Set integer ticks if appropriate
if floor(xl(2)) - ceil(xl(1)) <= 25
  set(hax,'XTick',ceil(xl(1)):floor(xl(2)))
  set(hax,'XMinorTick','off')
else  % to avoid crowding, e.g., when zooming back out
  set(hax,'XTickMode','auto')
  set(hax,'XMinorTick','on')
end
