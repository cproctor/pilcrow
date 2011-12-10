require 'rubygems'
require 'sinatra'
require 'data_mapper'
require 'sqlite3'
require 'dm-sqlite-adapter'
require 'dm-postgres-adapter'
require 'json'
require 'rack-flash'

require 'haml'
require 'sass'
require "sinatra/authorization"

require 'openssl'
require 'net/http'
require 'uri'
require 'csv'

OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

#If on Heroku, uses Heroku database. 
DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/development.db")

class Book
  include DataMapper::Resource  
  property 		:id,           		Serial
	property		:isbn,				 		String,	:required => true, :unique => true
  property 		:title,        		Text
	property		:author1_first, 	String
	property		:author1_last,		String	
	property		:all_authors,			Text
	property		:subtitle, 		 		Text
	property		:publisher, 	 		Text
	property		:pub_date,		 		Date
	property		:img_url, 		 		Text
	property		:small_img_url,		Text
	property		:preview_link,		Text
	property 		:page_count, 			Integer
	belongs_to 	:dewey_class, 		:required => false
	
	def dewey100
		return nil unless dewey_class_number
		dewey_class_number / 100 * 100
	end
	
	def dewey10
		return nil unless dewey_class_number
		dewey_class_number / 10 * 10
	end
end

class DeweyClass
	include DataMapper::Resource 
	property		:number,				Integer, :key => true	
	property		:description,		String
	property		:granularity,		Integer
	has n,			:books	
	
	def full_description
		parent ? parent.full_description + " > " + description : description
	end
	
	def top_level_description
		parent ? parent.top_level_description : description
	end
	
	def parent
		if number % 10 == 0
			return number % 100 == 0 ? nil : DeweyClass.get(number / 100 * 100)
		else
			return DeweyClass.get(number / 10 * 10) || DeweyClass.get(number / 100 * 100)
		end
	end
end

class Settings
	include DataMapper::Resource 
	property :key_string, 		String, :key => true
	property :value,					Text
	
	def self.value_of(key_string)
		Settings.count(:key_string => key_string) > 0 ? Settings.first(:key_string => key_string).value : nil
	end	
end

DataMapper.auto_upgrade! 

require './seeds.rb' unless DeweyClass.any?

enable :sessions
use Rack::Flash

helpers do
	def get_book_data(isbn)
		uri_string = "https://www.googleapis.com/books/v1/volumes?q=isbn:#{isbn}&projection=lite"
		if Settings.value_of('api_key')
			uri_string = uri_string + "&key=" + Settings.value_of('api_key') 
		end
		uri = URI.parse(uri_string)
		request = Net::HTTP::Get.new(uri.request_uri)
		socket = Net::HTTP.new(uri.host, uri.port)
		socket.use_ssl = true
		
		#Only on Heroku
		socket.verify_mode = OpenSSL::SSL::VERIFY_PEER 
		socket.ca_file = '/usr/lib/ssl/certs/ca-certificates.crt'
		#----
		
		store = OpenSSL::X509::Store.new
		store.add_cert OpenSSL::X509::Certificate.new(File.new('certs/googleapis.pem'))
		socket.cert_store = store
		google_response = socket.request(request)
		JSON.parse(google_response.body)
	end
	
	def clean_up_date(date)
		if date =~ /\d{4}-\d{2}-\d{2}/
			return date
		elsif date =~ /(\d{4})-(\d{2})/
			return "#{$1}-#{$2}-01"
		elsif date =~ /(\d{4})/
			return "#{$1}-01-01"
		end
	end
	
	include Sinatra::Authorization
	
	def authorization_realm
		"pilcrow"
	end
	
	def authorize(login, password)
		if Settings.value_of('username') && Settings.value_of('password')
	  	return login == Settings.value_of('username') && password == Settings.value_of('password')
		else
			return true
		end
	end
end

#Index
['/', '/books'].each do |path|
	get path do
		@books = Book.all(:dewey_class_number.not => nil, :order => [:dewey_class_number.asc, :author1_last.asc, :author1_first.asc, :title.asc])
		flash.now[:alert] = "Go to <a href='/settings'>Settings</a> to configure this app." if Settings.count == 0
		haml :index
	end
end

#Index-unclassified
get '/books/unclassified' do
	@books = Book.all(:dewey_class_number => nil)
	haml :unclassified
end

#New
get '/books/new' do
	login_required
	haml :new
