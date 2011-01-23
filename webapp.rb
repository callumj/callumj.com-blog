$adminCheck = KeyManager.new(File.dirname(__FILE__) + "/keys.txt")

#Filters
before do  
  #Check admin pages
  if /^\/admin/.match(request.path_info) && request.path_info != "/admin.css"
    @adminVal = $adminCheck.getValue(params[:admin_key])
    if @adminVal == nil
      puts "User attempted to access admin page, with key: '#{params[:admin_key]}'"
      redirect "/error"
    else
      @adminMode = true
      puts "User granted access to admin page, with key: '#{params[:admin_key]}'"
    end
  end
end


#Basic pages
get '/' do
  params[:page_num] = 1
  @posts = Post.all(:limit => 10, :order => 'created_at DESC', :conditions => {:hidden => [false, nil]})
  erb :index
end

get '/page/:page_num' do
  offset = (params[:page_num].to_i * 10) - 10
  offset = 0 if (offset < 0)
  @posts = Post.all(:limit => 10, :offset => offset, :order => 'created_at DESC', :conditions => {:hidden => [false, nil]})
  if (@posts.size == 0)
    redirect "/page/#{params[:page_num].to_i - 1}"
  else
    erb :index
  end
end

get '/tag/:tag' do
  params[:page_num] = 1
  @posts = Post.all(:tags => params[:tag], :limit => 10)
  erb :index
end

get '/tag/:tag/page/:page' do
  offset = (params[:page_num].to_i * 10) - 10
  offset = 0 if (offset < 0)
  @posts = Post.all(:tags => params[:tag], :limit => 10, :offset => offset)
  
  if (@posts.size == 0)
    redirect "/tag/#{params[:tag]}/page/#{params[:page_num].to_i - 1}"
  else
    erb :index
  end
end

get '/post/:ref.html' do
  puts params[:ref]
  @post = Post.first(:conditions => {:ref => params[:ref]})
  redirect '/404' if @post == nil
    
  erb :post
end

get '/error' do
  erb :error
end

#User actions

post '/add_comment' do
  targetRef = params[:post]
  postAuthor = params[:author].gsub(/<\/?[^>]*>/, "")
  postContent = params[:content].gsub(/<\/?[^>]*>/, "")
  ipAddr = @env['REMOTE_ADDR']
  
  targetObject = Post.first(:conditions => {:ref => targetRef})
  
  if targetObject != nil && params[:message] == "..." && postContent != nil && postContent != "" && postAuthor != nil && postAuthor != "" && targetObject.commentsAllowed != false
    targetObject.comments << Comment.new(:author => postAuthor, :content => postContent, :address => ipAddr, :created_at => Time.now)
    targetObject.save
  end
    redirect "/post/#{targetRef}.html"
  
    
end


#Admin actions
get '/admin/new_post' do
  @postIsHidden = false
  
  erb :admin_new_post
end

get '/admin' do
  erb :admin_welcome
end

get '/admin/list_posts' do
  @allPosts = Post.all(:order => 'created_at DESC')
  
  erb :admin_list
end

get '/admin/delete/:ref' do
  targetPost = Post.first(:conditions => {:ref => params[:ref]})
  if targetPost != nil
    targetPost.destroy
  end
  
  redirect "/admin?admin_key=#{params[:admin_key]}"
end

get '/admin/edit/:ref' do
  @post = Post.first(:conditions => {:ref => params[:ref]})
  redirect "/admin/list_posts?admin_key=#{params[:admin_key]}" if @post == nil
  @postIsHidden = @post.hidden
  
  erb :admin_new_post
end

post '/admin/post_submit' do
  postRef = params[:ref_name]
  postTitle = params[:title]
  postTags = params[:tags]
  postBody = params[:body]
  postHiddenBool = params[:hidden]
  
  tagCol = []
  
  postTags.split(",").each {|val| tagCol << val.sub(/^\s/, "")}
  
  #update exisiting reference or create new
  lookup = Post.first(:conditions => {:ref => postRef})
  if lookup == nil
    lookup = Post.new 
    lookup.created_at = Time.new
  end
  
  lookup.title = postTitle
  lookup.content = params[:body]
  lookup.rendered_content = RedCloth.new(params[:body]).to_html
  lookup.tags = tagCol
  lookup.ref = postRef
  lookup.hidden = postHiddenBool.eql? "true"

  lookup.save
  
  redirect '/'
end


#Config directives
not_found do
  redirect '/error'
end

error do
  redirect '/error'
end

#RSS services
get '/rss.xml' do
  collection = Post.all(:limit => 30)
  collection = [] if collection == nil
  createRSS(collection)
end

get '/tag/:value/rss.xml' do
  collection = Post.all(:tags => params[:tag])
  collection = [] if collection == nil
  createRSS(collection)
end

def createRSS(fromPostArray)
  doc = LibXML::XML::Document.new()
  doc.root = LibXML::XML::Node.new('rss')
  root = doc.root
  
  
  root << channelElement = LibXML::XML::Node.new('channel')
  
  channelElement << titleElement = LibXML::XML::Node.new('title')
  titleElement << "the callumj internet website"
  
  channelElement << descriptionElement = LibXML::XML::Node.new('description')
  descriptionElement << "the website by callum jones"
  
  channelElement << linkElement = LibXML::XML::Node.new('link')
  linkElement << "http://callumj.com/"
  
  fromPostArray.each do |post|
    channelElement << itemContainer = LibXML::XML::Node.new('item')
    
    itemContainer << titleElement = LibXML::XML::Node.new('title')
    titleElement << post.title

    itemContainer << descriptionElement = LibXML::XML::Node.new('description')
    descriptionElement << LibXML::XML::Node.new_cdata(RedCloth.new(post.content).to_html)

    itemContainer << pubDateElement = LibXML::XML::Node.new('pubDate')
    pubDateElement << Time.at(post.created_at.to_i).rfc822()
    
    itemContainer << guidElement = LibXML::XML::Node.new('guid')
    guidElement << "http://callumj.com/post/#{post.ref}.html"
    
    itemContainer << linkElement = LibXML::XML::Node.new('link')
    linkElement << "http://callumj.com/post/#{post.ref}.html"
  end
  
  doc.to_s(:indent => true)
end
