module Pipedriver
  class Person < APIResource
    include Pipedriver::APIOperations::List
    include Pipedriver::APIOperations::Create
    include Pipedriver::APIOperations::Edit
    include Pipedriver::APIOperations::Delete

    # The API uses 'persons' instead of 'people' as the plural of person.
    def self.url
      "/persons"
    end
  end
end
