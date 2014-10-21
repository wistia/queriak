# queriak

This is a proof of concept that shows that riak-search cannot be used to
perform unique (or "distinct") counts on a given field reliably. We attempt this
via solr4's "grouping" feature, which optionally returns the number of groups.

The Riak Ruby client does not yet support the groupings feature, so we construct
a curl command to perform the search instead.

This fails because [unique group counts are added between shards, so duplicate
copies are double-counted](https://cwiki.apache.org/confluence/display/solr/Result+Grouping?focusedCommentId=47384139#comment-47384139).

[See also](https://wiki.apache.org/solr/FieldCollapsing).

We use stats.calcDistinct to iterate over the result set to verify whether our
final count is truly the distinct count or whether it is artificially inflated.

## Quick Demo (Appears to Work):

`brew install riak`

Open `/usr/local/Cellar/riak/2.0.1/libexec/etc/riak.conf` and set `search = on`

```
ulimit -n 32768
riak start
```

Run: `ruby proveit.rb`

Riak will generate 1000 random entries, and then perform two similar searches.
The first shows you total results, and the second shows you distinct results.

## Multi-Node Proof of Failure:

Make sure riak is stopped with `riak stop`

Install erlang R16 via `brew install -v --use-gcc erlang-r16`

Install multi-node riak:

```
curl -O http://s3.amazonaws.com/downloads.basho.com/riak/2.0/2.0.1/riak-2.0.1.tar.gz
tar zxvf riak-2.0.1.tar.gz
cd riak-2.0.1
make devrel DEVNODES=5
```

Open `dev/dev1/etc/riak.conf` and change `search = off` to `search = on`.
Repeat for dev2, dev3, dev4 and dev5.

```
ulimit -n 32768
for node in dev/dev*; do $node/bin/riak start; done
for n in {2..5}; do dev/dev$n/bin/riak-admin cluster join dev1@127.0.0.1; done
dev/dev1/bin/riak-admin cluster plan
dev/dev1/bin/riak-admin cluster commit
dev/dev1/bin/riak-admin member-status
```

Run: `ruby proveit.rb proof`

## Output

Here is a sample output from the program, with both run types:

```
$ ruby proveit.rb 
Generating object 100
Generating object 200
Generating object 300
Generating object 400
Generating object 500
Generating object 600
Generating object 700
Generating object 800
Generating object 900
Generating object 1000
Waiting 1 second for indexing
How many total loads were there for account 7? num_found should be ~50.
44
How many unique loads were there for account 7? ngroups should be ~22-28.
24
Same question with stats.calcDistinct: countDistinct should be ~22-28.
24

$ ruby proveit.rb proof
Generating object 100
Generating object 200
Generating object 300
Generating object 400
Generating object 500
Generating object 600
Generating object 700
Generating object 800
Generating object 900
Generating object 1000
Waiting 1 second for indexing
How many total loads were there for account 7? num_found should be ~50.
44
How many unique loads were there for account 7? ngroups should be ~22-28.
38
Same question with stats.calcDistinct: countDistinct should be ~22-28.
22
```

## Credits

Thanks to Wes Jossey for demoing solr4's groupings implementation for me and
giving me just enough hope to try this out.
