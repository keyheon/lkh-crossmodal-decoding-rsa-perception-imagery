%% Utility function
% ===================================================================
% Author of this script:
%   Ki Heon Lee
% Contact:
%   kiheon97@gmail.com
% ===================================================================
function [R1, R2, RI] = make_rsms_default(X1, X2, X3)
    n_items = size(X1, 1);
    all_data = [X1; X2; X3];

    keep = all(isfinite(all_data), 1);
    voxel_std = std(all_data, 0, 1, 'omitnan');
    keep = keep & isfinite(voxel_std) & (voxel_std > 0);

    if sum(keep) >= 3
        R1 = corr(X1(:, keep)');
        R2 = corr(X2(:, keep)');
        RI = corr(X3(:, keep)');
    else
        keep1 = finite_nonconstant_voxels(X1);
        keep2 = finite_nonconstant_voxels(X2);
        keep3 = finite_nonconstant_voxels(X3);

        R1 = corr(X1(:, keep1)', 'Rows', 'pairwise');
        R2 = corr(X2(:, keep2)', 'Rows', 'pairwise');
        RI = corr(X3(:, keep3)', 'Rows', 'pairwise');
    end

    R1(1:n_items+1:end) = 1;
    R2(1:n_items+1:end) = 1;
    RI(1:n_items+1:end) = 1;

    R1 = (R1 + R1') / 2;
    R2 = (R2 + R2') / 2;
    RI = (RI + RI') / 2;
end