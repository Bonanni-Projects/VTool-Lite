function [out1,out2,out3] = CompareSignalGroups(Signals1,Signals2,varargin)

% COMPARESIGNALGROUPS - Compare two signal groups.
% CompareSignalGroups(Signals1,Signals2)
% CompareSignalGroups(Signals1,Signals2 [,'full'] [,'plot'])
% [metrics,message1,message2] = CompareSignalGroups(...)
%
% Compares two signal groups, 'Signals1' and 'Signals2'.  Reports 
% or plots differences in their 'Values' arrays by column(*).  Also 
% detects name array differences(**).  Columns with equivalent signal 
% data (i.e., "equal" or "equal with equal nans") are excluded from 
% reporting unless the 'full' option is specified. 
%
% Supported options are: 
%    'full'   -  option to include all signals in reporting 
%                rather than limiting to signals with differences.
%    'plot'    - option results in a plot of computed metrics, 
%                defined below. 
%
% The following metrics are computed and represented in either 
% screen display, returned output, or plotting.  If returned as 
% output, they are provided as fields of structure 'metrics'. 
% Letting 'x1' and 'x2' denote a pair of corresponding signals 
% from 'Signals1' and 'Signals2', respectively, the represented 
% quantities are: 
%    'index'      -  signal index
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
%    'message1'  -  summarizes the equality status for the 'Values' arrays. 
%    'message2'  -  reports if name-layer or name-array differences are detected. 
% If the 'metrics' output is supplied or the 'plot' option is chosen, screen 
% output is limited to display of 'message2' only.  However, if all output 
% arguments are provided, all screen output is suppressed. 
%
% (*)For display of name arrays and mappings to column numbers, see 
% function "Display". 
%
% (**)For comparison of signal names using a visualization tool, see 
% function "CompareNames". 
%
% See also "CompareDatasets". 
%
% P.G. Bonanni
% 9/19/18

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% Check signal-group inputs
if (IsSignalGroupArray(Signals1) && numel(Signals1) > 1) || ...
   (IsSignalGroupArray(Signals2) && numel(Signals2) > 1)
  error('Works for scalar signal groups only.')
end
[~,valid1] = IsSignalGroup(Signals1);
[~,valid2] = IsSignalGroup(Signals2);
if ~valid1
  error('Input #1 is not a valid signal group.  See "IsSignalGroup".')
elseif ~valid2
  error('Input #2 is not a valid signal group.  See "IsSignalGroup".')
end

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

% Get signal data
Values1 = Signals1.Values;
Values2 = Signals2.Values;

% Get name arrays and name layers
[NAMES1,Layers1] = GetNamesMatrix(Signals1);
[NAMES2,Layers2] = GetNamesMatrix(Signals2);

% Check 'Values' compatibility
if size(Values1,1) ~= size(Values2,1)
  error('Signal groups have mismatched data lengths.')
elseif size(Values1,2) ~= size(Values2,2)
  error('Number of signals in the two signal groups does not match.')
end

% Signal length
npoints = size(Values1,1);

% Number of signals
nsignals = size(Values1,2);

% Initialize
special = false;

% Special cases
if npoints == 0 && nsignals == 0                              % no signals, no data
  special = true;
  metrics = InitializeMetrics(nsignals,nan,nan,nan,nan,0);
  message = 'No signals or data.';
elseif npoints == 0                                           % no data
  special = true;
  metrics = InitializeMetrics(nsignals,nan,nan,nan,nan,0);
  message = 'No signal data.';
elseif nsignals == 0                                          % no signals
  special = true;
  metrics = InitializeMetrics(nsignals,nan,nan,nan,nan,0);
  message = 'No signals.';
elseif isequal(Values1,Values2)                               % all cols equal and not empty ...
  special = true;                                             % and no NaN values
  metrics = InitializeMetrics(nsignals,0,0,0,0,0);
  message = 'All signals equal.  No nan values.';
elseif isequaln(Values1,Values2) && ...
       all(any(isnan(Values1)) | any(isnan(Values2))) && ...  % all cols equaln and not empty ...
       all(any(~isnan(Values1) & ~isnan(Values2)))            % with mix of NaN and real values
  special = true;
  metrics = InitializeMetrics(nsignals,0,0,0,0,0);
  message = 'All signals equal with equal nans.  All include real values and nans.';
elseif isequaln(Values1,Values2) && ...                       % all cols equaln and not empty ...
       all(all(isnan(Values1)) & all(isnan(Values2)))         % but with no real values
  special = true;
  metrics = InitializeMetrics(nsignals,nan,nan,nan,nan,0);
  message = 'All signals equal with equal nans.  Signals are all-nan.';
end

