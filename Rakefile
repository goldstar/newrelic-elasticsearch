require "bundler/gem_tasks"
require "rake/testtask"

task :default => :test

task :test do
  Rake::TestTask.new do |t|
    t.libs << 'test'
    t.pattern = "test/**/*_test.rb"
  end
end

task :generate_resolver do
  list = File.read(File.expand_path('test/endpoint_list.txt', __dir__))

  pp list.lines.each.with_object({}) { |l, memo|
    scanner = StringScanner.new(l)
    scanner.scan_until(/(POST|GET|PUT|DELETE|HEAD)/)
    next if scanner.pre_match.nil?

    operation_name = scanner.pre_match.rstrip
    method = scanner.matched
    url_pattern = scanner.rest
    api_name = if matches = /\/(_.*?)(\/|\b)/.match(url_pattern)
                 matches[1]
               end


    if memo.has_key?([method, api_name])
      next if memo[[method, api_name]] == operation_name
      memo[[method, api_name]] = :"ambiguous#{api_name || "_" + method.downcase}_resolver"
    else
      memo[[method, api_name]] = operation_name
    end

  }.sort_by { |k,v| k[1] || '_' }.to_h
end

