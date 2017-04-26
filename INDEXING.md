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
* `Argo::Indexer.generate_index_logger` will create a logger instance that writes to the file specified in `Settings.INDEXER.LOG` with leading string obtained by executing the block provided to `generate_index_logger`.

## Bulk reindexing

This approach is deprecated, but we haven't yet ironed out a process for doing a full reindex from scratch. One alternate option to this approach would be to queue the IDs of the objects that need to be reindexed using `sulmq`, for processing by `dor_indexing_app`. See the [`dor_indexing_app`](https://github.com/sul-dlss/dor_indexing_app) Wiki for the new methods. The `Argo::PidGatherer`, in particular, is not migrated, but we've had issues with our Fedora instance's `risearch` results (see Issue \#380). As such, this [dump script](https://github.com/sul-dlss/argo/blob/master/bin/dump_fedora_pids.rb) may be useful in obtaining a full PID list from DOR, in the event that there's no _trustworthy_ Solr index from which to get a list of IDs.

There are many scenarios where you might want to reindex many or all of the objects in Fedora in bulk.  E.g.: migrating bad data that resulted from a bug in a dor-services `to_solr` method once that bug is fixed, catching up the index if some indexing messages from other applications got dropped (e.g. due to network or Karaf trouble), or rebuilding the index after inadvertent corruption or deletion.

The easiest way to do this (in terms of the least work for the person managing the indexing) is to use `Argo::BulkReindexer.reindex_all`.  Conveniently, there is a rake task for this:  `rake argo:reindex_all`.  This will query Fedora for the PIDs of all of its objects, and create grouped batches of jobs for reindexing all of them.  This mechanism isn't as robust as we'd like, due to issues we've had with Fedora's risearch mechanism.  There are also many situations where you don't want to reindex everything, and you'll need to build up a custom set of indexing lists manually.  Conveniently, we can address both of those problems by delving into the gory details of the machinery behind `Argo::BulkReindexer.reindex_all`.

### An overview of how Argo's bulk reindexing fits together

The quick explanation is that Argo uses the delayed_job gem (via Rails' Active Job) to queue reindexing jobs, where each job contains `Settings.BULK_REINDEXER.BATCH_SIZE` PIDs to reindex, as well as a priority.  Jobs are prioritized because the correct indexing of some objects depends on other objects being indexed first (e.g., an Item shouldn't be indexed before the APO that governs it).  As such, batches are homogenous by object type, and the priority of the batch corresponds to the priority of that object type, with lower values being higher priority.  For example, when using `reindex_all`, the uber APO batch (which contains the one PID for the uber APO) is of priority 0, workflow batches have priority 1, and so on.  See `Argo::PidGatherer.pid_lists_for_full_reindex`.  delayed_job workers will need to be running to pick up the jobs.  They should be running by default on instances like prod/dev/stage.  You'll need to start them manually on laptop installations using `bin/delayed_job start` (see the main Argo README or https://github.com/collectiveidea/delayed_job for more info).

### The constituent parts

#### Argo::Indexer
In addition to `reindex_pid`, there's a bulk reindex method called `reindex_pid_list` (and a version that does profiling, `reindex_pid_list_with_profiling`).  This method takes a list of PIDs to reindex, and an optional flag indicating whether to commit after indexing everything in the batch (defaults to false).  It essentially just calls `reindex_pid` on each object (the profiling version profiles the call to `reindex_pid_list`, and spits out the profiling info in callgrind format, see PROFILING.md for more on that).

#### Argo::PidGatherer
`Argo::PidGatherer` can be used to generate a list of lists, where each sub-list corresponds to an object type (e.g. uber APO, Workflows, Agreements, etc).  The sublists are in order of indexing priority, with the highest priority starting at zero, and continuing in descending order.  This list of lists is returned by either `pid_lists_for_full_reindex` or `pid_lists_for_unindexed`.

The simplest usage is to instantiate `PidGatherer` and just call either `pid_lists_for_full_reindex` or `pid_lists_for_unindexed`.  Behind the scenes, these methods call methods to get lists by object type.  A couple of these lists (e.g. the single element uber APO list) use hardcoded values.  Most, however, query Fedora by object type, and then memoize the result.  One of the methods queries Solr for all its PIDs.  The `pid_lists_for_unindexed` subtracts the result of `solr_pids` from the lists returned by `pid_lists_for_full_reindex`, so that the lists contain only those things that haven't yet been indexed.  `solr_pids` can optionally take a more targeted query than the one to return all records.

