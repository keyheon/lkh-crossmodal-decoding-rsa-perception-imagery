%% Utility function
% ===================================================================
% Author of this script:
%   Ki Heon Lee
% Contact:
%   kiheon97@gmail.com
% ===================================================================
function roiList = resolve_rois(roi_spec, root)
roiList = {};

if iscell(roi_spec) && ~isempty(roi_spec)
    roiList = roi_spec(:).';
elseif ischar(roi_spec) && ~isempty(roi_spec)
    if exist(roi_spec, 'dir') == 7
        D1 = dir(fullfile(roi_spec, '*.nii'));
        D2 = dir(fullfile(roi_spec, '*.img'));
        roiList = [fullfile({D1.folder}, {D1.name}), fullfile({D2.folder}, {D2.name})];
    else
        if contains(roi_spec, '*') || contains(roi_spec, '^') || contains(roi_spec, '$')
            [d, pat] = fileparts(roi_spec);
            if isempty(d)
                d = pwd;
            end
            roiList = cellstr(spm_select('FPList', d, pat)).';
        elseif exist(roi_spec, 'file') == 2
            roiList = {roi_spec};
        end
    end
else
    roi_dir = fullfile(root, 'ROIs');
    if exist(roi_dir, 'dir') == 7
        D = [dir(fullfile(roi_dir, 'rstr*.nii')); dir(fullfile(roi_dir, 'str*.nii')); ...
             dir(fullfile(roi_dir, 'rstr*.img')); dir(fullfile(roi_dir, 'str*.img'))];
        roiList = fullfile({D.folder}, {D.name});
    end
end

roiList = unique(roiList, 'stable');
end