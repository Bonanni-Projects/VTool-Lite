function mask = maketrue(irange,n)

% MAKETRUE - Return logical ones within index range(s).
% mask = maketrue(irange,n)
% mask = maketrue(irange)
%
% Returns nx1 vector 'mask' having logical ones within index ranges 
% specified by 'irange', and logical zeros elsewhere.  Input 'irange' 
% is Nx2, with each row defining the [start,end] indices of a range.  
% If not specified, length 'n' defaults to the maximum value found 
% in 'irange'.
%
% See also "where".
%
% P.G. Bonanni
% 3/2/12


if nargin < 2
  n = max(irange(:));
end

% Check input for validity
if size(irange,2)~=2
  error('Input ''irange'' must be Nx2.');
elseif any(irange(:)<1) || any(irange(:)>n)
  error('Input ''irange'' contains one or more index values out of range.')
elseif any(diff(irange,1,2)<0)
  error('Input ''irange'' is invalid.  Must have start<=end on all rows.')
end

% Initialize
mask = false(n,1);

% Build mask
for k = 1:size(irange,1)
  mask(irange(k,1):irange(k,2)) = true;
end
