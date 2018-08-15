
function board = reproduceRandomCheckerboardStimulus(noiseSeed, numChecksX, numChecksY, numUpdates, binaryFlag)
%reset random stream to recover stim trajectories
noiseStream = RandStream('mt19937ar', 'Seed', noiseSeed);
% get stim trajectories and response in frame updates
board = zeros(numChecksY,numChecksX,numUpdates);
for ii = 1:numUpdates
    if (binaryFlag)
        board(:,:,ii) = ... 
            noiseStream.rand(numChecksY,numChecksX) > 0.5;
    else
        board(:,:,ii) = ... 
            noiseStream.randn(numChecksY,numChecksX);
    end
end