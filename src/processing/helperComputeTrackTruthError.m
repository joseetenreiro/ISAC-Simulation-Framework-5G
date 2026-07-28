function [targetErrors, targetTrackHits] = ...
    helperComputeTrackTruthError( ...
    tracks, targetPositions, distanceTolerance)
%HELPERCOMPUTETRACKTRUTHERROR Compute target-to-track Cartesian errors.

numTargets = size(targetPositions, 1);

targetErrors = NaN(1, numTargets);
targetTrackHits = false(1, numTargets);

if isempty(tracks)
    return;
end

numTracks = numel(tracks);
trackPositions = NaN(numTracks, 2);

for trackIndex = 1:numTracks

    state = tracks(trackIndex).State;

    % State convention: [x; vx; y; vy].
    trackPositions(trackIndex, :) = [
        state(1), state(3)
        ];
end

for targetIndex = 1:numTargets

    truePositionXY = ...
        targetPositions(targetIndex, 1:2);

    distances = vecnorm( ...
        trackPositions - truePositionXY, ...
        2, ...
        2);

    targetErrors(targetIndex) = ...
        min(distances);

    targetTrackHits(targetIndex) = ...
        targetErrors(targetIndex) <= distanceTolerance;
end
end