classdef Image < clandininlab.stimuli.PerspectiveSphere
    properties
        shiftX = 0              % Texture shift (scroll) on the texture x axis (degrees on sphere [0,360])
        shiftY = 0              % Texture shift (scroll) on the texture y axis (degrees on sphere [0,360])
        imageMatrix             % Image data matrix (M-by-N grayscale, M-by-N-by-3 truecolor, M-by-N-by-4 truecolor with alpha)
    end
    properties (Access = private)
        minFunction                 % Texture minifying function
        magFunction                 % Texture magnification function
        wrapModeS                   % Wrap mode for texture coordinate s (i.e. x)
        wrapModeT                   % Wrap mode for texture coordinate t (i.e. y)
        needToUpdateVertexBuffer
        needToUpdateTexture
    end
    methods
        function obj = Image(matrix)
            % Image texture to paint on parent class
            % PerspectiveSphere
            % Constructs an image texture with the specified image matrix data. The image data must be provided as an
            % M-by-N (grayscale), M-by-N-by-3 (truecolor), or M-by-N-by-4 (truecolor with alpha) matrix.

            if ~isa(matrix, 'uint8') && ~isa(matrix, 'single')
                error('Matrix must be of class uint8 or single');
            end

            obj.imageMatrix = matrix;
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
            init@clandininlab.stimuli.PerspectiveSphere(obj, canvas);

            image = obj.imageMatrix;
            if size(image, 3) == 1
                image = repmat(image, 1, 1, 3);
            end

            obj.texture = stage.core.gl.TextureObject(canvas, 2);
            obj.texture.setWrapModeS(obj.wrapModeS);
            obj.texture.setWrapModeT(obj.wrapModeT);
            obj.texture.setMinFunction(obj.minFunction);
            obj.texture.setMagFunction(obj.magFunction);
            obj.texture.setImage(image);

            minFunc = obj.minFunction;
            if minFunc == GL.LINEAR_MIPMAP_LINEAR ...
                || minFunc == GL.LINEAR_MIPMAP_NEAREST ...
                || minFunc == GL.NEAREST_MIPMAP_NEAREST ...
                || minFunc == GL.NEAREST_MIPMAP_LINEAR ...

                obj.texture.generateMipmap();
            end

            obj.updateVertexBuffer();
        end
        
        function set.shiftX(obj, shiftX)
            obj.shiftX = shiftX;
            obj.needToUpdateVertexBuffer = true; %#ok<MCSUP>
        end

        function set.shiftY(obj, shiftY)
            obj.shiftY = shiftY;
            obj.needToUpdateVertexBuffer = true; %#ok<MCSUP>
        end
        
        function set.imageMatrix(obj, matrix)
            obj.imageMatrix = matrix;
            obj.needToUpdateTexture = true; %#ok<MCSUP>
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
            nCycles = 1; %wrap image around entire semi-sphere just once
            
            %Normalize ShiftX and Y (degrees of visual angle) by 360 to map to texture coordinates ([0,1])
            obj.getVertexData(obj.shiftX/360,obj.shiftY/360,nCycles);
            vertexData = obj.vertexData;
            
            obj.vbo.uploadData(single(vertexData));

            obj.needToUpdateVertexBuffer = false;
        end

        function updateTexture(obj)
            image = obj.imageMatrix;
            if size(image, 3) == 1
                image = repmat(image, 1, 1, 3);
            end

            obj.texture.setSubImage(image);

            minFunc = obj.minFunction;
            if minFunc == GL.LINEAR_MIPMAP_LINEAR ...
                || minFunc == GL.LINEAR_MIPMAP_NEAREST ...
                || minFunc == GL.NEAREST_MIPMAP_NEAREST ...
                || minFunc == GL.NEAREST_MIPMAP_LINEAR ...

                obj.texture.generateMipmap();
            end

            obj.needToUpdateTexture = false;

        end

    end
    
end