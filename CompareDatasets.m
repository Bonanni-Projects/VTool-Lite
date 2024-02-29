function [out1,out2,out3] = CompareDatasets(Data1,Data2,varargin)

% COMPAREDATASETS - Compare two datasets.
% CompareDatasets(Data1,Data2)
% CompareDatasets(Data1,Data2 [,'full'] [,'plot'])
% [metrics,message1,message2] = CompareDatasets(...)
%
% Compares two datasets, 'Data1' and 'Data2'.  Reports differences 
% by field and signal group, or plots differences by signal.  Also 
% detects name array differences(*).  Columns with equivalent signal 
% data (i.e., "equal" or "equal with equal nans") are excluded from 
% reporting unless the 'full' option is specified.  Absolute time 
% offsets between the datasets are ignored. 
%
% Supported options are: 
%    'full'   -  option to include all signals in reporting 
%                rather than limiting to signals with differences.
%    'plot'    - option results in a plot of computed metrics, 
%                defined below. 
%
% The following metrics are computed and represented in either 
% screen display, returned output, or plotting.  If returned as 
% output, they are provided as subfields of structure 'metrics', 
% under field names corresponding to the signal groups to which 
% the signals belong.  Letting 'x1' and 'x2' denote a pair of 
% corresponding signals from 'Data1' and 'Data2', respectively, 
% the represented quantities are: 
%    'index'      -  signal index within the signal group
%    'maxabs'     -  maximum absolute difference
%                      = max(abs(x2-x1))
%    'maxfrac'    -  maximum fractional difference
%                      = max(abs((x2-x1)./x1))
%    'rmsrel'     -  rms difference, relative to max value
%                      = rms(x2-x1)/max(abs(x1))
%    'maxabsrel'  -  maximum absolute difference, relative to max value
%                      = max(abs(x2-x1))/max(abs(x1))
%    'status'     -  a status indicator set as follows:
%                      -1  ->  not equal
%                       0  ->  equal, with no NaN values
%                       1  ->  equal, taking NaN values as equal
% These quantities are all Nx1 vectors, where N is the number of 
% signals compared (the full set of signals, if 'full' option chosen, 
% or the number of signals with differences otherwise). In computing 
% 'maxfrac', values from 'x2' are substituted for 'x1' in the denominator 
% wherever 'x1' is zero.  In computing 'rmsrel' and 'maxabsrel', 
% max(abs(x2)) is used in place of max(abs(x1)) if 'x1' is identically 
% zero.  NaN values in 'maxabs', 'maxfrac', 'rmsrel', and 'maxabsrel' 
% signify that no numerical values remain after removal of NaN entries. 
%
% Also returned as outputs are two message strings: 
%    'message1'  -  summarizes the equality status for all signal data. 
%    'message2'  -  reports if name-layer or name-array differences are detected. 
% If the 'metrics' output is supplied or the 'plot' option is chosen, screen 
% output is limited to display of 'message2' only.  However, if all output 
% arguments are provided, all screen output is suppressed. 
%
% (*)For comparison of signal names using a visualization tool, see 
% function "CompareNames". 
%
% See also "CompareSignalGroups". 
%
% P.G. Bonanni
% 9/23/18

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% Check dataset inputs
if (IsDatasetArray(Data1) && numel(Data1) > 1) || ...
   (IsDatasetArray(Data2) && numel(Data2) > 1)
  error('Works for scalar datasets only.')
end
[~,valid1] = IsDataset(Data1);
[~,valid2] = IsDataset(Data2);
if ~valid1
  error('Input #1 is not a valid dataset.  See "IsDataset".')
elseif ~valid2
  error('Input #2 is not a valid dataset.  See "IsDataset".')
end

% Convert to elapsed time
Data1 = ConvertToElapsedTime(Data1);
Data2 = ConvertToElapsedTime(Data2);

% Collect remaining options arguments
options = varargin;
if ~isempty(options)
  if ~all(cellfun(@ischar,options)) || ...
     ~all(ismember(options,{'full','plot'}))
    error('Invalid syntax or unrecognized option(s).')
  end
  if any(strcmp('full',options)), OptionFull='on'; else OptionFull='off';  end
  if any(strcmp('plot',options)), OptionPlot='on'; else OptionPlot='off';  end
else
  OptionFull='off';
  OptionPlot='off';
end

% Get field names
fields1 = fieldnames(Data1);
fields2 = fieldnames(Data2);

% Get signal-group names
[~,groups1] = GetSignalGroups(Data1);
[~,groups2] = GetSignalGroups(Data2);

% Report any field name differences, but only 
% if no outputs requested and plot mode is off.
if ~isempty(setxor(fields1,fields2)) && nargout==0 && strcmp(OptionPlot,'off')
  fprintf('Datasets do not have the same fields.\n');
  list1 = setdiff(fields1,fields2,'stable');
  list2 = setdiff(fields2,fields1,'stable');
  if ~isempty(list1)
    fprintf('  Fields in first and not in second:\n');
    disp(list1)
  end
  if ~isempty(list2)
    fprintf('  Fields in second and not in first:\n');
    disp(list2)
  end
  fprintf('\n');
end

