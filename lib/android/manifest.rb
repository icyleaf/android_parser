require 'rexml/document'
require 'uri'

module Android
  # parsed AndroidManifest.xml class
  # @see http://developer.android.com/guide/topics/manifest/manifest-intro.html
  class Manifest
    APPLICATION_TAG = '/manifest/application'

    # <activity>, <service>, <receiver> or <provider> element in <application> element of the manifest file.
    class Component
      # component types
      TYPES = ['activity', 'activity-alias', 'service', 'receiver', 'provider', 'application']

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

        @intent_filters = parse_intent_filters
        @metas = parse_metas
      end

      private

      def parse_intent_filters
        intent_filters = []
        return intent_filters if @elem.elements['intent-filter'].nil?

        @elem.each_element('intent-filter') do |filter|
          next if filter&.elements&.empty?
          next unless IntentFilter.valid?(filter)

          intent_filter = IntentFilter.new(filter)
          intent_filters << intent_filter unless intent_filter.empty?
        end

        intent_filters
      end

      def parse_metas
        metas = []
        return metas if @elem.elements['meta-data'].nil?

        @elem.each_element('meta-data') do |e|
          metas << Meta.new(e)
        end

        metas
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

      # @return whether this instance is the launcher activity.
      def launcher_activity?
        intent_filters.any? do |intent_filter|
          intent_filter.exist?('android.intent.category.LAUNCHER')
        end
      end

      # @return whether this instance is the default main launcher activity.
      def default_launcher_activity?
        intent_filters.any? do |intent_filter|
          intent_filter.exist?('android.intent.category.LAUNCHER') &&
          intent_filter.exist?('android.intent.category.DEFAULT')
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

    class Application < Component
      def self.valid?(elem)
        elem&.name == 'application'
      end
    end

    # intent-filter element in components
    class IntentFilter
      # filter types
      TYPES = ['action', 'category', 'data']

      # browsable of category
      CATEGORY_BROWSABLE = 'android.intent.category.BROWSABLE'

      # the element is valid IntentFilter element or not
      # @param [REXML::Element] elem xml element
      # @return [Boolean]
      def self.valid?(filter)
        filter.elements.any? do |elem|
          TYPES.include?(elem.name.downcase)
        end
      rescue => e
        false
      end

      # @return [IntentFilter::Action] intent-filter actions
      attr_reader :actions
      # @return [IntentFilter::Category] intent-filter categories
      attr_reader :categories
      # @return [IntentFilter::Data] intent-filter data
      attr_reader :data
      # @return [IntentFilter::Data] intent-filter data
      attr_reader :activity

      def initialize(filter)
        @activity = filter.parent
        @actions = []
        @categories = []
        @data = []

        filter.elements.each do |element|
          type = element.name.downcase
          next unless TYPES.include?(type)

          case type
          when 'action'
            @actions << Action.new(element)
          when 'category'
            @categories << Category.new(element)
          when 'data'
            @data << Data.new(element)
          end
        end
      end

      # Returns true if self contains no elements.
      # @return [Boolean]
      def empty?
        @actions.empty? &&
        @categories.empty? &&
        @data.empty?
      end

      def exist?(name, type: nil)
        if type.to_s.empty? && !name.start_with?('android.intent.')
          raise 'Fill type or use correct name'
        end

        type ||= name.split('.')[2]
        raise 'Not found type' unless TYPES.include?(type)

        method_name = case type
                      when 'action'
                        :actions
                      when 'category'
                        :categories
                      when 'data'
                        :data
                      end

        values = send(method_name).select { |e| e.name == name }
        values.empty? ? false : values #(values.size == 1 ? values.first : values)
      end

      def deep_links
        return unless deep_link?

        data.select {|d| !d.host.nil?  }
            .map { |d| d.host }
            .uniq
      end

      def deep_link?
        browsable? && data.any? { |d| ['http', 'https'].include?(d.scheme) }
      end

      def schemes
        return unless schemes?

        data.select {|d| !d.scheme.nil? && !['http', 'https'].include?(d.scheme) }
            .map { |d| d.scheme }
            .uniq
      end

      def schemes?
        browsable? && data.any? { |d| !['http', 'https'].include?(d.scheme) }
      end

      def browsable?
        exist?(CATEGORY_BROWSABLE)
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
      manifest_values('/manifest/uses-permission')
    end

    # used features array
    # @return [Array<String>] features names
    # @note return empty array when the manifest includes no use-features element
    # @since 2.5.0
    def use_features
      manifest_values('/manifest/uses-feature')
    end

    # Returns the manifest's application element or nil, if there isn't any.
    # @return [Android::Manifest::Application] the manifest's application element
    def application
      element = @doc.elements['//application']
      Application.new(element) if Application.valid?(element)
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

    # @return [Array<Android::Manifest::Component>] all services in the apk
    # @note return empty array when the manifest include no services
    # @since 2.5.0
    def services
      components.select { |c| c.type == 'service' }
    end

    def deep_links
      activities.each_with_object([]) do |activity, obj|
        intent_filters = activity.intent_filters
        next if intent_filters.empty?

        intent_filters.each do |filter|
          next unless filter.deep_link?

          obj << filter.deep_links
        end
      end.flatten.uniq
    end

    def schemes
      activities.each_with_object([]) do |activity, obj|
        intent_filters = activity.intent_filters
        next if intent_filters.empty?

        intent_filters.each do |filter|
          next unless filter.schemes?

          obj << filter.schemes
        end
      end.flatten.uniq
    end

    # def intent_filters
    #   components.each_with_object([]) do |component, obj|
    #     intent_filters = component.intent_filters
    #     next if intent_filters.empty?

    #     obj << intent_filters
    #   end.flatten
    # end

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
      @doc.elements['/manifest/uses-sdk']
          .attributes['minSdkVersion']
          .to_i
    end

    # @return [Integer] targetSdkVersion in uses element
    # @since 2.5.0
    def target_sdk_version
      @doc.elements['/manifest/uses-sdk']
          .attributes['targetSdkVersion']
          .to_i
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
        activities = @doc.elements['/manifest/application'].find{ |e| e.name == 'activity' && !e.attributes['label'].nil? }
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

    private

    def manifest_values(path, key = 'name')
      values = []
      @doc.each_element(path) do |elem|
        values << elem.attributes[key]
      end
      values.uniq
    end
  end
end
