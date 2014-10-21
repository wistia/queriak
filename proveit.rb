require 'rubygems'
require 'bundler/setup'
require 'riak'
require 'timerizer'
require 'json'

require 'time'

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
    'account_id_i' => (rand * 10).to_i,
    'type_s' => ['load', 'play'].sample,
    'uuid_s' => "user-#{(rand * 30).to_i}",
    'media_id_i' => (rand * 90).to_i,
    # 'created_at_dt' => (rand * 100).to_i.days.ago.to_time.iso8601
  }
  obj.store
end

puts "Waiting 1 second for indexing"
sleep 1

# Search

puts "How many unique users loaded a media for account 7? ngroups should be ~22-28."
puts JSON.parse(`curl "http://localhost:8098/search/query/events_index?wt=json&indent=true&rows=0&q=type_s:load%20AND%20account_id_i:7&group=true&group.field=uuid_s&group.ngroups=true" --silent`)['grouped']['uuid_s']['ngroups']

puts "How many total loads were there for account 7? numFound should be ~50."
puts JSON.parse(`curl "http://localhost:8098/search/query/events_index?wt=json&indent=true&rows=0&q=type_s:load%20AND%20account_id_i:7" --silent`)['response']['numFound']
