module CMD::Mover::Easings

  #def self.pos_from_array(ary, t)
  #end
  # Penner Easings
  # http://www.robertpenner.com/easing/

  def self.linear(t, b, c, d)
    return c * t / d + b
  end

  def self.quad_in (t, b, c, d)
    t /= d
    return c * t * t + b
  end

  def self.quad_out (t, b, c, d)
    t = t / d
    return -c *(t)*(t-2) + b
  end

  def self.quad_in_out (t, b, c, d )
    t /= (d/2.0)
    return (c/2*t*t + b) if ((t) < 1)
    t-=1
    return (-c/2 * ((t)*(t-2) - 1) + b)
  end

  def self.cubic_in_out(t, b, c, d)
    t /= d / 2.0
    return c/2.0*t*t*t + b if ((t) < 1)
    t -= 2.0
    return c/2*((t)*t*t + 2) + b
  end

  def self.cubic_in(t, b, c, d)
    return c*(t/=d)*t*t + b
  end

  def self.cubic_out(t, b, c, d)
    return c*((t=t/d-1)*t*t + 1) + b
  end

  def self.quart_in(t, b, c, d)
    return c*(t/=d)*t*t*t + b
  end
  def self.quart_out(t, b, c, d)
    return -c * ((t=t/d-1)*t*t*t - 1) + b
  end
  def self.quart_in_out(t, b, c, d)
    t /= d / 2.0
    return c/2*t*t*t*t + b if (t < 1) 
    t -= 2.0
    return -c/2.0 * ((t)*t*t*t - 2) + b
  end

  def self.quint_in(t, b, c, d)
    return c*(t/=d)*t*t*t*t + b
  end
  def self.quint_out(t, b, c, d)
    return c*((t=t/d-1)*t*t*t*t + 1) + b
  end
  def self.quint_in_out(t, b, c, d)
    return c/2*t*t*t*t*t + b if ((t/=d/2) < 1)
    return c/2*((t-=2)*t*t*t*t + 2) + b
  end

  def self.expo_in(t, b, c, d)
    return (t==0) ? b : c * 2 ** ((10 * (t/d - 1)) + b)
  end
  def self.expo_out(t, b, c, d)
    return (t==d) ? b+c : c * ((-2 ** (-10 * t/d) + 1) + b)
  end
  def self.expo_in_out(t, b, c, d)
    return b if (t==0)
    return b+c if (t==d)
    return c/2.0 * (2 ** (10 * (t - 1))) + b if ((t/=d/2) < 1)
    return c/2.0 * (-(2 ** (-10 * (t-=1))) + 2) + b
  end

  def self.back_out(t, b, c,d, s=1.70158)
    return c*((t=t/d-1)*t*((s+1)*t + s) + 1) + b
  end

  def self.back_in(t, b, c, d, s=1.70158)
    return c*(t/=d)*t*((s+1)*t - s) + b
  end

  def self.back_both(t, b, c, d, s=1.70158)
    if ((t /= d/2 ) < 1) 
      return c/2.0*(t*t*(((s*=(1.525))+1)*t - s)) + b
    end
    return c/2.0*((t-=2)*t*(((s*=(1.525))+1)*t + s) + 2) + b
  end


  def self.bounceOut(t, b, c, d) 
    return c*(7.5625*t*t) + b if ((t/=d) < (1/2.75))  
    return c*(7.5625*(t-=(1.5/2.75))*t + 0.75) + b if (t < (2/2.75))
    return c*(7.5625*(t-=(2.25/2.75))*t + 0.9375) + b if (t < (2.5/2.75))
    return c*(7.5625*(t-=(2.625/2.75))*t + 0.984375) + b
  end

  def self.elastic_in_out(t, b, c, d, a = nil,  p=nil)
    return b if (t==0)
    return b+c if ((t/=d/2)==2)
    p=d*(0.3*1.5) if (!p)
    if (!a || a < Math.abs(c)) 
      a=c
      s=p/4
    else
      s = p/(2*Math.PI) * Math.asin(c/a)
    end
    return -0.5*(a*(2**(10*(t-=1))) * Math.sin( (t*d-s)*(2*Math::PI)/p )) + b if (t < 1)
    return a*(2 ** (-10*(t-=1))) * Math.sin( (t*d-s)*(2*Math::PI)/p )*0.5 + c + b;
  end

end
