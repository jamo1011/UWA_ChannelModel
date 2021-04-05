%% Parameters

fileName = 'beach.stl';
rxLoc = [5; 0; -.5];
tx_z = -.2;
txLim_x = [-10, 10];
txLim_y = [-10, 10];

%% Initialize
% Create figure and read stl
figure
subplot(1,2,1)
view(3)
trisurf(stlread('surface.stl'), 'FaceAlpha', 0.3, 'EdgeColor', 'none', 'FaceColor', 'b');
hold on; axis equal; axis off; grid off; 
trisurf(stlread('ground.stl'), 'EdgeColor', 'none', 'FaceColor', [0.585, 0.293, 0]);
xlabel('x'); ylabel('y'); zlabel('z');

% Create transmitter and receiver, raytrace
tx = txsite("cartesian",  "AntennaPosition", [-5; 9; -.2],"TransmitterFrequency", 2.8e9);
rx = rxsite("cartesian","AntennaPosition", rxLoc);
tx_plot = scatter3(tx.AntennaPosition(1,:), tx.AntennaPosition(2,:), tx.AntennaPosition(3,:), 50, 'r', 'filled');
scatter3(rx.AntennaPosition(1,:), rx.AntennaPosition(2,:),rx.AntennaPosition(3,:), 50, 'b', 'filled');
pm = propagationModel("raytracing","CoordinateSystem","cartesian", ...
"Method","sbr","MaxNumReflections",3,"SurfaceMaterial","wood");



%% Loop
maxx = 20;
minn = 0;
map = cool;
for X = linspace(txLim_x(1), txLim_x(2), 3)
    for Y = linspace(txLim_y(1), txLim_y(2), 3)
        tx = txsite("cartesian",  "AntennaPosition", [X; Y; tx_z],"TransmitterFrequency", 2.8e9);
        tx_plot.XData = X;
        tx_plot.YData = Y;
        
        % Traces rays
        rays = raytrace(tx, rx, pm, 'Map', 'beach.stl');
        rays = rays{1};

        for i = 1:length(rays)
            if rays(i).LineOfSight
                propPath = [rays(i).TransmitterLocation, rays(i).ReceiverLocation];
            else
                propPath = [rays(i).TransmitterLocation, rays(i).ReflectionLocations, rays(i).ReceiverLocation];
            end
    
            % Plot rays
            color = map(ceil((rays(i).PropagationDistance - minn)/(maxx-minn)*size(map,1)),:);
            lines = line(propPath(1,:), propPath(2,:), propPath(3,:), 'Color', color);
        
        end
        
        pause(.1)
        max([rays.PropagationDistance])
    end
end

%{
rays = raytrace(tx, rx, pm, 'Map', 'beach.stl');
rays = rays{1};

%% Plot rays
maxx = ceil(max([rays.PathLoss]));
minn = floor(min([rays.PathLoss]));
map = cool;
for i = 1:length(rays)
    if rays(i).LineOfSight
        propPath = [rays(i).TransmitterLocation, ...
        rays(i).ReceiverLocation];
    else
        propPath = [rays(i).TransmitterLocation, ...
        rays(i).ReflectionLocations, ...
        rays(i).ReceiverLocation];
    end
    
    % Choose color
    color = map(ceil((rays(i).PathLoss - minn)/(maxx-minn)*size(map,1)),:);
    
    % Plot rays
    line(propPath(1,:), propPath(2,:), propPath(3,:), 'Color', color);
    colormap(map)
    c = colorbar;
    c.TickLabels = linspace(minn, maxx, 6);
    c.Label.String = 'Path Loss (dB)';
end

%} 
