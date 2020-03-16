# frozen_string_literal: true

# == Schema Information
#
# Table name: taggings
#
#  id            :integer          not null, primary key
#  taggable_type :string(255)
#  taggable_id   :integer
#  created_by    :integer
#  created_at    :datetime
#  updated_at    :datetime
#  tag_id        :integer
#

class TaggingsController < ApplicationController
  TAGGABLE_TYPES = {
    'Person' => Person.active,
    'ResearchSession' => ResearchSession
  }.freeze

  # FIXME: Refactor and re-enable cop
  #
  # TODO: (EL) more rigorously test tagging logic
  def create
    klass = TAGGABLE_TYPES.fetch(params[:taggable_type])

    if klass && params[:tag].present? && params[:tag] != ''
      obj = klass.includes(:tags, :taggings).find(params[:taggable_id])
      tag = params[:tag].downcase
      # if we want owned tags. Not sure we do...
      # res = current_user.tag(obj,with: params[:tagging][:name])
      unless obj.tags.map(&:name).include?(tag)
        obj.tag_list.add(tag)

        # super awkward way of finding the right *kind* of tag
        if obj.save
          found_tag = klass.tagged_with(tag).first.tags.detect { |t| t.name == tag }
          @tagging = obj.taggings.find_by(tag_id: found_tag.id)
        else
          flash[:error] = "Oops, can't add that tag: #{unless obj.valid?
                                                         obj.errors.messages
                                                       end}"
        end
      end
    end
    respond_to do |format|
      format.js {}
    end
  end

  # rubocop:enable
  def destroy
    @tagging = ActsAsTaggableOn::Tagging.find(params[:id])

    if @tagging.present?
      klass = TAGGABLE_TYPES.fetch(@tagging.taggable_type)
      obj = klass.find @tagging.taggable_id
      obj.tag_list.remove(@tagging.tag.name)
      obj.save
      @tagging_id = @tagging.id
      respond_to do |format|
        format.js
      end
    else
      respond_to do |format|
        format.js { render text: "alert('failed to destroy tag.')" }
      end
    end
  end

  def index
    @tags = Person.active.tag_counts_on(:tags).order('taggings_count DESC')
  end

  def search
    klass = params[:type].blank? ? Person.active : TAGGABLE_TYPES.fetch(params[:type])

    @tags = klass.tag_counts.where('name like ?', "%#{params[:q].downcase}%")
                 .order(taggings_count: :desc)

    # the methods=> :value is needed for tokenfield.
    # https://github.com/sliptree/bootstrap-tokenfield/issues/189
    render json: @tags.to_json
  end
end
