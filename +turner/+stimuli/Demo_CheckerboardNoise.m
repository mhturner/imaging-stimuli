presentation = stage.core.Presentation(4);
windowSize = [800, 600];
window = stage.core.Window(windowSize, false);
canvas = turner.stage.Canvas(window, 'disableDwm', false);

%Set projection matrix
projection = turner.stage.MatrixStack();
projection.flyPerspective(windowSize);
canvas.setProjection(projection); %set perspective

%checkerboard stimulus
boardSize = [40, 40];
backgroundIntensity = 0.5;
noiseStdv = 0.3;
noiseSeed = 1;
noiseStream = RandStream('mt19937ar', 'Seed', noiseSeed);

initMatrix = uint8(255.*(0.5 .* ones(boardSize)));
board = turner.stimuli.Image(initMatrix);
board.setMinFunction(GL.NEAREST); %don't interpolate to scale up board
board.setMagFunction(GL.NEAREST);
board.position = [0, 0, 0];

checkerboardController = stage.builtin.controllers.PropertyController(board, 'imageMatrix',...
        @(state)turner.stimuli.getNewCheckerboard(boardSize,backgroundIntensity,noiseStdv,noiseStream));

% Frame tracker stimulus:
Tracker = turner.stimuli.FrameTracker();

presentation.addStimulus(board);
presentation.addController(checkerboardController);
presentation.addStimulus(Tracker);


presentation.play(canvas);

 