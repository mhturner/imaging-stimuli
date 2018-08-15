classdef ExpandingMovingSquare < clandininlab.protocols.ClandininLabStageProtocol
    properties
        preTime = 500                           % Leading duration (ms)
        stimTime = 3000                          % Duration (ms)
        tailTime = 500                           % Trailing duration (ms)
        intensity = 0                           % Bar intensity (0-1)
        squareSizes = [5, 10, 20, 30, 40, 50, 60]  % Deg. visual angle, Perp. to axis of movement
        barSpeed = 60                            % Deg./sec.
        orientation = 0                          % Deg.
        center = [0, 30]                          % Deg. (az., el.)
        backgroundIntensity = 0.5                 % Background light intensity (0-1)
        numberOfAverages = uint16(40)             % Number of epochs
        randomizeOrder = true                     % Randomize sequence of orientations t/f
    end
    
    properties (Hidden)
        sizeSequence
        currentSize
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
            
            % Create sequences for orientation
            obj.sizeSequence = obj.squareSizes;
        end
        
        function prepareEpoch(obj, epoch)
            prepareEpoch@clandininlab.protocols.ClandininLabStageProtocol(obj, epoch);
            
            % Determine current orientation
            index = mod(obj.numEpochsCompleted, length(obj.sizeSequence)) + 1;
            % Randomize the bar orientation order at the beginning of each sequence.
            if index == 1 && obj.randomizeOrder
                randInds = randperm(length(obj.sizeSequence));
                obj.sizeSequence = obj.sizeSequence(randInds);
            end
            obj.currentSize = obj.sizeSequence(index);
            
            epoch.addParameter('currentSize', obj.currentSize);
        end
        
        function p = createPresentation(obj)
            p = stage.core.Presentation((obj.preTime + obj.stimTime + obj.tailTime) * 1e-3);
            
            % Set background intensity for presentation
            p.setBackgroundColor(obj.backgroundIntensity);
            
            % "Rectangle" stimulus:
            Rect = clandininlab.stimuli.Rectangle();
            Rect.width = obj.currentSize;
            Rect.height = obj.currentSize;
            Rect.color = obj.intensity;
            Rect.rectOrientation = obj.orientation;

            startPosition = -90; %deg. Enough to start off screen, empirically
            thetaController = stage.builtin.controllers.PropertyController(Rect, 'azimuth',@(state)obj.center(1) +...
                cosd(obj.orientation)*(startPosition + obj.barSpeed*state.time));
            
            phiController = stage.builtin.controllers.PropertyController(Rect, 'elevation',@(state)obj.center(2) +...
                sind(obj.orientation)*(startPosition + obj.barSpeed*state.time));

            p.addStimulus(Rect);
            p.addController(thetaController);
            p.addController(phiController);

            % Visibility controller
            rectVisible = stage.builtin.controllers.PropertyController(Rect, 'visible', @(state)state.time >= obj.preTime * 1e-3 && state.time < (obj.preTime + obj.stimTime) * 1e-3);
            p.addController(rectVisible);
        end

        function tf = shouldContinuePreparingEpochs(obj)
            tf = obj.numEpochsPrepared < obj.numberOfAverages;
        end
        
        function tf = shouldContinueRun(obj)
            tf = obj.numEpochsCompleted < obj.numberOfAverages;
        end
        
    end
    
end