However, there are setters for each list that the query methods memoize to.  As such, you can provide values of your own for each of those lists (or some subset of them).  Then you can take that `PidGatherer` instance and call `pid_lists_for_full_reindex` or `pid_lists_for_unindexed`.  It will use whatever overridden values you've already provided, and for any that weren't manually specified, it'll run the query methods for the first time (which will retrieve and memoize results).

#### Argo::LocalIndexingJob
`Argo::LocalIndexingJob` is a subclass of `ActiveJob::Base`.  Its `perform` method just calls `Argo::Indexer.reindex_pid_list` (or its profiled counterpart, based on `Settings.INDEXING_JOB.SHOULD_PROFILE`).  Batches are committed immediately if `Settings.INDEXING_JOB.SHOULD_COMMIT_BATCHES`, and not otherwise.  So, you can create a job to reindex a batch of PIDs by doing something like `LocalIndexingJob.delay(priority: priority).perform_later(pid_list)`.

#### Argo::BulkReindexer
`Argo::BulkReindexer.new` expects a list of lists in the format returned by `PidGatherer.pid_lists_for_full_reindex` (described above).  Indeed, the static method `Argo::BulkReindexer.reindex_all` just creates an instance of its parent class using `pid_lists_for_full_reindex` from a new instance of `PidGatherer`.

Once you've created a `BulkReindexer` instance with the desired `pid_lists`, you can have it index them by calling `queue_prioritized_pid_lists_for_reindexing`.  This method will:
* iterate over `pid_lists` in order.
 * for each object type sub-list, it will break the list into chunks of `Settings.BULK_REINDEXER.BATCH_SIZE`, and create an `LocalIndexingJob` for each chunk of PIDs.  It will also set the priority on each job, such that each batch has a priority corresponding to the object type contained in that batch (since the lists are already in priority order, it just uses the index of the parent list from `pid_lists`).  The delayed_job workers will then pick up the queued jobs in order of priority, and execute them.  Everything will get logged properly since the jobs are ultimately executing calls to `reindex_pid` (via a few intermediate layers).  Additionally, the delayed_job workers will log higher level info about their success/failure to execute.

### An example of some custom reindexing code (to tie it all together)

Let's say, for example, that you discovered that Fedora's risearch returned incomplete results.  Further, let's suppose that you've overhauled the Solr schema Argo uses, as part of a major blacklight upgrade, and you need to reindex all the objects that are currently in your production Fedora repo.  So as to preserve some sanity in this hypothetical, you can query Fedora's underlying MySQL instance and get a list of all PIDs in Fedora (of which a subset are returned by the Fedora risearch for all PIDs).  You can also query your old production Solr instance for what it believes are lists of PIDs for each object type that we care about prioritizing (and you're reasonably confident that this old data is accurate).  Though `PidGatherer`'s queries won't return everything you need, you do actually have all the info you need to build a list for a full reindex.  You can do so by doing something like the following:
```ruby
# create a new PidGatherer
pid_gatherer = Argo::PidGatherer.new

# lets assume our MySQL dump of all PIDs was written to a file with one PID on each line, and that it's reasonable to open it naively and just load up the whole thing
all_pids = open('dor-prod_pids_from_mysql_2015-12-15.txt').read.split

# lets assume that the PID lists from the old prod Solr were written as JSON lists, and that they can also just be loaded up into memory and parsed
workflow_pids = JSON.parse(open('argo_prod_solr_pid_dumps/argo_prod_solr_workflow_pids_2015-12-16.txt').read)
agreement_pids = JSON.parse(open('argo_prod_solr_pid_dumps/argo_prod_solr_agreement_pids_2015-12-16.txt').read)
apo_pids = JSON.parse(open('argo_prod_solr_pid_dumps/argo_prod_solr_apo_pids_2015-12-16.txt').read)
collection_pids = JSON.parse(open('argo_prod_solr_pid_dumps/argo_prod_solr_collection_pids_2015-12-16.txt').read)
set_pids = JSON.parse(open('argo_prod_solr_pid_dumps/argo_prod_solr_set_pids_2015-12-16.txt').read)

# turns out we didn't distinguish the hydrus ones from the non-hydrus ones above.  don't bother querying Fedora for these, a default indexing run already did that.
hydrus_apo_pids = []
hydrus_collection_pids = []

# this is a list of PIDs we dumped that are already in our new Solr core, and that we don't need to try reindexing
solr_pids = JSON.parse(open('prod-b_solr_pids_2015-12-16.txt').read)

# set the all the queryable PidGatherer fields manually
pid_gatherer.all_pids = all_pids
pid_gatherer.solr_pids = solr_pids
pid_gatherer.workflow_pids = workflow_pids
pid_gatherer.agreement_pids = agreement_pids
pid_gatherer.apo_pids = apo_pids
pid_gatherer.hydrus_apo_pids = hydrus_apo_pids
pid_gatherer.collection_pids = collection_pids
pid_gatherer.hydrus_collection_pids = hydrus_collection_pids
pid_gatherer.set_pids = set_pids

# create a custom BulkReindexer using the result of pid_lists_for_unindexed on the custom PidGatherer instance, then queue the indexing jobs
pid_lists_for_unindexed = pid_gatherer.pid_lists_for_unindexed
bulk_reindexer = Argo::BulkReindexer.new(pid_lists_for_unindexed)
bulk_reindexer.queue_prioritized_pid_lists_for_reindexing
```

