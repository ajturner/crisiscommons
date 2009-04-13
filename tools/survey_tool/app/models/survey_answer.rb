class SurveyAnswer < ActiveRecord::Base
  CHOICE_FOR_UNCHECKED = "__UNCHECKED"

  attr_accessible :question_id, :asset_id, :value

  belongs_to :question, :class_name => 'SurveyQuestion'
  belongs_to :response, :class_name => 'SurveyResponse'
  belongs_to :asset

  def display_value
    value
  end
end

class VideoLinkAnswer < SurveyAnswer
  belongs_to :external_video, :dependent => :destroy

  validate :validate_video

  before_validation :update_external_video

  def validate_video
    return true if value.empty?

    valid = external_video.valid?
    external_video.errors.each {|attr, msg| self.errors.add(:value, msg)}
    valid
  end

  def display_value
    if external_video and external_video.valid?
      external_video.build_embed
    else
      super
    end
  end

  def update_external_video
    self.external_video ||= ExternalVideo.new
    external_video.update_attribute(:media_embed, value)
  end

  def value=(val)
    write_attribute(:value, val)
    update_external_video
  end

end