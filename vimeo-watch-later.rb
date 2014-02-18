#!/usr/bin/env ruby

require 'vimeo'
require 'json'

def friendly_filename(filename)
    filename.gsub(/[^\w\s_-]+/, '')
            .gsub(/(^|\b\s)\s+($|\s?\b)/, '\\1\\2')
            .gsub(/\s+/, '_')
end

#
# You need to set up the following variables
# Register your private utility application at: 
# https://developer.vimeo.com/apps/new
# So that you will obtain the necesarry data
#

CONSUMER_KEY=""
CONSUMER_SECRET=""
USERNAME=""
TOKEN=""
TOKENSECRET=""
# The Dropbox path
# It is relative to $HOME
dboxdir = "Dropbox/var/youtube-dl"

url_list_path = ENV['HOME'] + "/" + dboxdir + "/vimeo_urls.lst"

album = Vimeo::Advanced::Album.new( CONSUMER_KEY,
                        CONSUMER_SECRET,
                        :token => TOKEN,
                        :secret => TOKENSECRET)

watchLater = album.get_watch_later(
                        {:page => "1",
                        :per_page =>"40",
                        :full_response => "1",
                        :format => "json"})

# For debugging
#tmpfile = ENV['TEMP']
#if tmpfile == nil or tmpfile == ""
#       tmpfile = "/tmp"
#end
#File.open( tmpfile + "/vimeo-wlvideos.json", "w" ) do |f|
#       f.write( JSON.pretty_generate( watchLater ) )
#end

videos = watchLater["videos"]["video"];

videos.each do |oneVideo|
        id = oneVideo["id"]
        title = oneVideo["title"]
        url = nil

        # Search for "video" format (not "mobile" or other)
        oneVideo["urls"]["url"].each do |oneUrl|
                anyurl = oneUrl["_content"]
                if oneUrl["type"] == "video"
                        url = oneUrl["_content"]
                end
        end

        # Fallback to other format if "video" unavailable
        if url == nil
                url = anyurl
        end

        # Check if the video is already processed before
        result = []
        open( url_list_path ) { |f| result = f.grep(/#{url}/) }
        if result.size() > 0
                puts url + " (" + title[0..25] + ") is already processed, skipping!"
                puts ""
                next
        end

        puts id + " :: " + title
        puts url

        # Store to the cloud file
        filename = friendly_filename ( title )
        filename = filename[0..30]
        dboxfile = dboxdir + "/" + filename + ".txt"

        File.open( ENV['HOME'] + "/" + dboxfile, "w") do |f|
                f.write( url )
        end

        # Remember that the video was being processed
        File.open( url_list_path, "a+" ) {|f|
                f.write( url )
                f.write( "\n" )
        }

        # Optional remove - uncomment
        # Unfortunately the Vimeo gem (v. 1.5.3) fails at this anyway
        # But your version might actually work
        #begin
        #       album.remove_from_watch_later(
        #               :token => TOKEN,
        #               :video_id => id
        #               )
        #rescue
        #       puts "Failed to remove from WatchLater"
        #end

        puts "Processed <<" + filename + " : " + url + ">>, stored to ~/" + dboxfile
        puts "-----------"
        puts ""
end
