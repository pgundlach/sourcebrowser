# pgpretty - prettyprinter (html output) for several languages
require 'cgi'

# PGPretty outputs pretty printed html from the source that is given
# by the method initialize or by PGPretty#source=. 
class PGPretty
	# attr_accessor :source

	# Optional _source_ is the contents of the sourcefile that should be prettyprinted.
	def initialize(source="")
		self.source=source
	end
	# Alternative to give the class the source file
	def source=(source)
		@source  = CGI::escapeHTML(source)
	end
	
	def tex (search=nil,ignorecomments=false)
		tmp=""
		if search 
			@source=@source.gsub(/(#{search})/i, '<span class="highlight">\&</span>')
		end
		len=@source.length
		pos=0
		while pos < len
			lookingat=@source[pos..pos+200]
			case lookingat
			when /\A(%.*)$/  # comment
				str=$&
				pos += $&.length
				if ignorecomments
					str.gsub!(/(<span class="highlight">)([^<]*)(<\/span>)/,'\2')
				end
				tmp << %Q!<span class="comment">#{str}</span>! 
			when /\A([^\]\[(){}\\%]+)/
				tmp << $1
				pos += $1.length
			when /\A(\\g?def)\\([A-Za-z!@?]+)/
				tmp << %Q!<a name="#{$2}"</a><span class="cs">#{$1}</span><span class="def">\\#{$2}</span>! 
				pos += $&.length
			when /\A(\\)([A-Za-z!@?]+|[^<])/
				# $log.debug "CS"
				tmp << %Q!<span class="cs">#{$&}</span>! 
				pos += $&.length 
			when /\A(\{|\}|\(|\)|\[|\])/
				tmp << %Q!<span class="br">#{$1}</span>! 
				pos += 1 
			else
				tmp << lookingat[0..0]
				pos += 1
			end
		end
		return tmp
	end
	def xml (search=nil,ignorecomments=false)
		tmp=""
		if search 
			@source.gsub!(/(#{search})/i, '<span class="highlight">\&</span>')
		end
		len=@source.length
		pos=0

		while pos < len
			lookingat=@source[pos..pos+100]
			case lookingat
			when /\A\/(&gt;)/
				tmp << %Q!<span class="cs">/</span><span class="br">#{$1}</span>!
				pos += $&.length
			when /\A(&gt;)/
				tmp << %Q!<span class="br">#{$1}</span>!
				pos += $&.length
			when /\A(&lt;)(\/?[A-Za-z0-9.]+)/
				tmp << %Q!<span class="br">#{$1}</span><span class="cs">#{$2}</span><span class="br">#{$3}</span>! 
				pos += $&.length
			else
				tmp << lookingat[0..0]
				pos += 1
			end
		end
		return tmp
	end
	def verbatim (search=nil,ignorecomments=false)
		if search 
			@source.gsub!(/(#{search})/i, '<span class="highlight">\&</span>')
		end
		return @source
	end
	def perl (search=nil,ignorecomments=false)
		tmp=""
		len=@source.length
		pos=0
		while pos < len
			lookingat=@source[pos..pos+100]
			case lookingat
			when /\A(#.*)$/ 
				tmp << %Q!<span class="comment">#{$1}</span>! 
				pos += ($1.length)
			when /\A(sub)/
				tmp << %Q!<span class="cs">#{$1}</span>! 
				pos += $1.length
			when /\A(\{|\}|\(|\)|\[|\])/
				tmp << %Q!<span class="br">#{$1}</span>! 
				pos += 1 
			when /\A([^\]\[(){}#]+)/
				tmp << $1
				pos += $1.length
			else
				tmp << lookingat[0..0]
				pos += 1
			end
		end
		return tmp
	end
	def ruby (search=nil,ignorecomments=false)
		tmp=""
		len=@source.length
		pos=0
		while pos < len
			lookingat=@source[pos..pos+100]
			case lookingat
			when /\A(#.*)$/ 
				tmp << %Q!<span class="comment">#{$1}</span>! 
				pos += ($1.length)
			when /\A(sub)/
				tmp << %Q!<span class="cs">#{$1}</span>! 
				pos += $1.length
			when /\A(\{|\}|\(|\)|\[|\])/
				tmp << %Q!<span class="br">#{$1}</span>! 
				pos += 1 
			when /\A([^\]\[(){}#]+)/
				tmp << $1
				pos += $1.length
			else
				tmp << lookingat[0..0]
				pos += 1
			end
		end
		return tmp
	end
	def metapost (search=nil,ignorecomments=false)
		tmp=""
		keywords=%w(if elseif else fi true false known unknown expr let
		enddef save begingroup endgroup	for upto endfor 
		input endinput message
		path pair numeric boolean string decimal
		and not or
		shifted  cycle center round withpen scaled clip to fill withcolor
		draw filldraw
		xpart ypart
		ulcorner llcorner urcorner lrcorner)
		kw=Regexp.new(/\A(#{keywords.join('|')})\b/)
		if search 
			@source.gsub!(/(#{search})/, '<span class="highlight">\&</span>')
		end

		len=@source.length
		pos=0
		while pos < len
			lookingat=@source[pos..pos+100]
			# $log.debug "lookingat=" + lookingat + "="
			case lookingat
			when /\A(%.*)/
				str=$&
				pos += $&.length
				if ignorecomments
					#str.gsub!(/(<span class="highlight">)([^<]*)(<\/span>)/,'\2')
					str.gsub!(/<span class="highlight">/,'')
					str.gsub!(/<\/span>/,'')
				end
				tmp << %Q!<span class="comment">#{str}</span>! 
			when /\A(\{|\}|\(|\)|\[|\])/ # bracket 
				tmp << %Q!<span class="br">#{$1}</span>! 
				pos += 1
			when /\A(def |vardef )([a-zA-Z_]+)/
				tmp << %Q!<a name="#{$2}">!
				tmp << %Q!<span class="cs">#{$1}</span><span class="def">#{$2}</span>!
				pos += $&.length
			when kw
				tmp <<  %Q!<span class="cs">#{$&}</span>!
				pos += $&.length
			when /\A([a-zA-Z]+)/
				tmp <<  %Q!#{$&}!
				pos += $&.length
			else
				tmp << lookingat[0..0]
				pos += 1
			end
		end
		return tmp
	end
end
