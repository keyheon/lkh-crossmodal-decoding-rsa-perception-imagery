%% Utility function
% ===================================================================
% Author of this script:
%   Ki Heon Lee
% Contact:
%   kiheon97@gmail.com
% ===================================================================
function [roiList_ok, dropped] = verify_roi_grid_and_autofix(roiList, refImg, outDir, root)
    Vref = spm_vol(refImg);
    tol_mat = 1e-4;
    roiList_ok = {};
    dropped = {};

    for i = 1:numel(roiList)
        f = roiList{i};
        try
            Vr = spm_vol(f);
            same = isequal(Vr.dim, Vref.dim) && max(abs(Vr.mat(:) - Vref.mat(:))) < tol_mat;
            if ~same
                [~, name, ext] = fileparts(f);
                base = regexprep(name, '^r+', '');

                cand = {};
                cand{end + 1} = strrep(f, ['r' base ext], [base ext]);

                roi_dir = fullfile(root, 'ROIs');
                if exist(roi_dir, 'dir') == 7
                    c = [dir(fullfile(roi_dir, '**', [base ext])); ...
                         dir(fullfile(roi_dir, '**', ['r' base ext]))];
                    for k = 1:numel(c)
                        cand{end + 1} = fullfile(c(k).folder, c(k).name);
                    end
                end

                cand = unique(cand, 'stable');
                cand = cand(cellfun(@(x) exist(x, 'file') == 2, cand));

                if ~isempty(cand)
                    roiList_fix = reslice_rois_force_to_ref_and_return_rpaths(cand(1), refImg, outDir);
                    Vr2 = spm_vol(roiList_fix{1});
                    same2 = isequal(Vr2.dim, Vref.dim) && max(abs(Vr2.mat(:) - Vref.mat(:))) < tol_mat;
                    if same2
                        roiList_ok{end + 1} = roiList_fix{1};
                        continue
                    end
                end
            else
                roiList_ok{end + 1} = f;
                continue
            end
        catch
        end
        dropped{end + 1} = roiList{i};
    end
    roiList_ok = unique(roiList_ok, 'stable');
end