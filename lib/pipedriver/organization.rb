module Pipedriver
  class Organization < APIResource
    include Pipedriver::APIOperations::List
    include Pipedriver::APIOperations::Create
    include Pipedriver::APIOperations::Edit
    include Pipedriver::APIOperations::Delete

  end
end
