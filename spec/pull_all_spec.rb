require File.join(File.dirname(__FILE__),'spec_helper')

describe Pickler, "when pulling all features from Tracker" do
  before do
    @domain     = "http://www.pivotaltracker.com:80"
    @service    = "/services/v2/"
  end

  after do # clean up the files the test creates
    FileUtils.rm Dir.glob( File.join( File.dirname(__FILE__), '..', 'features'
      ) + '/**/*.feature') # test data in "*.feature.original" files
  end


  it "should terminate with success" do
    Kernel.should_receive(:exit).with(0).and_return(nil)
    begin
      Pickler.run([ "pull" ])
    rescue SystemExit
    end
  end

  it "should GET the story list with a filter" do

    # make a mock to check the URL for getting the story list
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


        # story states: 2 unscheduled, 3 unstarted, 5 started, 4 finished,
        #               6 delivered, 1 accepted, 7 rejected
  it "should not GET stories in states: unscheduled, unstarted" do


  end


  it "should write .feature files for pulled stories" do
    begin
      Pickler.run([ "pull" ])
    rescue SystemExit
    end
  end
end
