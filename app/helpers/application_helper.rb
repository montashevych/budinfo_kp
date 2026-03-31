module ApplicationHelper
  def locale_link_class(locale)
    base = "rounded px-2 py-1 text-sm font-medium transition-colors"
    if I18n.locale == locale
      "#{base} bg-stone-900 text-white"
    else
      "#{base} text-stone-600 hover:bg-stone-100"
    end
  end
end
