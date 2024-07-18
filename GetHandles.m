function [Ht,Hf,Ho,hfig,ht,hf,ho] = GetHandles(option)

% GETHANDLES - Return handles to axes and figures.
% [Ht,Hf,Ho] = GetHandles()
% [Ht,Hf,Ho] = GetHandles('all' | 'current')
% [Ht,Hf,Ho,hfig,ht,hf,ho] = GetHandles(...)
%
% Returns handles to 'Timeseries', 'Spectrum', and other docked 
% figure axes as matrices (Ht,Hf,Ho). Rows in each matrix correspond 
% to subplots, and columns correspond to figure numbers.  Ordering 
% of subplots for non-Timeseries and non-Spectrum axes is top to 
% bottom and left to right.  Nan values correspond to unused axes.  
% Any undocked figures are ignored. 
%
% Additional outputs 'hfig' and (ht,hf,ho) are returned in vector 
% form. Output 'hfig' contains an ordered list of handles to docked 
% figures, corresponding to columns of (Ht,Hf,Ho). Outputs (ht,hf,ho) 
% contain the non-NaN entries of (Ht,Hf,Ho) in columnwise order. 
%
% Two modes are available: 'all', for which the axes from all docked 
% figures are included, and 'current', in which case only those 
% docked figures generated in the same call as the currently active 
% figure are considered.  If not specified, 'all' is assumed. 
%
% P.G. Bonanni
% 3/7/20

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


if nargin < 1
  option = 'all';
end

% Get handles to docked figures
hfig = get(0,'Children');
C = get(hfig,'WindowStyle');
mask = strcmp(C,'docked');
hfig = hfig(mask);

% If 'current' mode ...
if strcmp(option,'current')
  mask = strcmp(get(gcf,'Tag'),get(hfig,'Tag'));
  hfig = hfig(mask);
end

% Return immediately if none present
if isempty(hfig)
  Ht   = [];
  Hf   = [];
  Ho   = [];
  hfig = [];
  ht   = [];
  hf   = [];
  ho   = [];
  return
end

% Order handles according to figure number
C = get(hfig,'Number');
if isscalar(C), num=C; else num=cat(1,C{:}); end
[~,i] = sort(num);  hfig=hfig(i);

% Number of docked figures
nfigs = length(hfig);

% Default number of plot rows for Timeseries and Spectrum axes
nrows0 = GetParam('DefaultNumberPlotRows');

% Initialize
C1 = cell(nfigs,1);
C2 = cell(nfigs,1);
C3 = cell(nfigs,1);

% Populate cell arrays
for k = 1:nfigs
  % ---
  h = findobj('Parent',hfig(k),'Tag','Timeseries');
  if ~isempty(h)
    C = get(h,'Position');
    if isnumeric(C), X=C; else X=cat(1,C{:}); end
    [~,i] = sort(X(:,2),'descend');  % sort by descending y position
    C1{k} = h(i);
  end
  % ---
  h = findobj('Parent',hfig(k),'Tag','Spectrum');
  if ~isempty(h)
    C = get(h,'Position');
    if isnumeric(C), X=C; else X=cat(1,C{:}); end
    [~,i] = sort(X(:,2),'descend');  % sort by descending y position
    C2{k} = h(i);
  end
  % ---
  h = findobj('Parent',hfig(k),'Tag','');
  if ~isempty(h)
    C = get(h,'Position');
    if isnumeric(C), X=C; else X=cat(1,C{:}); end
    X = round(10*X)/10;                 % round to nearest 0.1"
    [~,i] = sortrows(X(:,1:2),[1,-2]);  % sort by ascending x, then descending y position
    C3{k} = h(i);
  end
end

% Re-format as matrices
nrows = max([cellfun(@length,C1); nrows0]);
Ht = nan(nrows,nfigs);  % initialize
for k = 1:nfigs
  h = C1{k};
  Ht(1:length(h),k) = h;
end
nrows = max([cellfun(@length,C2); nrows0]);
Hf = nan(nrows,nfigs);  % initialize
for k = 1:nfigs
  h = C2{k};
  Hf(1:length(h),k) = h;
end
nrows = max(cellfun(@length,C3));
Ho = nan(nrows,nfigs);  % initialize
for k = 1:nfigs
  h = C3{k};
  Ho(1:length(h),k) = h;
end

% Extract non-NaN entries into vectors
ht = Ht(:);  ht(isnan(ht))=[];
hf = Hf(:);  hf(isnan(hf))=[];
ho = Ho(:);  ho(isnan(ho))=[];
