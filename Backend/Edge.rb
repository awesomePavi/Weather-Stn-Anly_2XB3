require './station'
require 'set'

=begin
Edge takes in two nodes and calculates:
  - weather the two nodes are within tolerance of each other using rain and temperature and accounting for days accuracy
  - calcualtes the length of the edge using longitudes and latitudes, and the circumfrence of the earth

=end

class Edge
  #tolerances whcih are static and set externally
  @percipTolerance=0;
  @tempTolerance=0;
  @daysAccuracy=0;


=begin
  sets the tolerances from values parsed by server
=end
  def self.setTolerances(rain,temp,days)
    @percipTolerance = rain;
    @tempTolerance = temp;
    @daysAccuracy = days;
  end

=begin
 takes in two nodes and calulates weateher the stations can predict each other and the length of the edge
=end
  def initialize(node1, node2)
    @s1=node1
    @s2=node2

    #calculate length
    @length = Edge.distanceCalc(@s1,@s2)
  end

=begin
  Determines which station has less days of data and returns the length of that station
=end
  def self.getLength(val1,val2)
    if (val2.length<val1.length)
      return val2.length;
    else
      return val1.length;
    end
  end

=begin
  This function using longitude and latitude as well as the circumfrence OF the earth,
  using HAVERSINE formula
=end
  def self.distanceCalc(s1, s2)
    radiusEarth=6371000;
    x1 = s1.location.longitude*(Math::PI/180.0)
    x2 = s2.location.longitude*(Math::PI/180.0)
    y1 = s1.location.latitude*(Math::PI/180.0)
    y2 = s2.location.latitude*(Math::PI/180.0)
    deltaX = x1-x2
    deltaY=y1-y2
    #haversine formula
    a = Math.sin(deltaX/2.0) * Math.sin(deltaX/2.0) + Math.cos(x1) * Math.cos(x2) * Math.sin(deltaY/2.0)* Math.sin(deltaY/2.0)
    circumfrence = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1.0-a))

    return radiusEarth * circumfrence
  end

=begin
  checks if the temperature is wihtin tolerance for the days of accuracy and returns a boolean
=end
  def self.checkTempTolerance(val1, val2)
    # the number of days in tolerance
    tmpVals=0.0;
    # the number of days of data to be parsed
    leng=Edge.getLength(val1,val2)
    # for all the days
    for i in 0..(leng-1)
      # if the two stations are in tolerance
      if (Edge.withinTolerance(val1[i].t_max, val2[i].t_max,   @tempTolerance) && Edge.withinTolerance(val1[i].t_min, val2[i].t_min,   @tempTolerance))
        tmpVals=tmpVals+1
      end
    end
    #if the number of days in tolerance + the accuracy is greater then ot equal to the numer of days the station passes
    return (tmpVals+ @daysAccuracy)>=leng
  end

=begin
  Checks if the percipatation accuracy is wihihin toleracne for the two stations
=end
  def self.checkRainTolerance(val1, val2)
    # the number of days in tolerance
    tmpVals=0.0;
    # the number of days of data to be parsed
    leng=Edge.getLength(val1,val2)
    # for all the days
    for i in 0..(leng-1)
      # if the two stations are in tolerance
      if (Edge.withinTolerance(val1[i].precipitation, val2[i].precipitation,  @percipTolerance))
        tmpVals=tmpVals+1
      end
    end
    #if the number of days in tolerance + the accuracy is greater then ot equal to the numer of days the station passes
    return (tmpVals+  @daysAccuracy)>=leng
  end

=begin
  the boolean which calculates the tolerance of any two articualr peices of data
=end
  def self.withinTolerance(val1, val2, tolerance)
    # if neither piece of data exist it is not in toleracne
    if (!val1 or !val2)
      return false;
    end
    #if oen vlaue is greater then the oter then subtract one way
    if (val1>val2)
      return (val1-val2)<=tolerance
    end
    #else subtract the other way
    return (val2-val1)<=tolerance
  end

