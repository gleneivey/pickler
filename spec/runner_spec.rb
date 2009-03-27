require File.join(File.dirname(__FILE__),'spec_helper')

describe Pickler, "when pushing a new .feature file" do
  before do

        # setup response to "push" here, not global, so that if
        # used by other *_spec's, we won't collide.  Only needed for PUTs
    url = "http://www.pivotaltracker.com/services/v2/projects/1/stories"
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
end
