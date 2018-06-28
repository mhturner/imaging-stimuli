classdef RepeatingImpulseSquare < clandininlab.protocols.ClandininLabStageProtocol
    
    properties
        preTime = 500                   % Leading duration (ms)
        stimTime = 10000                % Total stimulus (ms)
        tailTime = 500                  % Trailing duration (ms)
        
        interPulseFrames = 15              % Period between pulse onsets (frames)
        pulseFrames = 3              % Duration of pulse, in frames
        
        intensity = 0                   % intensity of square (0-1)
        
        backgroundIntensity = 0.5       % Background light intensity (0-1)
        numberOfAverages = uint16(10)  % Number of epochs
        squareSize = 10                 % Deg.
        center = [0, 30]                % Deg. (az., el.)
    end
    
    properties (Hidden)
        onFrames
        frameRate
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
            
            % Get pulse ON frames
            obj.frameRate = obj.rig.getDevice('Stage').getPatternRate(); %Hz
            ff = 1:floor((obj.stimTime/1e3)*obj.frameRate); %frames
            obj.onFrames = find(mod(ff,obj.interPulseFrames) < obj.pulseFrames);
            obj.onFrames(1:obj.pulseFrames-1) = []; %cut first on frames, no "start" frame (mod = 0)
            if ~(obj.onFrames(end) - obj.onFrames(end-1) == 1) %last frame is a "Start"
            	obj.onFrames(end) = [];
            end
        end
        
        function prepareEpoch(obj, epoch)
            prepareEpoch@clandininlab.protocols.ClandininLabStageProtocol(obj, epoch);

            epoch.addParameter('onFrames', obj.onFrames);
        end
        
        function p = createPresentation(obj)
            p = stage.core.Presentation((obj.preTime + obj.stimTime + obj.tailTime) * 1e-3);
            
            % Set background intensity for presentation
            p.setBackgroundColor(obj.backgroundIntensity);
            
            % "Rectangle" stimulus:
            Rect = clandininlab.stimuli.Rectangle();
            Rect.width = obj.squareSize;
            Rect.height = obj.squareSize;
            Rect.azimuth = obj.center(1);
            Rect.elevation = obj.center(2);

            p.addStimulus(Rect);
            
            % Color controller:
            preFrames = floor((obj.preTime/1e3)*obj.frameRate);
            rectColor = stage.builtin.controllers.PropertyController(Rect, 'color',...
                @(state)getRectColor(obj, state.frame - preFrames));
            p.addController(rectColor); %add the controller
            
            function I = getRectColor(obj, frame)
                if ismember(frame,obj.onFrames)
                    I = obj.intensity;
                else
                    I = obj.backgroundIntensity;
                end
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