=begin
  Checks if the edge nodes can be sued to predict each other
=end
  def is_related?()
    return (Edge.checkTempTolerance(@s1.weather, @s2.weather) and Edge.checkRainTolerance(@s1.weather, @s2.weather))
  end

=begin
  Checks if the edge nodes can be sued to predict each other
=end
  def self.is_related?(s1,s2)
    return (Edge.checkTempTolerance(s1.weather, s2.weather) and Edge.checkRainTolerance(s1.weather, s2.weather))
  end

=begin
  getter for the nodes in the edge object
=end
  def nodes()
    return @s1, @s2
  end

=begin
  getter for the length of the edge
=end
  def distance()
    return @length
  end

=begin
  greater then or equal function made specfically fro comparisons for minPQ
=end
  def >= (other)
    #compares by edge length
    return @length>=other.distance()
  end


  def cross(other)
    if other.is_a? Edge
      #Other
      oa, ob = other.nodes
      x1o, y1o, x2o, y2o = oa.lon, oa.lat, ob.lon, ob.lat
      mo = (y2o - y1o)/(x2o - x1o)
      bo = y1o - mo * x1o


      # Self
      sa, sb = self.nodes
      x1s, y1s, x2s, y2s = sa.lon, sa.lat, sb.lon, sb.lat
      ms = (y2s - y1s)/(x2s - x1s)
      bs = y1s - ms * x1s

      #Equation
      x = (bo - bs) / (ms - mo)
      y = ms * x + bs

      #Cross?
      if sa.lon > sb.lon
        x_max, x_min = sa.lon, sb.lon
      else
        x_max, x_min = sb.lon, sa.lon
      end

      if sa.lat > sb.lat
        y_max, y_min = sa.lat, sb.lon
      else
        y_max, y_min = sb.lat, sa.lon
      end

      # t = 1
      if ((x < x_max) and not x.near? x_max) and
          ((x > x_min) and not x.near? x_min) and
          ((y < y_max) and not y.near? y_max) and
          ((y > y_min) and not y.near? y_min)
        return true
      else
        return false
      end
      # if (x < x_max - t) and (x > x_min + t) and (y < y_max - t) and (y > y_min + t)
      #   return true
      # else
      #   return false
      # end
    else
      other.each do |e|
        if self.cross e
          return true
        end
      end
      return false
    end
  end

  def reverse
    return Edge.new @s2, @s1
  end

  def eql? other
    self.class == other.class && self.state == other.state
  end

  def hash
    @s1.hash + @s2.hash
  end


  def state
    self.instance_variables.map { |variable| self.instance_variable_get variable }
  end

  def to_s
    @s1.location.latitude.to_s + "," + @s1.location.longitude.to_s + "," + @s2.location.latitude.to_s  + "," + @s2.location.longitude.to_s
  end
end

class Float
  def near? other, epsilon = 1e-6
    (self - other).abs < epsilon.to_f
  end
end


# tmp = Edge.new(Station.new(1, 1, 1, 0, 0), Station.new(1, 1, 1, 10, 10), 0)
# tmp2 = Edge.new(Station.new(1, 1, 1, 10, 0), Station.new(1, 1, 1, 0, 0), 0)
# tmp3 = Edge.new(Station.new(1, 1, 1, 5, 0), Station.new(1, 1, 1, 0, 0), 0)
# hi = Set.new()
# hi.add(tmp2)
# hi.add(tmp3)
# print tmp.cross(Set.new())
# print tmp.cross(hi)
# puts "over"

# e1 = Edge.new((Station.new 0, 0, 0, 38.28, -119.61), (Station.new 0, 0, 0, 36.9111,-119.305), 0)
# e2 = Edge.new((Station.new 0, 0, 0, 38.07,-119.23), (Station.new 0, 0, 0, 37.25028,-119.70528), 0)
# puts e1.cross e2