end

#Show
get '/books/:id' do
	@book = Book.get!(params[:id])
	haml :show
end

get '/lookup' do
	if @book = Book.first(:isbn => params[:isbn])
		redirect "/books/#{@book.id}"
	else
		flash[:alert] = "No book in the library has ISBN #{params[:isbn]}"
		redirect "/"
	end
end

#Create
post '/books' do
	login_required
	if temp = Book.first(:isbn => params[:isbn])
		flash[:alert] = "<strong>#{temp.title}</strong> is already in the library."
		redirect '/books/new'
	else
		begin
			book_data = get_book_data(params[:isbn])
			this_book = book_data['items'][0]['volumeInfo']
			if this_book['authors']
				author1_first = this_book['authors'][0].split(" ")[0..-2].join(" ")
				author1_last = this_book['authors'][0].split(" ")[-1]
				all_authors = this_book['authors'].join(', ')
			else
				author1_first = author1_last = ""
			end
			if this_book['imageLinks']
				img_url = this_book['imageLinks']['thumbnail']
				small_img_url = this_book['imageLinks']['smallThumbnail']
			else
				img_url = small_img_url = ""
			end
			@book = Book.new({ :isbn 					=> 	params[:isbn],
												:title 					=> 	this_book['title'],
												:subtitle 			=> 	this_book['subtitle'],
												:author1_first	=>	author1_first,
												:author1_last		=> 	author1_last,
												:all_authors		=> 	all_authors,
												:publisher			=> 	this_book['publisher'],
												:pub_date				=> 	clean_up_date(this_book['publishedDate']),
												:img_url				=> 	img_url,
												:small_img_url 	=>	small_img_url,
												:preview_link 	=> 	this_book['previewLink'], 
												:page_count			=>	this_book['pageCount']
											})
		rescue => e
			if book_data && book_data['kind'] == "books#volumes" && book_data['totalItems'] == 0
				flash[:alert] = "Sorry, couldn't find that ISBN. Try entering it again. Some old or cheap books aren't in the system. In that case, see if you can find a different edition on Amazon--the ISBN will be part of the Amazon URL, right after /dp/****."
			else
				flash[:alert] = "Sorry, something went wrong: #{e}<br><br>Google returned: #{book_data} (#{book_data['kind']}, #{book_data['totalItems']})"
			end
			redirect 'books/new'
		end
		if @book.save
			redirect "/books/#{@book.id}/edit"
		else
			flash[:alert]= "The following errors were reported: #{@book.errors.values.flatten.join(", ")}"
			redirect 'books/new'
		end
	end
end

#Edit
get '/books/:id/edit' do
	login_required
	@book = Book.get!(params[:id])
	@dewey100		= DeweyClass.all(:granularity => 100)
	@dewey10	 	= DeweyClass.all(:granularity => [100, 10])
	@dewey1 		= DeweyClass.all
	haml :edit
end

#Update
put '/books/:id' do
	login_required
	book = Book.get!(params[:id])
	book.dewey_class_number = params[:dewey1] || params[:dewey10] || params[:dewey100]
	book.save
	redirect Book.count(:dewey_class_number => nil) == 0 ? "/books/#{params[:id]}" : "/books/unclassified"
end

#upgrade!!!
get '/upgrade' do
	login_required
	Book.all.each do |book|
		book_data = get_book_data(book.isbn)
		this_book = book_data['items'][0]['volumeInfo']
		book.preview_link = this_book['previewLink']
		book.page_count	= this_book['pageCount']
		book.save
	end
	flash[:alert] = "Upgraded."
	redirect '/'
end

#Delete
get '/books/:id/delete' do
	login_required
	book = Book.get!(params[:id])
	book.destroy
	redirect Book.count(:dewey_class_number => nil) == 0 ? "/books" : "/books/unclassified"
end

# Settings
get '/settings' do
	login_required
	haml :settings
end

post '/settings' do
	login_required
	updated = []
	['username', 'password', 'api_key'].collect do |key_string|
		if params[key_string.to_sym] && !params[key_string.to_sym].empty?
			setting = Settings.first(:key_string => key_string) || Settings.new(:key_string => key_string)
			setting.value = params[key_string.to_sym]
			if setting.save
				updated << key_string
			end
		end
	end
	flash[:alert] = "Updated settings: #{updated.join(', ')}"	
	redirect '/settings'
end
	


