module Pipedriver
  class Filter < APIResource
    include Pipedriver::APIOperations::List
    include Pipedriver::APIOperations::Delete

  end
end
