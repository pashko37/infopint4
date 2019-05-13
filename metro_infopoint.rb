require 'yaml'

class MetroInfopoint
  def initialize(path_to_timing_file:'', path_to_lines_file:'')
    path_to_lines_file = path_to_lines_file != '' ? path_to_lines_file : File.join(Dir.pwd, 'config', "config.yml")
    path_to_timing_file = path_to_timing_file != '' ? path_to_timing_file : File.join(Dir.pwd, 'config', "timing4.yml")
    @timing_data = YAML.load_file(path_to_timing_file)['timing']

    @nodes = []
    @connections = {}
    @routes = {}
    @timing_data.each do |route|
      start_station = route["start"].to_s
      end_station = route["end"].to_s
      @nodes << start_station
      @nodes << end_station
      @connections[start_station] ||= []
      @connections[end_station] ||= []
      @connections[start_station] << end_station
      @connections[end_station] << start_station
      route["connections"] ||= []
      route["connections"] << end_station
      route["connections"] << start_station
      @routes["#{start_station}_#{end_station}"] = route
      @routes["#{end_station}_#{start_station}"] = route
    end
    # p @connections
    @nodes = @nodes.uniq

  end

  def calculate(from_station:, to_station:)

    { price: calculate_price(from_station: from_station, to_station: to_station),
      time: calculate_time(from_station: from_station, to_station: to_station) }
  end

  def calculate_price(from_station:, to_station:)

    _build_routes( from_station.to_s, to_station.to_s, "price"  )
  end

  def calculate_time(from_station:, to_station:)

    _build_routes( from_station.to_s, to_station.to_s, "time"  )
  end

  def _build_routes( from_station, to_station, type )
    unchecked_routes = @nodes
    distances = {}
    @previous = {}
    @nodes.each do |station|
      distances[station] = Float::INFINITY
      @previous[station] = -1
    end
    distances[from_station] = 0

    until unchecked_routes.empty?
      closest_station = unchecked_routes.min_by{|s| distances[s] }
      break if distances[closest_station] == Float::INFINITY
      unchecked_routes -= [closest_station]
      @connections[closest_station].each do |neighbor|
        if unchecked_routes.include?(neighbor)
          alt = distances[closest_station] + @routes["#{closest_station}_#{neighbor}"]["time"]
          if (alt < distances[neighbor])
            distances[neighbor] = alt
            @previous[neighbor] = closest_station
          end
        end

      end

    end
    path = find_path(to_station.to_s)
    sym = 0
    path.each.with_index(1) do |station,index|
      sym += @routes["#{station}_#{path[index]}"][type] if path[index]
    end
    sym
  end


  def find_path(dest)
    @path = []
    if @previous[dest] != -1
      find_path @previous[dest]
    end
    @path << dest
  end


end

 m = MetroInfopoint.new
 p "input start station"
 a = gets.chomp()
 p "input finish station"
 b = gets.chomp()
 p m.calculate(from_station: a, to_station: b)
