
World(Rack::Test::Methods)

Given /^I am a valid API user$/ do
  #@user = Factory(:user)
  authorize SdrServices::Config.username, SdrServices::Config.password
end

Given(/^I have (\d+) of "(.*?)" records$/) do |rows, element_name|
  druids = []
  n = rows.to_i
  n.times do |i|
    # generate a random DRUID (using randexp, see features/support/env.rb)
    druid = /[:lower:]{2}\d{3}[:lower:]{2}\d{4}/.generate
    druids.push(druid) unless druids.include? druid
  end
  druids.each do |druid|
    # Create a digital object with a random home_repository word of 3-5 letters.
    digital_object = {
        :digital_object_id => druid,
        :home_repository => /\w{3,5}/.generate
    }
    ArchiveCatalogSQL::DigitalObject.insert(digital_object)
  end
end

Given(/^I have (\d+) of "(.*?)" records in "(.*?)" repository$/) do |rows, element_name, repository|
  druids = []
  n = rows.to_i
  n.times do |i|
    # generate a random DRUID (using randexp, see features/support/env.rb)
    druid = /[:lower:]{2}\d{3}[:lower:]{2}\d{4}/.generate
    druids.push(druid) unless druids.include? druid
  end
  druids.each do |druid|
    # Create a digital object with a random home_repository word of 3-5 letters.
    digital_object = {
        :digital_object_id => druid,
        :home_repository => repository
    }
    ArchiveCatalogSQL::DigitalObject.insert(digital_object)
  end
end

Given(/^I send and accept "([^"]*)"$/) do |mime_type|
  if mime_type == 'XML'
    header 'Accept', 'text/xml'
    header 'Content-Type', 'text/xml'
  end
  if mime_type == 'JSON'
    header 'Accept', 'application/json'
    header 'Content-Type', 'application/json'
  end
end

When /^I send a GET request for "([^\"]*)"$/ do |path|
  get path
end

When /^I send a POST request to "([^\"]*)" with the following:$/ do |path, body|
  post path, body
end

When /^I send a PUT request to "([^\"]*)" with the following:$/ do |path, body|
  put path, body
end

When /^I send a DELETE request to "([^\"]*)"$/ do |path|
  delete path
end

Then /^the response should be "([^\"]*)"$/ do |status|
  last_response.status.should == status.to_i
end

Then(/^the "([^"]*)" response should have a "([^"]*)" array$/) do |mime_type, tag|
  if mime_type == 'XML'
    doc = Nokogiri::XML(last_response.body)
    doc.xpath("//#{tag}").length.should == 1
    doc.xpath("//#{tag}/@type").first.value.should == 'array'
  end
  if mime_type == 'JSON'
    # the JSON object has no child 'tag'
    doc = JSON.parse(last_response.body)
    doc.class.should == Array
  end
end

Then(/^the "([^"]*)" response should have (.*) of "([^"]*)" elements$/) do |mime_type, n_children, child_tag|
  if mime_type == 'XML'
    doc = Nokogiri::XML(last_response.body)
    doc.xpath("//#{child_tag}").length.should == n_children.to_i
  end
  if mime_type == 'JSON'
    doc = JSON.parse(last_response.body)
    doc.length.should == n_children.to_i
    # Each 'child' should be an object (it has no additional 'child-tag wrapping')
    doc.map { |e| e.class == Hash }.all?.should be true
  end
end

Then(/^the "([^"]*)" response should (.*) "([^"]*)" elements with "([^"]*)" repository$/) do |mime_type, n_children, child_tag, repo|
  if mime_type == 'XML'
    doc = Nokogiri::XML(last_response.body)
    repos = doc.xpath("//#{child_tag}/home-repository")
    repos.length.should == n_children.to_i
    repos.map {|r| r.children.first.to_s == repo }.all?.should be true
  end
  if mime_type == 'JSON'
    repos = JSON.parse(last_response.body)
    repos.length.should == n_children.to_i
    repos.map { |e| e.class == Hash }.all?.should be true
    repos.map {|r| r['home_repository'] == repo }.all?.should be true
  end
end


