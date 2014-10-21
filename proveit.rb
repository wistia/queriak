require 'rubygems'
require 'bundler/setup'
require 'riak'
require 'timerizer'
require 'json'

NUM_INSERTS = 1000

# Setup

client = Riak::Client.new(
  nodes: [{host: '127.0.0.1'}]
)

bucket = client.bucket('events')
client.create_search_index 'events_index'
client.set_bucket_props bucket, {search_index: 'events_index'}
## Inserts

NUM_INSERTS.times do |t|
  puts "Generating object #{t + 1}" if (t + 1) % 100 == 0
  obj = bucket.get_or_new(t.to_s)
  obj.data = {
    'type_s' => ['load', 'play'].sample,
    'uuid_s' => "user-#{(rand * 1000).to_i}",
    'media_id_i' => (rand * 100).to_i,
    'created_at_dt' => (rand * 100).to_i.days.ago
  }
  obj.store#(type: 'events_index')
end

puts "Waiting 3 seconds for indexing"
sleep 3

# Search

result = client.search('events', 'uuid_s:load')
puts result
puts "Found #{result['num_found']} loads."
