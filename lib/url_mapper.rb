class UrlMapper
  @@instance = nil
  attr_accessor :maps
  
  def initialize
    self.maps = Array.new
  end
  
  def redirect_for(src)
    self.maps.each do |map|
      redir = true
      if (map[:match].is_a? Regexp)
        if map[:dest].include?("*")
          match_data = map[:match].match(src)
          if (match_data != nil && match_data.size > 1)
	          map[:cust_dest] = map[:dest].gsub("*", match_data[1]) 
	        else
		        redir = false
		      end
        else
          redir = map[:match].match(src) != nil
        end
      elsif (map[:match].is_a? String)
        redir = map[:match].eql?(src)
      end
      if redir
        if (map[:cust_dest] != nil)
          return map[:cust_dest]
        else
          return map[:dest]
        end
      end
    end
    
    nil
  end
  
  def self.instance
    @@instance = self.new if @@instance == nil
    @@instance
  end
end

def urlmap(dest,src)
  UrlMapper.instance.maps << {:match => src, :dest => dest}
end