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

    pickler_output_file_for_feature(2).should_not exist
    pickler_output_file_for_feature(3).should_not exist
    pickler_output_file_for_feature(8).should_not exist
    pickler_output_file_for_feature(9).should_not exist
    [ 1, 4, 5, 6, 7 ].each do |story_num|
      pickler_output_content_for_feature(story_num).should eql(
        expected_content_for_feature(story_num) )
    end
  end


  it "should not filter by 'state' when --any-state" do
    begin
      Pickler.run([ "pull", "--any-state" ])
    rescue SystemExit
    end

    pickler_output_file_for_feature(8).should_not exist
    pickler_output_file_for_feature(9).should_not exist
    (1..7).each do |story_num|
      pickler_output_content_for_feature(story_num).should eql(
        expected_content_for_feature(story_num) )
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

    pickler_output_file_for_feature(2).should_not exist
    pickler_output_file_for_feature(3).should_not exist
    [ 1, 4, 5, 6, 7, 8 ].each do |story_num|
      pickler_output_content_for_feature(story_num).should eql(
        expected_content_for_feature(story_num) )
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

  def pickler_output_content_for_feature(story_num)
    File.readlines(@features_path + story_num.to_s + ".feature")
  end

  def expected_content_for_feature(story_num)
    File.readlines(@features_path + story_num.to_s + ".feature.original")
  end

  class FileName
    def initialize(path) @path= path;       end
    def exist?()         File.exist? @path; end
  end
  def pickler_output_file_for_feature(story_num)
    FileName.new(@features_path + story_num.to_s + ".feature")
  end
end