% List of common fields
fields = intersect(fields1,fields2,'stable');

% List of common signal groups
groups = intersect(groups1,groups2,'stable');

% Check for equal number of signals in common groups
for k = 1:length(groups)
  group = groups{k};
  if size(Data1.(group).Values,2) ~= size(Data2.(group).Values,2)
    error('Mismatched number of signals detected in group ''%s''.',group)
  end
end

% Check for differences in common fields
for k = 1:length(fields)
  field = fields{k};

  % If field is not a signal group ...
  if ~IsSignalGroup(Data1.(field))
    status1 = isequal(Data1.(field),Data2.(field));
    status2 = isequaln(Data1.(field),Data2.(field));
    if status1
      metrics.(field)  = 'equal';
      messages.(field) = 'equal';
    elseif status2
      metrics.(field)  = 'equal with equal nans';
      messages.(field) = 'equal with equal nans';
    else
      metrics.(field)  = 'DIFFERENT';
      messages.(field) = 'DIFFERENT';
    end
  else  % if field is a signal group
    if strcmp(OptionFull,'on'), options={'full'}; else options={}; end
    [metrics1,message1,~] = CompareSignalGroups(Data1.(field),Data2.(field),options{:});
    metrics.(field)  = metrics1;
    messages.(field) = message1;
  end
end

% Note the unmatched fields
metrics.UNMATCHED_FIELDS = setxor(fields1,fields2,'stable')';
if isempty(metrics.UNMATCHED_FIELDS), metrics.UNMATCHED_FIELDS={}; end

% Overall message
if isequal(Data1,Data2)
  message = 'Datasets are equal.';
elseif isequaln(Data1,Data2)
  message = 'Datasets are equal with equal nans.';
elseif isequal(rmfield(Data1,setdiff(fields1,fields)),rmfield(Data2,setdiff(fields2,fields)))
  message = 'The fields common to the two datasets are equal.';
elseif isequaln(rmfield(Data1,setdiff(fields1,fields)),rmfield(Data2,setdiff(fields2,fields)))
  message = 'The fields common to the two datasets are equal with equal nans.';
elseif isequal(rmfield(Data1,setdiff(fields1,groups)),rmfield(Data2,setdiff(fields2,groups)))
  message = 'The signal groups common to the two datasets are equal.';
elseif isequaln(rmfield(Data1,setdiff(fields1,groups)),rmfield(Data2,setdiff(fields2,groups)))
  message = 'The signal groups common to the two datasets are equal with equal nans.';
else  % all other cases
  message = 'The datasets are different.';
end

% If plot requested ...
if strcmp(OptionPlot,'on')

  % Collect signals into single groups
  Signals1 = CollectSignals(Data1);
  Signals2 = CollectSignals(Data2);
  nsignals = size(Signals1.Values,2);

  % Call "CompareSignalGroups" function for plotting only
  [~,~,~] = CompareSignalGroups(Signals1,Signals2,'plot');

  % Attach signal-name strings as 'UserData' for access by data tips
  [~,Names] = arrayfun(@(i)GetNames(Signals1,i),(1:nsignals)','Uniform',false);
  set(gcf,'UserData',Names)

  % Set up data cursor feature
  handle = datacursormode(gcf);
  set(handle,'Enable','on')
  set(handle,'UpdateFcn',@callback_fcn1)
end

% Report differences if no outputs requested and plot mode is off
if nargout==0 && strcmp(OptionPlot,'off')

  if ~isempty(setxor(fields1,fields2))
    fprintf('Checking common fields:\n');
  else  % if fieldnames are equal
    fprintf('Results by field:\n');
  end

  % Loop over common fields
  for k = 1:length(fields)
    field = fields{k};
    str = ['''',field,''''];
    if ~IsSignalGroup(Data1.(field))
      fprintf('  %25s:   %s\n', str, messages.(field));
    else  % if IsSignalGroup(Data1.(field))
      fprintf('  %25s:   (SIGNAL GROUP) %s\n', str, messages.(field));
    end
  end

  fprintf('\n');
end

% Get name arrays and name layers
[NAMES1,Layers1] = GetNamesMatrix(Data1);
[NAMES2,Layers2] = GetNamesMatrix(Data2);

% Check name-layer and name-array compatibility, then 
% report results if no output argument supplied.
if ~isequal(Layers1,Layers2)
  messageN = 'Name layers in the two datasets do not match.';
  if nargout < 3
    fprintf('%s\n',messageN);
    fprintf('First dataset has layers:\n');
    disp(Layers1)
    fprintf('Second dataset has layers:\n');
    disp(Layers2)
  end
elseif isequal(NAMES1,NAMES2)  % check 'NAMES' compatibility
  messageN = 'Name arrays match.  Use function "Display" to view.';
  if nargout < 3
    fprintf('%s\n',messageN);
  end
else  % if ~isequal(NAMES1,NAMES2)
  messageN = 'Name arrays do not match.  Use function "CompareNames" to view differences.';
  if nargout < 3
    fprintf('%s\n',messageN);
  end
end

% If output requested ...
if nargout
  out1 = metrics;
  out2 = message;
  out3 = messageN;
end
