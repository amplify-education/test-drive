require 'optparse'
require 'uuidtools'
require 'highline/import'
require 'yaml'

module Test
  module Drive
    class App
      include Methadone::Main
      include Methadone::CLILogging
      extend Formatter
      extend GitHelper

      main do
        @server_url = options[:server] ||= ask('Jenkins URL:  ')
        @user = options[:user] ||= ask('Jenkins User ID:  ')
        @api_key = options[:password] ||= ask('Jenkins Password/API Token:  ')
        @target_job = options[:job] ||= ask('Jenkins job to trigger:  ')


        config_file = File.expand_path('.test-drive.yml', ENV['HOME'])
        if !File.exists?(config_file) && agree('Save these credentials as default values?  ', true)
          File.open(config_file, 'w') { |file| YAML.dump(options, file) }
        end

        @client = JenkinsClient.new @server_url, @user, @api_key
        @patch_file = 'patch'

        create_patch @patch_file
        debug File.readlines File.open @patch_file

        tracking_id = UUIDTools::UUID.random_create.to_s
        id_param = {'name' => 'TRACKING_ID', 'value' => tracking_id}
        @client.upload_file_to_job(@target_job, tracking_id, @patch_file)

        build_number = @client.get_build_number(@target_job, id_param, 120)

        @client.print_output(build_number, @target_job)
        result = @client.wait_for_job_status(@target_job, build_number)

        print_result(result)
        git_push if options[:push] && ['SUCCESS', 'UNSTABLE'].include?(result)

        delete_patch @patch_file
      end

      defaults_from_config_file '.test-drive.yml'

      on '-s JENKINS_URL', '--server', 'URL for the Jenkins server'
      on '-u USER', '--user', 'Jenkins user ID'
      on '-p API_KEY', '--password', 'Jenkins password or API token'
      on '-j TARGET_JOB', '--job', 'Jenkins job to be triggered'
      on '-n', '--[no-]push', 'Option to enable (or suppress) pushing to the remote repo'


      description 'A simple command-line tool for running a Jenkins test job before pushing code to a remote repo'

      version VERSION

      use_log_level_option :toggle_debug_on_signal => 'USR1'
    end
  end
end
