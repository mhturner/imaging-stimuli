classdef PerspectiveSphereOLD < stage.core.Stimulus
    % A 3D sphere stimulus. Made out of a triangle strip
    
    properties
        position = [0, 0, 0]    % Center position in 3D space [x, y, z]
        radius = 1              % Radius in x and z
        height = 1              % Radius in y
        angularPosition = 0     % degrees, horizontal
        orientation = 0         % degrees, vertical
        color = [1, 1, 1]
        opacity = 1
        imageMatrix
    end
    
    properties (SetAccess = private)
        numSides    % Number of side of the regular polygon base
    end
    
    properties (Access = private)
        minFunction                 % Texture minifying function
        magFunction                 % Texture magnification function
        wrapModeS                   % Wrap mode for texture coordinate s (i.e. x)
        wrapModeT                   % Wrap mode for texture coordinate t (i.e. y)
        vbo     % Vertex buffer object
        vao     % Vertex array object
        texture
    end
    
    methods
        
        function obj = PerspectiveSphere(numSides)
            % Constructs a 3D sphere stimulus with an optionally specified number of sides.
            if nargin < 1
                numSides = 101;
            end
            obj.numSides = numSides;
            obj.minFunction = GL.LINEAR_MIPMAP_LINEAR;
            obj.magFunction = GL.LINEAR;
            obj.wrapModeS = GL.REPEAT;
            obj.wrapModeT = GL.REPEAT;
        end
        
        function setImageMatrix(obj, matrix)
            if ~isa(matrix, 'uint8') && ~isa(matrix, 'single')
                error('Matrix must be of class uint8 or single');
            end
            obj.imageMatrix = matrix;
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
            init@stage.core.Stimulus(obj, canvas);
            % makes a sphere using a single, long triangle strip
            i = (0:obj.numSides)/obj.numSides;
            phi = i * 1 * pi;  %vertical angles (y)
            theta = i * 2 * pi; %horizontal angles  (x,z)
            
            phiStep = mean(diff(phi));
            thetaStep = mean(diff(theta));

            [PHI, THETA] = meshgrid([phi],[theta theta(1)]); %wrap around horizontally to prevent weird sawtooth artifact at edge
            phi = PHI(:);
            theta = THETA(:);

            stride = 24;
            vertexData = zeros(1, size(phi,1) * 6 * 4);
            vertexData(1:stride:end) = sin(theta) .* sin(phi); %x
            vertexData(2:stride:end) = cos(phi); %y
            vertexData(3:stride:end) = cos(theta) .* sin(phi); %z
            vertexData(4:stride:end) = 1; %?
            vertexData(5:stride:end) = theta / (2*pi); %texture U
            vertexData(6:stride:end) = phi / (2*pi); %texture V
            

            %next vertex: step on vertical angle (phi)
            vertexData(7:stride:end) = sin(theta) .* sin(phi+phiStep); %x
            vertexData(8:stride:end) = cos(phi+phiStep); %y
            vertexData(9:stride:end) = cos(theta) .* sin(phi+phiStep); %z
            vertexData(10:stride:end) = 1;
            vertexData(11:stride:end) = theta / (2*pi);
            vertexData(12:stride:end) = (phi + phiStep) / (2*pi);

            %next vertex: step on horizontal angle (theta)
            vertexData(13:stride:end) = sin(theta+thetaStep) .* sin(phi); %x
            vertexData(14:stride:end) = cos(phi); %y
            vertexData(15:stride:end) = cos(theta+thetaStep) .* sin(phi); %z
            vertexData(16:stride:end) = 1;
            vertexData(17:stride:end) = (theta+thetaStep) / (2*pi);
            vertexData(18:stride:end) = phi / (2*pi);

            %next vertex: step on theta & phi (diagonal)
            vertexData(19:stride:end) = sin(theta+thetaStep) .* sin(phi+phiStep); %x
            vertexData(20:stride:end) = cos(phi+phiStep); %y
            vertexData(21:stride:end) = cos(theta+thetaStep) .* sin(phi+phiStep); %z
            vertexData(22:stride:end) = 1;
            vertexData(23:stride:end) = (theta+thetaStep) / (2*pi);
            vertexData(24:stride:end) = (phi+phiStep) / (2*pi);

            obj.vbo = stage.core.gl.VertexBufferObject(canvas, GL.ARRAY_BUFFER, single(vertexData), GL.STATIC_DRAW);

            obj.vao = stage.core.gl.VertexArrayObject(canvas);
            obj.vao.setAttribute(obj.vbo, 0, 4, GL.FLOAT, GL.FALSE, 6*4, 0);
            obj.vao.setAttribute(obj.vbo, 1, 2, GL.FLOAT, GL.FALSE, 6*4, 4*4);
            
            image = obj.imageMatrix;
            if size(image, 3) == 1
                image = repmat(image, 1, 1, 3);
            end
            
            if ~isempty(image)
                obj.texture = stage.core.gl.TextureObject(canvas, 2);
                %IMAGE
                obj.texture.setImage(image);


%                 GRATING


%                 minFunc = obj.minFunction;
%                 if minFunc == GL.LINEAR_MIPMAP_LINEAR ...
%                     || minFunc == GL.LINEAR_MIPMAP_NEAREST ...
%                     || minFunc == GL.NEAREST_MIPMAP_NEAREST ...
%                     || minFunc == GL.NEAREST_MIPMAP_LINEAR ...
% 
%                     obj.texture.generateMipmap();
%                 end
            end
            

            
            
            
        end
        
    end
    
    methods (Access = protected)
        
        function performDraw(obj)
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
end

