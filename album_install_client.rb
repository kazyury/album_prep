#!ruby -Ks

require 'fileutils'

class InstallServerError < StandardError; end
class InstallClient
  def initialize(dir,uri='druby://192.168.0.1:12345')
    usage unless dir 
    usage unless File.directory?(dir)
    @fromdir=dir
    @uploaddir='UploadWaiting'
    @upload_winpath=File.expand_path(@uploaddir).gsub(/\//,'\\')
    FileUtils.mkdir(@uploaddir) unless File.directory?(@uploaddir)
    @fake=false
  end

  def usage
    puts "ruby album_install_client.rb dir"
    puts "  dir is a digital camera data directory. (e.g.) F:\\DCIM\\100OLYMP"
    exit
  end

  def fake=(bool)
    @fake=bool
  end
  
  private
  def copy_from_camera
    puts "---> COPY FROM CAMERA"
    raise "BUG" unless File.directory?(@fromdir) or File.directory?(@uploaddir)
    files=Dir.entries(@fromdir)
    files.delete('.')
    files.delete('..')

    files.sort{|a,b| File.mtime(@fromdir+'\\'+a) <=> File.mtime(@fromdir+'\\'+b)}.each do |f|
      next if File.extname(f).downcase == '.thm' # サムネイル画像はスキップする。

      mtime = File.mtime(@fromdir+'\\'+f)
      filename = mtime.strftime("%Y%m%d") + "_" + mtime.strftime("%H%M%S") + File.extname(f).downcase

      puts "File copying #{@fromdir}/#{f} ---> #{@uploaddir}/#{filename}"
      FileUtils.cp(@fromdir+'\\'+f , @uploaddir+'\\'+filename) unless @fake
    end 
    puts "<--- END(COPY FROM CAMERA). Hit Enter to continue."
    $stdin.gets unless @fake
  end

  def generate_movies_firstframe
    puts "---> GENERATE FF JPEG"
    files=Dir.entries(@uploaddir)
    files.delete('.')
    files.delete('..')
    
    Dir.chdir(@uploaddir) do
      files.find_all{|f| /\.mov\Z/i=~f}.each do |f|
        puts "\n\nGenerating JPEG from movie's first frame using ffmpeg... #{@uploaddir}/#{f}"
        unless @fake
          system('C:\\home\\softwares\\ffmpeg\\ffmpeg -i '+f+' -f image2 -pix_fmt jpg -ss 1 -s 640x480 -an -y -vframes 1 ff'+File.basename(f,'.mov')+'.jpg')
        end
      end
      puts "Thanks ffmpeg !"
    end
    puts "<--- END(GENERATE FF JPEG). Hit Enter to continue."
    $stdin.gets unless @fake
  end

end

if __FILE__==$0
  require 'optparse'

	opt=OptionParser.new
	opt.banner ="album_install_client. \n"
	opt.banner+="[usage]\n"
	opt.banner+="album_install_client photopath \n"
	opt.banner+="                     -L photopath \n"
	opt.banner+="                     -S \n"
	opt.banner+="                     -c photopath \n"
	opt.banner+="                     [-r|-g|-s|-e] \n"
	opt.banner+="                     -f\n"
	opt.banner+="                     -h\n"
	opt.banner+="------------------------------------------------------------\n\n"

	opt_fake=false
  actions={
    :copy_from_camera=>false,
    :photo_resize=>false,
    :generate_movies_firstframe=>false,
    :send_contents=>false,
    :request_execution=>false
  }
  opt.on('-L','--Local',"Localの全処理を行う。") do |v|
    actions[:copy_from_camera]=true 
    actions[:generate_movies_firstframe]=true 
  end
	opt.on('-h','--help','Show this message.'){|v| puts opt ; exit }
	opt.on('-f','--fake','Do NOT process actually.'){|v| opt_fake=true }
	opt.parse!(ARGV)

  actions.each{|k,v| actions[k]=true} unless actions.any?{|k,v| v==true }
  if actions[:copy_from_camera] && (opt_fake==false)
    unless ARGV[0]
      puts opt
      exit
    end
    unless File.exist?(ARGV[0]) && File.directory?(ARGV[0])
      puts opt
      exit
    end
  end
  ARGV[0] ? photodir=ARGV[0] : photodir='.'

  client = InstallClient.new(photodir)
  client.fake=true if opt_fake
  client.send(:copy_from_camera)            if actions[:copy_from_camera]
  client.send(:generate_movies_firstframe)  if actions[:generate_movies_firstframe]

#InstallClient.new(ARGV[0]).run(:debug)

end
