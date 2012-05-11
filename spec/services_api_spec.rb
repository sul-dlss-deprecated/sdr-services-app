require 'spec_helper'

describe Sdr::ServicesApi do
  
  def app
    @app ||= Sdr::ServicesApi
  end

  describe "POST '/sdr/objects/{druid}/cm-inv-diff'" do
    let(:content_md) { <<-EOXML
      <?xml version="1.0"?>
      <contentMetadata type="sample" objectId="druid:jq937jp0017">
        <resource type="version" sequence="1" id="version-2">
          <file datetime="2012-03-26T08:15:11-06:00" size="40873" id="title.jpg">
            <checksum type="MD5">1a726cd7963bd6d3ceb10a8c353ec166</checksum>
            <checksum type="SHA-1">583220e0572640abcd3ddd97393d224e8053a6ad</checksum>
          </file>
          <file datetime="2012-03-26T09:35:15-06:00" size="32915" id="page-1.jpg">
            <checksum type="MD5">c1c34634e2f18a354cd3e3e1574c3194</checksum>
            <checksum type="SHA-1">0616a0bd7927328c364b2ea0b4a79c507ce915ed</checksum>
          </file>
          <file datetime="2012-03-26T09:23:36-06:00" size="39450" id="page-2.jpg">
            <checksum type="MD5">82fc107c88446a3119a51a8663d1e955</checksum>
            <checksum type="SHA-1">d0857baa307a2e9efff42467b5abd4e1cf40fcd5</checksum>
          </file>
          <file datetime="2012-03-26T09:24:39-06:00" size="19125" id="page-3.jpg">
            <checksum type="MD5">a5099878de7e2e064432d6df44ca8827</checksum>
            <checksum type="SHA-1">c0ccac433cf02a6cee89c14f9ba6072a184447a2</checksum>
          </file>
        </resource>
      </contentMetadata>
      EOXML
    }
    
    it "returns diff xml between content metadata and a specific version" do
      post '/sdr/objects/druid:jq937jp0017/cm-inv-diff?version=1', content_md
      last_response.should be_ok
      last_response.body.should =~ /<fileInventoryDifference/
    end
    
    it "handles version as an optional paramater" do
      post '/sdr/objects/druid:jq937jp0017/cm-inv-diff', content_md
      last_response.should be_ok
      last_response.body.should =~ /<fileInventoryDifference/
    end
    
  end
end
