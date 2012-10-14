require 'helper'

describe 'configuration' do

  after do
    Pipedriver.reset
  end

  describe '.configure' do
    Pipedriver::Configuration::VALID_CONFIG_KEYS.each do |key|
      it "should set the #{key}" do 
        Pipedriver.configure do |config|
          config.send("#{key}=", key)
          Pipedriver.send(key).must_equal key
        end
      end
    end
  end

  Pipedriver::Configuration::VALID_CONFIG_KEYS.each do |key|
    describe ".#{key}" do
      it 'should return the default value' do
        Pipedriver.send(key).must_equal Pipedriver::Configuration.const_get("DEFAULT_#{key.upcase}")
      end
    end
  end
end