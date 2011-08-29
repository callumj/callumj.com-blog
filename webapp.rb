enable :sessions

helpers do
  def protected!
    unless authorized?
      response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
      throw(:halt, [401, "Not authorized\n"])
    end
  end

  def authorized?
    @session = Session.where(:sec1 => session[:sec1], :sec2 => session[:sec2]).first
    
    if !(@session != nil && @session.session_valid?)
      @auth ||=  Rack::Auth::Basic::Request.new(request.env)
      if (@auth.provided? && @auth.basic? && @auth.credentials)
        username = @auth.credentials[0]
        password = @auth.credentials[1]
                
        @valid_user = User.where(:user_name => username, :hash_password => Digest::SHA1.hexdigest(password)).first
        if (@valid_user != nil)
          puts "#{@valid_user.display_name} logged on"
          @session = Session.new(:user => @valid_user)
          @session.build
          @session.save
          
          session[:sec1] = @session.sec1
          session[:sec2] = @session.sec2
        end
      end  
    end
    
    return (@session != nil && @session.session_valid?)
  end
end

before do
  @css_files = ["/style.css"]
  @js_files = []
  if request.path_info.start_with?("/admin")
    protected!
    @adminMode = true
    @css_files << "/admin.css"
    @js_files << "/jquery.js"
    @js_files << "/admin.js"
  end
end


#Basic pages
get '/' do
  params[:page_num] = 0
  @posts = Post.all(:limit => 10, :order => 'created_at DESC', :conditions => {:hidden => [false, nil]})
  erb :index
end

get '/page/:page_num' do
  redirect to("/") if params[:page_num].to_i == 0
  
  offset = (params[:page_num].to_i * 10) - 10
  offset = 0 if (offset < 0)
  @posts = Post.all(:limit => 10, :offset => offset, :order => 'created_at DESC', :conditions => {:hidden => [false, nil]})
  if (@posts.size == 0 && offset > 0)
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
  @js_files << "/upload.js"
  @postIsHidden = false
  
  erb :admin_new_post
end

get '/admin' do
  
  @all_users = User.all
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
  
  redirect "/admin"
end

get '/admin/edit/:ref' do
  @js_files << "/upload.js"
  @post = Post.first(:conditions => {:ref => params[:ref]})
  redirect "/admin/list_posts" if @post == nil
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
  
  postRef = postTitle.gsub(/\W+/,"-").downcase unless (postRef != nil && postRef.strip.length > 1)
  
  postTags.split(",").each {|val| tagCol << val.sub(/^\s/, "")}
  
  #update exisiting reference or create new
  lookup = Post.first(:conditions => {:ref => postRef})
  if lookup == nil
    lookup = Post.new 
    lookup.created_at = Time.new
  end
  
  lookup.title = postTitle
  lookup.content = params[:body]
  lookup.rendered_content = BlueCloth.new(params[:body]).to_html
  lookup.tags = tagCol
  lookup.ref = postRef
  lookup.hidden = postHiddenBool.eql? "true"
  lookup.updated_at = Time.new
  
  lookup.save
  
  redirect '/'
end

post '/admin/upload' do
  resp = {}
  unless params["file_upload"] != nil
    resp[:error => "File upload error"]
  end
  
  file = params["file_upload"]
  
  #resize if image
  is_image = false
  if (file[:type].match(/image[\/]*/) != nil)
    is_image = true
    img_data = Magick::Image.read(file[:tempfile].path)
    if (img_data.length > 0)
      img = img_data[0]
      img = img.resize_to_fit(400,400)
      img.write(file[:tempfile].path)
    end
  end
  
  path_name = "#{Digest::SHA1.hexdigest("#{file[:filename]}#{Time.now.to_i.to_s}")}#{File.extname(file[:filename])}"
  AWS::S3::S3Object.store(
      path_name,
      open(file[:tempfile]),
      $GLOBAL_CONFIG["s3"]["bucket"],
      :content_type => file[:type],
      :x_amz_acl => "public-read"
    )
  
  resp[:is_image] = is_image
  resp[:obj_url] = AWS::S3::S3Object.url_for(path_name, $GLOBAL_CONFIG["s3"]["bucket"]).gsub(/[?].*/,"")
  resp[:old_name] = file[:filename].gsub(File.extname(file[:filename]),"")
  
  content_type("json")
  resp.to_json
