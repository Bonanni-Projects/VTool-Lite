function [H,centers,means] = WeightedHistogram(values,weights,edges)

% WEIGHTEDHISTOGRAM - Weighted histogram calculation.
% [H,centers,means] = WeightedHistogram(values,weights,edges)
% [H,centers,means] = WeightedHistogram(values,weights,nbins)
%
% Computes histogram of data vector 'values' given equal-size 
% vector of associated 'weights'.  Input vector 'edges' defines 
% monotonically increasing bin boundaries, where edge(i) specifies 
% the left edge, and edge(i+1) the right edge of the ith bin (with 
% '-inf' and 'inf' values at the ends permitted).  Alternatively, 
% scalar parameter 'nbins' specifies the number of equal-width bins 
% between the minimum and maximum value of the 'values' vector.  
% Output 'H' is the computed histogram, 'centers' gives the derived 
% bin center values, and 'means' gives the mean of the 'values' 
% vector segregated by bin. (In the event that edges is bounded 
% by 'inf' values at either end, the center value is replaced by 
% the corresponding mean value.)  All outputs are column vectors 
% of length equal to the number of bins. 
%
% P.G. Bonanni
% 8/10/19

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


if numel(edges)==1
  nbins = edges;
  edges = linspace(min(values(:)),max(values(:)),nbins+1);
end

% Check inputs
if ~isvector(values) || ~isvector(weights)
  error('Accepts vector inputs for ''values'' and ''weights'' only.')
elseif numel(weights) ~= numel(values)
  error('Input vectors ''values'' and ''weights'' must be equal in length.\n');
elseif ~isvector(edges)
  error('The specified or derived ''edges'' must be a vector.')
elseif ~all(diff(edges) >=0 )
  error('The specified or derived ''edges'' must be monotonically increasing.')
end

% Make columns
values = values(:);
weights = weights(:);
edges = edges(:);

% Partition 'values' into bins
[~,~,index] = histcounts(values,edges);

% Number of bins
nbins = length(edges)-1;

% Report on non-binned values, but skip reporting if 'values' is all-NaN
if ~all(isnan(values))
  mask = index==0;
  if any(mask)
    fprintf('Note: The specified ''edges'' results in %d values being excluded.\n',sum(mask))
  end
  mask = isnan(values);
  if any(mask)
    fprintf('      Found and excluded %d NaNs.\n',sum(mask))
  end
end

% Initialize
H = zeros(nbins,1);
means = nan(nbins,1);

% Weight distribution and mean values
for k = 1:nbins
  mask = index==k;
  if any(mask)
    H(k) = sum(weights(mask));
    means(k) = mean(values(mask));
  end
end

% Bin centers
centers = mean([edges(1:end-1),edges(2:end)],2);
if isinf(centers(1)), centers(1)=means(1); end
if isinf(centers(end)), centers(end)=means(end); end
