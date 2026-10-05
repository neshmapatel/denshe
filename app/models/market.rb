# Which shop a visitor is browsing. India is the home market. Australia
# shows the same cabinet, with prices the admin has set in Australian dollars.
class Market
  CODES = %w[in au].freeze

  def self.india
    new("in")
  end

  def self.australia
    new("au")
  end

  def self.resolve(code)
    new(CODES.include?(code.to_s) ? code.to_s : "in")
  end

  def initialize(code)
    @code = self.class::CODES.include?(code.to_s) ? code.to_s : "in"
  end

  def code
    @code
  end

  def australia?
    @code == "au"
  end

  def india?
    !australia?
  end

  def currency
    australia? ? "AUD" : "INR"
  end

  def name
    australia? ? "Australia" : "India"
  end
end