end

#User management
get '/admin/add_user' do
  @user = User.new
  
  erb :admin_user
end

get '/admin/edit_user/:user_name' do
  @user = User.where(:user_name => params[:user_name]).first
  
  erb :admin_user
end

post '/admin/submit_user' do
  prev_user_name = params[:prev_user_name].strip
  user_name = params[:user_name].strip_tags
  display_name = params[:display_name].strip_tags
  password = params[:password].strip
  
  target_user = nil
  
  if prev_user_name.empty?
    target_user = User.new
  else
    target_user = User.where(:user_name => prev_user_name).first
  end
  
  target_user.user_name = user_name
  target_user.display_name = display_name
  target_user.password = password if !password.empty?
  target_user.save
  
  redirect to('/admin')
end

get '/admin/delete_user/:user_name' do
  if User.count > 1
    @target = User.where(:user_name => params[:user_name]).first
    @target.delete if @target != nil
  end
  
  redirect to('/admin')
end


#Config directives
not_found do
  #see if have any custom mappings
  res = UrlMapper.instance.redirect_for(request.path_info)
  
  if (res != nil)
    redirect res
  else
    redirect '/error'
  end
end

error do
  redirect '/error'
end

#S3 services
get '/s3/:request' do
  #check for S3 object existence and redir
  url = AWS::S3::S3Object.url_for(params[:request], $GLOBAL_CONFIG["s3"]["bucket"])
  if (url != nil)
    redirect url.gsub(/[?].*/,"")
  else
    redirect "/"
  end
end

#RSS services
get '/rss.xml' do
  collection = Post.all(:limit => 30,:order => 'created_at DESC', :conditions => {:hidden => [false, nil]})
  collection = [] if collection == nil
  createRSS(collection)
end

get '/tag/:value/rss.xml' do
  collection = Post.all(:tags => params[:tag], :order => 'created_at DESC', :conditions => {:hidden => [false, nil]})
  collection = [] if collection == nil
  createRSS(collection)
end

def createRSS(fromPostArray)
  doc = LibXML::XML::Document.new()
  doc.root = LibXML::XML::Node.new('rss')
  root = doc.root
  
  
  root << channelElement = LibXML::XML::Node.new('channel')
  
  channelElement << titleElement = LibXML::XML::Node.new('title')
  titleElement << "callumj.com. an internet webpage"
  
  channelElement << descriptionElement = LibXML::XML::Node.new('description')
  descriptionElement << "the website by callum jones"
  
  channelElement << linkElement = LibXML::XML::Node.new('link')
  linkElement << "http://callumj.com/"
  
  fromPostArray.each do |post|
    channelElement << itemContainer = LibXML::XML::Node.new('item')
    
    itemContainer << titleElement = LibXML::XML::Node.new('title')
    titleElement << post.title

    itemContainer << descriptionElement = LibXML::XML::Node.new('description')
    descriptionElement << LibXML::XML::Node.new_cdata(post.rendered_content)

    itemContainer << pubDateElement = LibXML::XML::Node.new('pubDate')
    pubDateElement << Time.at(post.created_at.to_i).rfc822()
    
    itemContainer << guidElement = LibXML::XML::Node.new('guid')
    guidElement << "http://callumj.com/post/#{post.ref}.html"
    
    itemContainer << linkElement = LibXML::XML::Node.new('link')
    linkElement << "http://callumj.com/post/#{post.ref}.html"
  end
  
  doc.to_s(:indent => true)
end
