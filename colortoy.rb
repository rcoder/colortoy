#!/usr/bin/env ruby

require 'erb'
require 'tempfile'
require 'matrix'

require 'rubygems'
require 'rmagick'

MIN_CLUSTERS = 4
# hahaha
INFINITY = 2**63

if ARGV.size < 1
  STDERR.puts("Usage: colortoy.rb <image file imagemagick can read> [<number of colors>]")
  exit 1
end

class Vector
  def cosine(other)
    if other.size != size
      raise ArgumentError, "cannot take cosine of differently-sized vectors!"
    end

    inner_product(other) / (r * other.r)
  end

  def self.unit_f(dim)
    make_with_dim(1.0, dim)
  end

  def self.zeros(dim)
    make_with_dim(0, dim)
  end

  def self.average(vectors)
    if vectors.empty?
      raise ArgumentError, "cannot take average of empty vector array"
    end

    sum = zeros(vectors.first.size)
    vectors.each {|vec| sum += vec }
    sum / vectors.size
  end

  private

  def self.make_with_dim(init_val, dim)
    elements([init_val]*dim)
  end
end

class Array
  def pop_rand!
    delete_at(rand(size))
  end
end

class Cluster
  attr_accessor :centroid, :members

  def initialize(dim, center=nil)
    @dims = dim
    @centroid = center || Vector.random_f(dim)
    @members = []
    @members << center unless center.nil?
  end

  def find_centroid!
    prev_centroid = @centroid
    @centroid = Vector.average(@members)
    1.0 - @centroid.cosine(prev_centroid)
  end
end

def kmeans(vectors, k, delta=0.00005)
  dim = vectors.first.size
  initial_assigns = vectors.dup
  clusters = []

  k.times do
    init = initial_assigns.pop_rand!
    clusters << Cluster.new(dim, init)
  end

  cluster_idx = {}

  while initial_assigns.size > 0
    vec = initial_assigns.pop_rand!
    c = clusters[rand(clusters.size)]
    cluster_idx[vec] = c
    c.members << vec
  end

  while true
    clusters.reject! {|c| c.members.empty? }
    curr_deltas = clusters.map {|c| c.find_centroid! }
    max_delta = curr_deltas.max
    break if max_delta <= delta || clusters.size < 2

    vectors.each do |vec|
      best_cluster = nil
      best_score = -INFINITY
      clusters.each do |c|
        score = vec.cosine(c.centroid)
        if score >= best_score
          best_cluster = c
          best_score = score
        end
      end

      if cluster_idx.has_key?(vec)
        cluster_idx[vec].members.delete(vec)
      end

      best_cluster.members << vec
      cluster_idx[vec] = best_cluster
    end
  end

  clusters.map {|c| Vector.average(c.members).to_a }
end

template = ERB.new(DATA.read)

img_name = ARGV[0]
img_path = File.expand_path(img_name)
src_img = Magick::Image.read(ARGV[0]).first
palette = src_img.resize_to_fit(512, 512).quantize(128)
width = palette.columns
height = palette.rows

colors = palette.color_histogram.keys.map do |p|
  Vector.elements([p.red, p.green, p.blue, p.intensity].map {|i| i / (2**16).to_f})
end

color_clusters = kmeans(colors, (ARGV[1] || MIN_CLUSTERS).to_i)

color_names = color_clusters.map do |t|
  t[0..2].inject("#") {|s, c| s + "%0x" % (c*256) }
end

Tempfile.open(['colortoy', '.html']) do |fh|
  fh.write(template.result(binding))
  fh.flush
  fh.close
  cmd = "open #{fh.path}"
  puts cmd
  system(cmd)
  puts "Press Enter when finished..."
  STDIN.gets
end

__END__
<!DOCTYPE html>
<html>
  <head>
    <title>Image analysis for <%= img_name %></title>
    <style>
      .src-image {
        text-align: center;
      }

      .color-wrap {
        padding: 16px; margin-top: 16px; text-align: center; width: 100%;
      }

      .color-span {
        color: #fff; font-size: 16px; font-weight: bold; width: 128px;
        padding: 16px; margin: 8px; font-family: sans-serif;
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

