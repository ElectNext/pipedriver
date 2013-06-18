# Pipedriver

TODO: Write a gem description

## Installation

Add this line to your application's Gemfile:

    gem 'pipedriver'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install pipedriver

## Usage

### Rails

   	# Create a new contact and set a task to send him a card in 3 days
   	
   	Pipedriver.api_key = 'YOUR_PIPEDRIVE_API_KEY'
   	
   	# Create a new contact
   	contact_attrs = {
      :name => "Gordon Morris",
      :email => "gordon@electnext.com",
      :phone => "319-385-7101"
    }
    create_resp = Pipedriver::Person.create(contact_attrs)
    
    # Get the ID of the newly created contact
    contact_id = create_resp.success ? create_resp.data["id"] : nil
    
    unless contact_id.nil?
      # Create the task
      new_activity_attrs = {
        :subject => 'Send a card', 
        :type => 'task', 
        :due_date => 2.days.from_now.to_s, 
        :person_id => contact_id 
      }
      activity_resp = Pipedriver::Activity.create(new_activity_attrs)
    end
    
    


TODO: Write more usage instructions here

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request