function out = PlotDatasetAsStrips(Data,names,option)

% PLOTDATASETASSTRIPS - Plot dataset signals as strips in current axes.
% PlotDatasetAsStrips(Data,names)
% PlotDatasetAsStrips(Data,names,'normalize')
% h = PlotDatasetAsStrips(...)
%
% Plots selected signals from a dataset as separate strips within 
% the current axes object. Input 'Data' is a scalar dataset, and 
% 'names' is a cell array of signal names. If the 'normalize' 
% option is specified, the signals are normalized to have uniform 
% range; otherwise their relative scaling is preserved. Optionally 
% returns vector of handles 'h' to the generated plots. 
%
% P.G. Bonanni
% 3/18/26

% Copyright (c) 2026  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


if nargin < 3
  option = '';
end

% Check 'Data' argument
[flag,valid] = IsDataset(Data);
if ~flag || ~valid
  error('Input ''Data'' is not a valid dataset.  See "IsDataset".')
end

% Make column
names = names(:);

% Check 'names' argument
if ~iscellstr(names)
  error('Input ''names'' must be a cell array of character strings.')
elseif any(cellfun(@isempty,names))
  error('One or more ''names'' entries is empty.')
end

% Check that all requested names are valid
[~,ismatched] = SelectFromDataset(names,Data);
if any(~ismatched)
  error('One or more requested signals is not present in the dataset.')
end

% Number of signals
nsignals = length(names);

% Get time vector
t = Data.Time.Values;

% Get signal data
Signals = SelectFromDataset(names,Data);
Values = Signals.Values;
MaskN = isnan(Values);

% Find signal bounds, with and without inclusion of 0 values (NOTE: row vectors)
minvals = min(Values,[],1);    % original
maxvals = max(Values,[],1);    % original
Values1 = [Values; zeros(1,width(Values))];
minvals1 = min(Values1,[],1);  % w/ zeros included
maxvals1 = max(Values1,[],1);  % w/ zeros included

% Apply the appropriate normalization, and locate zero lines
if startsWith(option,'normalize')  % includes 'normalized'
  % Apply individual normalization to equal range
  Values = 2*(Values - minvals)./(maxvals-minvals) - 1;
  Values(:,minvals==maxvals) = 0;
  Values(MaskN) = nan;
  offset0 = 0;
else
  % Apply a uniform normalization that includes display of 0 line
  minval = min(minvals1);
  maxval = max(maxvals1);
  if minval~=maxval
    Values = 2*(Values - minval)./(maxval-minval) - 1;
    offset0 = interp1([minval,maxval],[-0.4,0.4],0);
  else  % if minval==maxval
    Values = zeros(size(Values));
    Values(MaskN) = nan;
    if minval == 0,    offset0 =  0;
    elseif minval > 0, offset0 = -1;
    elseif minval < 0, offset0 =  1;
    end
  end
end

% Define rectangular plotting regions
xlo = repmat(min(t),nsignals,1);  % left limits
xhi = repmat(max(t),nsignals,1);  % right limits
ylo = (1:nsignals)' - 0.4;        % lower limits
yhi = (1:nsignals)' + 0.4;        % upper limits

% Apply scaling and offsets for plotting
Values = Values*0.4 + (nsignals:-1:1);

% Get time name and units
layers = GetLayers(Data);
nameT = Data.Time.(layers{1}){1};
unitsT = Data.Time.Units{1};

% Generate plot
h = plot(t,Values,'LineWidth',1.5);
set(gca,'XLim',[min(t),max(t)])
set(gca,'YLim',[0.4,nsignals+0.6])
set(gca,'YTick',(1:nsignals)'+offset0)
set(gca,'YTickLabel',flipud(strrep(names,'_','\_')))
set(gca,'color',get(gcf,'color'))  % erase background color

% Label the time axis
if ~strcmp(unitsT,'datetime')
  if ~isempty(unitsT)
    xlabel(sprintf('%s (%s)',nameT,unitsT))
  else  % if unitless
    xlabel(nameT)
  end
end

% Suppress y-axis tick marks and "zero lines" for normalized plots
if startsWith(option,'normalize')  % includes 'normalized'
  set(gca,'XGrid','off','YGrid','off')
  set(get(gca,'YAxis'),'TickLength',[0,0])
else
  set(gca,'XGrid','off','YGrid','on')
end

% Highlight the plotting regions
for k = 1:nsignals
  xvec = [xlo(k),xhi(k),xhi(k),xlo(k)]; 
  yvec = [ylo(k),ylo(k),yhi(k),yhi(k)];
  patch(xvec,yvec,'w','linestyle','none')  % plot patch and move to rear
  set(gca,'children',circshift(get(gca,'children'),-1))
end

% Move axis box to top
set(gca,'Layer','top')

% If output argument provided...
if nargout
  out = h;
end
