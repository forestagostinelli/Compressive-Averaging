function hf = plot_usa(f, names)
  hf = figure; ax = usamap('all');
  set(ax, 'Visible', 'off')
  states = shaperead('usastatelo', 'UseGeoCoords', true);
  state_names = {states.Name};
  cmap = colormap;
  for i = 1:length(f)
    name = names{i};
    index= strcmp(name, state_names);
    val = (f(i) - min(f)) / (max(f) - min(f));
    color = cmap(floor(val * (length(cmap)-1)) + 1, :);
    axes = 1;
    if strcmp(name, 'Alaska') == 1
      axes = 2;
    elseif strcmp(name, 'Hawaii') == 1
      axes = 3;
    end
    geoshow(ax(axes), states(index),  'FaceColor', color)
  end
  for k = 1:3
    setm(ax(k), 'Frame', 'off', 'Grid', 'off',...
      'ParallelLabel', 'off', 'MeridianLabel', 'off')
  end
end

