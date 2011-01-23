require File.dirname(__FILE__) + "/../dependencies.rb"

dir = "#{File.dirname(__FILE__)}/../post_store"
Dir.new(dir).each do |obj|
  if obj.match('[.]xml$') != nil
    puts "Looking at #{obj}"
    begin
      file = File.new("#{dir}/#{obj}", "r")
      container = ""
      while (line = file.gets)
        container << line
      end
      file.close
      xmlHash = Hash.from_xml(container)
      postObj = xmlHash["post"]
      tagObj = xmlHash["post"]["keywords"]
      if postObj != nil
        postInsertion = Post.new
        if postObj["title"].is_a? Array
          postInsertion.title = postObj["title"][1]
        else
          postInsertion.title = postObj["title"]
        end
        puts postInsertion.title
        postInsertion.ref = postObj["ref"]
        postInsertion.created_at = Time.at(postObj["date"].to_i)
        postInsertion.content = postObj["content"]
        postInsertion.hidden = true if postObj["hidden"] != nil && postObj["hidden"] == "true"
        postInsertion.commentsAllowed = false if postObj["comments"] != nil && postObj["comments"] == "false"
        tagObj.each do |tagInner|
          tagInner[1].each do |tag|
            postInsertion.tags << tag.strip
          end
        end
        postInsertion.save
      end
    rescue => err
      puts "Exception: #{err}"
    end
  end
end