# Indexing in Argo

## Indexing overview

Argo uses Solr as an index for faceting and searching data in the corresponding Fedora repository.

Objects can be reindexed as a result of a couple different things:
* An object is edited in Fedora (by Argo or another application), and a message is sent to an endpoint in the dor_indexing_app service (`/dor/reindex/PID`), triggering a reindex of the object.
* An object is part of a batch of objects queued for bulk indexing within Argo (deprecated)

To support indexing, dor-services will:
* load the object from Fedora.
* create a Solr document representing the object (using its `to_solr` method).
* save the document to the Solr instance specified in the configuration, possibly committing immediately.

## Argo::Indexer

This is deprecated for `Dor::IndexingService` in `dor-services`.

### Reusable methods

The `Argo::Indexer` class provides re-usable methods for indexing:
* `Argo::Indexer.reindex_pid` takes a PID (druid) and reindexes it as per the above explanation (load from Fedora, create Solr doc, save to Solr).  It also takes an optional logger to use instead of the default (which might be useful for something like logging info about a request triggering the reindex from in the Rails app).  Finally, it gives the option to swallow exceptions.  The default is to let them bubble up, but a caller doing bulk indexing might wish to proceed and index everything it can, with the expectation that the logs will be reviewed later for errors (though note that only `StandardError` errors get trapped, all others always propogate).  The outcome of each indexing attempt is logged, with the PID (druid) and status of the attempt.

## Bulk reindexing

Queue the IDs of the objects that need to be reindexed using `sulmq`, for processing by `dor_indexing_app`. See the [`dor_indexing_app`](https://github.com/sul-dlss/dor_indexing_app) Wiki for the new methods. We've had issues with our Fedora instance's `risearch` results (see Issue \#380). As such, this [dump script](https://github.com/sul-dlss/argo/blob/master/bin/dump_fedora_pids.rb) may be useful in obtaining a full PID list from DOR, in the event that there's no _trustworthy_ Solr index from which to get a list of IDs.

There are many scenarios where you might want to reindex many or all of the objects in Fedora in bulk.  E.g.: migrating bad data that resulted from a bug in a dor-services `to_solr` method once that bug is fixed, catching up the index if some indexing messages from other applications got dropped (e.g. due to network or Karaf trouble), or rebuilding the index after inadvertent corruption or deletion.
