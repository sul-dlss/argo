# Profiling code in Argo

When performance problems are discovered, it may not be immediately apparent what parts of the code are responsible.  Profiling can help determine where processing time is being spent by analyzing running code.


## Profiling tools (`RubyProf`, etc)

`RubyProf` collects stats about execution time for all methods called for the particular execution that's being performed.  Thus, if you run the code you're interested in with a workload which is representative of the real work the program would do, you can get an idea of which methods are taking the most time to execute, and hopefully which methods can be made more efficient.

Though `RubyProf` has settings which are supposed to collect similar statistics for things like memory usage, our limited experience using `RubyProf` to profile Argo code indicated that only processing time stats can actually be collected.  We'd be happy to be shown otherwise, and our testing was brief, so it's possible we missed something.  The type of data collected is determined by `Settings.PROFILER.MEASURE_MODE`.

There is a gem called memory_profiler, which operates similarly to `RubyProf`, which will be discussed briefly at the end of this document.


## Argo::Profiler

`Argo::Profiler` is a thin wrapper class which provides convenience methods for using `RubyProf` to profile code and output the results to log files.

For more detail on `RubyProf` usage and options, visit https://github.com/ruby-prof/ruby-prof

### Profiling a block of code and outputting the results

The basic usage is to create an instance of the profiler, call `prof` on the block of code you're interested in, and output the results, e.g.:
```
profiler = Argo::Profiler.new
profiler.prof { Argo::Indexer.reindex_pid_list pid_list, should_commit }
profiler.print_results_call_tree(out_file_id)
```

In the above example, we'd be profiling the call to `Argo::Indexer.reindex_pid_list` with params `pid_list` and `should_commit` (though an arbitrarily large block of code could be profiled).  The results will then be printed to a file named after the value of the string `out_file_id`, in the directory specified by `Settings.PROFILER.OUTPUT_DIR` (`log/profiler` in the app root, by default).  Unless `Settings.PROFILER.MEASURE_MODE` is edited from the default (which is not advised, as mentioned above), the stats collected will be the `WALL` time for methods ("the real-world time elapsed between any two moments", see https://github.com/ruby-prof/ruby-prof#measurements).  The output will be in the callgrind format, and will print stats for methods which consumed `Settings.PROFILER.CALLTREE_PRINTER_MIN_PERCENT` or more of the CPU time during the profiling session.


## Analyzing profiler output

`RubyProf` prints results in a number of formats, of which the `Argo::Profiler` wrapper exposes four via the following methods:
* `print_results_call_tree` uses `RubyProf::CallTreePrinter` to output profiling info in the callgrind format.  This is the most detailed and filterable profiling info, though this profiling can add significant memory overhead, as a lot of info is being collected, and the output files can be quite large (tens of MB), even when `Settings.PROFILER.CALLTREE_PRINTER_MIN_PERCENT` is high.  You can view and analyze output using a tool such as `qcachegrind` on OS X (obtainable by running `brew install qcachegrind`) in the terminal.  You can merge files from multiple runs using `cg_merge`, though `qcachegrind` will let you view multiple files simultaneously.  More info on callgrind, cachegrind, and the valgrind tools at these links:
 * https://github.com/sul-dlss/argo/issues/250#issuecomment-159094534
 * https://kcachegrind.github.io/html/Documentation.html
 * https://www.coffeepowered.net/2013/08/02/ruby-prof-for-rails/
 * http://valgrind.org/docs/manual/cg-manual.html#cg-manual.profile
* `print_results_call_stack` uses `RubyProf::CallStackPrinter` to print an HTML visualization of the call tree with stats on time spent in each method.  Less resource intensive than `print_results_call_tree`, and requires less tooling to view since it can be opened in a web browser, but provides less flexibility for detailed analysis.
* `print_results_flat` uses `RubyProf::FlatPrinterWithLineNumbers` to print a flat text file with aggregated stats.  Same performance/granularity trade-off as `print_results_call_stack`.
* `print_results_graph_html` uses `RubyProf::GraphHtmlPrinter` and HTML file with the call graph:  "show how long each method runs, which methods call it and which methods it calls".  Same performance/granularity trade-off as `print_results_call_stack`.


## Profiling advice

Ideally, you want to profile a re-creation of the performance problem you're experiencing, or something as similar as possible, since the results collected are from actual running code.

If you introduce performance problems or instability with profiling, which can happen for very resource intensive activities, you may want to sample something representative of your overall workload.  For example, when we profiled bulk reindexing, as in the earlier example, the workers that executed the reindexing code tended to leak memory and die.  We found that this happened slowly even without profiling, but was greatly accelerated when we collected stats in the callgrind format.  Additionally, profiling slowed down execution considerably.  As such, we'd enable profiling for limited windows (a few rounds of restarting workers over the course of an hour or two), as opposed to an entire indexing run (which might take two days without profiling).  Though the runs weren't realistic with profiling enabled, in that they took much longer overall, the execution time for different methods remained proportionally the same, and we were able to collect a lot of useful data on where indexing was especially resource intensive, and which operations took a disproportionate amount of time.  See https://github.com/sul-dlss/argo/issues/250 for more detail on this example.


## Other profiling options

### New Relic
Argo has the New Relic gem installed, and is currently configured to collect profiling info for deployed canonical instances (prod, dev, stage).  At this time, DLSS is using the free account, and so the info exposed is limited, but may be of some use, especially for keeping tabs on day to day performance in the absence of specific known issues.

### MemoryProfiler
The `MemoryProfiler` gem (https://github.com/SamSaffron/memory_profiler) can be used to wrap and profile blocks of code in a similar manner to the `RubyProf` gem.  It does not appear to output in an easily-to-analyze format like callgrind, but it does collect quite a bit of useful info, and gave us some help as noted here: https://github.com/sul-dlss/argo/issues/250#issuecomment-161386755
