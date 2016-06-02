require 'sinatra'
require 'haml'
require 'prawn'
require 'aws-sdk'

get '/' do
  haml :home
end

post '/upload' do
  puts "/upload"
  filename = params[:file][:filename]
  tempfile = params[:file][:tempfile]
  target = "files/#{filename}"
  puts target
  File.open(target, 'wb') {|f| f.write tempfile.read }
  redirect "/list"
end

get '/list' do
  @files = Dir.glob("files/*.{jpg,gif}")
  haml :list
end

post '/save' do
  result = ""
  params[:files].each {|f| result += f.to_s}


  pdf = Prawn::Document.new

  params[:files].each do |f|
    title = f.to_s
    pdf.image title, :at => [50, 250], :width => 300, :height => 350
    pdf.start_new_page
  end

  if params[:file_name].include? ".pdf"
    name = params[:file_name]
  else
    name = params[:file_name] + ".pdf"
  end

  pdf.render_file "files/" + name

  upload("files/" + name)

  result
end

def upload(file)
  s3 = Aws::S3::Resource.new(region: 'eu-central-1')
  bucket = '166543-robson'
  name = File.basename file

  obj = s3.bucket(bucket).object(name)

  if obj.upload_file(file)
    puts "Uploaded #{file} to bucket #{bucket}"
  else
    puts "Could not upload #{file} to bucket #{bucket}!"
  end
end