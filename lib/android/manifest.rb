require 'rexml/document'

module Android
  # parsed AndroidManifest.xml class
  # @see http://developer.android.com/guide/topics/manifest/manifest-intro.html
  class Manifest
    APPLICATION_TAG = '/manifest/application'

    # <activity>, <service>, <receiver> or <provider> element in <application> element of the manifest file.
    class Component
      # component types
      TYPES = ['activity', 'activity-alias', 'service', 'receiver', 'provider']

      # the element is valid Component element or not
      # @param [REXML::Element] elem xml element
      # @return [Boolean]
      def self.valid?(elem)
        TYPES.include?(elem.name.downcase)
      rescue => e
        false
      end

      # @return [String] type string in TYPES
      attr_reader :type
      # @return [String] component name
      attr_reader :name
      # @return [String] icon id - use apk.icon_by_id(icon_id) to retrieve it's corresponding data.
      attr_reader :icon_id
      # @return [Array<Manifest::IntentFilters<Manifest::IntentFilter>>]
      attr_reader :intent_filters
      # @return [Array<Manifest::Meta>]
      attr_reader :metas
      # @return [REXML::Element]
      attr_reader :elem


      # @param [REXML::Element] elem target element
      # @raise [ArgumentError] when elem is invalid.
      def initialize(elem)
        raise ArgumentError unless Component.valid?(elem)
        @elem = elem
        @type = elem.name
        @name = elem.attributes['name']
        @icon_id = elem.attributes['icon']

        @intent_filters = []
        unless elem.elements['intent-filter'].nil?
          elem.each_element('intent-filter') do |filters|
            intent_filters = []
            filters.elements.each do |filter|
              next unless IntentFilter.valid?(filter)

              intent_filters << IntentFilter.parse(filter)
            end
            @intent_filters << intent_filters
          end
        end

        @metas = []
        elem.each_element('meta-data') do |e|
          @metas << Meta.new(e)
        end
      end
    end

    class Activity < Component
      # the element is valid Activity element or not
      # @param [REXML::Element] elem xml element
      # @return [Boolean]
      def self.valid?(elem)
        ['activity', 'activity-alias'].include?(elem.name.downcase)
      rescue => e
        false
      end

      def launcher_activity?
        intent_filters.flatten.any? do |filter|
          filter.type == 'category' && filter.name == 'android.intent.category.LAUNCHER'
        end
      end

      # @return whether this instance is the default main launcher activity.
      def default_launcher_activity?
        intent_filters.any? do |intent_filter|
          intent_filter.any? { |f| f.type == 'category' && f.name == 'android.intent.category.LAUNCHER' } &&
            intent_filter.any? { |f| f.type == 'category' && f.name == 'android.intent.category.DEFAULT' }
        end
      end
    end

    class ActivityAlias < Activity
      # @return [String] target activity name
      attr_reader :target_activity

      # @param [REXML::Element] elem target element
      # @raise [ArgumentError] when elem is invalid.
      def initialize(elem)
        super
        @target_activity = elem.attributes['targetActivity']
      end
    end

    class Service < Component
    end

    class Receiver < Component
    end

    class Provider < Component
    end



    # intent-filter element in components
    module IntentFilter
      # filter types
      TYPES = ['action', 'category', 'data']

      # the element is valid IntentFilter element or not
      # @param [REXML::Element] elem xml element
      # @return [Boolean]
      def self.valid?(elem)
        TYPES.include?(elem.name.downcase)
      rescue => e
        false
      end

      # parse inside of intent-filter element
      # @param [REXML::Element] elem target element
      # @return [IntentFilter::Action, IntentFilter::Category, IntentFilter::Data]
      #    intent-filter element
      def self.parse(elem)
        case elem.name
        when 'action'
          Action.new(elem)
        when 'category'
          Category.new(elem)
        when 'data'
          Data.new(elem)
        else
          nil
        end
      end

      # intent-filter action class
      class Action
      # @return [String] action name of intent-filter
        attr_reader :name
      # @return [String] action type of intent-filter
        attr_reader :type

        def initialize(elem)
          @type = 'action'
          @name = elem.attributes['name']
        end
      end

      # intent-filter category class
      class Category
      # @return [String] category name of intent-filter
        attr_reader :name
      # @return [String] category type of intent-filter
        attr_reader :type

        def initialize(elem)
          @type = 'category'
          @name = elem.attributes['name']
        end
      end

      # intent-filter data class
      class Data
        # @return [String]
        attr_reader :type
        # @return [String]
        attr_reader :host
        # @return [String]
        attr_reader :mime_type
        # @return [String]
        attr_reader :path
        # @return [String]
        attr_reader :path_pattern
        # @return [String]
        attr_reader :path_prefix
        # @return [String]
        attr_reader :port
        # @return [String]
        attr_reader :scheme

        def initialize(elem)
          @type = 'data'
          @host = elem.attributes['host']
          @mime_type = elem.attributes['mimeType']
          @path = elem.attributes['path']
          @path_pattern = elem.attributes['pathPattern']
          @path_prefix = elem.attributes['pathPrefix']
          @port = elem.attributes['port']
          @scheme = elem.attributes['scheme']
        end
      end
    end

    # meta information class
    class Meta
      # @return [String]
      attr_reader :name
      # @return [String]
      attr_reader :resource
      # @return [String]
      attr_reader :value
      def initialize(elem)
        @name = elem.attributes['name']
        @resource = elem.attributes['resource']
        @value = elem.attributes['value']
      end
    end

    #################################
    # Manifest class definitions
    #################################
    #
    # @return [REXML::Document] manifest xml
    attr_reader :doc

    # @param [String] data binary data of AndroidManifest.xml
    def initialize(data, rsc=nil)
      parser = AXMLParser.new(data)
      @doc = parser.parse
      @rsc = rsc
    end

    # used permission array
    # @return [Array<String>] permission names
    # @note return empty array when the manifest includes no use-parmission element
    def use_permissions
      perms = []
      @doc.each_element('/manifest/uses-permission') do |elem|
        perms << elem.attributes['name']
      end
      perms.uniq
    end

    # @return [Array<Android::Manifest::Component>] all components in apk
    # @note return empty array when the manifest include no components
    def components
      components = []
      unless @doc.elements['/manifest/application'].nil?
        @doc.elements['/manifest/application'].each do |elem|
          components << Component.new(elem) if Component.valid?(elem)
        end
      end
      components
    end

    # @return [Array<Android::Manifest::Activity&ActivityAlias>] all activities in the apk
    # @note return empty array when the manifest include no activities
    def activities
      activities = []
      unless @doc.elements['/manifest/application'].nil?
        @doc.elements['/manifest/application'].each do |elem|
          next unless Activity.valid?(elem)

          activities << (elem.name == 'activity-alias' ? ActivityAlias.new(elem) : Activity.new(elem))
        end
      end
      activities
    end

    # @return [Array<Android::Manifest::Activity&ActivityAlias>] all activities that are launchers in the apk
    # @note return empty array when the manifest include no activities
    def launcher_activities
      activities.select(&:launcher_activity?)
    end

    # application package name
    # @return [String]
    def package_name
      @doc.root.attributes['package']
    end

    # application version code
    # @return [Integer]
    def version_code
      @doc.root.attributes['versionCode'].to_i
    end

    # application version name
    # @return [String]
    def version_name(lang=nil)
      vername = @doc.root.attributes['versionName']
      unless @rsc.nil?
        if /^@(\w+\/\w+)|(0x[0-9a-fA-F]{8})$/ =~ vername
          opts = {}
          opts[:lang] = lang unless lang.nil?
          vername = @rsc.find(vername, opts)
        end
      end
      vername
    end

    # @return [Integer] minSdkVersion in uses element
    def min_sdk_ver
      @doc.elements['/manifest/uses-sdk'].attributes['minSdkVersion'].to_i
    end

    # application label
    # @param [String] lang language code like 'ja', 'cn', ...
    # @return [String] application label string(if resouce is provided), or label resource id
    # @return [nil] when label is not found
    # @since 0.5.1
    def label(lang=nil)
      label = @doc.elements['/manifest/application'].attributes['label']
      if label.nil?
        # application element has no label attributes.
        # so looking for activites that has label attribute.
        activities = @doc.elements['/manifest/application'].find{|e| e.name == 'activity' && !e.attributes['label'].nil? }
        label = activities.nil? ? nil : activities.first.attributes['label']
      end
      unless @rsc.nil?
        if /^@(\w+\/\w+)|(0x[0-9a-fA-F]{8})$/ =~ label
          opts = {}
          opts[:lang] = lang unless lang.nil?
          label = @rsc.find(label, opts)
        end
      end
      label
    end

    # return xml as string format
    # @param [Integer] indent size(bytes)
    # @return [String] raw xml string
    def to_xml(indent=4)
      xml =''
      formatter = REXML::Formatters::Pretty.new(indent)
      formatter.write(@doc.root, xml)
      xml
    end
  end
end
