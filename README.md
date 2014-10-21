# queriak

This is a proof of concept that demonstrates how riak-search can be used to
perform unique (or "distinct") counts on a given field. This is done using
solr4's "grouping" feature, which optionally returns the number of groups.

The Riak Ruby client does not yet support the groupings feature, so we construct
a curl command to perform the search instead.

## Quick Demo:

`brew install riak`

Open `/usr/local/Cellar/riak/2.0.1/libexec/etc/riak.conf` and set `search = on`

```
ulimit -n 32768
riak start
```

Run: `./proveit.rb`

Riak will generate 1000 random entries, and then perform two similar searches.
The first shows you total results, and the second shows you distinct results.
