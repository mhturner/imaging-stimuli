classdef FullFieldNoise < clandininlab.protocols.ClandininLabStageProtocol
    
    properties
        preTime = 2000                  % Leading duration (ms)
        stimTime = 20000                % Duration (ms)
        tailTime = 2000                 % Trailing duration (ms)
        noiseStdv = 0.3                 % contrast, as fraction of mean
        frameDwell = 2                  % Frames per noise update
        useRandomSeed = true            % false = repeated noise trajectory (seed 0)   
        backgroundIntensity = 0.5       % Background light intensity (0-1)
        numberOfAverages = uint16(10)   % Number of epochs
    end
    
    properties (Hidden)
        noiseSeed
        noiseStream
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
            
            % Uniform semisphere stimulus:
            Sphere = clandininlab.stimuli.PerspectiveSphere;
            Sphere.color = obj.backgroundIntensity;
            p.addStimulus(Sphere);
            % Controller to update intensity
            preFrames = round(60 * (obj.preTime/1e3));
            noiseValue = stage.builtin.controllers.PropertyController(Sphere, 'color',...
                @(state)getNoiseIntensity(obj, state.frame - preFrames));
            p.addController(noiseValue); %add the controller
            function i = getNoiseIntensity(obj, frame)
                persistent intensity;
                if frame<0 %pre frames. frame 0 starts stimPts
                    intensity = obj.backgroundIntensity;
                else %in stim frames
                    if mod(frame, obj.frameDwell) == 0 %noise update
                        intensity = obj.backgroundIntensity + ...
                            obj.noiseStdv * obj.backgroundIntensity * obj.noiseStream.randn;
                    end
                end
                i = intensity;
            end

            sphereVisible = stage.builtin.controllers.PropertyController(Sphere, 'visible', @(state)state.time >= obj.preTime * 1e-3 && state.time < (obj.preTime + obj.stimTime) * 1e-3);
            p.addController(sphereVisible);
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
        end

        function tf = shouldContinuePreparingEpochs(obj)
            tf = obj.numEpochsPrepared < obj.numberOfAverages;
        end
        
        function tf = shouldContinueRun(obj)
            tf = obj.numEpochsCompleted < obj.numberOfAverages;
        end
        
    end
    
end

