classdef CheckerboardNoise < clandininlab.protocols.ClandininLabStageProtocol
    
    properties
        preTime = 2000                  % Leading duration (ms)
        stimTime = 20000                 % Duration (ms)
        tailTime = 2000                 % Trailing duration (ms)
        stixelSize = 10                  % deg. visual angle
        binaryNoise = true              % binary checkers - overrides noiseStdv
        noiseStdv = 0.3                 % contrast, as fraction of mean
        frameDwell = 2                  % Frames per noise update
        useRandomSeed = true            % false = repeated noise trajectory (seed 0)   
        backgroundIntensity = 0.5       % Background light intensity (0-1)
        numberOfAverages = uint16(10)    % Number of epochs
    end
    
    properties (Hidden)
        noiseSeed
        noiseStream
        numChecksX
        numChecksY
    end
    
    methods
        
        function didSetRig(obj)
            didSetRig@clandininlab.protocols.ClandininLabStageProtocol(obj);
        end
        
        function p = getPreview(obj, panel)
            if isempty(obj.rig.getDevices('Stage'))
                p = [];
                return;
            end
            p = io.github.stage_vss.previews.StagePreview(panel, @()obj.createPresentation(), ...
                'windowSize', obj.rig.getDevice('Stage').getTrueCanvasSize());
        end
        
        function prepareRun(obj)
            prepareRun@clandininlab.protocols.ClandininLabStageProtocol(obj);
        end
        
        function p = createPresentation(obj)
            % Presentation duration
            p = stage.core.Presentation((obj.preTime + obj.stimTime + obj.tailTime) * 1e-3);
            % Set background intensity for presentation
            p.setBackgroundColor(obj.backgroundIntensity);
            
            % Checkerboard stimulus:
            initMatrix = uint8(255.*(obj.backgroundIntensity .* ones(obj.numChecksY,obj.numChecksX)));
            Board = clandininlab.stimuli.Image(initMatrix);
            %get number of stixels/checkers in board:
            obj.numChecksX = ceil(rad2deg(range(Board.thetaLimits)) / obj.stixelSize);
            obj.numChecksY = ceil(rad2deg(range(Board.phiLimits)) / obj.stixelSize);
            %resize semisphere so aspect ratio of semisphere matches that
            %of board
            newThetaRange = deg2rad(obj.stixelSize * obj.numChecksX);
            newPhiRange = deg2rad(obj.stixelSize * obj.numChecksY);
            Board.thetaLimits = mean(Board.thetaLimits) + [-newThetaRange/2 newThetaRange/2];
            Board.phiLimits = mean(Board.phiLimits) + [-newPhiRange/2 newPhiRange/2];
            Board.setMinFunction(GL.NEAREST); %don't interpolate to scale up board
            Board.setMagFunction(GL.NEAREST);
            p.addStimulus(Board);
            
            preFrames = round(60 * (obj.preTime/1e3)); %TO DO: generalize this for different frame rates
            checkerboardController = stage.builtin.controllers.PropertyController(Board, 'imageMatrix',...
                @(state)getNewCheckerboard(obj, state.frame - preFrames));
            p.addController(checkerboardController);
            function i = getNewCheckerboard(obj, frame)
                persistent boardMatrix;
                if frame<0 %pre frames. frame 0 starts stimPts
                    boardMatrix = obj.backgroundIntensity;
                else %in stim frames
                    if mod(frame, obj.frameDwell) == 0 %noise update
                        if (obj.binaryNoise)
                            boardMatrix = 2*obj.backgroundIntensity * ...
                                (obj.noiseStream.rand(obj.numChecksY,obj.numChecksX) > 0.5);
                        else
                            boardMatrix = obj.backgroundIntensity + ...
                                obj.noiseStdv * obj.backgroundIntensity * ...
                                obj.noiseStream.randn(obj.numChecksY,obj.numChecksX);
                        end
                    end
                end
                i = uint8(255 * boardMatrix);
            end

            % Use a visible controller to make the grating appear only
            % during the stim time
            boardVisible = stage.builtin.controllers.PropertyController(Board, 'visible', @(state)state.time >= obj.preTime * 1e-3 && state.time < (obj.preTime + obj.stimTime) * 1e-3);
            p.addController(boardVisible);
        end
        
        function prepareEpoch(obj, epoch)
            prepareEpoch@clandininlab.protocols.ClandininLabStageProtocol(obj, epoch);
            % Determine seed values.
            if obj.useRandomSeed
                obj.noiseSeed = RandStream.shuffleSeed;
            else
                obj.noiseSeed = 0;
            end
            
            %at start of epoch, set random stream
            obj.noiseStream = RandStream('mt19937ar', 'Seed', obj.noiseSeed);
            epoch.addParameter('noiseSeed', obj.noiseSeed);
            epoch.addParameter('numChecksX', obj.numChecksX);
            epoch.addParameter('numChecksY', obj.numChecksY);
        end

        function tf = shouldContinuePreparingEpochs(obj)
            tf = obj.numEpochsPrepared < obj.numberOfAverages;
        end
        
        function tf = shouldContinueRun(obj)
            tf = obj.numEpochsCompleted < obj.numberOfAverages;
        end
        
    end
    
end

