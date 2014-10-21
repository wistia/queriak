require 'rubygems'
require 'bundler/setup'
require 'riak'
require 'timerizer'
require 'json'

require 'time'

NUM_INSERTS = 1000

TEST_TYPE = ARGV[0]
HTTP_PORT = (TEST_TYPE == 'proof') ? 10058 : 8098

# Setup
client = nil
if TEST_TYPE == 'proof'
  client = Riak::Client.new(
    nodes: [
      {host: '127.0.0.1', pb_port: 10017, http_port: 10018},
      {host: '127.0.0.1', pb_port: 10027, http_port: 10028},
      {host: '127.0.0.1', pb_port: 10037, http_port: 10038},
      {host: '127.0.0.1', pb_port: 10047, http_port: 10048},
      {host: '127.0.0.1', pb_port: 10057, http_port: 10058}
    ]
  )
else
  client = Riak::Client.new(
    nodes: [{host: '127.0.0.1'}]
  )
end

bucket = client.bucket('events')
begin
  client.create_search_index 'events_index'
  client.set_bucket_props bucket, {search_index: 'events_index'}
rescue
  puts "Race condition on bucket creation. Please run once more."
end

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

puts "How many total loads were there for account 7? num_found should be ~50."
puts client.search('events_index', 'type_s:load AND account_id_i:7', rows: 0)['num_found']

puts "How many unique loads were there for account 7? ngroups should be ~22-28."
puts JSON.parse(`curl "http://localhost:#{HTTP_PORT}/search/query/events_index?wt=json&indent=true&rows=0&q=type_s:load%20AND%20account_id_i:7&group=true&group.field=uuid_s&group.ngroups=true" --silent`)['grouped']['uuid_s']['ngroups']
