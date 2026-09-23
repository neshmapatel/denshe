module SearchableAdmin
  def searchable(placeholder:)
    sidebar :search, only: :index, priority: 0 do
      text_node helpers.render(
        partial: "admin/shared/search_bar",
        locals: {
          url: collection_path,
          placeholder: placeholder,
          extra_params: { scope: params[:scope] }.compact_blank
        }
      )
    end

    controller do
      def scoped_collection
        collection = super
        return collection unless action_name == "index"
        return collection unless collection.respond_to?(:search)

        collection.search(params[:search])
      end
    end
  end
end
