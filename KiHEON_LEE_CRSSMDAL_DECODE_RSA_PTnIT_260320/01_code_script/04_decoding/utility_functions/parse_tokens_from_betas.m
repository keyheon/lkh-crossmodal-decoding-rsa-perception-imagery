%% Utility function
% ===================================================================
% Author of this script:
%   Ki Heon Lee
% Contact:
%   kiheon97@gmail.com
% ===================================================================
function [emo, run] = parse_tokens_from_betas(F)
tok = @(x) regexp(x, 'beta_r(\d+)_([A-Za-z]+)\.nii', 'tokens', 'once');
T = cellfun(@(p) tok(getbase(p)), F, 'UniformOutput', false);
run = cellfun(@(c) str2double(c{1}), T);
emo = lower(cellfun(@(c) c{2}, T, 'UniformOutput', false));
end