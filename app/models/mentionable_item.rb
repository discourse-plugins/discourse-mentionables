# frozen_string_literal: true

class MentionableItem < ActiveRecord::Base
  validates :slug, presence: true, uniqueness: true

  before_validation do
    if !self.slug && SiteSetting.mentionable_items_generate_slugs
      self.slug = self.name.parameterize
    end
  end

  before_save do
    if SiteSetting.mentionable_items_onebox_fallback
      apply_onebox_fallback
    end
  end

  def self.destroy_all
    self.all.destroy_all
    MentionableItems::Log.create(
      type: MentionableItems::Log.types[:destroy_all],
      source: nil
    )
  end

  def self.remove!(item)
    MentionableItem
      .where(url: item[:url])
      .destroy_all
  end

  def apply_onebox_fallback
    preview = Oneboxer.preview(self.url)
    document = Nokogiri::HTML(preview)

    return if document.nil?

    [:image_url, :name, :description].each do |key|
      value = self.send(key)

      if value.blank?
        if key == :image_url
          value = document.css('.thumbnail').attr('src')
        elsif key == :name
          value = document.css('h3 a').inner_html
        elsif key == :description
          value = document.css('p').inner_html
        end

        self.send("#{key.to_s}=", value) if value.present?
      end
    end
  end
end

# == Schema Information
#
# Table name: mentionable_items
#
#  id                  :bigint           not null, primary key
#  url                 :string           not null
#  name                :string           not null
#  slug                :string
#  image_url           :string
#  description         :string
#  affiliate_snippet_1 :string
#  affiliate_snippet_2 :string
#  affiliate_snippet_3 :string
#  created_at          :datetime
#  updated_at          :datetime
#
# Indexes
#
#  index_mentionable_items_on_slug  (slug) UNIQUE
#
