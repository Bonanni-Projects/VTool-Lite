function HighlightRegions(Xranges,color,varargin)

% HIGHLIGHTREGIONS - Highlight x regions on time or frequency plots.
% HighlightRegions(Xranges,color [,'only'] ['time' | 'freq'])
%
% Highlights regions between a specified set of x values on 
% all time or frequency plots produced by a given call to 
% "PlotSignalGroup" or its calling functions. Matrix 'Xranges' 
% is Nx2, with each row giving the left and right boundaries of 
% a time or frequency region to be highlighted.  Parameter 'color' 
% is either a string value ('r', 'g', 'b', ...), or a scalar index 
% into the current colormap, or a 1x3 vector defining the desired 
% color. If 'only' is specified, the axis background color is 
% removed before the regions are highlighted. 
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
  option = '';
elseif length(args) == 1
  option = args{1};
elseif length(args) >= 2  && isempty(axtype)
  error('Only ''time'' or ''freq'' are valid axis-type options.')
else  % specified axtype preceded by extra arguments
  error('Too many input arguments, or unrecognized option(s).')
end
if isempty(axtype)
  axtype = 'time';
end
if ~isempty(option) && ~(ischar(option) && strcmp(option,'only'))
  error('Invalid option.')
end

% Set 'tag' value
if strncmpi(axtype,'time',4)
  tag = 'Timeseries';
elseif strncmpi(axtype,'freq',4)
  tag = 'Spectrum';
end

% Check format
if size(Xranges,2) ~= 2
  error('Input ''Xranges'' must be N x 2.');
end

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

  if strcmp(option,'only')
    % Erase axis background color
    set(ax,'color',get(gcf,'color'))
  end

  % Get x- and y-axis limits
  x = get(ax,'XLim');
  y = get(ax,'YLim');
  xlo = min(x);
  xhi = max(x);
  ylo = min(y);
  yhi = max(y);

  % Loop over regions
  for k = 1:size(Xranges,1)

    % Region boundaries
    t1 = min(Xranges(k,:));
    t2 = max(Xranges(k,:));

    % Define and plot a rectangular patch
    xvec = [t1,t2,t2,t1];
    yvec = [ylo,ylo,yhi,yhi];
    patch(ax,xvec,yvec,color,'linestyle','none')

    % Move patch to rear of other plot objects
    set(ax,'children',circshift(get(ax,'children'),-1))
  end

  % Move axis box to top layer, to correct 
  % for overlay of patch on axis box
  set(ax,'Layer','top')

  % Restore axis limits
  set(ax,'XLim',[xlo,xhi],'YLim',[ylo,yhi])
end
