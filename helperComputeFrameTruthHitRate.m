function [frameTruthHitRate, targetHits] = ...
    helperComputeFrameTruthHitRate( ...
    truthRangeAoA, clusteredDetections, ...
    rangeTolerance, aoaTolerance)
%HELPERCOMPUTEFRAMETRUTHHITRATE Associate detections with true targets.

numTargets = size(truthRangeAoA, 2);

targetHits = false(1, numTargets);

if numTargets == 0
    frameTruthHitRate = NaN;
    return;
end

if isempty(clusteredDetections)
    frameTruthHitRate = 0;
    return;
end

for targetIndex = 1:numTargets

    trueRange = truthRangeAoA(1, targetIndex);
    trueAoA = truthRangeAoA(2, targetIndex);

    rangeError = abs( ...
        clusteredDetections(1, :) - trueRange);

    aoaError = abs(wrapTo180( ...
        clusteredDetections(2, :) - trueAoA));

    normalizedDistance = sqrt( ...
        (rangeError / rangeTolerance).^2 + ...
        (aoaError / aoaTolerance).^2);

    targetHits(targetIndex) = ...
        any(normalizedDistance <= 1);
end

frameTruthHitRate = mean(targetHits);
end