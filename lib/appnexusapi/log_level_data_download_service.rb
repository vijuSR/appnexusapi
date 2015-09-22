class AppnexusApi::LogLevelDataDownloadService < AppnexusApi::Service
  def initialize(connection, options = {})
    @read_only = true
    @downloaded_files_path = options[:downloaded_files_path] || '.'
    super(connection)
  end

  def download_location(params = {})
    @connection.get(uri_suffix, params).headers['location']
  end

  # Parameter is a LogLevelDataResource
  # Downloads a gzipped file
  def download_resource(data_resource)
    data_resource.download_params.each do |params|
      uri = URI.parse(download_location(params))
      filename = File.join(@downloaded_files_path, "#{params[:siphon_name]}_#{params[:hour]}_#{params[:timestamp]}_#{params[:split_part]}.gz")
      download_file(uri, filename)
    end
  end

  def get
    raise(AppnexusApi::NotImplemented, "This service is designed to work through download_location method")
  end

  def uri_name
    'siphon-download'
  end

  private

  def download_file(uri, filename)
    puts "Starting HTTP download for: " + uri.to_s
    http_object = Net::HTTP.new(uri.host, uri.port)
    http_object.use_ssl = true if uri.scheme == 'https'
    begin
      http_object.start do |http|
        request = Net::HTTP::Get.new uri.request_uri
        http.read_timeout = 500
        http.request request do |response|
          open filename, 'wb' do |io|
            response.read_body do |chunk|
              io.write chunk
            end
          end
        end
      end
    rescue Exception => e
      puts "=> Exception: '#{e}'. Skipping download."
      return
    end
    puts "Stored download as " + filename + "."
  end
end
