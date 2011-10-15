require 'spec_helper'
class FICSTestCallback
  def sought_callback(text)
    puts "in FICSTestCallback #{text}"
  end
end

#include Wrong
describe Chess::Client::FICS do
  #include Wrong
  before(:all) do
    @callback_object = FICSTestCallback.new
    puts "cb object"
    puts @callback_object.inspect
    @fics = Chess::Client::FICS.new(:username => 'badhorsey', :password => 'bvymdx', :log_file => 'log.txt', :callback_object => @callback_object)
    @fics.run
    sleep 5
  end
  
  after(:all) do
  end
  it "should login to fics" do
    @fics.sought
    puts Time.now
    eventually do 
      @callback_object.should_receive(:sought_callback) do |res|
        puts "in callback"
        puts res.inspect
      end
    end
    sleep 5
    puts Time.now
  end
end


