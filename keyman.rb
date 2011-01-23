class KeyManager
  @permittedKeys = nil
  
  def initialize(filePath)
    if File.exists?(filePath)
      #read the file
        file = File.new(filePath, "r")
        @permittedKeys = {}
        while (line = file.gets)
            splitString = line.split("::")
            @permittedKeys[splitString[0]] = splitString[1] if splitString.length == 2
        end
        file.close
    else
      raise ArgumentError, "File not found"
    end
  end
  
  def getValue(key)
    return @permittedKeys[key]
  end
end