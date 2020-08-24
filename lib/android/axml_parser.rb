require 'rexml/document'
require 'stringio'


module Android
  # binary AXML parser
  # @see https://android.googlesource.com/platform/frameworks/base.git Android OS frameworks source
  # @note
  #   refer to Android OS framework code:
  #   
  #   /frameworks/base/include/androidfw/ResourceTypes.h,
  #   
  #   /frameworks/base/libs/androidfw/ResourceTypes.cpp
  class AXMLParser
    def self.axml?(data)
      (data[0..3] == "\x03\x00\x08\x00")
    end

    # axml parse error
    class ReadError < StandardError; end

    TAG_START_NAMESPACE = 0x00100100
    TAG_END_NAMESPACE =   0x00100101
    TAG_START =           0x00100102
    TAG_END =             0x00100103
    TAG_TEXT =            0x00100104
    TAG_CDSECT =          0x00100105
    TAG_ENTITY_REF =      0x00100106

    VAL_TYPE_NULL              =0
    VAL_TYPE_REFERENCE         =1
    VAL_TYPE_ATTRIBUTE         =2
    VAL_TYPE_STRING            =3
    VAL_TYPE_FLOAT             =4
    VAL_TYPE_DIMENSION         =5
    VAL_TYPE_FRACTION          =6
    VAL_TYPE_INT_DEC           =16
    VAL_TYPE_INT_HEX           =17
    VAL_TYPE_INT_BOOLEAN       =18
    VAL_TYPE_INT_COLOR_ARGB8   =28
    VAL_TYPE_INT_COLOR_RGB8    =29
    VAL_TYPE_INT_COLOR_ARGB4   =30
    VAL_TYPE_INT_COLOR_RGB4    =31

    # @return [Array<String>] strings defined in axml
    attr_reader :strings

    # @param [String] axml binary xml data
    def initialize(axml)
      @io = StringIO.new(axml, "rb")
      @strings = []
    end

    # parse binary xml
    # @return [REXML::Document]
    def parse
      @doc = REXML::Document.new
      @doc << REXML::XMLDecl.new

      @num_str = word(4*4)
      @xml_offset = word(3*4)

      @parents = [@doc]
      @namespaces = []
      parse_strings
      parse_tags
      @doc
    end


    # read one word(4byte) as integer
    # @param [Integer] offset offset from top position. current position is used if ofset is nil
    # @return [Integer] little endian word value
    def word(offset=nil)
      @io.pos = offset unless offset.nil?
      @io.read(4).unpack("V")[0]
    end

    # read 2byte as short integer
    # @param [Integer] offset offset from top position. current position is used if ofset is nil
    # @return [Integer] little endian unsign short value
    def short(offset)
      @io.pos = offset unless offset.nil?
      @io.read(2).unpack("v")[0]
    end

    # relace string table parser
    def parse_strings
      strpool = Resource::ResStringPool.new(@io.string, 8) # ugh!
      @strings = strpool.strings
    end

    # parse tag
    def parse_tags

      # skip until first TAG_START_NAMESPACE
      pos = @xml_offset
      pos += 4 until (word(pos) == TAG_START_NAMESPACE)
      @io.pos -= 4

      # read tags
      #puts "start tag parse: %d(%#x)" % [@io.pos, @io.pos]
      until @io.eof?
        last_pos = @io.pos
        tag, tag1, line, tag3, ns_id, name_id = @io.read(4*6).unpack("V*")
        case tag
        when TAG_START
          tag6, num_attrs, tag8  = @io.read(4*3).unpack("V*")

          prefix = ''
          if ns_id != 0xFFFFFFFF
            namespace_uri = @strings[ns_id]
            prefix = get_namespace_prefix(namespace_uri) + ':'
          end
          elem = REXML::Element.new(prefix + @strings[name_id])

          # If this element is a direct descendent of a namespace declaration
          # we add the namespace definition as an attribute.
          if @namespaces.last[:nesting_level] == current_nesting_level
            elem.add_namespace(@namespaces.last[:prefix], @namespaces.last[:uri])
          end
          #puts "start tag %d(%#x): #{@strings[name_id]} attrs:#{num_attrs}" % [last_pos, last_pos]
          @parents.last.add_element elem
          num_attrs.times do
            key, val = parse_attribute
            if val.is_a?(String)
              # drop invalid chars that would be rejected by REXML from string
              val = val.scan(REXML::Text::VALID_XML_CHARS).join
            end
            elem.add_attribute(key, val)
          end
          @parents.push elem
        when TAG_END
          @parents.pop
        when TAG_END_NAMESPACE
          @namespaces.pop
          break if @namespaces.empty? # if the topmost namespace (usually 'android:') has been closed, we‘re done.
        when TAG_TEXT
          text = REXML::Text.new(@strings[ns_id])
          @parents.last.text = text
          dummy = @io.read(4*1).unpack("V*") # skip 4bytes
        when TAG_START_NAMESPACE
          prefix = @strings[ns_id]
          uri = @strings[name_id]
          @namespaces.push({ prefix: prefix, uri: uri, nesting_level: current_nesting_level })
        when TAG_CDSECT
          raise ReadError, "TAG_CDSECT not implemented"
        when TAG_ENTITY_REF
          raise ReadError, "TAG_ENTITY_REF not implemented"
        else
          raise ReadError, "pos=%d(%#x)[tag:%#x]" % [last_pos, last_pos, tag]
        end
      end
    end

    # parse attribute of a element
    def parse_attribute
      ns_id, name_id, val_str_id, flags, val = @io.read(4*5).unpack("V*")
      key = @strings[name_id]
      unless ns_id == 0xFFFFFFFF
        namespace_uri = @strings[ns_id]
        prefix = get_namespace_prefix(namespace_uri)
        key = "#{prefix}:#{key}"
      end
      value = convert_value(val_str_id, flags, val)
      return key, value
    end

    # find the first declared namespace prefix for a URI
    def get_namespace_prefix(ns_uri)
      # a namespace might be given as a URI or as a reference to a previously defined namespace.
      # E.g. like this:
      # <tag1 xmlns:android="http://schemas.android.com/apk/res/android">
      #   <tag2 xmlns:n0="android" />
      # </tag1>

      # Walk recursively through the namespaces to
      # transitively resolve URIs that just pointed to previous namespace prefixes
      current_uri = ns_uri
      @namespaces.reverse.each do |ns|
        if ns[:prefix] == current_uri
          # we found a previous namespace declaration that was referenced to by
          # the current_uri. Proceed with this namespace’s URI and try to see if this
          # is also just a reference to a previous namespace
          current_uri = ns[:uri]
        end
      end

      # current_uri now contains the URI of the topmost namespace declaration.
      # We’ll take the prefix of this and return it.
      @namespaces.reverse.each do |ns|
        return ns[:prefix] if ns[:uri] == current_uri
      end
      raise "Could not resolve URI #{ns_uri} to a namespace prefix"
    end

    def current_nesting_level
      @parents.length
    end

    def convert_value(val_str_id, flags, val)
      unless val_str_id == 0xFFFFFFFF
        value = @strings[val_str_id]
      else
        type = flags >> 24
        case type
        when VAL_TYPE_NULL
          value = nil
        when VAL_TYPE_REFERENCE
          value = "@%#x" % val # refered resource id.
        when VAL_TYPE_INT_DEC
          value = val
        when VAL_TYPE_INT_HEX
          value = "%#x" % val
        when VAL_TYPE_INT_BOOLEAN
          value = ((val == 0xFFFFFFFF) || (val==1)) ? true : false
        else
          value = "[%#x, flag=%#x]" % [val, flags]
        end
      end
    end
  end

end
