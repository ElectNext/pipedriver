module Pipedriver
  class ProductField < APIResource
    include Pipedriver::APIOperations::List
    include Pipedriver::APIOperations::Create
    include Pipedriver::APIOperations::Delete

  end
end