If all went well above, a custom set of indexing jobs was created to make up the difference from the initial `reindex_all` call that fell short, using the results of queries dumped to text files.  The delayed_job worker will pick up the jobs and chug through them.

The nice thing about setting the lists in a custom `PidGatherer` and calling `pid_lists_for_full_reindex` or `pid_lists_for_unindexed` is that you get to leverage the conveniences of `PidGatherer` (filtering invalid druids, constructing a list of lists for reindexing in the expected formatting with priority by object type).  But it would be fine to pass any list of lists to a custom instance of `BulkReindexer`, so long as the sub-lists were in the desired priority order, and only contained valid PIDs.

### Gotchas
* As far as we can tell, the dor-services `to_solr` code that generates the Solr documents leaks memory.  As such, the delayed_job workers leak memory, and eventually reindexing workers will die if they run for long enough.  As such, large reindexing batches may require some babysitting, and restarting of workers.  Our intent is to use a monitoring tool like Bluepill or Eye to automate this babysitting, but for now it's manual.
* As mentioned above, Fedora's risearch seems to return incomplete results, meaning the default version of `reindex_all` that introduced this document is unreliable.
* delayed_job is generally good about adhering to priority, but some testing indicates that there is some times a bit of bleed between priority levels.  Our suspicion is that when one priority level has been entirely consumed by the workers, it is possible that idle workers will start picking up jobs of the next priority.  If the lower priority jobs happen to finish first, some things may intermingle between the end of processing one priority level and the start of processing the next.  We are investigating ways to enforce this ordering more strictly.
* For real work, and realistic testing, run as many workers in parallel as you can, since much of the slowness of indexing is due to network wait time when a worker makes requests to Fedora.  This means any given worker spends a lot of time waiting on IO, not actually utilizing the CPU.
* Since you want to run a lot of workers, and they use a lot of memory, throw a lot of memory and CPU at a box that's doing heavy bulk reindexing.  For example, we've run 12 workers on a VM with 32 GB of RAM and 12 CPUs allocated.
* At present, because of the way delayed_job works and is configured, each worker is essentially an instance of the Argo application.  So they all start pretty heavy, even before they start leaking memory.  We are interested in extricating the bulk reindexing machinery used by the delayed_job workers from Rails, but haven't started work on this yet.
* If you're having performance issues, and you decide to turn profiling on, expect the profiling to make indexing much slower and much less stable.  Still, we found profiling a smaller but representative subset of the indexing work to be quite helpful in optimizing things like the number of workers we let run.  It's not necessary to try to profile a run of half a million objects to get useful data (it's probably not even practically feasible).
