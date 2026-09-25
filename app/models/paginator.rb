# Small offset paginator. The storefront lists are a few hundred rows at most,
# so this stays lighter than pulling in a pagination gem.
class Paginator
  PER_PAGE = 24
  WINDOW = 2

  attr_reader :page, :per_page

  def initialize(scope, page:, per_page: PER_PAGE)
    @scope = scope
    @per_page = per_page.to_i.clamp(1, 96)
    @page = [ page.to_i, 1 ].max
    @page = total_pages if @page > total_pages
  end

  def records
    @records ||= @scope.offset((page - 1) * per_page).limit(per_page)
  end

  def total_count
    @total_count ||= @scope.except(:order, :limit, :offset).count
  end

  def total_pages
    @total_pages ||= [ (total_count.to_f / per_page).ceil, 1 ].max
  end

  def many_pages?
    total_pages > 1
  end

  def first_page?
    page == 1
  end

  def last_page?
    page == total_pages
  end

  def previous_page
    page - 1 unless first_page?
  end

  def next_page
    page + 1 unless last_page?
  end

  def offset
    (page - 1) * per_page
  end

  # Page numbers around the current page, with `nil` standing in for a gap.
  def series
    return (1..total_pages).to_a if total_pages <= 7

    pages = [ 1, total_pages, *((page - WINDOW)..(page + WINDOW)) ]
    pages = pages.select { |number| number.between?(1, total_pages) }.uniq.sort

    pages.each_with_object([]) do |number, series|
      series << nil if series.any? && number - series.last.to_i > 1
      series << number
    end
  end
end
