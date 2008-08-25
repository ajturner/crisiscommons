namespace :backgroundrb do
  def setup_queue_migration
    config_file = "#{RAILS_ROOT}/config/database.yml"
    require "erb"
    require "active_record"
    config = YAML.load(ERB.new(IO.read(config_file)).result)
    env = ENV["RAILS_ENV"] || ENV["env"] || 'development'

    ActiveRecord::Base.establish_connection(config[env])
    migration_klass = Class.new(ActiveRecord::Migration) do
      def self.up
        create_table :bdrb_job_queues do |t|
          t.column :args, :binary
          t.column :worker_name, :string
          t.column :worker_method, :string
          t.column :job_key, :string
          t.column :taken, :int
          t.column :finished, :int
          t.column :timeout, :int
          t.column :priority, :int
          t.column :submitted_at, :datetime
          t.column :started_at, :datetime
          t.column :finished_at, :datetime
          t.column :archived_at, :datetime
          t.column :tag, :string
          t.column :submitter_info, :string
          t.column :runner_info, :string
          t.column :worker_key, :string
        end
      end

      def self.down
        drop_table :bdrb_job_queues
      end
    end
    migration_klass.up
  end

  require 'yaml'
  desc 'Setup backgroundrb in your rails application'
  task :setup do
    script_dest = "#{RAILS_ROOT}/script/backgroundrb"
    script_src = File.dirname(__FILE__) + "/../script/backgroundrb"

    FileUtils.chmod 0774, script_src

    defaults = {:backgroundrb => {:ip => '0.0.0.0',:port => 11006 } }

    config_dest = "#{RAILS_ROOT}/config/backgroundrb.yml"

    unless File.exists?(config_dest)
        puts "Copying backgroundrb.yml config file to #{config_dest}"
        File.open(config_dest, 'w') { |f| f.write(YAML.dump(defaults)) }
    end

    unless File.exists?(script_dest)
        puts "Copying backgroundrb script to #{script_dest}"
        FileUtils.cp_r(script_src, script_dest)
    end

    workers_dest = "#{RAILS_ROOT}/lib/workers"
    unless File.exists?(workers_dest)
      puts "Creating #{workers_dest}"
      FileUtils.mkdir(workers_dest)
    end

    test_helper_dest = "#{RAILS_ROOT}/test/bdrb_test_helper.rb"
    test_helper_src = File.dirname(__FILE__) + "/../script/bdrb_test_helper.rb"
    unless File.exists?(test_helper_dest)
      puts "Copying Worker Test helper file #{test_helper_dest}"
      FileUtils.cp_r(test_helper_src,test_helper_dest)
    end

    worker_env_loader_dest = "#{RAILS_ROOT}/script/load_worker_env.rb"
    worker_env_loader_src = File.join(File.dirname(__FILE__),"..","script","load_worker_env.rb")
    unless File.exists? worker_env_loader_dest
      puts "Copying Worker envionment loader file #{worker_env_loader_dest}"
      FileUtils.cp_r(worker_env_loader_src,worker_env_loader_dest)
    end
    begin
      setup_queue_migration
    rescue
      error_msg = $!.message
      puts error_msg.first(85)
    end
  end

  desc "Create backgroundrb queue table"
  task :create_queue do
    setup_queue_migration
  end

  desc 'update backgroundrb config files from your rails application'
  task :update do
    temp_scripts = ["backgroundrb","load_worker_env.rb"].map {|x| "#{RAILS_ROOT}/script/#{x}"}
    temp_scripts.each do |file_name|
      if File.exists?(file_name)
        puts "Removing #{file_name} ..."
        FileUtils.rm(file_name,:force => true)
      end
    end
    new_temp_scripts = ["backgroundrb","load_worker_env.rb"].map {|x| File.dirname(__FILE__) + "/../script/#{x}" }
    new_temp_scripts.each do |file_name|
      puts "Updating file #{File.expand_path(file_name)} ..."
      FileUtils.cp_r(file_name,"#{RAILS_ROOT}/script/")
    end
  end

  desc 'Remove backgroundrb from your rails application'
  task :remove do
    script_src = "#{RAILS_ROOT}/script/backgroundrb"
    temp_scripts = ["backgroundrb","load_worker_env.rb"].map {|x| "#{RAILS_ROOT}/script/#{x}"}

    if File.exists?(script_src)
        puts "Removing #{script_src} ..."
        FileUtils.rm(script_src, :force => true)
    end

    test_helper_src = "#{RAILS_ROOT}/test/bdrb_test_helper.rb"
    if File.exists?(test_helper_src)
      puts "Removing backgroundrb test helper.."
      FileUtils.rm(test_helper_src,:force => true)
    end

    workers_dest = "#{RAILS_ROOT}/lib/workers"
    if File.exists?(workers_dest) && Dir.entries("#{workers_dest}").size == 2
        puts "#{workers_dest} is empty...deleting!"
        FileUtils.rmdir(workers_dest)
    end
  end
end
