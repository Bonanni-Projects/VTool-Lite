function handle = xlines(x,y,s)

% XLINES - Draw lines of constant x.
% xlines(x,y [,s])
% xlines(x [,s])
% h = xlines(...)
%
% Superimposes lines of constant abcissa value 'x' on the 
% current plot.  Vector 'x' specifies the x-values at which 
% the lines are to be drawn.  Upper and lower limits for the 
% lines are determined by the extrema of vector 'y'.  If not 
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
y0 = get(gca,'Ylim');
s0 = 'k-';

if nargin==2
  if ischar(y)
    s = y;
    y = y0;
  else
    s = s0;
  end
elseif nargin==1
  y = y0;
  s = s0;
end

% Fix format
x = x(:);

% Upper/lower limits
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

% Check hold state
if ~ishold, nohold=1; else nohold=0; end

% Plot lines 
xvec = [                  x,                   x, nanfunx(size(x))]';  xvec=xvec(:);
yvec = [repmat(ylo,size(x)), repmat(yhi,size(x)), nanfuny(size(x))]';  yvec=yvec(:);
hold on, h=plot(xvec,yvec,s);

% Restore original hold state
if nohold, hold off; end

% Return handle
if nargout
  handle = h;
end
