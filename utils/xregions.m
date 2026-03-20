function xregions(varargin)

% XREGIONS - Highlight regions between lines of constant x.
% xregions(x,y,color [,'only'])
% xregions(x,color [,'only'])
%
% Highlights regions between a specified set of abcissa values 
% on the current plot.  Matrix 'x' is Nx2, with each row giving 
% the left and right boundaries of a region to be highlighted.  
% Upper and lower limits for the regions are determined by the 
% extrema of vector 'y'.  If not supplied, these extrema are 
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
y0 = get(gca,'Ylim');
onlyflag = 0;

% If last argument is 'only' ...
if strcmp(varargin{end},'only')
  onlyflag = 1;        % flag to erase axis background
  varargin(end) = [];  % pop last argument from list
end

if length(varargin)==2
  x=varargin{1}; y=y0; color=varargin{2};
elseif length(varargin)==3
  x=varargin{1}; y=varargin{2}; color=varargin{3};
else
  error('Invalid usage.')
end

% Check format
if size(x)==[2,1]
  x = x';  % special case: if 2x1, interpret as 1x2
end
if size(x,2)~=2
  error('x must be N x 2.');
end

if onlyflag
  % Erase axis background color
  set(gca,'color',get(gcf,'color'))
end

% Upper/lower limits
ylo = min(y);
yhi = max(y);

% Current axis limits
ax = axis;

% Loop over regions
for k = 1:size(x,1)

  % Region boundaries
  xlo = min(x(k,:));
  xhi = max(x(k,:));

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
