# frozen_string_literal: true

describe Android::AXMLParser do
  let(:bin_xml_path){ File.expand_path(File.dirname(__FILE__) + '/data/sample_AndroidManifest.xml') }
  let(:bin_xml){ File.open(bin_xml_path, 'rb') {|f| f.read } }
  let(:axmlparser){ Android::AXMLParser.new(bin_xml) }

  let(:bin_xml_with_namespaces_path){ File.expand_path(File.dirname(__FILE__) + '/data/sample_AndroidManifest_with_namespaces.xml') }
  let(:bin_xml_with_namespaces){ File.open(bin_xml_with_namespaces_path, 'rb') {|f| f.read } }
  let(:axmlparser_with_namespaces){ Android::AXMLParser.new(bin_xml_with_namespaces) }

  let(:bin_xml_with_transitive_namespace_declaration_path){ File.expand_path(File.dirname(__FILE__) + '/data/sample_AndroidManifest_with_transitive_namespace_declaration.xml') }
  let(:bin_xml_with_transitive_namespace_declaration){ File.open(bin_xml_with_transitive_namespace_declaration_path, 'rb') {|f| f.read } }
  let(:axmlparser_with_transitive_namespace_declaration){ Android::AXMLParser.new(bin_xml_with_transitive_namespace_declaration) }

  describe "#parse" do

    subject { axmlparser.parse }
    context 'with sample_AndroidManifest.xml' do
      it { should be_instance_of(REXML::Document) }
      specify 'root element should be <manifest> element' do
        subject.root.name.should eq 'manifest'
      end
      specify 'should have 2 <uses-permission> elements' do
        subject.get_elements('/manifest/uses-permission').should have(2).items
      end
    end

    context 'with nil data as binary xml' do
      let(:bin_xml) { nil }
      specify { expect{ subject }.to raise_error }
    end

  end

  describe "#parse with namespaces" do
    subject { axmlparser_with_namespaces.parse }
    context 'with sample_AndroidManifest_with_namespaces.xml' do
      it { should be_instance_of(REXML::Document) }
      specify 'it should parse the full manifest even if there are namespaces' do
        subject.get_elements('/manifest/application').should have(1).item
      end
    end
  end

  describe "#parse with transitive namespace declarations" do
    subject { axmlparser_with_transitive_namespace_declaration.parse }
    context 'with sample_AndroidManifest_with_namespaces.xml' do
      it { should be_instance_of(REXML::Document) }
      specify 'it should parse the full manifest even if there are namespaces' do
        subject.get_elements('/manifest/uses-permission/thisisjustatest').last.attributes['android:name'].should eq('this is a name')
      end
    end
  end

  describe "#strings" do
    context 'with sample_AndroidManifest.xml' do
      subject { axmlparser.strings }
      before do
        axmlparser.parse
      end
      it { should be_instance_of(Array) }

      # ugh!! the below test cases depend on sample_AndroidManifest.xml
      it { should have(26).items} # in sample manifest.
      it { should include("versionCode") }
      it { should include("versionName") }
      it { should include("minSdkVersion") }
      it { should include("package") }
      it { should include("manifest") }
    end
  end

  describe '#convert_value' do
    let(:axmlparser){ Android::AXMLParser.new('') }
    subject { axmlparser.convert_value(str_id, flags, val) }
    context 'when parsing boolean attribute' do
      let(:str_id) { 0xFFFFFFFF }
      let(:flags) { 0x12000008 }
      context 'and value is 0x01' do
        let(:val) { 0x01 }
        it { should be_truthy }
      end
      context 'and value is 0xFFFFFFF' do
        let(:val) { 0xFFFFFFFF }
        it { should be_truthy }
      end
      context 'and value is 0x00' do
        let(:val) { 0x00 }
        it { should be_falsey }
      end
    end
  end
end
