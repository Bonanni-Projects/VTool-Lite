function PlotPsdStats(varargin)

% PLOTPSDSTATS - Plot power-spectral-density stats.
% PlotPsdStats(Stats,Info)
% PlotPsdStats(pathname)
% PlotPsdStats(..., <Option1>,<Value>,<Option2>,{Value>,...)
%
% Plots the statistically representative PSD spectra and "Error-PSD" 
% spectra from a "Stats array" and the companion 'Info' structure 
% generated using "ComputeStatsArray".  Alternatively, loads these 
% structures from the "computed_stats" file specified by 'pathname'. 
%
% The function behavior can be modified by supplying option/value 
% pairs.  The following options are available: 
%   'PlotMode'    -  'normal' (default) or 'single'.  In the 'normal' 
%                    mode, subplots are employed to group multiple 
%                    classification bins within a single figure window. 
%                    The 'single' mode specifies only one plot per 
%                    figure window. (The 'single' mode is recommended 
%                    only if the total number of plots, controlled by 
%                    'Selections' and 'BinIndex', is small). 
%   'StatNames'   -  cell array of names, of length matching that 
%                    of 'Stats', to be used for the plot legends. 
%                    If not provided, the function defaults to the 
%                    Stats(i).name strings. 
%   'Selections'  -  cell array of signal names to plot. The 
%                    default is all signals in the Stats array. 
%   'BinIndex'    -  integer vector listing the index values of 
%                    classification bin(s) to plot.  The default  
%                    is to plot all bins for all signal selections. 
%   'CasesPerBin' -  option to annotate the plots to show the 
%                    number of cases per bin.  Set to 'on' or 
%                    'off'. Default is 'on'. 
%   'UseRelPsd'   -  'on' or 'off', indicating whether to plot 
%                    normalized error spectra (i.e., "RelPsdStats") 
%                    instead of direct error spectra ("ErrPsdStats"). 
%                    Default is 'off'. 
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

% If 'Stats' has only one element
if isscalar(Stats)
  Info.ArrayName0 = '(empty)';
end

% Check for required stats fields
if ~all(isfield(Stats,{'PsdStats','ErrPsdStats','RelPsdStats'}))
  error('Required PSD stats are not present in the input.')
end

% Initialize
PlotMode    = [];
StatNames   = [];
Selections  = [];
BinIndex    = [];
CasesPerBin = [];
UseRelPsd = [];

if ~isempty(varargin)
  % Check option/value pairs
  OptionsList = {'PlotMode','StatNames','Selections','BinIndex','CasesPerBin','UseRelPsd'};
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
elseif ~(isnumeric(BinIndex) && isempty(BinIndex)) && ...
       (~isnumeric(BinIndex) || ~isvector(BinIndex) || ~all(rem(BinIndex,1)==0) || any(BinIndex <= 0))
  error('Specified ''BinIndex'' is not valid.')
elseif ~(isnumeric(CasesPerBin) && isempty(CasesPerBin)) && ...
       (~ischar(CasesPerBin) || ~ismember(CasesPerBin,{'on','off'}))
  error('Specified ''CasesPerBin'' option is not valid.')
elseif ~(isnumeric(UseRelPsd) && isempty(UseRelPsd)) && ...
       (~ischar(UseRelPsd) || ~ismember(UseRelPsd,{'on','off'}))
  error('Specified ''UseRelPsd'' option is not valid.')
end

% Extract required 'Info' fields
Selections0 = Info.Selections;
Units       = Info.PsdUnits;
Ref         = Info.Ref;

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

  % Locate the specified selections within the 'Ref' signal group
  [~,ismatched,index] = SelectFromGroup(Selections,Ref);
  if ~all(ismatched)
    error('One or more specified ''Selections'' is not present in the array.')
  end

  % Get PSD signal units
  Units = Units(index);

  % Modify the required statistics structures accordingly
  for k = 1:length(Stats)
    Stats(k).PsdStats    = structfun(@(x)x(:,index,:),Stats(k).PsdStats,   'Uniform',false);
    Stats(k).ErrPsdStats = structfun(@(x)x(:,index,:),Stats(k).ErrPsdStats,'Uniform',false);
    Stats(k).RelPsdStats = structfun(@(x)x(:,index,:),Stats(k).RelPsdStats,'Uniform',false);
  end

else
  % Use default signal list
  Names = Selections0;
end

% If 'BinIndex' specified
if ~isempty(BinIndex)

  % Check for validity
  if any(BinIndex > length(Info.BinResults2))
    error('One or more specified ''BinIndex'' exceeds the number available.')
  end

  % Modify the Info structure
  Info.BinResults2 = Info.BinResults2(BinIndex);

  % Modify the required statistics structures accordingly
  for k = 1:length(Stats)
    Stats(k).PsdStats    = structfun(@(x)x(:,:,BinIndex),Stats(k).PsdStats,   'Uniform',false);
    Stats(k).ErrPsdStats = structfun(@(x)x(:,:,BinIndex),Stats(k).ErrPsdStats,'Uniform',false);
    Stats(k).RelPsdStats = structfun(@(x)x(:,:,BinIndex),Stats(k).RelPsdStats,'Uniform',false);
  end
end

% Default 'PlotMode' if necessary
if isempty(PlotMode), PlotMode='normal'; end

% Default 'CasesPerBin' if necessary
if isempty(CasesPerBin), CasesPerBin='on'; end

% Number of signals
M = length(Names);

% Set a tag string with a timestamp
tag = sprintf('PlotLtMinMaxStats: %s', datestr(now));

% Set figure-stacking mode
set(0,'DefaultFigureWindowStyle','docked')

% Get reference name
ArrayName0 = Info.ArrayName0;

% Stats array length
nstats = length(Stats);

% If the 'ArrayName0' is present in the 'Stats' array, ensure 
% it is first.  If not present, construct a "stand-in" with 
% nan values in place of the PSD statistics. 
if any(strcmp(ArrayName0,{Stats.name}))
  % Re-sort 'Stats' to make 'ArrayName0' first (if necessary)
  i = find(strcmp(ArrayName0,{Stats.name}));
  index = [i,setdiff(1:nstats,i,'stable')];
  Stats = Stats(index);
else
  % Make the "nan" replacement as first element in the array
  Stats = [Stats(1); Stats];  % append to beginning
  Stats(1).name = ArrayName0;
  Stats(1).PsdStats    = structfun(@(x)nan(size(x)),Stats(1).PsdStats,   'Uniform',false);
  Stats(1).ErrPsdStats = structfun(@(x)nan(size(x)),Stats(1).ErrPsdStats,'Uniform',false);
  Stats(1).RelPsdStats = structfun(@(x)nan(size(x)),Stats(1).RelPsdStats,'Uniform',false);
  nstats = nstats + 1;  % increment length
end

% Loop over signals
for m = 1:M

  % Set figure name
  name = Names{m};

  % If 'normal' mode chosen ...
  if strcmp(PlotMode,'normal')

    % Plot two arrays, side by side, per page
    for j = 1:2:nstats-1
      if j+2 <= nstats  % if at least two Stats elements remain
        PlotSpectraForSignal(Stats(1),Stats(j+(1:2)),Info,CasesPerBin,UseRelPsd,name,tag,Units{m},m)
      else  % if only one remains
        PlotSpectraForSignal(Stats(1),Stats(j+ 1   ),Info,CasesPerBin,UseRelPsd,name,tag,Units{m},m)
      end
    end

  else  % if strcmp(PlotMode,'single')
    PlotSpectraForSignal1(Stats(1),Stats,Info,CasesPerBin,UseRelPsd,name,tag,Units{m},m)
  end
end

% Reset to no-stacking mode
set(0,'DefaultFigureWindowStyle','normal')



% --------------------------------------------------------------------------------------
function PlotSpectraForSignal(Stats0,Stats,Info,CasesPerBin,UseRelPsd,name,tag,units,m)

% 'NORMAL' MODE
% Plot all the spectra for signal index 'm', given a "reference" Stats 
% structure 'Stats0', and a 1 or 2-element 'Stats' array.  If the array 
% contains two elements, the spectra for the first element are plotted 
% on the left-hand side, and the spectra for the second are plotted on 
% the right.  If the array contains only a single element, only the 
% left-hand-side plots are generated.  Input 'name' is the signal 
% name, 'units' is the units string, and 'CasesPerBin' specifies 
% whether to annotate the plots with the number of cases per bin. 
% Input 'tag' is a tag string applied to all resulting figures. 

% Frequency vector
f = Stats0.f;

% Extract bin information
BinResults = Info.BinResults2;
BinTitles = {BinResults.title};
ncases = [BinResults.cases];

% If 'CasesPerBin' option not selected, change 'ncases' to all-NaN
if strcmp(CasesPerBin,'off'), ncases=nan(size(ncases)); end

% Generate title and label strings (and prevent LaTeX interpretation of '_' characters)
titleL = sprintf('%s vs %s',Stats(1).name,Stats0.name);
titleL = strrep(titleL,'_','\_');
LegendL = {Stats0.name,Stats(1).name,sprintf('error %s',Stats(1).name)};
LegendL = cellfun(@(x)strrep(x,'_','\_'),LegendL,'Uniform',false);
if length(Stats) == 2
  titleR = sprintf('%s vs %s',Stats(2).name,Stats0.name);
  titleR = strrep(titleR,'_','\_');
  LegendR = {Stats0.name,Stats(2).name,sprintf('error %s',Stats(2).name)};
  LegendR = cellfun(@(x)strrep(x,'_','\_'),LegendR,'Uniform',false);
end

% If plotting normalized error-PSDs 
if strcmp(UseRelPsd,'on')
  fieldname = 'RelPsdStats';

  % For better plot scaling, re-zero the spectra based on the initial 
  % value of the first non-NaN spectrum.  Find this normalizing value.
  p = [Stats0.PsdStats.p50(1,m,1); arrayfun(@(x)x.PsdStats.p50(1,m,1),Stats)];
  iref = find(~isnan(p),1,'first');
  if isempty(iref)
    error('All spectra are NaN!.')
  end
  p0 = p(iref);

  % Adjust legend text
  LegendL{3}=['normalized ',LegendL{3}];
  if length(Stats)==2, LegendR{3}=['normalized ',LegendR{3}]; end

else  % default case
  fieldname = 'ErrPsdStats';
  p0 = 0;
end

% Number of bins
nbins = length(BinResults);

% Axes handles
ax = [];  % initialize

% Plot four bins per page
for j = 0:4:nbins-1

  figure
  set(gcf,'Name',name,'NumberTitle','off')

  if j+1 <= nbins
    ax1=subplot(4,2,1);
    titlestr = sprintf('%s        %s', BinTitles{j+1},titleL);
    PlotMedianSpectra(f, Stats0.PsdStats, Stats(1).PsdStats, Stats(1).(fieldname), p0,ncases(j+1),units,titlestr,j+1,m)
    if j+1 < nbins, xlabel(''), end
    ax = [ax; ax1];
  end
  if j+2 <= nbins
    ax3=subplot(4,2,3);
    titlestr = sprintf('%s        %s', BinTitles{j+2},titleL);
    PlotMedianSpectra(f, Stats0.PsdStats, Stats(1).PsdStats, Stats(1).(fieldname), p0,ncases(j+2),units,titlestr,j+2,m)
    if j+2 < nbins, xlabel(''), end
    ax = [ax; ax3];
  end
  if j+3 <= nbins
    ax5=subplot(4,2,5);
    titlestr = sprintf('%s        %s', BinTitles{j+3},titleL);
    PlotMedianSpectra(f, Stats0.PsdStats, Stats(1).PsdStats, Stats(1).(fieldname), p0,ncases(j+3),units,titlestr,j+3,m)
    if j+3 < nbins, xlabel(''), end
    ax = [ax; ax5];
  end
  if j+4 <= nbins
    ax7=subplot(4,2,7);
    titlestr = sprintf('%s        %s', BinTitles{j+4},titleL);
    PlotMedianSpectra(f, Stats0.PsdStats, Stats(1).PsdStats, Stats(1).(fieldname), p0,ncases(j+4),units,titlestr,j+4,m)
    ax = [ax; ax7];
  end

  if length(Stats) == 2
    if j+1 <= nbins
      ax2=subplot(4,2,2);
      titlestr = sprintf('%s        %s', BinTitles{j+1},titleR);
      PlotMedianSpectra(f, Stats0.PsdStats, Stats(2).PsdStats, Stats(2).(fieldname), p0,ncases(j+1),units,titlestr,j+1,m)
      if j+1 < nbins, xlabel(''), end
      ax = [ax; ax2];
    end
    if j+2 <= nbins
      ax4=subplot(4,2,4);
      titlestr = sprintf('%s        %s', BinTitles{j+2},titleR);
      PlotMedianSpectra(f, Stats0.PsdStats, Stats(2).PsdStats, Stats(2).(fieldname), p0,ncases(j+2),units,titlestr,j+2,m)
      if j+2 < nbins, xlabel(''), end
      ax = [ax; ax4];
    end
    if j+3 <= nbins
      ax6=subplot(4,2,6);
      titlestr = sprintf('%s        %s', BinTitles{j+3},titleR);
      PlotMedianSpectra(f, Stats0.PsdStats, Stats(2).PsdStats, Stats(2).(fieldname), p0,ncases(j+3),units,titlestr,j+3,m)
      if j+3 < nbins, xlabel(''), end
      ax = [ax; ax6];
    end
    if j+4 <= nbins
      ax8=subplot(4,2,8);
      titlestr = sprintf('%s        %s', BinTitles{j+4},titleR);
      PlotMedianSpectra(f, Stats0.PsdStats, Stats(2).PsdStats, Stats(2).(fieldname), p0,ncases(j+4),units,titlestr,j+4,m)
      ax = [ax; ax8];
    end
  end

  % Link/re-link axes (linking here keeps subplots equal in size)
  linkaxes(ax,'xy')

  % Add legends (Note: Early Matlab versions 
  % require "[h,~] = legend(.)" syntax to 
  % force new legend with all lines visible, 
  % even with NaN data)
  h = legend(ax1,LegendL{:});
  pos = get(h,'Position');
  pos(1:2) = [0.05,0.90];
  set(h,'Position',pos)
  if length(Stats) == 2
    h = legend(ax2,LegendR{:});
    pos = get(h,'Position');
    pos(1:2) = [0.83,0.90];
    set(h,'Position',pos)
  end

  % Add title to figure window
  titlestr = sprintf('%s - PSD statistics',strrep(name,'_','\_'));
  suptitle(titlestr)

  % Tag the figure
  set(gcf,'Tag',tag)
end



% ---------------------------------------------------------------------------------------
function PlotSpectraForSignal1(Stats0,Stats,Info,CasesPerBin,UseRelPsd,name,tag,units,m)

% 'SINGLE' MODE
% Plot all the spectra for signal index 'm', given a "reference" Stats 
% structure 'Stats0', and a 'Stats' array.  Only one plot is populated 
% per figure, looping first through classification bins and then through 
% Stats array elements.  Input 'name' is the signal name, 'units' is 
% the units string, and 'CasesPerBin' specifies whether to annotate the 
% plots with the number of cases per bin. Input 'tag' is a tag string 
% applied to all resulting figures. 

% Frequency vector
f = Stats0.f;

% Extract bin information
BinResults = Info.BinResults2;
BinTitles = {BinResults.title};
ncases = [BinResults.cases];

% If 'CasesPerBin' option not selected, change 'ncases' to all-NaN
if strcmp(CasesPerBin,'off'), ncases=nan(size(ncases)); end

% If plotting normalized error-PSDs 
if strcmp(UseRelPsd,'on')
  fieldname = 'RelPsdStats';

  % For better plot scaling, re-zero the spectra based on the initial 
  % value of the first non-NaN spectrum.  Find this normalizing value.
  p = [Stats0.PsdStats.p50(1,m,1); arrayfun(@(x)x.PsdStats.p50(1,m,1),Stats)];
  iref = find(~isnan(p),1,'first');
  if isempty(iref)
    error('All spectra are NaN!.')
  end
  p0 = p(iref);

else  % default case
  fieldname = 'ErrPsdStats';
  p0 = 0;
end

% Number of bins
nbins = length(BinResults);

% Axes handles
ax = [];  % initialize

% Loop over Stats elements except reference
for k = 2:length(Stats)

  % Generate title and label strings (and prevent LaTeX interpretation of '_' characters)
  title1 = sprintf('%s vs %s',Stats(k).name,Stats0.name);
  title1 = strrep(title1,'_','\_');
  Legend = {Stats0.name,Stats(k).name,sprintf('error %s',Stats(k).name)};
  Legend = cellfun(@(x)strrep(x,'_','\_'),Legend,'Uniform',false);
  if strcmp(UseRelPsd,'on'), Legend{3}=['normalized ',Legend{3}]; end

  % Loop over classification bins
  for j = 1:nbins

    figure
    figname = sprintf('%s - %d vs %d',name,k,1);
    set(gcf,'Name',figname,'NumberTitle','off')

    ax1=subplot(1,1,1);
    titlestr = sprintf('%s        %s', BinTitles{j},title1);
    PlotMedianSpectra(f, Stats0.PsdStats, Stats(k).PsdStats, Stats(k).(fieldname), p0,ncases(j),units,titlestr,j,m)
    legend(Legend{:})
    ax = [ax; ax1];

    % Link/re-link axes
    linkaxes(ax,'xy')

    % Add title to figure window
    titlestr = sprintf('%s - PSD statistics',strrep(name,'_','\_'));
    suptitle(titlestr)

    % Tag the figure
    set(gcf,'Tag',tag)
  end
end



% -------------------------------------------------------------------------------------------
function PlotMedianSpectra(f,PsdStats1,PsdStats2,ErrPsdStats,p0,ncases,units,titlestr,bin,m)

% Plot median PSD spectra and median RelPsd spectrum for 
% specified signal 'm' and 'bin' index values. 

% Frequency range to display
fLim = GetParam('FrequencyPlotRange');

% Generate plots
plot(f,PsdStats1.p50(:,m,bin)-p0,'-', ...
     f,PsdStats2.p50(:,m,bin)-p0,'-'), hold on
set(gca,'ColorOrderIndex',2)
plot(f,ErrPsdStats.p50(:,m,bin),'-.')
hold off
set(gca,'XLim',[0,fLim])
grid on
xlabel('Frequency (Hz)')
ylabel(units)
title(titlestr)

% If displaying 'ncases'
if ~isnan(ncases)
  str = sprintf('%d cases ',ncases);
  YLim = get(gca,'YLim');
  text(fLim,mean(YLim),str,'FontSize',8,'Color',0.5*[1,1,1],'Horiz','right','Vert','bottom')
end
