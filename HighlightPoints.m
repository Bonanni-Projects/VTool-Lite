function handle = HighlightPoints(x,varargin)

% HIGHLIGHTPOINTS - Highlight x values on time or frequency plots.
% HighlightPoints(x [,color] ['time' | 'freq'])
% h = HighlightPoints(...)
%
% Superimposes vertical lines on all time or frequency plots 
% at the specified 'x' points.  Optional parameter 'color' is 
% either a string value ('r', 'g', 'b', ...), or a 1x3 vector 
% defining the desired color.  Only plots produced by a given 
% call to function "PlotSignalGroup" (or its calling functions) 
% are affected. Specify 'time' for time series plots, or 'freq' 
% for frequency plots ('psd','psde','coh').  If not specified, 
% time series plots are assumed.  Returns a vector of handles 
% to the resulting plot lines if output argument 'h' is provided. 
%
% P.G. Bonanni
% 7/24/19

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


args = varargin;
if ~isempty(args) && ischar(args{end}) && ...
    any(strncmpi(args{end},{'time','freq'},4))
  axtype = args{end};
  args(end) = [];
else  % mark for default
  axtype = '';
end
if isempty(args)
  color = 'r';
elseif length(args) == 1
  color = args{1};
elseif length(args) >= 2  && isempty(axtype)
  error('Only ''time'' or ''freq'' are valid axis-type options.')
else  % specified axtype preceded by extra arguments
  error('Too many input arguments, or unrecognized option(s).')
end
if isempty(axtype)
  axtype = 'time';
end

% Set 'tag' value
if strncmpi(axtype,'time',4)
  tag = 'Timeseries';
elseif strncmpi(axtype,'freq',4)
  tag = 'Spectrum';
end

% Initialize
hvec = [];

% Make column
x = x(:);

% Get list of "current" Timeseries or Spectrum axes
axvec = findobj('Tag',tag);  % initialize
if length(axvec) > 1
  Parents = get(axvec,'Parent');
  FigTags = cellfun(@(x)get(x,'Tag'),Parents,'Uniform',false);
  mask = strcmp(FigTags,get(gcf,'Tag'));
  axvec = axvec(mask);
end

% Loop over the axes
for ax = axvec'

  % Get y-axis limits
  y = get(ax,'Ylim');
  yhi = max(y);
  ylo = min(y);

  % Set appropriate "nan" functions
  if datenum(version('-date')) > datenum('1-Jun-2014')
    if isdatetime(x), nanfunx=@NaT; else nanfunx=@NaN; end
    if isdatetime(y), nanfuny=@NaT; else nanfuny=@NaN; end
  else
    nanfunx = @NaN;
    nanfuny = @NaN;
  end

  % Plot lines 
  xvec = [                  x,                   x, nanfunx(size(x))]';  xvec=xvec(:);
  yvec = [repmat(ylo,size(x)), repmat(yhi,size(x)), nanfuny(size(x))]';  yvec=yvec(:);
  h=line(ax,xvec,yvec,'Color',color,'LineStyle','-');

  % Restore original y-axis limits
  set(ax,'YLim',[ylo,yhi])

  % Append handle
  hvec = [hvec; h];
end

% Return handle
if nargout
  handle = hvec;
end
