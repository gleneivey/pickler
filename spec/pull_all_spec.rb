require File.join(File.dirname(__FILE__),'spec_helper')

describe Pickler, "when pulling all features from Tracker" do
  before(:all) do
    @domain        = "http://www.pivotaltracker.com:80"
    @service       = "/services/v2/"

    @features_path = File.join( File.dirname(__FILE__), '..', 'features', '' )
    # test data in "*.feature.original" files
    FileUtils.rm Dir.glob( @features_path + '**/*.feature')
  end

  after do # clean up the files the test creates
    FileUtils.rm Dir.glob( @features_path + '**/*.feature')
  end


  it "should terminate with success" do
    Kernel.should_receive(:exit).with(0).and_return(nil)
    begin
      Pickler.run([ "pull" ])
    rescue SystemExit
    end
  end

  it "should GET the story list with a filter" do
    verify_filter_path_match( /stories\?filter=Scenario\+includedone%3Atrue/ )

    begin
      Pickler.run([ "pull" ])
    rescue SystemExit
    end
    
    @filter_path_match.should eql(1)
  end


        # test data, story [number] [state]
        #   2 unscheduled, 3 unstarted, 5 started, 4 finished,
        #   6 delivered, 1 accepted, 7 rejected
  it "should write .feature files for pulled stories (no options)" do
    begin
      Pickler.run([ "pull" ])
    rescue SystemExit
    end

    File.exist?( @features_path + "2.feature" ).should be_false
    File.exist?( @features_path + "3.feature" ).should be_false
    File.exist?( @features_path + "8.feature" ).should be_false
    File.exist?( @features_path + "9.feature" ).should be_false
    [ 1, 4, 5, 6, 7 ].each do |feat|
      File.readlines( @features_path + feat.to_s + ".feature").should eql(
        File.readlines( @features_path + feat.to_s + ".feature.original") )
    end
  end


  it "should not filter by 'state' when --any-state" do
    begin
      Pickler.run([ "pull", "--any-state" ])
    rescue SystemExit
    end

    File.exist?( @features_path + "8.feature" ).should be_false
    File.exist?( @features_path + "9.feature" ).should be_false
    (1..7).each do |feat|
      File.readlines( @features_path + feat.to_s + ".feature").should eql(
        File.readlines( @features_path + feat.to_s + ".feature.original") )
    end
  end


  it "should not filter on 'Scenario' when --any-description" do
    verify_filter_path_match( /stories\?filter=includedone%3Atrue/ )

    begin
      Pickler.run([ "pull", "--any-description" ])
    rescue SystemExit
    end
    
    @filter_path_match.should eql(1)
  end


  it "should include non-Cucumber stories when --any-description" do
    begin
      Pickler.run([ "pull", "--any-description" ])
    rescue SystemExit
    end

    File.exist?( @features_path + "2.feature" ).should be_false
    File.exist?( @features_path + "3.feature" ).should be_false
    [ 1, 4, 5, 6, 7, 8 ].each do |feat|
      File.readlines( @features_path + feat.to_s + ".feature").should eql(
        File.readlines( @features_path + feat.to_s + ".feature.original") )
    end
  end

private

  def verify_filter_path_match( regExp )
    # make a mock to check the URLs of requests Pickler generates
    mock_http = mock("Mock-HTTP")

    # for all requests, get responses from FakeWeb; check each path for filter
    @filter_path_match = 0
    mock_http.stub!(:request).with(instance_of(Net::HTTP::Get)).
      and_return { | request |
      if request.path =~ regExp
        @filter_path_match+= 1
      end
      FakeWeb.response_for(:get, @domain + request.path)
    }

    # use our mock for HTTP access attempts
    Net::HTTP.should_receive(:new).and_return(mock_http)
  end
end
