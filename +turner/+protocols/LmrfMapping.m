classdef LmrfMapping < clandininlab.protocols.ClandininLabStageProtocol
    
    properties
        preTime = 500                   % Leading duration (ms)
        stimTime = 2000                 % Duration (ms)
        tailTime = 500                  % Trailing duration (ms)
        intensity = 0                   % intensity of square (0-1)
        backgroundIntensity = 0.5       % Background light intensity (0-1)
        
        speed = 60                      % Deg/sec.
        squareSize = 10                 % Deg.
        azimuths = -30:10:30            % Deg.
        elevations = 5:10:35            % Deg.   
        orientations = [0 90 180 270]   % Deg.
        numberOfAverages = uint16(100)  % Number of epochs
        randomizeOrder = true          % Randomize sequence of locations t/f
    end
    
    properties (Hidden)
        AzElOr_sequence
        currentAzimuth
        currentElevation
        currentOrientation
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
            
            % Create Azimuth, Elevation, Orientation sequence
            [Az, El, Or] = meshgrid(obj.azimuths, obj.elevations, obj.orientations);
            obj.AzElOr_sequence = [Az(:), El(:), Or(:)];
        end
        
        function prepareEpoch(obj, epoch)
            prepareEpoch@clandininlab.protocols.ClandininLabStageProtocol(obj, epoch);
            
            % Determine current azimuth & elevation
            index = mod(obj.numEpochsCompleted, size(obj.AzElOr_sequence,1)) + 1;
            % Randomize the sequence order at the beginning of each sequence.
            if index == 1 && obj.randomizeOrder
                randInds = randperm(size(obj.AzElOr_sequence,1));
                obj.AzElOr_sequence = obj.AzElOr_sequence(randInds,:);
            end
            obj.currentAzimuth = obj.AzElOr_sequence(index,1);
            obj.currentElevation = obj.AzElOr_sequence(index,2);
            obj.currentOrientation = obj.AzElOr_sequence(index,3);
            
            epoch.addParameter('currentAzimuth', obj.currentAzimuth);
            epoch.addParameter('currentElevation', obj.currentElevation);
            epoch.addParameter('currentOrientation', obj.currentOrientation);
        end
        
        function p = createPresentation(obj)
            p = stage.core.Presentation((obj.preTime + obj.stimTime + obj.tailTime) * 1e-3);
            
            % Set background intensity for presentation
            p.setBackgroundColor(obj.backgroundIntensity);

            % "Rectangle" stimulus:
            Rect = clandininlab.stimuli.Rectangle();
            Rect.width = obj.squareSize;
            Rect.height = obj.squareSize;
            Rect.color = obj.intensity;
            Rect.rectOrientation = obj.currentOrientation;

            distanceTraveled = obj.barSpeed * obj.stimTime; %deg
            
            thetaController = stage.builtin.controllers.PropertyController(Rect, 'azimuth',@(state)obj.currentAzimuth +...
                cosd(obj.currentOrientation)*(-distanceTraveled/2 + obj.barSpeed*state.time));
            
            phiController = stage.builtin.controllers.PropertyController(Rect, 'elevation',@(state)obj.currentElevation +...
                sind(obj.currentOrientation)*(-distanceTraveled/2 + obj.barSpeed*state.time));

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

