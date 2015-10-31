require 'sinatra'
require 'data_mapper'
require 'sinatra/flash'

enable :sessions

SITE_TITLE = "Recall"
SITE_DESCRIPTION = "'cause you're too busy to remember"

DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/recall.db")
 
class Note
  include DataMapper::Resource
  property :id, Serial
  property :content, Text, :required => true
  property :complete, Boolean, :required => true, :default => false
  property :created_at, DateTime
  property :updated_at, DateTime
end
 
DataMapper.auto_upgrade!

helpers do
    include Rack::Utils
    alias_method :h, :escape_html
end

#home page
get '/' do
  @notes = Note.all :order => :id.desc
  @title = 'All Notes'
  flash[:error] = 'No notes found. Add your first below.' if @notes.empty?
  erb :home
end

post '/' do
  n = Note.new
  n.content = params[:content]
  n.created_at = Time.now
  n.updated_at = Time.now
  n.save
  if n.save
    flash[:notice] = 'Note created successfully.'
  else
    flash[:error] = 'Failed to save note.'
  end
  redirect '/'
end

get '/rss.xml' do
    @notes = Note.all :order => :id.desc
    builder :rss
end

#Editing note
get '/:id' do
  @note = Note.get params[:id]
  @title = "Edit note ##{params[:id]}"
  if @note 
    erb :edit
  else
    flash[:error] = "Can't find that node"
    redirect '/'
  end
end

put '/:id' do
  n = Note.get params[:id]
  n.content = params[:content]
  n.complete = params[:complete] ? 1 : 0
  n.updated_at = Time.now
  if n.save
    flash[:notice] = 'Note updated successfully'
  else
    flash[:error] = 'Failed to save note'
  end
  redirect '/'
end

#Deleting note
get '/:id/delete' do
  @note = Note.get params[:id]
  @title = "Confirm deletion of note ##{params[:id]}"
  if @note
    erb :delete
  else 
    flash[:error] = "Can't find that node"
    redirect '/'
  end
end

delete '/:id' do
  n = Note.get params[:id]
  n.destroy
  redirect '/'
end

get '/:id/complete' do
  n = Note.get params[:id]
  flash[:error] = "Can't find that note" unless n
  n.complete = n.complete ? 0 : 1 # flip it
  n.updated_at = Time.now
  if n.save
    flash[:notice] = 'Note marked as complete'
  else
    flash[:error] = 'Error marking note as complete'
  end  
  redirect '/'
end