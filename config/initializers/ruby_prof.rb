# frozen_string_literal: true

# this is a global setting for RubyProf, picked up from Settings at app startup.  overrides the actual ENV var, since we'd prefer to control it using Settings.
ENV['RUBY_PROF_MEASURE_MODE'] = Settings.PROFILER.MEASURE_MODE
RubyProf.figure_measure_mode
