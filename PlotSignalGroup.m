function PlotSignalGroup(varargin)

% PLOTSIGNALGROUP - Plot a signal group or signal group array.
% PlotSignalGroup(Signals)
% PlotSignalGroup(Time,Signals)
% PlotSignalGroup(TIMES,SIGNALS)
% PlotSignalGroup(TIMES,SIGNALS,<Option1>,<Value>,<Option2>,{Value>,...)
%
% Plots all or a selection of signals from signal group array 'Signals' 
% or signal group array 'SIGNALS'.  Input 'Time' (or 'TIMES') is the 
% signal group (or equal-length signal-group array) containing the 
% time signals for the array elements.  A scalar signal-group structure 
% 'Time' may be provided if the time signal is common to all array 
% elements.  If omitted entirely, signals are plotted versus a unitless 
% time index. 
%
% Like-named signals across the array are plotted as curve families within 
% subplots, in a succession of stacked figure windows, and annotations for 
% the plots are drawn from the signal-group attributes. 
%
% A subset of the contained signals, and control over the format of the 
% plots, may be specified via option/value pairs, the options including: 
%   'names'         -  a list of selected signal names, defaulting to 
%                      all signals in group if empty or not specified. 
%                      The elements of 'names' may be drawn from any 
%                      combination of available name layers. 
%   'groupname'     -  a category name for the group or array, used 
%                      for messaging to the screen only, and defaulting 
%                      to 'group' if empty or not specified. 
%   'titlestr'      -  a title string to include on all plot windows, 
%                      defaulting to the empty string if not specified. 
%   'Legend'        -  a cell array of legend strings, the array equal 
%                      in length to 'Signals', defaulting to none if 
%                      'Signals' is scalar, and {'Group 1','Group 2', ...} 
%                      if a group array. 
%   'nrows'         -  number of subplot rows per figure window, default-
%                      ing to the value defined in function "GetParam". 
%                      Ignored if 'OptionSingle' is set to 'on'. 
%   'OptionSingle'  -  'off' or 'on', with 'on' enforcing full-window 
%                      plots, but defaulting to 'off' if not specified. 
%   'OptionTime'     - 'off' or 'on', with 'on' specifying a time-series 
%                      plot for each signal (default 'on'). 
%   'OptionPSD'     -  'off' or 'on', with 'on' specifying inclusion of 
%                      a power spectral density plot for each signal 
%                      (default 'off'). 
%   'OptionPSDE'    -  'off' or 'on', with 'on' specifying inclusion of 
%                      of a power spectral density error plot for each 
%                      signal, computed with respect to the corresponding 
%                      signal in the first signal group array element 
%                      (default 'off').  Choosing this option also turns 
%                      on 'OptionPSD', and both sets of power spectra are 
%                      plotted on the same axes. 
%   'OptionCOH'     -  'off' or 'on', with 'on' specifying inclusion of 
%                      spectral coherence magnitude and phase plots, 
%                      computed with respect to corresponding signals in 
%                      the first signal-group array element (default 'off'). 
%   'OptionLabels'  -  'off' or 'on', with 'on' specifying annotation of 
%                      the complete set of signal name labels from all 
%                      name layers within the plot axes (default 'on'). 
%   'tag'           -  a string tag to record on all generated figures, 
%                      defaulting to current date-time string if not 
%                      specified. 
%
% If 'Signals' is a group array, all but the 'Values' field are assumed 
% identical across the array, including information on all name layers. 
% The length of the array determines the number of lines in each plot. 
% Time and frequency axes across all plots and generated figures are 
% separately linked, to enable synchronized zooming and panning. (Turn 
% this feature off after plotting using function "UnlinkAxes".) 
%
% P.G. Bonanni
% 2/23/18

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% Check calling syntax
args = varargin;  % initialize
mask = cellfun(@isstruct,args);  if all(~mask), error('Invalid usage.'); end
i = find(mask,1,'first');        if i~=1, error('Invalid usage.'); end
j = find(mask,1,'last');         if j>2,  error('Invalid usage.'); end

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
end

% If 'TIMES' input missing
if i==j, TIMES=[]; SIGNALS=args{1}; args(1)=[];
else TIMES=args{1}; SIGNALS=args{2}; args(1:2)=[]; end

% Return immediately if array length is zero
if isempty(SIGNALS), return, end

% Build 'TIMES' input if missing
if isempty(TIMES)
  fun = @(x)BuildTimeGroup(x,'Index',1,'','Time vector');
  TIMES = arrayfun(fun,SIGNALS);
end

% Check 'TIMES' input
if  numel(TIMES)~=1 && length(TIMES)~=length(SIGNALS)
  error('The ''TIMES'' signal group/array is invalid.')
end

% Check for matching 'SIGNALS' array elements
if numel(SIGNALS) > 1
  C = arrayfun(@GetNamesMatrix,SIGNALS,'Uniform',false);
  if ~all(isequal(C{:}))
    error('Non-homogeneous signal group array. Names do not match.')
  end
end

% Check sizes of 'TIMES' and 'SIGNALS'
if ~isscalar(TIMES) && (numel(TIMES) ~= numel(SIGNALS))
  error('Arrays ''TIMES'' and ''SIGNALS'' have incompatible sizes.')
end

% Ensure 'TIMES' and 'SIGNALS' have same shape
if numel(TIMES) == numel(SIGNALS)
  TIMES = reshape(TIMES,size(SIGNALS));
end

% Check data length, and matching of 'TIMES' against 'SIGNALS'
n1 = arrayfun(@(x)size(x.Values,1),TIMES(:));
n2 = arrayfun(@(x)size(x.Values,1),SIGNALS(:));
if any(n1 < 2 | n2 < 2)
  error('Minimum data length for plotting is 2.')
elseif ~all(n1==n2)
  error('Signal group arrays ''TIMES'' and ''SIGNALS'' are not compatible.')
end

% Check option/value pairs
OptionsList = {'names','groupname','titlestr','Legend','nrows','OptionSingle', ...
               'OptionTime','OptionPSD','OptionPSDE','OptionCOH','OptionLabels','tag'};
if rem(length(args),2) ~= 0
  error('Incomplete option/value pair(s).')
elseif any(cellfun('isclass',args(1:2:end),'char') == 0)
  error('One or more invalid options specified.')
elseif any(~ismember(args(1:2:end),OptionsList))
  error('One or more invalid options specified.')
end
Options = args(1:2:end);
if length(unique(Options)) ~= length(Options)
  fprintf('WARNING: One or more options is repeated.\n')
end

% Initialize all options to defaults
[names,groupname,nrows,OptionSingle,OptionTime,OptionPSD, ...
 OptionPSDE,OptionCOH,OptionLabels,titlestr,Legend,tag] = deal([]);

% Make option/value assignments
for k = 1:2:length(args)
  eval(sprintf('%s = args{%d};',args{k},k+1));
end

% Number of signal groups
ngroups = length(SIGNALS);

% Extend 'TIMES' to match 'SIGNALS', if necessary
if ngroups>1 && numel(TIMES)==1
  TIMES = repmat(TIMES,size(SIGNALS));
end

% Get default number of plot rows
NROWS = GetParam('DefaultNumberPlotRows');

% Default input values
if isempty(groupname),    groupname    = 'group';  end
if isempty(nrows),        nrows        = NROWS;    end
if isempty(OptionSingle), OptionSingle = 'off';    end
if isempty(OptionTime),   OptionTime   = 'on';     end
if isempty(OptionPSD),    OptionPSD    = 'off';    end
if isempty(OptionPSDE),   OptionPSDE   = 'off';    end
if isempty(OptionCOH),    OptionCOH    = 'off';    end
if isempty(OptionLabels), OptionLabels = 'on';     end
if isempty(titlestr),     titlestr     = '';       end
if isempty(Legend),       Legend       = {''};     end

% Default tag
if isempty(tag)
  fmt = 'dd-mmm-yyyy HH:MM:SS.FFF';
  tag = ['PlotSignalGroup: ',datestr(clock,fmt)];
end

% Selecting PSDE option automatically selects PSD option
if strcmp(OptionPSDE,'on'), OptionPSD='on'; end

% Default Legend for array inputs
if isempty(Legend) && ngroups > 1
  Legend = arrayfun(@int2str,1:ngroups,'Uniform',false);
  Legend = strcat({'Group '},Legend);
end

% Replace [] by '' in name layers and 'Units'
Layers = GetLayers(SIGNALS(1));
for k = 1:ngroups
  for j = 1:length(Layers)
    layer = Layers{j};
    mask = cellfun(@isempty,SIGNALS(k).(layer));
    [SIGNALS(k).(layer){mask}] = deal('');
  end
  mask = cellfun(@isempty,SIGNALS(k).Units);
  [SIGNALS(k).Units{mask}] = deal('');
end

set(0,'DefaultFigureWindowStyle','docked')

% Get sample times for all groups
[TSc,TSRANGESc] = arrayfun(@GetSampleTime,TIMES,'Uniform',false);  % 'arrayfun' does not support 'duration' type ...
TS = reshape([TSc{:}],size(TIMES));                                % ... without 'Uniform' false
TS = double(TS);
% ---
% Check sampling uniformity
X1 = cell2mat(TSc(:));
X2 = cell2mat(TSRANGESc(:));
if (strcmp(OptionPSD, 'on') || strcmp(OptionPSDE, 'on') || strcmp(OptionCOH, 'on')) && ... 
   (any(X2(:,1) <= 0) || any(diff(X2,1,2)./X1 > 0.05))
  error('Spectral analysis rejected: Sampling is non-uniform or invalid.')
end

% Initial plot 'placement' (see "addPlot" function)
placement = [0,0];  % initialize
if strcmp(OptionTime,'on'), placement(1)=placement(1)+1; end
if strcmp(OptionPSD, 'on'), placement(1)=placement(1)+1; end
if strcmp(OptionCOH, 'on'), placement(1)=placement(1)+2; end

% Select signals from the group, if specified
if ~isempty(names)
  SIGNALS = arrayfun(@(x)SelectFromGroup(names,x),SIGNALS);
end

% If valid signals remain in the group ...
if ~isempty(SIGNALS(1).Values)

  % Signal count
  nsignals = size(SIGNALS(1).Values,2);

  % Get list of default signal names for the group
  Names = GetDefaultNames(SIGNALS);

  % If PSD, PSDE, or coherence spectra required ...
  if strcmp(OptionPSD,'on') || strcmp(OptionPSDE,'on') || strcmp(OptionCOH,'on')
    % Compute PSDs, and PSDEs/cross spectra with first signal group
    fprintf('Computing PSDs and cross spectra for %s ... ',groupname);
    [PSD,PSDE,Cmag,Cang,Freqs] = computeSpectra(SIGNALS,TS);
    fprintf('done.\n');
  end

  % Loop over signals
  for k = 1:nsignals
    j = rem(k-1,nrows) + 1;

    % Set name to use for / append to figure name
    fignamek = Names{k};  % (use default name)

    % If time-series option specified ...
    if strcmp(OptionTime,'on')

      % Move to right by one "column"
      placement(2) = placement(2) + 1;

      addPlot(OptionSingle,fignamek,titlestr,tag,nrows,1,j,placement)
      plotSignal(TIMES(:),SIGNALS(:),k,'Time Series',Legend,placement(2),1.5,OptionLabels)
      if strcmp(OptionSingle,'off') && ~(j==nrows || k==nsignals), xlabel(''), end
    end

    % If 'PSD' option specified ...
    if strcmp(OptionPSD,'on')

      % Move to right by one "column"
      placement(2) = placement(2) + 1;

      % Plot PSD spectrum
      addPlot(OptionSingle,fignamek,titlestr,tag,nrows,1,j,placement)
      plotSignal(Freqs,PSD,k,'Power Spectrum',Legend,placement(2),1.5,OptionLabels)
      if strcmp(OptionSingle,'off') && ~(j==nrows || k==nsignals), xlabel(''), end
    end

    % If 'PSDE' option specified ...
    if strcmp(OptionPSDE,'on')

      % Plot PSDE spectrum on same axes as PSD
      hold on, s=get(gca); if isfield(s,'ColorOrderIndex'), set(gca,'ColorOrderIndex',1), end
      plotSignal(Freqs,PSDE,k,'Power Spectrum (with Error)',strcat(Legend,' error'),placement(2),0.5,OptionLabels)
      if strcmp(OptionSingle,'off') && ~(j==nrows || k==nsignals), xlabel(''), end
    end

    % If 'COH' option specified ...
    if strcmp(OptionCOH,'on')

      % Move to right by one "column"
      placement(2) = placement(2) + 1;

      % Plot position state coherence magnitude
      addPlot(OptionSingle,fignamek,titlestr,tag,nrows,1,j,placement)
      plotSignal(Freqs,Cmag,k,'Coherence Magnitude',Legend,placement(2),1.5,OptionLabels)
      if strcmp(OptionSingle,'off') && ~(j==nrows || k==nsignals), xlabel(''), end

      % Move to right by one "column"
      placement(2) = placement(2) + 1;

      % Plot position state coherence difference angle
      addPlot(OptionSingle,fignamek,titlestr,tag,nrows,1,j,placement)
      plotSignal(Freqs,Cang,k,'Coherence Phase',Legend,placement(2),1.5,OptionLabels)
      if strcmp(OptionSingle,'off') && ~(j==nrows || k==nsignals), xlabel(''), end
    end

    % Reset placement
    placement(2) = 0;
  end
end

% Link time axes from the current call
h = findobj('Tag','Timeseries');
if length(h) > 1
  Parents = get(h,'Parent');
  Tags = cellfun(@(x)get(x,'Tag'),Parents,'Uniform',false);
  mask = strcmp(tag,Tags);  h=h(mask);
  if length(h) > 1
    xlim = get(h,'XLim');
    xlim = cat(1,xlim{:});
    xlim = [min(xlim(:,1)),max(xlim(:,2))];
    linkaxes(h,'x')
    set(h,'XLim',xlim)
  end
end

% Link frequency axes from the current call
h = findobj('Tag','Spectrum');
if length(h) > 1
  Parents = get(h,'Parent');
  Tags = cellfun(@(x)get(x,'Tag'),Parents,'Uniform',false);
  mask = strcmp(tag,Tags);  h=h(mask);
  if length(h) > 1
    xlim = get(h,'XLim');
    xlim = cat(1,xlim{:});
    xlim = [min(xlim(:,1)),max(xlim(:,2))];
    linkaxes(h,'x')
    set(h,'XLim',xlim)
  end
end

set(0,'DefaultFigureWindowStyle','normal')



% -------------------------------------------------------------------
function addPlot(OptionSingle,figname,titlestr,tag,m,n,p,placement)

% Prepares next figure and/or subplot, with option for single-axes 
% figures and division of the plot window into "columns".  Within 
% the first column: assigns 'figname', 'titlestr' and 'tag' to 
% figure window on first call, and appends 'figname' to existing 
% figure name (with comma separation) on subplots after the first.  
%
% Input 'placement' is a 2-vector: first element specifies the 
% number of "columns" in the figure window, second element specifies 
% which column to use.  Inputs (m,n,p) are interpreted as "subplot" 
% indices within the specified column. 

if strcmp(OptionSingle,'on') || (placement(2)==1 && p==1)
  figure('Name',figname,'NumberTitle','off','Tag',tag, ...
         'DefaultLegendAutoUpdate','off')
  axes('pos',[0 0.98 1 0.02],'visible','off','Tag','suptitle');
  text(0.5,1,titlestr,'Fontsize',12,'FontWeight','bold', ...
       'Vert','top','Horiz','center','Interp','none');
end

% Compute new (m,n,p), accounting for 'placement'
[j,i] = ind2sub([n,m],p);
j = n*(placement(2)-1) + j;
n = n*placement(1);
p = (i-1) * n + j;

if strcmp(OptionSingle,'off')
  if placement(1) <= 2
    subplot(m,n,p)
  else  % if placement(1) > 2
    subtightplot(m,n,p,0.07,0.07,0.05)
  end
  if p > 1 && placement(2) == 1
    str = get(gcf,'Name');
    str = [str, ', ', figname];
    set(gcf,'Name',str)
  end
else
  subplot(1,1,1)
end



% ----------------------------------------------------------------------------------------
function plotSignal(Xsignals,Ysignals,k,strlabel,Legend,placement,thickness,OptionLabels)

% Generates a multi-line plot for the kth signal within the 'Ysignals' 
% signal groups, using data in 'Xsignals' as abcissa vectors.  Inputs 
% 'Xsignals', 'Ysignals' are arrays of signal groups.  Input 'strlabel' 
% is a plot label string, and 'Legend' is a cell array containing the 
% legend labels.  If placement==1, plots are labeled using signal names 
% instead of 'strlabel'; otherwise, the provided 'strlabel' is used.  
% Input 'thickness' specifies the line thickness.  Input 'OptionLabels' 
% ('on'/'off') specifies whether to display a list of names from all 
% name layers within the plot axes. 

% Default plot range for frequency plots
fmax = GetParam('FrequencyPlotRange');  % Hz

% Extract X and Y data vectors
Xsignals = Xsignals(:)';  % make row
Ysignals = Ysignals(:)';  % make row
X = arrayfun(@(x)x.Values,Xsignals,'Uniform',false);
Y = arrayfun(@(x)x.Values,Ysignals,'Uniform',false);
Y = cellfun(@(x)x(:,k),Y,'Uniform',false);

% Collect names for the 'Xsignals'
xnames = GetNamesMatrix(Xsignals(1));

% Determine abscissa range (and consider that 'datetime' type is possible)
C = arrayfun(@(x)x.Values(1),  Xsignals,'Uniform',false);  xi=cat(1,C{:});
C = arrayfun(@(x)x.Values(end),Xsignals,'Uniform',false);  xf=cat(1,C{:});
Xrange = [min(xi),max(xf)];

% Generate the plot
C = [X; Y];
h=plot(C{:},'LineWidth',thickness);
if strcmp(Xsignals(1).Units{1},'datenum'), datetick, end
set(gca,'XLim',Xrange)
set(gca,'XMinorTick','on','YMinorTick','on','TickDir','out')
grid on
if ~any(strcmp(Xsignals(1).Units{1},{'datenum','datetime'}))
  if ~isempty(Xsignals(1).Units{1})
    xlabel(sprintf('%s (%s)',xnames{1}, Xsignals(1).Units{1}))
  else  % if unitless
    xlabel(xnames{1})
  end
end
ylabel(Ysignals(1).Units{k})

% Modify the x-axis limit on frequency plots
if ~isempty(regexpi(Xsignals(1).Units{1},'Hz$','match'))
  set(gca,'XLim',[0,fmax])
end

% Set y-axis limits on coherence plots
if ~isempty(regexpi(Xsignals(1).Units{1},'Hz$','match')) && strcmp(Ysignals(1).Units{k},'')
  set(gca,'YLim',[0,1])
elseif ~isempty(regexpi(Xsignals(1).Units{1},'Hz$','match')) && strcmp(Ysignals(1).Units{k},'deg')
  set(gca,'YLim',[-180,180])
end

% Collect names for the 'Ysignals'
NAMES = GetNamesMatrix(Ysignals(1));
names = NAMES(k,:); names=setdiff(names,{''},'stable');  % all names, no empties
if length(names) > 2
  names1 = names(1:2);    % for title, use at most two names
  names2 = names;         % for in-plot annotation, use all names
else
  names1 = names;
  names2 = names;
end

% Set title
if placement == 1  % primary, first-column placement
  if length(names1) == 2
    title(sprintf('%s   :   %s',names1{:}),'Interp','none');
  else  % if length(names1) == 1
    title(sprintf('%s',names1{:}),'Interp','none');
  end
else  % if secondary placement
  title(sprintf('... %s',strlabel),'Interp','none');
end

% Add the legend, if any, for visible curves only
Legend = strrep(Legend,'_',' ');  % use space chars
set(h,{'DisplayName'},Legend(:))
mask = cellfun(@(x)all(isnan(x))||all(isinf(x)),Y);
set(h(mask),'HandleVisibility','off')
if any(~mask) && any(~cellfun(@isempty,Legend))
  legend('off')
  legend('show')
end

% Annotate with full set of names (if not already present)
if strcmp(OptionLabels,'on') && ~isempty(names2) && isempty(findobj(gca,'Type','text'))
  str = sprintf('%s\n',names2{:});  str(end)=[];
  text(0.02,0.95,str,'Units','normalized','Vert','top','Interp','none')
end

% Tag the axes for later linking
if isempty(regexpi(Xsignals(1).Units{1},'Hz$','match'))  % if units are not *Hz, assume timeseries
  set(gca,'Tag','Timeseries')
else  % if strcmp(Xsignals(1).Units{1},{'Hz','kHz','MHz','GHz',...})
  set(gca,'Tag','Spectrum')
end



% ---------------------------------------------------------------------
function [PSD,PSDE,Cmag,Cang,Freqs] = computeSpectra(SIGNALS,TS,fmax)

% Computes power, error, and coherence spectra.  Input 'SIGNALS' is 
% an array of signal groups, and 'TS' is a vector of corresponding 
% sample times.  Input 'fmax' specifies a maximum frequency value 
% in Hz.  Error spectra and coherences are computed for all signal 
% groups with respect to the first signal group in the sequence.  
% Outputs are all signal-group arrays, with 'PSD' giving the power 
% spectra in dB, 'PSDE' the error spectra in dB, 'Cmag'the coherence 
% magnitudes, 'Cang' the coherence difference angles, and 'Freqs' 
% the corresponding frequencies. 

% If no 'fmax' specified, don't truncate frequency axis
if nargin<3, fmax=inf; end

% Number of signal groups
ngroups = length(SIGNALS);

% Number of signals per group (same for all)
nsignals = size(SIGNALS(1).Values,2);

% Compute PSDs, and error/cross spectra with first signal group
fun = @(x,Ts)CrossSpectSignals(SIGNALS(1),TS(1),x,Ts);
[Pxy,F,~,Pyy,Perr] = arrayfun(fun,SIGNALS,TS,'Uniform',false);
Pxy  = cat(2,Pxy{:});   % array of signal groups (complex-valued)
Pyy  = cat(2,Pyy{:});   % array of signal groups (real-valued)
Perr = cat(2,Perr{:});  % array of signal groups (real-valued)

% Compute PSD magnitudes in dB
PSD = Pyy;  % initialize
fun = @(x)10*log10(abs(x));
C = cellfun(fun,{Pyy.Values},'Uniform',false);
[PSD.Values] = deal(C{:});
[PSD.Units] = deal(repmat({'dB'},nsignals,1));

% Compute PSDE magnitudes in dB
PSDE = Perr;  % initialize
fun = @(x)10*log10(abs(x));
C = cellfun(fun,{Perr.Values},'Uniform',false);
[PSDE.Values] = deal(C{:});
[PSDE.Units] = deal(repmat({'dB'},nsignals,1));

% Compute magnitudes and difference angles
Cmag = Pxy;  % initialize
Cang = Pxy;  % initialize
fun1 = @(x)abs(x);            % magnitude function
fun2 = @(x)-angle(x)*180/pi;  % diff angle function, deg
C = cellfun(fun1,{Pxy.Values},'Uniform',false);  [Cmag.Values]=deal(C{:});
C = cellfun(fun2,{Pxy.Values},'Uniform',false);  [Cang.Values]=deal(C{:});
[Cmag.Units] = deal(repmat({''},nsignals,1));
[Cang.Units] = deal(repmat({'deg'},nsignals,1));

% Identify name layers
Layers = GetLayers(SIGNALS(1));

% Form frequency vectors into an array of signal groups
Names = repmat({{'Freq'}},size(Layers));
s = cell2struct(Names,Layers,1);
Freqs = repmat(s,1,ngroups);   % initialize array with name layers
[Freqs.Values]       = deal(F{:});                  % add frequency vectors
[Freqs.Units]        = deal({'Hz'});                % add units
[Freqs.Descriptions] = deal({'Frequency vector'});  % add descriptions

% Limit frequency range to 'fmax'
for k = 1:ngroups
  mask = Freqs(k).Values <= fmax;
  Freqs(k).Values(~mask)  = [];
  PSD(k).Values( ~mask,:) = [];
  PSDE(k).Values(~mask,:) = [];
  Cmag(k).Values(~mask,:) = [];
  Cang(k).Values(~mask,:) = [];
end