% For other cases ...
if ~special

  % Initialize
  metrics = InitializeMetrics(nsignals,0,0,0,0,0);
  messages = cell(nsignals,1);

  % Loop over signals
  for k = 1:nsignals

    % Get signal vectors
    x1 = Values1(:,k);
    x2 = Values2(:,k);

    % Absolute differences
    d = x2-x1;

    % Check equality status
    statusEQ  = isequal(x1,x2);
    statusEQN = isequaln(x1,x2);

    % Check for and remove NaN entries
    msg = '';  % initialize
    mask = isnan(x1) | isnan(x2);
    if any(mask)
      msg = 'One or both signals contain(s) NaN entries, and';
      if all(isnan(x1)==isnan(x2))
             msg = [msg,' locations are (x) same, ( ) different.'];
        else msg = [msg,' locations are ( ) same, (x) different.']; end
      x1(mask) = [];
      x2(mask) = [];
      d(mask)  = [];
    end

    % Error metrics
    if isempty(d)
      % Trivial case
      maxabs1    = NaN;
      maxfrac1   = NaN;
      rmsrel1    = NaN;
      maxabsrel1 = NaN;

    else
      % Reference value (for normalization)
      if ~all(x1 == 0)
        refvalue = max(abs(x1));
      elseif all(x1 == 0) && ~all(x2 == 0)
        refvalue = max(abs(x2));
      elseif all(x1 == 0) &&  all(x2 == 0)
        refvalue = 1;
      end

      % RMS difference
      rmsd = norm(x2-x1)/sqrt(length(x1));

      % Eliminate zero-error cases
      mask = x1==x2;
      x1(mask) = [];
      x2(mask) = [];
      d(mask)  = [];

      % Compute error metrics
      if ~isempty(d)
        % Compute fractional error
        p = zeros(size(x1));
        zero = (x1==0);
        p(~zero) = d(~zero)./x1(~zero);
        p( zero) = d( zero)./x2( zero);

        % Error metrics
        maxabs1    = max(abs(d));
        maxfrac1   = max(abs(p));
        rmsrel1    = rmsd/refvalue;
        maxabsrel1 = max(abs(d))/refvalue;

      else
        % Error metrics
        maxabs1    = 0;
        maxfrac1   = 0;
        rmsrel1    = 0;
        maxabsrel1 = 0;
      end
    end

    % Set status value
    if statusEQ
      status1 = 0;
    elseif statusEQN
      status1 = 1;
    else  % neither
      status1 = -1;
    end

    % Record results
    metrics.maxabs(k)    = maxabs1;
    metrics.maxfrac(k)   = maxfrac1;
    metrics.rmsrel(k)    = rmsrel1;
    metrics.maxabsrel(k) = maxabsrel1;
    metrics.status(k)    = status1;

    % Record message
    messages{k} = msg;
  end

  % Overall message
  if all(metrics.status == 0)
    message = 'All signals equal.  No nan values.';
  elseif all(metrics.status == 1)
    message = 'All signals equal with equal nans.';
  elseif all(ismember(metrics.status,[0,1]))
    message = 'All signals equal, or equal with equal nans.';
  else % if any(metrics.status == -1)
    message = 'DIFFERENT: One or more signals not equal.';
  end
end

