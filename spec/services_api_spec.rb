require 'spec_helper'

describe Sdr::ServicesApi do
  
  def app
    @app ||= Sdr::ServicesApi
  end

  describe "POST '/objects/{druid}/cm-inv-diff'" do

    let(:content_md) { <<-EOXML
      <?xml version="1.0"?>
      <contentMetadata type="sample" objectId="druid:jq937jp0017">
        <resource type="version" sequence="1" id="version-2">
          <file datetime="2012-03-26T08:15:11-06:00" size="40873" id="title.jpg" shelve="yes" publish="yes" preserve="yes">
            <checksum type="MD5">1a726cd7963bd6d3ceb10a8c353ec166</checksum>
            <checksum type="SHA-1">583220e0572640abcd3ddd97393d224e8053a6ad</checksum>
          </file>
          <file datetime="2012-03-26T09:35:15-06:00" size="32915" id="page-1.jpg" shelve="yes" publish="yes" preserve="yes">
            <checksum type="MD5">c1c34634e2f18a354cd3e3e1574c3194</checksum>
            <checksum type="SHA-1">0616a0bd7927328c364b2ea0b4a79c507ce915ed</checksum>
          </file>
          <file datetime="2012-03-26T09:23:36-06:00" size="39450" id="page-2.jpg" shelve="yes" publish="yes" preserve="yes">
            <checksum type="MD5">82fc107c88446a3119a51a8663d1e955</checksum>
            <checksum type="SHA-1">d0857baa307a2e9efff42467b5abd4e1cf40fcd5</checksum>
          </file>
          <file datetime="2012-03-26T09:24:39-06:00" size="19125" id="page-3.jpg" shelve="yes" publish="yes" preserve="yes">
            <checksum type="MD5">a5099878de7e2e064432d6df44ca8827</checksum>
            <checksum type="SHA-1">c0ccac433cf02a6cee89c14f9ba6072a184447a2</checksum>
          </file>
        </resource>
      </contentMetadata>
      EOXML
    }

    let(:bad_content_md) { <<-EOXML
      <contentMetadata type="sample" objectId="druid:jq937jp0017">
        <resource type="version" sequence="1" id="version-2">
          <file datetime="2012-03-26T08:15:11-06:00" size="40873" id="title.jpg" shelve="yes" publish="yes" preserve="yes">
            <checksum type="SHA-1">583220e0572640abcd3ddd97393d224e8053a6ad</checksum>
          </file>
          <file datetime="2012-03-26T09:35:15-06:00"  id="page-1.jpg" shelve="yes" publish="yes" preserve="yes">
            <checksum type="MD5">c1c34634e2f18a354cd3e3e1574c3194</checksum>
            <checksum type="SHA-1">0616a0bd7927328c364b2ea0b4a79c507ce915ed</checksum>
          </file>
    EOXML
    }

    let(:empty_subset_md) { <<-EOXML
      <contentMetadata type="image" objectId="druid:ms205ty4764">
        <resource type="image" sequence="1" id="ms205ty4764_1">
          <label>Item 1</label>
          <file preserve="no" shelve="no" id="DLC1120b_001_001r_0_B_0365_packflat8.tif" publish="no" mimetype="image/tiff" size="39100812">
            <checksum type="md5">f3a8a45d5526ca9911b7eea600b2124a</checksum>
            <checksum type="sha1">d9cbce3070942e63b1e4bebc4e6f8232fceb148a</checksum>
            <imageData width="7216" height="5412"/>
          </file>
        </resource>
        <resource type="image" sequence="2" id="ms205ty4764_2">
          <label>Item 2</label>
          <file preserve="no" shelve="no" id="DLC1120b_001_001r_0_B_0450_packflat8.tif" publish="no" mimetype="image/tiff" size="39100812">
            <checksum type="md5">af1ae04394731b20a455c3f3b6abc804</checksum>
            <checksum type="sha1">9b883f6e234ed2a1912722bdee21ac9113530ac2</checksum>
            <imageData width="7216" height="5412"/>
          </file>
        </resource>
        <resource type="image" sequence="3" id="ms205ty4764_3">
          <label>Item 3</label>
          <file preserve="no" shelve="no" id="DLC1120b_001_001r_0_B_0465_packflat8.tif" publish="no" mimetype="image/tiff" size="39100812">
            <checksum type="md5">5e7a1dbf0f0bed4589ac6096770eb273</checksum>
            <checksum type="sha1">a098c4a0d00d1ec8c564e266efedc9adfc0dd583</checksum>
            <imageData width="7216" height="5412"/>
          </file>
        </resource>
      </contentMetadata>
    EOXML
    }

    # RSpec uses a method_missing trick for the be_* expectation.
    # Whenever it catches a call to be_foo, it creates an expectation to
    # match that #foo? on the receiver is true.
    # Since Rack's response object responds to #ok?, the be_ok expectation works.


    it "returns diff xml between content metadata and a specific version" do
      authorize SdrServices::Config.username, SdrServices::Config.password
      post '/objects/druid:jq937jp0017/cm-inv-diff?version=1', content_md
      last_response.should be_ok
      last_response.body.should =~ /<fileInventoryDifference/
    end

    it "returns 400 Bad Request if posted content metadata is invalid" do
      authorize SdrServices::Config.username, SdrServices::Config.password
      post '/objects/druid:jq937jp0017/cm-inv-diff?version=1', bad_content_md
      last_response.should_not be_ok
      # last_response.status.should == 400 #(but error handlers not translating errors in dev)
      last_response.body.should =~ /Moab::InvalidMetadataException/
      last_response.body.should =~ /missing md5/
    end
    
    it "returns a diff against the latest version if the version parameter is not passed in" do
      authorize SdrServices::Config.username, SdrServices::Config.password
      post '/objects/druid:jq937jp0017/cm-inv-diff', content_md
      last_response.should be_ok
            
      diff = Nokogiri::XML(last_response.body)
      diff.at_xpath('/fileInventoryDifference/@basis').value.should == 'v3-contentMetadata-all'
    end

    it "returns a diff against the latest version if an empty version param (?version=) is passed in" do
      authorize SdrServices::Config.username, SdrServices::Config.password
      post '/objects/druid:jq937jp0017/cm-inv-diff?version=', content_md
      last_response.should be_ok
      diff = Nokogiri::XML(last_response.body)
      diff.at_xpath('/fileInventoryDifference/@basis').value.should == 'v3-contentMetadata-all'
    end

    it "returns an empty diff if the base version does not exist and the requested subset is empty" do
      authorize SdrServices::Config.username, SdrServices::Config.password
      post '/objects/druid:ms205ty4764/cm-inv-diff?subset=shelve', empty_subset_md
      last_response.should be_ok
      diff = Nokogiri::XML(last_response.body)
      inventory_diff = <<-EOF
        <fileInventoryDifference objectId="druid:ms205ty4764" differenceCount="0" basis="v0" other="new-contentMetadata-shelve" >
          <fileGroupDifference groupId="content" differenceCount="0" identical="0" renamed="0" modified="0" deleted="0" added="0">
            <subset change="identical" count="0"/>
            <subset change="renamed" count="0"/>
            <subset change="modified" count="0"/>
            <subset change="deleted" count="0"/>
            <subset change="added" count="0"/>
          </fileGroupDifference>
        </fileInventoryDifference>
      EOF
      diff.to_xml.gsub(/reportDatetime=".*?"/,'').should be_equivalent_to(inventory_diff)
    end


    it "returns versionAdditions xml between content metadata and a specific version" do
      authorize SdrServices::Config.username, SdrServices::Config.password
      post '/objects/druid:jq937jp0017/cm-adds?version=3', content_md
      last_response.should be_ok
      last_response.body.should =~ /<fileInventory type="additions"/
    end

    it "handles version as an optional paramater" do
      authorize SdrServices::Config.username, SdrServices::Config.password
      post '/objects/druid:jq937jp0017/cm-inv-diff', content_md
      last_response.should be_ok
      last_response.body.should =~ /<fileInventoryDifference/
    end

  end

  describe "Version information" do

    it "returns a menu" do
      authorize SdrServices::Config.username, SdrServices::Config.password
      get '/objects/druid:jq937jp0017'
      last_response.body.should == <<-EOF
