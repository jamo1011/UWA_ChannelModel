clear;
clc;

%% Parameters
fileName = 'beach.stl';
rxLoc = [5; 0; -.5];
tx_z = -.2;
txLim_x = [-10, 10];
txLim_y = [5, 5];

fs = 50000; % Hz
c = 1500;  % m/s
ifftLen = 1024;
f = linspace(0, fs/2, ifftLen/2+1);


%% Initialize
% Create figure and read stl
figure
subplot(2,2,[1,3])
view(3)
trisurf(stlread('surface.stl'), 'FaceAlpha', 0.3, 'EdgeColor', 'none', 'FaceColor', 'b');
hold on; axis equal; axis off; grid off; 
trisurf(stlread('ground.stl'), 'EdgeColor', 'none', 'FaceColor', [0.585, 0.293, 0]);
xlabel('x'); ylabel('y'); zlabel('z');

% Create transmitter and receiver
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
for X = linspace(txLim_x(1), txLim_x(2), 100)
    for Y = linspace(txLim_y(1), txLim_y(2), 1)
        subplot(2,2,[1,3])
        tx = txsite("cartesian",  "AntennaPosition", [X; Y; tx_z],"TransmitterFrequency", 2.8e9);
        tx_plot.XData = X;
        tx_plot.YData = Y;
        
        % Traces rays
        rays = raytrace(tx, rx, pm, 'Map', 'beach.stl');
        rays = rays{1};

        H = zeros(1, length(f));
        lines = [];
        for i = 1:length(rays)
            if rays(i).LineOfSight
                propPath = [rays(i).TransmitterLocation, rays(i).ReceiverLocation];
            else
                propPath = [rays(i).TransmitterLocation, rays(i).ReflectionLocations, rays(i).ReceiverLocation];
            end
    
            % Plot rays
            color = map(ceil((rays(i).PropagationDistance - minn)/(maxx-minn)*size(map,1)),:);
            lines(i) = line(propPath(1,:), propPath(2,:), propPath(3,:), 'Color', color);
        
            % Calculate frequency and impulse response
            % Path loss
            A = 1;
            
            % Bottom reflections
            B = 1;
            
            % Surface reflections
            S = (-1)^rays(i).NumReflections;
            
            % Phase shift
            t = rays(i).PropagationDistance / c;
            theta = exp(-1j*2*pi*f*t);
            
            H_ray = A .* B .* S .* theta;
            H = H + H_ray;
        end
        
        subplot(2,2,2)
        % add complex conjugate to H
        H(end) = sqrt(H(end) * conj(H(end)));
        H = [H, conj(H(end-1:-1:2))];
        plot(abs(H))
        
        subplot(2,2,4)
        impulseResponse = ifft(H);
        plot(impulseResponse);
        pause(.01)
        
        delete(lines(:));
    end
end
