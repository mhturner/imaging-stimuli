presentation = stage.core.Presentation(4);
windowSize = [912, 1140]./2;
window = stage.core.Window(windowSize, false);
canvas = stage.core.Canvas(window);

%Set projection matrix
projection = stage.core.gl.MatrixStack();
projection.flyPerspective(windowSize);
canvas.setProjection(projection); %set perspective

%Ellipse stimulus
spot = clandininlab.stimuli.Ellipse();
% 
% checkerboardController = stage.builtin.controllers.PropertyController(spot, 'imageMatrix',...
%         @(state)clandininlab.utilities.getNewCheckerboard(boardSize,backgroundIntensity,noiseStdv,noiseStream));

% Frame tracker stimulus:
Tracker = clandininlab.stimuli.FrameTracker();

presentation.addStimulus(board);
% presentation.addController(checkerboardController);
presentation.addStimulus(Tracker);


presentation.play(canvas);

 