%% Utility function
% ===================================================================
% Author of this script:
%   Ki Heon Lee
% Contact:
%   kiheon97@gmail.com
% ===================================================================
function b = getbase(p)
[~, b, ext] = fileparts(p);
b = [b ext];
end