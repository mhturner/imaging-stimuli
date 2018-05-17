classdef StationarySquareMapping < clandininlab.protocols.ClandininLabStageProtocol
    
    properties
        preTime = 500                  % Leading duration (ms)
        stimTime = 5000                 % Duration (ms)
        tailTime = 500                 % Trailing duration (ms)
        contrast = 0.9                  % contrast of modulated square, relative to background (0-1)
        temporalFrequency = 2           % Hz
        backgroundIntensity = 0.5       % Background light intensity (0-1)
        numberOfAverages = uint16(100)  % Number of epochs
        squareSize = 5                  % Deg.
        azimuths = -40:10:40            % Deg.
        elevations = 5:10:55            % Deg.    
        randomizeOrder = true           % Randomize sequence of locations t/f
    end
    
    properties (Hidden)
        locationSequence
        currentAzimuth
        currentElevation
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
            
            % Create location sequence
            [Az, El] = meshgrid(obj.azimuths, obj.elevations);
            obj.locationSequence = [Az(:),El(:)]; % all pairwise combinations
        end
        
        function prepareEpoch(obj, epoch)
            prepareEpoch@clandininlab.protocols.ClandininLabStageProtocol(obj, epoch);
            
            % Determine current azimuth & elevation
            index = mod(obj.numEpochsCompleted, size(obj.locationSequence,1)) + 1;
            % Randomize the bar width sequence order at the beginning of each sequence.
            if index == 1 && obj.randomizeOrder
                randInds = randperm(size(obj.locationSequence,1));
                obj.locationSequence = obj.locationSequence(randInds,:);
            end
            obj.currentAzimuth = obj.locationSequence(index,1);
            obj.currentElevation = obj.locationSequence(index,2);
            
            epoch.addParameter('currentAzimuth', obj.currentAzimuth);
            epoch.addParameter('currentElevation', obj.currentElevation);
        end
        
        function p = createPresentation(obj)
            p = stage.core.Presentation((obj.preTime + obj.stimTime + obj.tailTime) * 1e-3);
            
            % Set background intensity for presentation
            p.setBackgroundColor(obj.backgroundIntensity);
            
            % "Rectangle" stimulus:
            Rect = clandininlab.stimuli.Rectangle();
            Rect.width = obj.squareSize;
            Rect.height = obj.squareSize;
            Rect.elevation = obj.currentElevation;
            Rect.azimuth = obj.currentAzimuth;

            p.addStimulus(Rect);
            
            % Color controller:
            if (obj.temporalFrequency > 0) 
                rectColor = stage.builtin.controllers.PropertyController(Rect, 'color',...
                    @(state)getRectColor(obj, state.time - obj.preTime/1e3));
                p.addController(rectColor); %add the controller
            end
            function I = getRectColor(obj, time)
                c = obj.contrast.*sin(2 * pi * obj.temporalFrequency * time);
                I = obj.backgroundIntensity + c*obj.backgroundIntensity;
            end
            
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

