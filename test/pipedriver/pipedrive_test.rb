require 'helper'

describe Pipedriver do
  it 'should have a version' do
    Pipedriver::VERSION.wont_be_nil
  end
end