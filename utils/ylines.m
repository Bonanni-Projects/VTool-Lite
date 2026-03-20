function handle = ylines(x,y,s)

% YLINES - Draw lines of constant y.
% ylines(x,y [,s])
% ylines(y [,s])
% h = ylines(...)
%
% Superimposes lines of constant ordinate value 'y' on the 
% current plot.  Vector 'y' specifies the y-values at which 
% the lines are to be drawn.  Upper and lower limits for the 
% lines are determined by the extrema of vector 'x'.  If not 
% supplied, these extrema are determined by the axis limits.  
% Optional parameter 's' specifies the line type and color.  
% Returns a handle to the resulting plot. 
%
% P.G. Bonanni
% 11/19/97
% 09/28/17, updated to handle "datetime" axes.

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% Default values
x0 = get(gca,'Xlim');
s0 = 'k-';

if nargin==2
  if ischar(y)
    s = y;
    y = x;
    x = x0;
  else
    s = s0;
  end
elseif nargin==1
  y = x;
  x = x0;
  s = s0;
end

% Fix format
y = y(:);

% Upper/lower limits
xhi = max(x);
xlo = min(x);

% Set appropriate "nan" functions
if datenum(version('-date')) > datenum('1-Jun-2014')
  if isdatetime(x), nanfunx=@NaT; else nanfunx=@NaN; end
  if isdatetime(y), nanfuny=@NaT; else nanfuny=@NaN; end
else
  nanfunx = @NaN;
  nanfuny = @NaN;
end

% Check hold state
if ~ishold, nohold=1; else nohold=0; end

% Plot lines 
xvec = [repmat(xlo,size(y)), repmat(xhi,size(y)), nanfunx(size(y))]';  xvec=xvec(:);
yvec = [                  y,                   y, nanfuny(size(y))]';  yvec=yvec(:);
hold on, h=plot(xvec,yvec,s);

% Restore original hold state
if nohold, hold off; end

% Return handle
if nargout
  handle = h;
end
