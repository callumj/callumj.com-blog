class Comment
  include MongoMapper::EmbeddedDocument
  
  key :created_at, Time
  key :address, String
  key :content, String
  key :author, String
end

class Post
  include MongoMapper::Document
  
  key :title, String
  key :content, String
  key :rendered_content, String
  key :created_at, Time
  key :updated_at, Time
  key :ref, String, :index => true
  key :tags, Array, :index => true
  key :hidden, Boolean
  key :commentsAllowed, Boolean
  
  many :comments
end