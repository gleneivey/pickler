require File.join(File.dirname(__FILE__),'spec_helper')

describe Pickler, "when pulling all features from Tracker" do
  before(:all) do
    @domain     = "http://www.pivotaltracker.com:80"
    @service    = "/services/v2/"

    @featuresPath = File.join( File.dirname(__FILE__), '..', 'features', '' )
    # test data in "*.feature.original" files
    FileUtils.rm Dir.glob( @featuresPath + '**/*.feature')
  end

  after do # clean up the files the test creates
    FileUtils.rm Dir.glob( @featuresPath + '**/*.feature')
  end


  it "should terminate with success" do
    Kernel.should_receive(:exit).with(0).and_return(nil)
    begin
      Pickler.run([ "pull" ])
    rescue SystemExit
    end
  end

  it "should GET the story list with a filter" do

    # make a mock to check the URLs of requests Pickler generates
    mockHttp = mock("Mock-HTTP")

    # for all requests, get responses from FakeWeb; check each path for filter
    @filterPathMatch = 0
    mockHttp.stub!(:request).with(instance_of(Net::HTTP::Get)).
      and_return { | request |
      if request.path =~ /stories\?filter=Scenario\+includedone%3Atrue/
        @filterPathMatch+= 1
      end
      FakeWeb.response_for(:get, @domain + request.path)
    }

    # use our mock for HTTP access attempts
    Net::HTTP.should_receive(:new).and_return(mockHttp)
    begin
      Pickler.run([ "pull" ])
    rescue SystemExit
    end
    
    @filterPathMatch.should eql(1)
  end


        # test data, story [number] [state]
        #   2 unscheduled, 3 unstarted, 5 started, 4 finished,
        #   6 delivered, 1 accepted, 7 rejected
  it "should write .feature files for pulled stories" do
    begin
      Pickler.run([ "pull" ])
    rescue SystemExit
    end

    File.exist?( @featuresPath + "2.feature" ).should be_false
    File.exist?( @featuresPath + "3.feature" ).should be_false
    [ 1, 4, 5, 6, 7 ].each do |feat|
      File.readlines( @featuresPath + feat.to_s + ".feature").should eql(
        File.readlines( @featuresPath + feat.to_s + ".feature.original") )
    end
  end
end
