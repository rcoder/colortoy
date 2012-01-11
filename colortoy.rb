#!/usr/bin/env ruby

require 'erb'
require 'tempfile'
require 'matrix'

$: << File.dirname(__FILE__) + "/lib"
require 'core_ext'
require 'cluster'

require 'rubygems'
require 'rmagick'

MIN_CLUSTERS = 4
# hahaha
INFINITY = 2**63

def main(img_name, cluster_cnt)
  template = ERB.new(DATA.read)

  img_path = File.expand_path(img_name)
  src_img = Magick::Image.read(img_name).first
  palette = src_img.resize_to_fit(512, 512).quantize(128)
  width = palette.columns
  height = palette.rows

  colors = palette.color_histogram.keys.map do |p|
    tuple = [p.red, p.green, p.blue, p.intensity].map {|i| i/(2**16).to_f }
    Vector.elements(tuple)
  end

  color_names = color_clusters.map do |t|
    t[0..2].inject("#") {|s, c| s + "%02x" % (c*256) }
  end

  Tempfile.open(['colortoy', '.html']) do |fh|
    fh.write(template.result(binding))
    fh.flush
    fh.close
    cmd = "open #{fh.path}"
    system cmd
    puts "Press Enter when finished..."
    STDIN.gets
  end
end

if $0 == __FILE__
  if ARGV.size < 1
    STDERR.puts("Usage: colortoy.rb <image file imagemagick can read> [<number of colors>]")
    exit 1
  end

  main(ARGV[0], (ARGV[1] || MIN_CLUSTERS).to_i)
end

__END__
<!DOCTYPE html>
<html>
  <head>
    <title>Image analysis for <%= img_name %></title>
    <style>
      body {
        background-color: #161616;
      }

      .src-image {
        text-align: center;
        padding: 8px;
      }

      .src-image img {
        border: 3px solid #000;
      }

      .color-wrap {
        padding: 16px; margin-top: 16px; text-align: center; width: 100%;
      }

      .color-span {
        color: #fff; font-size: 16px; font-weight: bold; width: 128px;
        padding: 16px; margin: 8px; font-family: sans-serif;
        border: 3px solid #000;
      }
    </style>
  </head>
  <body>
    <div class="src-image">
      <img src="<%= img_path %>" width="<%= width %>" height="<%= height %>"/>
    </div>
    <div class="color-wrap">
    <% color_names.each do |color| %>
      <span class="color-span" style="background-color: <%= color %>"><%= color %></span>
    <% end %>
    </div>
  </body>
</html>

