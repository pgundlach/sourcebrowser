# sourcebrowser.rb

require "logger"
require 'fileutils'
require 'find'
require 'yaml'
require 'cgi'
require 'erb'

require 'pgpretty'

# read config.rb and if this is not there read config.rb.in
src=test(?f,"../lib/config.rb") ? "../lib/config.rb" : "../lib/config.rb.in"
eval(File.read(src))


class Sourcebrowser
  
  attr_accessor :path
  # _path_ is a String, representing the user's input, such as "/tex/context" or "/colo-ema.tex". 
  # _params_ is a '&' separated list of parameters, such as "foo=bar&baz=yes", as found in
  # cgi scripts/urls
	def initialize(path,params=nil)

	  @path = path[0] == ?/ ? path[1..-1] : path 	  # remove leading slash 
      
    @params=params
    
		@cmd={}
		
		init_logger

		# foo=bar&some=other => @cmd['foo']='bar', @cmd['some']='other':
		@params && @params.split('&').each { |x|
			key,value = x.split('=')
			@cmd[key]=value
		}

		# @search must be nil if no searching is done
		@search = @cmd['search'] ? CGI.unescape(@cmd['search']) : nil

		# /context -> dir
		# /tex/context/base/context.tex  -> file
		# /context.tex  -> file in ...

		@pretty_methods={
			".afm"  => :verbatim,
			".bat"  => :verbatim,
			".bst"  => :verbatim,
			".cnf"  => :metapost,
			".dat"  => :verbatim,
			".dtd"  => :xml,
			".enc"  => :verbatim,
			".fo"   => :xml,
			".gui"  => :verbatim,
			".hyp"  => :tex,
			".ini"  => :verbatim,
			".log"  => :verbatim,
			".lua"  => :verbatim,
			".map"  => :verbatim,
			".mkii" => :tex,
			".mkiv" => :tex,
			".mp"   => :metapost,
			".noc"  => :tex,
			".ori"  => :tex,
			".pat"  => :tex,
			".pl"   => :perl,
			".pm"   => :perl,
			".properties" => :verbatim,
			".rb"   => :ruby,
			".rlx"  => :xml,
			".rme"  => :tex,
			".rng"  => :xml,
			".sty"  => :tex,
			".tcx"  => :verbatim,
			".tex"  => :tex,
			".tpm"  => :xml,
			".txt"  => :verbatim,
			".tws"  => :verbatim,
			".xml"  => :xml,
			".xsd"  => :xml,
			".xsl"  => :xml
		}
		@pgp=PGPretty.new

		@files=get_filelist

		# we have serveral posibilities: 
		# the filepart can be 
		# a) a directory, such as "/bibtex"
		# b) a path pointing to a file, such as /tex/context/base/colo-ema.tex
		# c) a filename, such as /colo-ema.tex

		# fill the instance variables @destdir and @destfile based on the request
		if File.directory?(File.join(BASE,@path))
			@destdir  = @path
			@logger.debug "directory"
		elsif File.file?(File.join(BASE,@path))
			@destfile = File.basename(@path)
			@destdir  = File.dirname(@path)
			@logger.debug "file"
		elsif	@files.include?(@path)
			@destfile = @path
			@destdir  = File.dirname(@files[@destfile]).sub(/^#{BASE}\//,'')
			@logger.debug "indirect file"
		else
			# incorrect path, fnf
			@logger.debug "nonexistant"
		end
	end

	def out
		unless @destfile || @destdir
			@logger.info "---- unknown file"
			@source="Unknown file or directory: #{@path}"
		else
			if @destfile
				thisfile=File.join(BASE,@destdir,@destfile)
				@source=pretty(thisfile)
				@fileinfo="#{File.basename(thisfile)} / last modification: #{File.mtime(thisfile).strftime("%Y-%m-%d %H:%M")}"
			end
		end
		@navigation=create_navigation(BASE)
		template = ERB.new(File.read(File.join(File.dirname(__FILE__),"out.rhtml")))
		template.result(binding)
	end
	
	def pretty(file)
		ext=File.extname(file)
		if @pretty_methods.include? ext
			@pgp.source=File.read(file)
			start=Time.new
			ret = @pgp.send @pretty_methods[ext], @search, @cmd['igncomments']=="yes"
			@logger.info "pretty print in " + (Time.now - start).to_s + "secs"
			ret
		else
			"sorry, I don't know how to display the file"
		end
	end
	
	def create_navigation(directory)
		@destdir ||= BASE
		
		if @search
			@search.gsub!(/('|")/, "")
			cmdline="IFS=\"\" find #{BASE} -type f | grep -v '\\(tws\\|properties\\|mem\\|fmt\\)$' | xargs grep "
			if @cmd['igncomments']=='yes'
				cmdline << "-lxHr '[^%]*#{@search}.*'"
			else
				cmdline << "-lHr '#{@search}'"
			end

			@logger.info "cmdline:" + cmdline
			ret=""
			IO.popen(cmdline) { |io|	ret = io.readlines }
			if ret==""
				dirs = [] 
			else
				dirs=ret.collect { |line|
					line.chomp
				}
			end
		else
			dirs=build_dirstructure(directory)
		end
		create_html_navigation(dirs)
	end
		
	def create_html_navigation(dirs)
		tmp = "<ul>\n"
		dirs.collect do |dir|
			# dirs can be an entry or an Array
			case dir
			when Array
				tmp << create_html_navigation(dir)
			when String
				url = "/" + dir.sub(/^#{BASE}\//,'')
				url << "?#{@params}" if @search
				tmp << %{<li><a href="#{url}">#{File.basename(dir)}</a></li>\n}
			else
				raise
			end
		end
		return tmp << "</ul>\n"
	end
	
	# Create a directory structure that should be used 
	# in the navigation tree. @destdir must be set!
	def build_dirstructure(current_dir)
		ary = []
		Dir.entries(current_dir).sort.each do |entry| 
			next if [".","..","ls-R","cont-tmf.zip", "cont-en.fmt","cont-nl.fmt","metafun.mem"].include?(entry)
			absdir=File.join(current_dir,entry)
			ary << absdir
			if File.join(BASE,@destdir).include?(absdir) && File.directory?(absdir)
				ary << build_dirstructure(absdir) 
			end
		end
		return ary
	end
  
  private
  
  # initialize the logger
  def init_logger
		@logger=Logger.new(DEBUGFILE,3,1000000)
		#  @logger.level = Logger::INFO 
		@logger.level = Logger::DEBUG
		@logger.datetime_format = "%a %b %d %H:%M:%S"
		@logger.info "start logging"
	end
	
	# yamlfile is much faster then Find#find
	def get_filelist
		if FileUtils.uptodate?(FILECACHE, BASE)
			@logger.debug "reding filecache"
			return YAML::load(File.read(FILECACHE))
		else
			@logger.info "regenerate filecache"
			files={}
			Find.find(BASE) { |f|
				files[File.basename(f)]=f if File.file?(f)
			}
			File.open(FILECACHE,"w") { |file| file << files.to_yaml }
			return files
		end
	end

end
