classdef Grating < turner.stimuli.PerspectiveSphere
    properties
        contrast = 1            % Scale factor for color values (-1 to 1, negative values invert the grating)
        size = [100, 100]       % Size [width, height] (pixels)
        phase = 0               % Phase offset (degrees)
        spatialFreq = 1/100     % Spatial frequency (cycles/pixels)
    end
    properties (Access = private)
        profile                     % Luminance profile wave ('sine', 'square', or 'sawtooth')
        resolution                  % Texture resolution
        minFunction                 % Texture minifying function
        magFunction                 % Texture magnification function
        wrapModeS                   % Wrap mode for texture coordinate s (i.e. x)
        wrapModeT                   % Wrap mode for texture coordinate t (i.e. y)
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
                
                obj.minFunction = GL.LINEAR_MIPMAP_LINEAR;
                obj.magFunction = GL.LINEAR;
                obj.wrapModeS = GL.REPEAT;
                obj.wrapModeT = GL.REPEAT;
        end
        
       function setMinFunction(obj, func)
            % Sets the OpenGL minifying function for the image (GL.NEAREST, GL.LINEAR, GL.NEAREST_MIPMAP_NEAREST, etc).
            obj.minFunction = func;
        end
        
        function setMagFunction(obj, func)
            % Sets the OpenGL magnifying function for the image (GL.NEAREST or GL.LINEAR).
            obj.magFunction = func;
        end
        
        function setWrapModeS(obj, mode)
            % Sets the OpenGL S (i.e. X) coordinate wrap mode for the image (GL.CLAMP_TO_EDGE, GL.MIRRORED_REPEAT, GL.REPEAT, etc).
            obj.wrapModeS = mode;
        end
        
        function setWrapModeT(obj, mode)
            % Sets the OpenGL T (i.e. Y) coordinate wrap mode for the image (GL.CLAMP_TO_EDGE, GL.MIRRORED_REPEAT, GL.REPEAT, etc).
            obj.wrapModeT = mode;
        end

        
        function init(obj, canvas)
            init@turner.stimuli.PerspectiveSphere(obj, canvas);

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
            modelView.rotate(obj.orientation, 0, 0, 1);
            modelView.rotate(obj.angularPosition, 0, -1, 0);
            modelView.scale(obj.radius, obj.height, obj.radius); %x,y,z
            
            c = obj.color;
            if length(c) == 1
                c = [c, c, c, obj.opacity];
            elseif length(c) == 3
                c = [c, obj.opacity];
            end
            
            % STRIDE here is 4 * (obj.numSides+1)*(obj.numSides+2)
            %   4 vertices defined in each iteration above. Do that for
            %   each phi (numSides+1) and theta ((numSides+2) because of
            %   wrap-around)
            obj.canvas.drawArray(obj.vao, GL.TRIANGLE_STRIP, 0, 4*(obj.numSides+1)*(obj.numSides+2), c, [], obj.texture);
            
            modelView.pop();
        end
    end
    
    methods (Access = private)

        function updateVertexBuffer(obj)
            nCycles = obj.size(1) * obj.spatialFreq;
            shiftX = obj.phase / 360;
            shiftY = obj.phase / 360;
            
            obj.getVertexData(shiftX,shiftY);
            vertexData = obj.vertexData;
            
            obj.vbo.uploadData(single(vertexData));

            obj.needToUpdateVertexBuffer = false;
        end

        

        function updateTexture(obj)
% %             switch obj.profile
% %                 case 'sine'
% %                     wave = sin(linspace(0, 2*pi, obj.resolution));
% %                 case 'square'
% %                     wave = sin(linspace(0, 2*pi, obj.resolution));
% %                     wave(wave >= 0) = 1;
% %                     wave(wave < 0) = -1;
% %                 case 'sawtooth'
% %                     wave = linspace(-1, 1, obj.resolution);
% %             end
% %             
% %             wave = wave * obj.contrast;
% %             wave = (wave + 1) / 2 * 255;
            
            wave = sin(30*linspace(0, 2*pi, 512));
            wave(wave >= 0) = 1;
            wave(wave < 0) = -1;

            wave = wave * 0.9;
            wave = (wave + 1) / 2 * 255;

            image = ones(1, 512, 4, 'uint8') * 255;
            image(:, :, 1:3) = [wave; wave; wave]';
            obj.texture.setImage(image);
            
            
            % 
%             image = ones(1, obj.resolution, 4, 'uint8') * 255;
%             image(:, :, 1:3) = [wave; wave; wave]';
% 
%             obj.texture.setImage(image);
% 
%             obj.needToUpdateTexture = false;
            
            
            
            
            obj.texture.setWrapModeS(obj.wrapModeS);
            obj.texture.setWrapModeT(obj.wrapModeT);
            obj.texture.setMinFunction(obj.minFunction);
            obj.texture.setMagFunction(obj.magFunction);
%             
%                 minFunc = obj.minFunction;
%             if minFunc == GL.LINEAR_MIPMAP_LINEAR ...
%                 || minFunc == GL.LINEAR_MIPMAP_NEAREST ...
%                 || minFunc == GL.NEAREST_MIPMAP_NEAREST ...
%                 || minFunc == GL.NEAREST_MIPMAP_LINEAR ...
% 
%                 obj.texture.generateMipmap();
%             end
%             
%             
%             
            


        end

    end
    
    
end