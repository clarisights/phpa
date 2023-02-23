# frozen_string_literal: true

require "open3"

module PHPA
  module Helper
    require "fileutils"

    def metric_server_class(adaptor_name)
      case adaptor_name
      when :graphite
        return Graphite
      when :influxdb
        return Influx
      else
        raise UnknownAdaptor, adaptor_name
      end
    end

    def log_txt(text)
      puts "#{Time.now.utc} :: #{text}"
      # when STDOUT is not flushed, log appears after sometime
      STDOUT.flush
    end

    def execute_command(command_str, verbose: true)
      stdout, stderr, status = Open3.capture3(command_str)
      log_txt stdout if verbose
      log_txt "STDERR: #{stderr}" if stderr.present?
      # log if program returned non zero exit code
      unless status.exitstatus.zero?
        msg = "Command Failed, exit code: #{status.exitstatus}, "\
              "command: #{command_str}"
        raise CommandFailed, msg
      end
      return stdout
    end

    def raise_metric_fetch_failed(e)
      if e.is_a?(MetricFetchFailed)
        raise e
      else
        raise MetricFetchFailed, e.message
      end
    end

    def create_lock_dir
      FileUtils.mkdir_p(Config::LOCK_DIR)
    end

    def lock_file_path(deployment_name)
      return "#{Config::LOCK_DIR}/#{deployment_name}.lock"
    end

    def acquire_lock(deployment_name)
      create_lock_dir
      # exit if lockfile already exits
      lock_file = lock_file_path(deployment_name)
      if File.exist?(lock_file)
        log_txt "ERR: Lockfile #{lock_file} already exits"
        exit(1)
      end

      lockfile = File.new(lock_file, "w")
      lockfile.write(Process.pid)
      lockfile.close
    end

    def release_lock(deployment_name)
      lock_file = lock_file_path(deployment_name)
      File.delete(lock_file)
    end

    def gracefully_shutdown
      # check for any files in lock directory
      # and keep waiting for lockfile to go away
      loop do
        if Dir.empty?(Config::LOCK_DIR)
          sleep(2)
        else
          exit(0)
        end
      end
    end

    # helper methods to interact with k8s
    def current_replicas(deployment, scope)
      sleep_dur = 1
      Config::REPLICA_RETRY.times do
        command = "kubectl get deploy #{deployment} -o yaml #{scope}"
        stdout = execute_command(command, verbose: false)
        yaml = YAML.load(stdout).deep_symbolize_keys!
        result = yaml[:status][:replicas]
        return result if result.present?

        sleep_dur += Config::RETRY_SLEEP_INCREMENT
        log_txt "current_replicas for '#{deployment}' is sleeping for #{sleep_dur}s"
        sleep sleep_dur
      end
      return 0
    rescue CommandFailed => e
      print_backtrace(e)
      # return nil to indicate that we failed to fetch current replica count
      return nil
    end

    def print_backtrace(e)
      log_txt e.message
      log_txt e.backtrace.join("\n")
    end

    def can_scale?(min, max, scale_to)
      return (min..max).cover?(scale_to)
    end

    def scale_it(deployment, scope, replicas)
      command = "kubectl scale deployment #{deployment} --replicas=#{replicas} #{scope}"
      execute_command(command)
    rescue CommandFailed => e
      log_txt "Failed to scale #{deployment}"
      print_backtrace(e)
    end
  end
end
