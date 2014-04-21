# Downloader iterates over a download queue and downloads and saves each video in the queue.
class Downloader
  class DownloadFailedError < StandardError; end

  def download(download_queue, params)
    download_queue.each do |url_name|
      # Skip invalid invalid link
      next unless url_name

      # Url
      url = url_name[:url]
      name = url_name[:name]
      extension = /\..*\z/.match(name)

      # override the file name if passed, but keep the extension
      if params[:name] != nil
        name = params[:name] + extension.to_s
      end

      result = ViddlRb::DownloadHelper.save_file url,
                                                 name,
                                                 :save_dir => params[:save_dir],
                                                 :tool => params[:tool] && params[:tool].to_sym
      if result
        puts "Download for #{name} successful."
        url_name[:on_downloaded].call(true) if url_name[:on_downloaded]

        if params[:extract_audio]
          title_parts = params[:name].split(' - ')
          metadata    = { artist: title_parts[0], title: title_parts[1] }
          
          ViddlRb::AudioHelper.extract  name, 
                                        params[:save_dir], 
                                        params[:save_audio_dir], 
                                        params[:audio_format], 
                                        metadata 
        end
      else
        url_name[:on_downloaded].call(false) if url_name[:on_downloaded]
        if params[:abort_on_failure]
          raise DownloadFailedError, "Download for #{name} failed."
        else
          puts "Download for #{name} failed. Moving onto next file."
        end
      end
    end
  end
end
