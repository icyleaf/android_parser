# frozen_string_literal: true

describe Android::Manifest do
  describe Android::Manifest::Component do
    describe "self.valid?" do
      subject { Android::Manifest::Component.valid?(elem) }

      context "with valid component element" do
        let(:elem) { REXML::Element.new('service') }
        it { should be_truthy }
      end

      context "with invalid component element" do
        let(:elem) { REXML::Element.new('invalid-name') }
        it { should be_falsey }
      end

      context "when some exception occurs in REXML::Element object" do
        let(:elem) {
          elem = double(REXML::Element)
          elem.stub(:name).and_raise(StandardError)
          elem
        }
        it { should be_falsey }
      end
    end

    describe '#intent_filters' do
      subject { Android::Manifest::Component.new(elem).intent_filters }

      context 'with valid component element has 2 intent-filter elements' do
        let(:elem) {
          elem = REXML::Element.new('activity')
          elem << intent_filter1
          elem << intent_filter2
          elem << intent_filter3
          elem << intent_filter4
          elem
        }

        let(:intent_filter1) {
          elem = REXML::Element.new('intent-filter')
          elem << REXML::Element.new('action')
          elem
        }

        let(:intent_filter2) {
          elem = REXML::Element.new('intent-filter')
          elem << REXML::Element.new('action')
          elem << REXML::Element.new('category')
          elem
        }

        let(:intent_filter3) {
          elem = REXML::Element.new('intent-filter')
          elem << REXML::Element.new('category')
          elem
        }

        let(:intent_filter4) {
          elem = REXML::Element.new('intent-filter')
          elem << REXML::Element.new('data')
          elem
        }

        it { should have(2).item }
      end

      context 'with invalid intent-filter elements' do
        let(:elem) {
          elem = REXML::Element.new('activity')
          elem << REXML::Element.new('intent-filter')
          elem << REXML::Element.new('intent-filter')
          elem
        }

        it { should have(0).item }
      end

      context 'with invalid intent-filter elements not found action element(s)' do
        let(:elem) {
          elem = REXML::Element.new('activity')
          elem << intent_filter1
          elem << intent_filter2
          elem << intent_filter3
          elem
        }

        let(:intent_filter1) {
          elem = REXML::Element.new('intent-filter')
          elem << REXML::Element.new('category')
          elem
        }

        let(:intent_filter2) {
          elem = REXML::Element.new('intent-filter')
          elem << REXML::Element.new('category')
          elem
        }

        let(:intent_filter3) {
          elem = REXML::Element.new('intent-filter')
          elem << REXML::Element.new('category')
          elem << REXML::Element.new('data')
          elem
        }

        it { should have(0).item }
      end
    end

    describe '#metas' do
      subject { Android::Manifest::Component.new(elem).metas }
      context 'with valid component element has 2 meta elements' do
        let(:elem) {
          elem = REXML::Element.new('service')
          elem << REXML::Element.new('meta-data')
          elem << REXML::Element.new('meta-data')
          elem
        }

        it { should have(2).item }
      end
    end

    describe '#elem' do
      subject { Android::Manifest::Component.new(elem).elem }
      let(:elem) { REXML::Element.new('service') }
      it { should eq elem }
    end

    describe Android::Manifest::Meta do
      let(:elem) do
        attrs = { 'name' => 'meta name', 'resource' => 'res', 'value' => 'val' }
        elem = double(REXML::Element, :attributes => attrs)
        elem
      end
      subject { Android::Manifest::Meta.new(elem) }
      its(:name) { should eq 'meta name' }
      its(:resource) { should eq 'res' }
      its(:value) { should eq 'val' }
    end
  end

  describe Android::Manifest::IntentFilter do
    describe '.new' do
      context 'assings "actions" element' do
        let(:elem) {
          elem = REXML::Element.new('filter')
          elem << REXML::Element.new('action')
          elem
        }
        subject { Android::Manifest::IntentFilter.new(elem).actions.first }
        it { should be_instance_of Android::Manifest::IntentFilter::Action }
      end

      context 'assings "categories" element' do
        let(:elem) {
          elem = REXML::Element.new('filter')
          elem << REXML::Element.new('category')
          elem
        }
        subject { Android::Manifest::IntentFilter.new(elem).categories.first }

        it { should be_instance_of Android::Manifest::IntentFilter::Category }
      end

      context 'assings "data" element' do
        let(:elem) {
          elem = REXML::Element.new('filter')
          elem << REXML::Element.new('data')
          elem
        }
        subject { Android::Manifest::IntentFilter.new(elem).data.first }
        it { should be_instance_of Android::Manifest::IntentFilter::Data }
      end

      context 'assings unknown element' do
        let(:elem) {
          elem = REXML::Element.new('filter')
          elem << REXML::Element.new('unknown')
          elem
        }
        subject { Android::Manifest::IntentFilter.new(elem) }
        it { should be_empty }
      end
    end

    describe '#empty?' do
      subject { Android::Manifest::IntentFilter.new(elem).empty? }

      context 'with vaild action element in intent filter element' do
        let(:elem) {
          elem = REXML::Element.new('intent-filter')
          elem << REXML::Element.new('action')
          elem
        }

        it { should be_falsey }
      end

      context 'with invaild category element in intent filter element' do
        let(:elem) {
          elem = REXML::Element.new('intent-filter')
          elem << REXML::Element.new('category')
          elem
        }

        it { should be_truthy }
      end

      context 'with invaild data element in intent filter element' do
        let(:elem) {
          elem = REXML::Element.new('intent-filter')
          elem << REXML::Element.new('data')
          elem
        }

        it { should be_truthy }
      end
    end

    describe '#exist?' do
      subject { Android::Manifest::IntentFilter.new(elem).exist?(name) }
      let(:category) {
        category = REXML::Element.new('category')
        category.add_attribute 'name', Android::Manifest::IntentFilter::CATEGORY_BROWSABLE
        category
      }

      context 'with vaild category element' do
        let(:name) { Android::Manifest::IntentFilter::CATEGORY_BROWSABLE }
        let(:elem) {
          elem = REXML::Element.new('intent-filter')
          category = REXML::Element.new('category')
          category.add_attribute 'name', name
          elem << category
          elem
        }
        it { should be_truthy }
      end

      context 'with vaild category element' do
        let(:name) { Android::Manifest::IntentFilter::CATEGORY_BROWSABLE }
        let(:elem) {
          elem = REXML::Element.new('intent-filter')
          elem << category
          elem
        }

        it { should have(1).item }
      end

      context 'with invaild non-match category element' do
        let(:name) { 'android.intent.category.DEFAULT' }
        let(:elem) {
          elem = REXML::Element.new('intent-filter')
          elem << category
          elem
        }

        it { should be_falsey }
      end

      context 'with invaild category element' do
        let(:name) { 'DEFAULT' }
        let(:elem) {
          elem = REXML::Element.new('intent-filter')
          elem << category
          elem
        }

        it { expect { subject }.to raise_error }
      end
    end

    describe '#browsable?' do
      subject { Android::Manifest::IntentFilter.new(elem).browsable? }

      context 'with browsable category element' do
        let(:elem) {
          elem = REXML::Element.new('intent-filter')
          category = REXML::Element.new('category')
          category.add_attribute 'name', Android::Manifest::IntentFilter::CATEGORY_BROWSABLE
          elem << category
          elem
        }

        it { should be_truthy }
      end

      context 'with unknown category element' do
        let(:elem) {
          elem = REXML::Element.new('intent-filter')
          category = REXML::Element.new('category')
          category.add_attribute 'name', "permission"
          elem << category
          elem
        }

        it { should be_falsey }
      end
    end

    describe '#deep_links?' do
      subject { Android::Manifest::IntentFilter.new(elem).deep_links? }
      let(:category) {
        elem = REXML::Element.new('category')
        elem.add_attribute 'name', Android::Manifest::IntentFilter::CATEGORY_BROWSABLE
        elem
      }

      let(:http_scheme_data) {
        elem = REXML::Element.new('data')
        elem.add_attribute 'scheme', 'http'
        elem
      }

      let(:app_scheme_data) {
        elem = REXML::Element.new('data')
        elem.add_attribute 'scheme', 'app'
        elem
      }

      context 'with browsable category and http scheme data' do
        let(:elem) {
          elem = REXML::Element.new('intent-filter')
          elem << category
          elem << http_scheme_data
          elem << app_scheme_data
          elem
        }

        it { should be_truthy }
      end

      context 'with browsable category and app scheme data' do
        let(:elem) {
          elem = REXML::Element.new('intent-filter')
          elem << category
          elem << app_scheme_data
          elem
        }

        it { should be_falsey }
      end
    end

    describe '#deep_links' do
      subject { Android::Manifest::IntentFilter.new(elem).deep_links }
      let(:category) {
        elem = REXML::Element.new('category')
        elem.add_attribute 'name', Android::Manifest::IntentFilter::CATEGORY_BROWSABLE
        elem
      }

      let(:http_scheme_data) {
        elem = REXML::Element.new('data')
        elem.add_attribute 'scheme', 'http'
        elem.add_attribute 'host', 'github.com'
        elem
      }

      context 'with browsable category and http scheme data' do
        let(:elem) {
          elem = REXML::Element.new('intent-filter')
          elem << category
          elem << http_scheme_data
          elem
        }

        it { should have(1).item }
        it { should eq ['github.com'] }
      end
    end

    describe '#schemes?' do
      subject { Android::Manifest::IntentFilter.new(elem).schemes? }
      let(:category) {
        elem = REXML::Element.new('category')
        elem.add_attribute 'name', Android::Manifest::IntentFilter::CATEGORY_BROWSABLE
        elem
      }

      let(:http_scheme_data) {
        elem = REXML::Element.new('data')
        elem.add_attribute 'scheme', 'http'
        elem
      }

      let(:app_scheme_data) {
        elem = REXML::Element.new('data')
        elem.add_attribute 'scheme', 'app'
        elem
      }

      context 'with invaild browsable category and http scheme data' do
        let(:elem) {
          elem = REXML::Element.new('intent-filter')
          elem << category
          elem << http_scheme_data
          elem
        }

        it { should be_falsey }
      end

      context 'with vaild browsable category and app scheme data' do
        let(:elem) {
          elem = REXML::Element.new('intent-filter')
          elem << category
          elem << app_scheme_data
          elem
        }

        it { should be_truthy }
      end
    end

    describe '#schemes' do
      subject { Android::Manifest::IntentFilter.new(elem).schemes }
      let(:category) {
        elem = REXML::Element.new('category')
        elem.add_attribute 'name', Android::Manifest::IntentFilter::CATEGORY_BROWSABLE
        elem
      }

      let(:app_scheme_data) {
        elem = REXML::Element.new('data')
        elem.add_attribute 'scheme', 'app'
        elem
      }

      context 'with browsable category and app scheme data' do
        let(:elem) {
          elem = REXML::Element.new('intent-filter')
          elem << category
          elem << app_scheme_data
          elem
        }

        it { should have(1).item }
        it { should eq ['app'] }
      end
    end
  end

  context "with stub AXMLParser" do
    let(:dummy_xml) {
      xml = REXML::Document.new
      xml << REXML::Element.new('manifest')
    }
    let(:manifest) { Android::Manifest.new('mock data') }

    before do
      parser = double(Android::AXMLParser, :parse => dummy_xml)
      Android::AXMLParser.stub(:new).and_return(parser)
    end

    describe "#use_permissions" do
      subject { manifest.use_permissions }
      context "with valid 3 permission elements" do
        before do
          3.times do |i|
            elem = REXML::Element.new("uses-permission")
            elem.add_attribute 'name', "permission#{i}"
            dummy_xml.root << elem
          end
        end

        it { subject.should have(3).items }

        it "should have permissions" do
          subject.should include("permission0")
          subject.should include("permission1")
          subject.should include("permission2")
        end
      end

      context "with no permissions" do
        it { should be_empty }
      end
    end

    describe "#use_features" do
      subject { manifest.use_features }
      context "with valid 3 feature elements" do
        before do
          3.times do |i|
            elem = REXML::Element.new("uses-feature")
            elem.add_attribute 'name', "feature#{i}"
            dummy_xml.root << elem
          end
        end

        it { subject.should have(3).items }

        it "should have features" do
          subject.should include("feature0")
          subject.should include("feature1")
          subject.should include("feature2")
        end
      end

      context "with no feature" do
        it { should be_empty }
      end
    end

    describe "#components" do
      subject { manifest.components }
      context "with valid components element" do
        before do
          app = REXML::Element.new('application')
          activity = REXML::Element.new('activity')
          app << activity
          dummy_xml.root << app
        end

        it "should have components" do
          subject.should have(1).items
        end

        it "should returns Component object" do
          subject[0].should be_kind_of Android::Manifest::Component
        end
      end

      context "with no components" do
        it { should be_empty }
      end

      context 'with text element in intent-filter element. (issue #3)' do
        before do
          app = REXML::Element.new('application')
          activity = REXML::Element.new('activity')
          intent_filter = REXML::Element.new('intent-filter')
          text = REXML::Text.new('sample')

          intent_filter << text
          activity << intent_filter
          app << activity
          dummy_xml.root << app
        end

        it "should have components" do
          subject.should have(1).items
        end

        it { expect { subject }.to_not raise_error }
      end
    end

    describe "#services" do
      subject { manifest.services }
      context "with valid services element" do
        before do
          app = REXML::Element.new('application')
          service = REXML::Element.new('service')
          app << service
          dummy_xml.root << app
        end

        it "should have services" do
          subject.should have(1).items
        end

        it "should returns Component object" do
          subject[0].should be_kind_of Android::Manifest::Component
        end
      end

      context "with no services" do
        it { should be_empty }
      end

      context 'with text element in intent-filter element.' do
        before do
          app = REXML::Element.new('application')
          service = REXML::Element.new('service')
          intent_filter = REXML::Element.new('intent-filter')
          text = REXML::Text.new('sample')

          intent_filter << text
          service << intent_filter
          app << service
          dummy_xml.root << app
        end

        it "should have services" do
          subject.should have(1).items
        end

        it { expect { subject }.to_not raise_error }
      end
    end
  end

  context "with real sample_AndroidManifest.xml data" do
    let(:bin_xml_path){ File.expand_path(File.dirname(__FILE__) + '/data/sample_AndroidManifest.xml') }
    let(:bin_xml){ File.open(bin_xml_path, 'rb') {|f| f.read } }
    let(:manifest){ Android::Manifest.new(bin_xml) }

    describe "#components" do
      subject { manifest.components }
      it { should be_kind_of Array }
      it { subject[0].should be_kind_of Android::Manifest::Component }
    end

    describe "#package_name" do
      subject { manifest.package_name }
      it { should == "example.app.sample" }
    end

    describe "#version_code" do
      subject { manifest.version_code}
      it { should == 101 }
    end

    describe "#version_name" do
      subject { manifest.version_name}
      it { should == "1.0.1-malware2" }
    end

    describe "#min_sdk_ver" do
      subject { manifest.min_sdk_ver}
      it { should == 10 }
    end

    describe "#target_sdk_version" do
      subject { manifest.target_sdk_version}
      it { should == 0 }
    end

    describe "#label" do
      subject { manifest.label }
      it { should == "@0x7f040001" }

      context "with real apk file" do
        let(:tmp_path){ File.expand_path(File.dirname(__FILE__) + '/data/sample.apk') }
        let(:apk) { Android::Apk.new(tmp_path) }
        let(:manifest){ apk.manifest }
        subject { manifest.label }
        it { should eq 'Sample' }
        context 'when assign lang code' do
          subject { manifest.label('ja') }
          it { should eq 'Sample' }
        end
      end
    end

    describe "#doc" do
      subject { manifest.doc }
      it { should be_instance_of REXML::Document }
    end

    describe "#to_xml" do
      let(:raw_xml){ str = <<EOS
<manifest xmlns:android='http://schemas.android.com/apk/res/android' android:versionCode='101' android:versionName='1.0.1-malware2' package='example.app.sample'>
    <uses-sdk android:minSdkVersion='10'/>
    <uses-permission android:name='android.permission.INTERNET'/>
    <uses-permission android:name='android.permission.WRITE_EXTERNAL_STORAGE'/>
    <application android:label='@0x7f040001' android:icon='@0x7f020000' android:debuggable='true'>
        <activity android:label='@0x7f040001' android:name='example.app.sample.SampleActivity'>
            <intent-filter>
                <action android:name='android.intent.action.MAIN'/>
                <category android:name='android.intent.category.LAUNCHER'/>
            </intent-filter>
        </activity>
    </application>
</manifest>
EOS
        str.strip
      }

      subject { manifest.to_xml }
      it "should return correct xml string" do
        subject.should == raw_xml
      end
    end

    describe "#launcher_activities" do
      subject { manifest.launcher_activities }
      it "should return the correct launcher activity" do
        subject.first.name.should == "example.app.sample.SampleActivity"
      end
    end
  end

  context "with sample_AndroidManifest_with_redundant_intentfilters.xml" do
    let(:bin_xml_path){ File.expand_path(File.dirname(__FILE__) + '/data/sample_AndroidManifest_with_redundant_intentfilters.xml') }
    let(:bin_xml){ File.open(bin_xml_path, 'rb') {|f| f.read } }
    let(:manifest){ Android::Manifest.new(bin_xml) }

    describe "#launcher_activities" do
      subject { manifest.launcher_activities }
      it "should return only one activity even if it has multiple redundant launcher intent filters" do
        subject.length.should == 1
        subject.first.name.should == "com.example.MainActivity"
      end
    end
  end
end
