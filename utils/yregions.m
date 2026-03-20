function yregions(varargin)

% YREGIONS - Highlight regions between lines of constant y.
% yregions(x,y,color [,'only'])
% yregions(y,color [,'only'])
%
% Highlights regions between a specified set of ordinate values 
% on the current plot.  Matrix 'y' is Nx2, with each row giving 
% the lower and upper boundaries of a region to be highlighted.  
% Left and right limits for the regions are determined by the 
% extrema of vector 'x'.  If not supplied, these extrema are 
% determined by the axis limits of the current plot.  Parameter 
% 'color' is either a string value ('r', 'g', 'b', ...), or a 
% scalar index into the current colormap, or a 1x3 vector 
% defining the desired color.  If 'only' is specified, the 
% axis background color is removed before the regions are 
% highlighted. 
%
% P.G. Bonanni
% 4/23/05

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% Default values
x0 = get(gca,'Xlim');
onlyflag = 0;

% If last argument is 'only' ...
if strcmp(varargin{end},'only')
  onlyflag = 1;        % flag to erase axis background
  varargin(end) = [];  % pop last argument from list
end

if length(varargin)==2
  x=x0; y=varargin{1}; color=varargin{2};
elseif length(varargin)==3
  x=varargin{1}; y=varargin{2}; color=varargin{3};
else
  error('Invalid usage.')
end

% Check format
if size(y,2)~=2
  error('y must be N x 2.');
end

if onlyflag
  % Erase axis background color
  set(gca,'color',get(gcf,'color'))
end

% Left/right limits
xlo = min(x);
xhi = max(x);

% Current axis limits
ax = axis;

% Loop over regions
for k = 1:size(y,1)

  % Region boundaries
  ylo = min(y(k,:));
  yhi = max(y(k,:));

  % Define and plot a rectangular patch
  xvec = [xlo,xhi,xhi,xlo];
  yvec = [ylo,ylo,yhi,yhi];
  patch(xvec,yvec,color,'linestyle','none')

  % Move patch to rear of other plot objects
  set(gca,'children',circshift(get(gca,'children'),-1))
end

% Move axis box to top layer, to correct 
% for overlay of patch on axis box
set(gca,'Layer','top')

% Restore axis limits
axis(ax)
