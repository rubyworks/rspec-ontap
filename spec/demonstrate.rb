describe "demonstration" do

  it "should show this passing" do
    1.should == 1
  end

  it "should show this failing" do
    1.should == 2
  end

  it "should show this raising an error" do
    raise NameError
  end

end