% If plot requested ...
if strcmp(OptionPlot,'on')
  PlotMetrics(metrics)

  % Attach signal-name strings as 'UserData' for access by data tips
  [~,Names] = arrayfun(@(i)GetNames(Signals1,i),(1:nsignals)','Uniform',false);
  set(gcf,'UserData',Names)

  % Set up data cursor feature
  handle = datacursormode(gcf);
  set(handle,'Enable','on')
  set(handle,'UpdateFcn',@callback_fcn1)
end

% Reduce metrics if specified
if strcmp(OptionFull,'off')
  metrics = FilterMetrics(metrics);
end

% Print signal-specific messages to screen if no outputs requested and 
% plot mode is off.  Also exclude special cases, which have no details.
if nargout==0 && strcmp(OptionPlot,'off') && ~special

  % Revise number of signals
  nsignals1 = length(metrics.index);

  % Apply filtering to messages
  messages = messages(metrics.index);

  % Report results
  if nsignals1 == 0
    % If no signals remain after filtering
    fprintf('No differences found.  All signals equal or equal with equal nans.\n');

  else
    fprintf('\n');

    % Print header line
    if strcmp(OptionFull,'on')
      fprintf('Pointwise comparisons by signal:\n');
    else  % if strcmp(OptionFull,'off')
      fprintf('Pointwise comparisons by signal (differences only):\n');
    end

    % Report results, by signal
    for k = 1:nsignals1
      if metrics.status(k) == 0
        fprintf('%3d:   equal\n',metrics.index(k));
      elseif metrics.status(k) == 1
        fprintf('%3d:   equal with equal nans\n',metrics.index(k));
      elseif metrics.status(k) == -1
        fprintf('%3d:   DIFFERENT',metrics.index(k));
        if ~isnan(metrics.maxabs(k))
          fprintf('   [maxabs,maxfrac = %.4e, %.4e]\n', metrics.maxabs(k),metrics.maxfrac(k));
        else
          fprintf('   [maxabs,maxfrac = (empty), (empty)]\n');
        end
        if ~isempty(messages{k})
          fprintf('       %s\n',messages{k});
        end
      end
    end
  end

  fprintf('\n');
end

% Substitute one-line summary for special cases
if nargout==0 && strcmp(OptionPlot,'off') && special
  % Print summary message only
  fprintf('%s\n',message);
  fprintf('\n');
end

% Check name-layer and name-array compatibility, then 
% report results if not all output argument supplied.
if ~isequal(Layers1,Layers2)
  messageN = 'Name layers in the two signal groups do not match.';
  if nargout < 3
    fprintf('%s\n',messageN);
    fprintf('First signal group has layers:\n');
    disp(Layers1)
    fprintf('Second signal group has layers:\n');
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

% If output(s) requested ...
if nargout
  out1 = metrics;
  out2 = message;
  out3 = messageN;
end



% ------------------------------------------------------------------------------------
function metrics = InitializeMetrics(nsignals,maxabs,maxfrac,rmsrel,maxabsrel,status)

% Initialize a 'metrics' structure with  
% the specified values. 

metrics.index     = (1:nsignals)';
metrics.maxabs    = repmat(maxabs,   nsignals,1);
metrics.maxfrac   = repmat(maxfrac,  nsignals,1);
metrics.rmsrel    = repmat(rmsrel,   nsignals,1);
metrics.maxabsrel = repmat(maxabsrel,nsignals,1);
metrics.status    = repmat(status,   nsignals,1);



% ------------------------------------------------------------------------------------
function metrics = FilterMetrics(metrics)

% Reduce 'metrics' to represent only signals 
% with differences. 

mask = metrics.status == -1;
metrics.index     = metrics.index(mask);
metrics.maxabs    = metrics.maxabs(mask);
metrics.maxfrac   = metrics.maxfrac(mask);
metrics.rmsrel    = metrics.rmsrel(mask);
metrics.maxabsrel = metrics.maxabsrel(mask);
metrics.status    = metrics.status(mask);



% ------------------------------------------------------------------------------------
function PlotMetrics(metrics)

% Plot the 'metrics' computed above. 

index     = metrics.index;
maxabs    = metrics.maxabs;
maxfrac   = metrics.maxfrac;
rmsrel    = metrics.rmsrel;
maxabsrel = metrics.maxabsrel;
status    = metrics.status;

% Number of signals
nsignals = length(index);

% Filter for "equaln" points
mask = status==1;
index1 = index(mask);

% Filter for zero-error and mismatched NaNs
mask = status==-1 & (maxabs==0 | isnan(maxabs));
index2 = index(mask);


figure
set(gcf,'Pos',[744,195,566,717])

ax1=subplot(411);
bar(index,maxabs), hold on
set(gca,'ColorOrderIndex',2)
plot(index1,zeros(size(index1)),'o','MarkerSize',4)
set(gca,'ColorOrderIndex',7)
plot(index2,zeros(size(index2)),'v','MarkerSize',4)
hold off
set(gca,'XLim',[0,nsignals+1])
set(gca,'XMinorTick','on'), grid on
%xlabel('Signal Index')
title('Max Absolute Error')

ax2=subplot(412);
bar(index,maxfrac), hold on
set(gca,'ColorOrderIndex',2)
plot(index1,zeros(size(index1)),'o','MarkerSize',4)
set(gca,'ColorOrderIndex',7)
plot(index2,zeros(size(index2)),'v','MarkerSize',4)
hold off
set(gca,'XLim',[0,nsignals+1])
set(gca,'XMinorTick','on'), grid on
%xlabel('Signal Index')
title('Max Fractional Error')

ax3=subplot(413);
bar(index,rmsrel), hold on
set(gca,'ColorOrderIndex',2)
plot(index1,zeros(size(index1)),'o','MarkerSize',4)
set(gca,'ColorOrderIndex',7)
plot(index2,zeros(size(index2)),'v','MarkerSize',4)
hold off
set(gca,'XLim',[0,nsignals+1])
set(gca,'XMinorTick','on'), grid on
%xlabel('Signal Index')
title('RMS Error Relative to Max Value')

ax4=subplot(414);
bar(index,maxabsrel), hold on
set(gca,'ColorOrderIndex',2)
plot(index1,zeros(size(index1)),'o','MarkerSize',4)
set(gca,'ColorOrderIndex',7)
plot(index2,zeros(size(index2)),'v','MarkerSize',4)
hold off
set(gca,'XLim',[0,nsignals+1])
set(gca,'XMinorTick','on'), grid on
xlabel('Signal Index')
title('Max Absolute Error Relative to Max Value')

linkaxes([ax1,ax2,ax3,ax4],'x')
