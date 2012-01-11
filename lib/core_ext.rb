require 'matrix'

class Array
  def pop_rand!
    delete_at(rand(size))
  end
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


