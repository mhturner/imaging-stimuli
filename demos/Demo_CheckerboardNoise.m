presentation = stage.core.Presentation(4);
windowSize = [912, 1140]./2;
window = stage.core.Window(windowSize, false);
canvas = stage.core.Canvas(window);

%Set projection matrix
projection = stage.core.gl.MatrixStack();
projection.flyPerspective(windowSize);
canvas.setProjection(projection); %set perspective

%checkerboard stimulus
 %board aspect ratio is in line with semisphere aspect ratio
 phiLimits = [0.25*pi, 0.75*pi];
thetaLimits = [0.5*pi, 1.5*pi];
checkSize_deg = 20;
nChecksX = ceil(rad2deg(range(thetaLimits)) / checkSize_deg);
nChecksY = ceil(rad2deg(range(phiLimits)) / checkSize_deg);

newThetaRange = deg2rad(checkSize_deg * nChecksX);
newPhiRange = deg2rad(checkSize_deg * nChecksY);



ar = range(thetaLimits)/range(phiLimits);

boardSize = [nChecksY, nChecksY * ar];
backgroundIntensity = 0.5;
noiseStdv = 0.3;
noiseSeed = 2;
noiseStream = RandStream('mt19937ar', 'Seed', noiseSeed);

initMatrix = uint8(255.*(0.5 .* ones(boardSize)));
board = clandininlab.stimuli.Image(initMatrix);
board.setMinFunction(GL.NEAREST); %don't interpolate to scale up board
board.setMagFunction(GL.NEAREST);
board.position = [0, 0, 0];
board.phiLimits = phiLimits;
board.thetaLimits = thetaLimits;
board.opacity = 0.5;

checkerboardController = stage.builtin.controllers.PropertyController(board, 'imageMatrix',...
        @(state)clandininlab.utilities.getNewCheckerboard(boardSize,backgroundIntensity,noiseStdv,noiseStream));

% Frame tracker stimulus:
Tracker = clandininlab.stimuli.FrameTracker();

presentation.addStimulus(board);
presentation.addController(checkerboardController);
presentation.addStimulus(Tracker);


presentation.play(canvas);

 