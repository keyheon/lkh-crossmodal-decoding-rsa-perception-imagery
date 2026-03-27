%% Utility function
% ===================================================================
% Author of this script:
%   Ki Heon Lee
% Contact:
%   kiheon97@gmail.com
% ===================================================================
function v = vec_ut(M)
    upper_mask = triu(true(size(M, 1)), 1);
    v = M(upper_mask);
end