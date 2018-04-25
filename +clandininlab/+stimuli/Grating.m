classdef Grating < clandininlab.stimuli.PerspectiveSphere
    %Grating texture to paint on perspective semi-sphere
    properties
        contrast = 1            % Scale factor for color values (-1 to 1, negative values invert the grating)
        phase = 0               % Phase offset (degrees)
        spatialFreq = 0.05      % Spatial frequency (cycles per degree)
    end
    properties (Access = private)
        profile                     % Luminance profile wave ('sine', 'square', or 'sawtooth')
        resolution                  % Texture resolution
        needToUpdateVertexBuffer
        needToUpdateTexture
    end
    methods
        function obj = Grating(profile,resolution)
                % Grating texture to paint on parent class
                % PerspectiveSphere
                if nargin < 1
                    profile = 'sine';
                end
                if nargin < 2
                    resolution = 512;
                end
                if ~any(strcmp(profile, {'sine', 'square', 'sawtooth'}))
                    error('Unknown profile');
                end
                obj.profile = profile;
                obj.resolution = resolution;
        end
       
        function init(obj, canvas)
            init@clandininlab.stimuli.PerspectiveSphere(obj, canvas);

            obj.texture = stage.core.gl.TextureObject(canvas, 2);
            obj.texture.setWrapModeS(GL.REPEAT);
            obj.texture.setImage(zeros(1, obj.resolution, 4, 'uint8'));

            obj.updateVertexBuffer();
            obj.updateTexture();                  
        end
        
        function set.phase(obj, phase)
            obj.phase = phase;
            obj.needToUpdateVertexBuffer = true; %#ok<MCSUP>
        end
    end
    
    methods (Access = protected)
        function performDraw(obj)
            if obj.needToUpdateVertexBuffer
                obj.updateVertexBuffer();
            end
            
            if obj.needToUpdateTexture
                obj.updateTexture();
            end
            
            modelView = obj.canvas.modelView;
            modelView.push();
            modelView.translate(obj.position(1), obj.position(2), obj.position(3));
            modelView.rotate(obj.orientation, 0, 0, -1);
            modelView.rotate(obj.azimuth, 0, 1, 0);
            modelView.rotate(obj.elevation, -1, 0, 0);
            modelView.scale(obj.radius, obj.radius, obj.radius); %x,y,z
            
            c = obj.color;
            if length(c) == 1
                c = [c, c, c, obj.opacity];
            elseif length(c) == 3
                c = [c, obj.opacity];
            end
            
            % STRIDE here is 4 * (obj.numSteps)*(obj.numSteps)
            %   4 vertices defined in each iteration above. Do that for
            %   each phi (numSteps) and theta (numSteps)
            obj.canvas.drawArray(obj.vao, GL.TRIANGLE_STRIP, 0, 4*(obj.numSteps)*(obj.numSteps), c, [], obj.texture);
            
            modelView.pop();
        end
    end
    
    methods (Access = private)

        function updateVertexBuffer(obj)
            segmentExtent = rad2deg(obj.thetaLimits(2) - obj.thetaLimits(1));
            
            %multiplier on texture coords, how many repeats of grating?
            nCycles = obj.spatialFreq * segmentExtent; 

            phaseShift = obj.phase / 360; % normalize to texture coords [0,1]
            
            obj.getVertexData(phaseShift,0,nCycles);
            vertexData = obj.vertexData;
            
            obj.vbo.uploadData(single(vertexData));

            obj.needToUpdateVertexBuffer = false;
        end

        function updateTexture(obj)
            switch obj.profile
                case 'sine'
                    wave = sin(linspace(0, 2*pi, obj.resolution));
                case 'square'
                    wave = sin(linspace(0, 2*pi, obj.resolution));
                    wave(wave >= 0) = 1;
                    wave(wave < 0) = -1;
                case 'sawtooth'
                    wave = linspace(-1, 1, obj.resolution);
            end
            
            wave = wave * obj.contrast;
            wave = (wave + 1) / 2 * 255;
            
            image = ones(1, obj.resolution, 4, 'uint8') * 255;
            image(:, :, 1:3) = [wave; wave; wave]';
            
            obj.texture.setSubImage(image);
            
            obj.needToUpdateTexture = false;

        end

    end
    
end