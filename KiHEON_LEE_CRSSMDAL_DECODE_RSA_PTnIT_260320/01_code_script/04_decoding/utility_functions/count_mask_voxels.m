%% Utility function
% ===================================================================
% Author of this script:
%   Ki Heon Lee
% Contact:
%   kiheon97@gmail.com
% ===================================================================
function n = count_mask_voxels(maskFile)
V = spm_vol(maskFile);
X = spm_read_vols(V);
n = sum(X(:) > 0 & isfinite(X(:)));
end