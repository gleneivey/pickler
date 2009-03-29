require File.join(File.dirname(__FILE__),'spec_helper')

describe Pickler, "when pushing a new .feature file" do

  before do
    @domain         = "http://www.pivotaltracker.com:80"
    @project1Path   = "/services/v2/projects/1"
    @storiesPath    = "/services/v2/projects/1/stories"

        # setup response to "push" here, not global, so that if
        # other *_spec's create stories, we won't collide.
        # (Only needed for POSTs)
    url = @domain + @storiesPath
    responseFile = File.join(File.dirname(__FILE__), 'tracker',
                             'projects', '1', 'stories.two.http')
    FakeWeb.register_uri(:post, url, :response => responseFile)

        # have to copy our pristine test file each time because
        # it will be modified
    @testFeaturePath = File.join('features', 'stories', 'two.feature')
    originalPath = @testFeaturePath + ".original"
    FileUtils.cp(originalPath, @testFeaturePath)
  end

  it "should terminate with success" do
    Kernel.should_receive(:exit).with(0).and_return(nil)
    begin
      Pickler.run([ "push", @testFeaturePath ])
    rescue SystemExit
    end
  end

  it "should have POST'ed the Feature's name" do

        # would be nice to use our FakeWeb setup for everything, but
        # can't assert on content of requests going into FakeWeb
    # make a mock to check our POST data; has to handle all requests
    # because 'tracker.rb' only creates one 'http' instance and caches it
    mockHttp = mock("Mock-HTTP")
    # don't care about requests to get project info
    mockHttp.stub!(:request).and_return(
      FakeWeb.response_for(:get, @domain + @project1Path) )
    # POST request is for "push" under test, check body content
    mockHttp.should_receive(:request).once.with(
      anything(), %r%<name>Fire photon torpedoes</name>% ).and_return(
        FakeWeb.response_for(:post, @domain + @storiesPath) )
    # use our mock for HTTP access attempts
    Net::HTTP.should_receive(:new).and_return(mockHttp)

    begin
      Pickler.run([ "push", @testFeaturePath ])
    rescue SystemExit
    end
  end

  it "should update the .feature with the new story's URL" do
    begin
      Pickler.run([ "push", @testFeaturePath ])
    rescue SystemExit
    end

    File.open(@testFeaturePath).gets.chomp.should eql(
      "# http://www.pivotaltracker.com/story/show/535216" )
  end
end
