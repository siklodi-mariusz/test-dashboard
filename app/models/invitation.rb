class Invitation < ApplicationRecord
  belongs_to :invited_by, class_name: "User"

  enum :role, { user: 0, admin: 1 }, default: :user

  validates :email, presence: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP },
                    uniqueness: true
  validate :email_not_registered, on: :create

  before_create :generate_token
  before_create :set_expires_at

  scope :unaccepted, -> { where(accepted_at: nil) }
  scope :pending, -> { unaccepted.where("expires_at > ?", Time.current) }
  scope :expired, -> { unaccepted.where("expires_at <= ?", Time.current) }

  def expired?
    accepted_at.nil? && expires_at <= Time.current
  end

  def accepted?
    accepted_at.present?
  end

  def pending?
    accepted_at.nil? && expires_at > Time.current
  end

  private

  def generate_token
    self.token = SecureRandom.urlsafe_base64(32)
  end

  def set_expires_at
    self.expires_at = 72.hours.from_now
  end

  def email_not_registered
    if email.present? && User.exists?(email: email)
      errors.add(:email, "is already registered")
    end
  end
end
