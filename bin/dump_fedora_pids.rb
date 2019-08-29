# frozen_string_literal: true

# a simple script for dumping the full list of druids from a fedora instance.
#
## assumptions:
# * you're running this script on the same machine as the fedora instance from which you want to dump.
# * the unix user you're running this script as can execute the 'mysql' command, and can write to '/tmp'.
# * that unix user can temporarily write a sql script file to the dir from which it's running this script.
# * the mysql user you're logging in as has permission to write files from the mysql client.
#   * if the mysql user doesn't have permission to write files, you can ksu to the root account, run 'mysql', and issue something like this grant:
#     GRANT FILE ON *.* TO 'fedora'@'localhost';
# * .fedora.my.cnf is a config file with a line like "  password = supersecretcredential".
# * the password in .fedora.my.cnf will get you into fedora sql db for its user (which defaults to "fedora").
# * .fedora.my.cnf exists in the same directory from which you're running this script, and can be read by the user running it.
#
# if all that's true, you should be able to do "ruby dump_fedora_pids.rb"
# and it should tell you where it wrote the pids

require 'date'

# a list of the files read and written by this script
cur_datetime_str = DateTime.now.strftime('%Y-%m-%d_%H:%M:%S')
fedora_conf_file_name = '.fedora.my.cnf'
out_file_name = "/tmp/all_pids_#{cur_datetime_str}"
script_file_name = "fedora_mysql_pid_dump_#{cur_datetime_str}.sql"

def get_fedora_password(conf_file_name)
  fedora_conf_file_contents = open(conf_file_name, 'r').read
  return (/^\s*password\s*=\s*(.*)$/.match(fedora_conf_file_contents))[1]
end

# define the connection info to get into the fedora DB
db_user_name = 'fedora'
db_password = get_fedora_password(fedora_conf_file_name)
db_name = 'fedora'

# a simple script that uses the db, selects everything from the table with the pids, and dumps the list to a file
mysql_script = <<~SQL
  use #{db_name}
  select doPID from doRegistry into OUTFILE "#{out_file_name}";
SQL

# make sure we can write the files we need to use without stepping on existing files
raise "script file already exists (#{script_file_name})" if File.exist? script_file_name
raise "out file already exists (#{out_file_name}" if File.exist? out_file_name

# write the temp script file
File.open(script_file_name, 'w') { |file| file.write mysql_script }

# execute the sql script by feeding the temp script file to the msql command with the login info as CL params
mysql_cmd = "mysql --user=#{db_user_name} --password=#{db_password} < #{script_file_name}"
puts %x(#{mysql_cmd})

# delete the temp sql script
File.delete(script_file_name)

# let the user know where to find their pids
puts "pid dump should be in #{out_file_name}"
