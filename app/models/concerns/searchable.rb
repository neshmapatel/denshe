module Searchable
  extend ActiveSupport::Concern

  included do
    scope :search, ->(term) {
      query = term.to_s.strip
      next all if query.blank?

      pattern = "%#{sanitize_sql_like(query)}%"
      clauses = search_columns.map { |column|
        column = column.to_s
        column.include?(".") ? "#{column} ILIKE :q" : "#{table_name}.#{column} ILIKE :q"
      }

      relation = search_joins.any? ? left_joins(*search_joins) : all
      relation.where(clauses.join(" OR "), q: pattern)
    }
  end

  class_methods do
    def search_columns
      raise NotImplementedError, "#{name} must define search_columns"
    end

    def search_joins
      []
    end
  end
end
