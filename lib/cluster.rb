# Numerical tower? What numerical tower?
Infinity = 1/0.0

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

  def self.kmeans(vectors, k, delta=0.00005)
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
        best_score = -Infinity
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
end
