# frozen_string_literal: true

require 'rexml/document'
require 'stringio'

module Android
  class AXMLWriter < AXMLParser
    # @param [String] axml binary xml data
    def initialize(axml)
      @io = StringIO.new(axml, "r+b")
      @strings = []
    end

    def modify_metadata!(name, new_value)
      parse if @doc.nil?

      entry = @metadata.find { |meta| meta['android:name'][:value] == name }
      raise "Metadata #{name} could not be found and modified" if entry.nil?

      pos = if entry['android:value'][:is_string]
              new_string_id = add_string!(new_value)
              new_value = new_string_id
              entry['android:value'][:val_str_id]
            else
              entry['android:value'][:position]
            end

      @io.pos = pos
      @io.write([new_value].pack('V'))
    end

    def add_string!(str)
      new_string_id, bytes_added = Resource::ResStringPool.new(@io.string, 8).add_string(str)

      # Update XML size and positions of metadata attributes.
      @io.pos = 4
      xml_size = @io.read(4).unpack1('V')
      @io.pos = 4
      @io.write([xml_size + bytes_added].pack('V'))

      @metadata = @metadata.map do |metadata|
        metadata.transform_values do |attribute|
          attribute[:position] += bytes_added
          attribute[:val_str_id] += bytes_added
          attribute
        end
      end
      new_string_id
    end
  end
end