<html><head>
<title>Object = druid:jq937jp0017 - Version = 3 of 3</title>
</head><body>
<h3>Object = druid:jq937jp0017 - Version = 3 of 3</h3>
<ul>
<li><a href='http://example.org/objects/druid:jq937jp0017/list/content'>get content list</a></li>
<li><a href='http://example.org/objects/druid:jq937jp0017/list/metadata'>get metadata list</a></li>
<li><a href='http://example.org/objects/druid:jq937jp0017/list/manifests'>get manifest list</a></li>
<li><a href='http://example.org/objects/druid:jq937jp0017/version_list'>get version list</a></li>
</ul>
</body></html>
EOF
    end

    it "returns current version number" do
      authorize SdrServices::Config.username, SdrServices::Config.password
      get '/objects/druid:jq937jp0017/current_version'
      last_response.should be_ok
      last_response.body.should == '<currentVersion>3</currentVersion>'
    end

    it "returns 404 if object not in SDR" do
      authorize SdrServices::Config.username, SdrServices::Config.password
      get '/objects/druid:zz999yy0000/current_version'
      last_response.should_not be_ok
      # last_response.status.should == 404 #(but error handlers not translating errors in dev)
      last_response.body.should =~ /Moab::ObjectNotFoundException/
    end

    it "returns current version metadata" do
      authorize SdrServices::Config.username, SdrServices::Config.password
      get '/objects/druid:jq937jp0017/version_metadata'
      last_response.should be_ok
      last_response.body.should =~ /<versionMetadata objectId="druid:ab123cd4567">/
    end

    it "returns version list" do
      authorize SdrServices::Config.username, SdrServices::Config.password
      get '/objects/druid:jq937jp0017/version_list'
      last_response.should be_ok
      last_response.body.should =~ %r{<title>Object = druid:jq937jp0017 - Versions</title>}
    end

  end

  describe "version differences" do

    it "returns a version differences report" do
      authorize SdrServices::Config.username, SdrServices::Config.password
      get '/objects/druid:jq937jp0017/version_differences?base=1&compare=3'
      last_response.should be_ok
      last_response.body.should =~ /<fileInventoryDifference objectId="druid:jq937jp0017"/
    end

  end

  describe "file list" do

    it "should return a list of manifest files" do
      authorize SdrServices::Config.username, SdrServices::Config.password
      get '/objects/druid:jq937jp0017/list/manifests'
      last_response.body.should =~ %r{<title>Object = druid:jq937jp0017 - Version = 3 of 3 - Manifests</title>}
    end

    it "should return a list of content files" do
      authorize SdrServices::Config.username, SdrServices::Config.password
      get '/objects/druid:jq937jp0017/list/content'
      last_response.body.should =~ %r{<title>Object = druid:jq937jp0017 - Version = 3 of 3 - Content</title>}
    end

    it "should return a list of metadata files" do
      authorize SdrServices::Config.username, SdrServices::Config.password
      get '/objects/druid:jq937jp0017/list/metadata'
      last_response.body.should =~ %r{<title>Object = druid:jq937jp0017 - Version = 3 of 3 - Metadata</title>}
    end

  end

  describe "file retrieval" do

    it "returns a content file" do
      authorize SdrServices::Config.username, SdrServices::Config.password
      get '/objects/druid:jq937jp0017/content/title.jpg?version=1'
      last_response.should be_ok
      last_response.header["content-type"].should =~ %r{image/jpeg}
    end

    it "returns a content file using a signature" do
      authorize SdrServices::Config.username, SdrServices::Config.password
      get '/objects/druid:jq937jp0017/content/title.jpg?signature=40873,1a726cd7963bd6d3ceb10a8c353ec166,583220e0572640abcd3ddd97393d224e8053a6ad'
      last_response.should be_ok
      last_response.header["content-type"].should =~ %r{image/jpeg}
    end


    #it "returns a content file signature" do
    #  authorize SdrServices::Config.username, SdrServices::Config.password
    #  get '/objects/druid:jq937jp0017/content/title.jpg?signature=true'
    #  last_response.should be_ok
    #  last_response.header["content-type"].should =~ %r{application/xml}
    #  last_response.body.should =~ /<fileSignature size="40873" md5="1a726cd7963bd6d3ceb10a8c353ec166" sha1="583220e0572640abcd3ddd97393d224e8053a6ad"\/>/
    #end

    it "returns a metadata file" do
      authorize SdrServices::Config.username, SdrServices::Config.password
      get '/objects/druid:jq937jp0017/metadata/provenanceMetadata.xml'
      last_response.should be_ok
      last_response.body.should =~ /<provenanceMetadata/
    end

    #it "returns a metadata file signature" do
    #   authorize SdrServices::Config.username, SdrServices::Config.password
    #   get '/objects/druid:jq937jp0017/metadata/provenanceMetadata.xml?signature'
    #   last_response.should be_ok
    #   last_response.body.should =~ /<fileSignature size="564" md5="17071e4607de4b272f3f06ec76be4c4a" sha1="b796a0b569bde53953ba0835bb47f4009f654349"\/>/
    # end

    it "returns the most recent manifest file if version param is omitted" do
      authorize SdrServices::Config.username, SdrServices::Config.password
      get '/objects/druid:jq937jp0017/manifest/signatureCatalog.xml'
      last_response.should be_ok
      last_response.body.should =~ /<signatureCatalog objectId="druid:jq937jp0017" versionId="3"/
    end

    #it "returns a manifest file signature" do
    #  authorize SdrServices::Config.username, SdrServices::Config.password
    #  get '/objects/druid:jq937jp0017/manifest/signatureCatalog.xml?signature'
    #  last_response.should be_ok
    #  last_response.body.should =~ /<fileSignature size="4210" md5="a4b5e6f14bcf0fd5f8e295c0001b6f19" sha1="e9804e90bf742b2f0c05858e7d37653552433183"\/>/
    #end

    it "returns a remediated contentMetadata file" do
      authorize SdrServices::Config.username, SdrServices::Config.password
      get '/objects/druid:jq937jp0017/cm-remediate?version=1'
      last_response.should be_ok
      last_response.body.should =~ /<contentMetadata/
    end

    it "returns 404 File not found, if posted content metadata is invalid" do
      authorize SdrServices::Config.username, SdrServices::Config.password
      get '/objects/druid:jq937jp0017/metadata/provenanceMetadata.xxx'
      last_response.should_not be_ok
      # last_response.status.should == 404 #(but error handlers not translating errors in dev)
      last_response.errors.should =~ /Moab::FileNotFoundException/
      last_response.errors.should =~ /metadata file provenanceMetadata.xxx not found/
    end

  end

  describe "special requests" do

    #it "should rsync a file to specified destination" do
    #  authorize SdrServices::Config.username, SdrServices::Config.password
    #  get '/objects/druid:jq937jp0017/rsync', "/tmp"
    #  last_response.should be_ok
    #  last_response.body.should =~ /^rsync/
    #end

    it "should return GB used by storage" do
      authorize SdrServices::Config.username, SdrServices::Config.password
      get '/gb_used'
      last_response.should be_ok
      last_response.body.should =~ /\d*/
    end


  end

  describe "helpers" do
    it "should correctly handle file paths" do
      authorize SdrServices::Config.username, SdrServices::Config.password
      get '/test/file_id_param/a'
      last_response.body.should == 'a'
      get '/test/file_id_param/a/b'
      last_response.body.should == 'a/b'
    end

  end

end
