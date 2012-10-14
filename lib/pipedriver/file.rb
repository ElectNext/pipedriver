module Pipedriver
  class File < APIResource
    include Pipedriver::APIOperations::List
    include Pipedriver::APIOperations::Edit
    include Pipedriver::APIOperations::Delete

  end
end
