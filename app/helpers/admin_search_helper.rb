module AdminSearchHelper
  def admin_search_bar(url:, placeholder:, extra_params: {})
    render partial: "admin/shared/search_bar", locals: {
      url: url,
      placeholder: placeholder,
      extra_params: extra_params
    }
  end
end
