%% Utility function
% ===================================================================
% Author of this script:
%   Ki Heon Lee
% Contact:
%   kiheon97@gmail.com
% ===================================================================
function roiList_out = reslice_rois_force_to_ref_and_return_rpaths(roiList_in, refImg, outDir)
% Reslice each ROI mask to the reference beta-image grid and return the
% resliced files with an 'r' prefix.
    if ~exist(outDir, 'dir')
        mkdir(outDir);
    end
    Vref = spm_vol(refImg);
    tol_mat = 1e-4;

    roiList_out = cell(size(roiList_in));
    for i = 1:numel(roiList_in)
        [srcFold, srcName, srcExt] = fileparts(roiList_in{i});
        base = regexprep(srcName, '^r+', '');
        dst_plain = fullfile(outDir, [base srcExt]);
        dst_r = fullfile(outDir, ['r' base srcExt]);

        if ~strcmp(roiList_in{i}, dst_plain)
            copyfile(roiList_in{i}, dst_plain);
            if endsWith(lower(srcExt), '.img')
                hdr_src = fullfile(srcFold, [srcName '.hdr']);
                hdr_dst = fullfile(outDir, [base '.hdr']);
                if exist(hdr_src, 'file')
                    copyfile(hdr_src, hdr_dst);
                end
            end
        end

        need_reslice = true;
        if exist(dst_r, 'file')
            Vr = spm_vol(dst_r);
            if isequal(Vr.dim, Vref.dim) && max(abs(Vr.mat(:) - Vref.mat(:))) < tol_mat
                need_reslice = false;
            else
                try
                    delete(dst_r);
                catch
                end
                if endsWith(lower(srcExt), '.img')
                    try
                        delete(fullfile(outDir, ['r' base '.hdr']));
                    catch
                    end
                end
            end
        end

        if need_reslice
            P = char(Vref.fname, dst_plain);
            spm_reslice(P, struct('mean', 0, 'interp', 0, 'which', 1, 'wrap', [0 0 0]));
        end

        Vr = spm_vol(dst_r);
        if ~isequal(Vr.dim, Vref.dim) || max(abs(Vr.mat(:) - Vref.mat(:))) >= tol_mat
            P = char(Vref.fname, dst_plain);
            spm_reslice(P, struct('mean', 0, 'interp', 0, 'which', 1, 'wrap', [0 0 0]));
        end

        roiList_out{i} = dst_r;

        try
            delete(dst_plain);
        catch
        end
        if endsWith(lower(srcExt), '.img')
            try
                delete(fullfile(outDir, [base '.hdr']));
            catch
            end
        end
    end
end