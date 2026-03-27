%% Utility function
% ===================================================================
% Author of this script:
%   Ki Heon Lee
% Contact:
%   kiheon97@gmail.com
% ===================================================================
function keep = finite_nonconstant_voxels(X)
    voxel_std = std(X, 0, 1, 'omitnan');
    keep = isfinite(voxel_std) & (voxel_std > 0);
end