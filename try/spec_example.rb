describe "demonstration" do

  it "should show this passing" do
    expect(1).to == 1
  end

  it "should show this failing" do
    expect(1).to == 2
  end

  it "should show this raising an error" do
    raise NameError
  end

  it "should capture stdout" do
    puts "HELLO!"
  end

end

