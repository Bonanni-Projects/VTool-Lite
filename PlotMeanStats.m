function PlotMeanStats(varargin)

% PLOTMEANSTATS - Plot mean-value stats.
% PlotMeanStats(Stats,Info)
% PlotMeanStats(pathname)
% PlotMeanStats(..., <Option1>,<Value>,<Option2>,{Value>,...)
%
% Plots mean stats from a "Stats array" and the companion 'Info' 
% structure generated using "ComputeStatsArray".  Alternatively, 
% loads these structures from the "computed_stats" file specified 
% by 'pathname'. 
%
% The function behavior can be modified by supplying option/value 
% pairs.  The following options are available: 
%   'PlotMode'    -  'normal' (default) or 'single'.  In the 'normal' 
%                    mode, plots are arranged in a 3 X 3 format 
%                    (representing 9 total signals) per figure 
%                    window. The 'single' mode specifies only 
%                    one plot per figure window. 
%   'StatNames'   -  cell array of names, of length matching that 
%                    of 'Stats', to be used for the plot legends. 
%                    If not provided, the function defaults to the 
%                    Stats(i).name strings. 
%   'Selections'  -  cell array of signal names to plot. The 
%                    default is all signals in the Stats array. 
%   'CasesPerBin' -  option to annotate the plots to show the 
%                    number of cases per bin.  Set to 'on' or 
%                    'off'. Default is 'on'. 
%   'XLabel'      -  specifies an alternative label for the x axis. 
%                    The description string associated with the 
%                    classification variable is used by default. 
%   'XTick'       -  specifies alternative locations for x-axis 
%                    gridlines. The classification bin boundaries, 
%                    i.e., 'edges', are used by default. 
%
% See also "PlotLtStats". 
%
% P.G. Bonanni
% 4/8/20

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


if nargin == 0
  error('Invalid usage.')
elseif nargin == 1
  pathname = varargin{1};
  Stats    = [];
  Info     = [];
  varargin(1) = [];
elseif nargin >= 2
  if isstruct(varargin{1})
    Stats     = varargin{1};
    Info      = varargin{2};
    pathname  = [];
    varargin(1:2) = [];
  elseif ischar(varargin{1})
    pathname  = varargin{1};
    Stats     = [];
    Info      = [];
    varargin(1) = [];
  else
    error('Invalid usage.')
  end
end

% If 'pathname' specified
if ~isempty(pathname)

  % Check 'pathname' input
  if ~ischar(pathname)
    error('Input ''pathname'' is not valid.')
  elseif ~exist(pathname,'file')
    error('Specified file ''%s'' not found.',pathname)
  end

  % Load structures from file
  load(pathname,'Stats','Info')
end

% Initialize
PlotMode    = [];
StatNames   = [];
Selections  = [];
CasesPerBin = [];
XLabel      = [];
XTick       = [];

if ~isempty(varargin)
  % Check option/value pairs
  OptionsList = {'PlotMode','StatNames','Selections','CasesPerBin','XLabel','XTick'};
  if rem(length(varargin),2) ~= 0
    error('Incomplete option/value pair(s).')
  elseif any(~cellfun('isclass',varargin(1:2:end),'char'))
    error('One or more invalid options specified.')
  elseif any(~ismember(varargin(1:2:end),OptionsList))
    error('One or more invalid options specified.')
  end
  % Get options list
  Options = varargin(1:2:end);
  if length(unique(Options)) ~= length(Options)
    fprintf('WARNING: One or more options is repeated.\n')
  end
  % Make option/value assignments
  for k = 1:2:length(varargin)
    eval(sprintf('%s = varargin{%d};',varargin{k},k+1));
  end
end

% Check option values, but allow [] throughout
if ~(isnumeric(PlotMode) && isempty(PlotMode)) && ...
   (~ischar(PlotMode) || ~ismember(PlotMode,{'normal','single'}))
  error('Specified ''PlotMode'' is not valid.')
elseif ~(isnumeric(StatNames) && isempty(StatNames)) && ...
   (~iscellstr(StatNames) || any(cellfun(@isempty,StatNames)) || numel(StatNames)~=numel(Stats))
  error('Specified ''StatNames'' is not valid.')
elseif ~(isnumeric(Selections) && isempty(Selections)) && ...
       (~iscellstr(Selections) || any(cellfun(@isempty,Selections)))
  error('Specified ''Selections'' is not valid.')
elseif ~(isnumeric(CasesPerBin) && isempty(CasesPerBin)) && ...
       (~ischar(CasesPerBin) || ~ismember(CasesPerBin,{'on','off'}))
  error('Specified ''CasesPerBin'' option is not valid.')
elseif ~(isnumeric(XLabel) && isempty(XLabel)) && ...
       ~ischar(XLabel)
  error('Specified ''XLabel'' option is not valid.')
elseif ~(isnumeric(XTick) && isempty(XTick)) && ...
       (~isnumeric(XTick) || ~isvector(XTick))
  error('Specified ''XTick'' option is not valid.')
end

% Extract required 'Info' fields
Selections0 = Info.Selections;
Ref         = Info.Ref;
edges1      = Info.edges1;
BinResults  = Info.BinResults1;
xvec        = Info.xvec;
xlabelstr   = Info.xlabelstr;

% If 'StatNames' specified
if ~isempty(StatNames)

  % Check for validity
  if ~iscellstr(StatNames) || numel(StatNames)~=numel(Stats) || any(cellfun(@isempty,StatNames))
    error('Specified ''StatNames'' is not valid, or contains one or more invalid entries.')
  end

  % Apply the names
  for k = 1:length(Stats)
    if strcmp(Stats(k).name, Info.ArrayName0)
      Info.ArrayName0 = StatNames{k};
    end
    Stats(k).name = StatNames{k};
  end
end

% If 'Selections' specified
if ~isempty(Selections)

  % Use the specified names
  Names = Selections;

  % Make the specified selections from the 'Ref' signal group
  [Ref1,ismatched,index] = SelectFromGroup(Selections,Ref);
  if ~all(ismatched)
    error('One or more specified ''Selections'' is not present in the array.')
  end

  % Modify the "LtMean" statistics structure accordingly
  for k = 1:length(Stats)
    Stats(k).LtMean = structfun(@(x)x(:,index),Stats(k).LtMean,'Uniform',false);
  end

else
  % Use the default signal list
  Names = Selections0;

  % Use original 'Ref'
  Ref1 = Ref;
end

% If 'XLabel' specified
if ~isempty(XLabel)
  xlabelstr = XLabel;
end

% If 'XTick' not specified
if isempty(XTick)
  XTick = edges1;
end

% Define legend strings
Legend = {Stats.name};
Legend = cellfun(@(x)strrep(x,'_','\_'),Legend,'Uniform',false);

% Default 'PlotMode' if necessary
if isempty(PlotMode), PlotMode='normal'; end

% Default 'CasesPerBin' if necessary
if isempty(CasesPerBin), CasesPerBin='on'; end

% Number of signals
M = length(Names);

% Compute a suitable x-axis range
XLim = interp1([-1,1],edges1([1,end]),[-1.4,1.4],'linear','extrap');

% Small value, for shifting error bars
e = (max(xvec)-min(xvec))/500;

% Set a tag string with a timestamp
tag = sprintf('PlotMeanStats: %s', datestr(now));

% Set figure-stacking mode
set(0,'DefaultFigureWindowStyle','docked')

% Generate "figure index" matrix
rows = 3;  % figure rows
cols = 3;  % figure cols
Index = reshape(1:rows*cols,cols,rows)';
Index = Index(:);

% Loop over signals
for m = 1:M

  % Choose a name to use for / append to figure name
  name = Names{m};

  % Generate subplot title and y-axis label
  units = Ref1.Units{m};
  titlestr1 = name;
  if ~isempty(units)
    ylabelstr = units;
  else  % if units not available
    ylabelstr = '';
  end

  % Rotate figure index 'j' within a rows X cols figure window
  j = rem(m-1,rows*cols) + 1;

  % In 'normal' mode only ...
  if strcmp(PlotMode,'normal')
    if j == 1
      figure  % ... add figure
      set(gcf,'Name',name,'NumberTitle','off')
    else      % ... or append 'name' to existing figure name
      str = get(gcf,'Name');
      str = [str, ', ', name];
      set(gcf,'Name',str)
    end
  end

  if strcmp(PlotMode,'normal')
    subplot(rows,cols,Index(j))
  else  % if strcmp(PlotMode,'single')
    figure, set(gcf,'Name',name,'NumberTitle','off')
  end
  C50 = arrayfun(@(x)x.LtMean.p50(:,m),Stats,'Uniform',false);
  C95 = arrayfun(@(x)x.LtMean.p95(:,m),Stats,'Uniform',false);
  C05 = arrayfun(@(x)x.LtMean.p05(:,m),Stats,'Uniform',false);
  Y   =     cat(2,C50{:});
  POS =     cat(2,C95{:}) - Y;
  NEG = Y - cat(2,C05{:});
  for k = 1:size(Y,2)
    errorbar(xvec+(k-1)*e, Y(:,k),NEG(:,k),POS(:,k))
    if k==1, hold on, end
  end
  hold off
  if strcmp(CasesPerBin,'on')
    xx=xvec;  yy=max(Y + 1.1*POS,[],2);
    labels = cellfun(@(x)sprintf('%d',x),{BinResults.cases},'Uniform',false);
    text(xx,yy,labels,'FontSize',8, 'Color',0.5*[1,1,1], 'Horiz','center','Vert','bottom')
  end
  set(gca,'XTick',XTick)
  set(gca,'XLim',XLim)
  grid on
  if rem(j,rows)==0 || m == M || strcmp(PlotMode,'single'), xlabel(xlabelstr,'Interp','none'), end
  ylabel(ylabelstr,'Interp','none')
  if strcmp(PlotMode,'single')
    legend(Legend{:})   % add legend
    set(gcf,'Tag',tag)  % tag the figure
  end
  title(titlestr1,'Interp','none')

  % If window is complete ('normal' mode only)
  if (j == rows*cols || m == M) && strcmp(PlotMode,'normal')
    linkaxes(findobj(gcf,'Type','axes'),'x')

    % Add legend at top right
    addLegend(Legend)

    % Add title to figure window
    titlestr = 'Mean statistics';
    suptitle(titlestr)

    % Tag the figure
    set(gcf,'Tag',tag)
  end

end

% Reset to no-stacking mode
set(0,'DefaultFigureWindowStyle','normal')



% -----------------------------------------------
function addLegend(Legend)

% Add legend at top right (Note: Early Matlab 
% versions require "[h,~] = legend(.)" syntax 
% to force new legend with all three lines 
% visible, even with NaN data)
h = legend(Legend{:});
pos = get(h,'Position');
pos(1:2) = [0.87,0.90];
set(h,'Position',pos)
