class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable

  validates :name, presence: true, length: { maximum: 100 }

  def send_devise_notification(notification, *args)
    devise_mailer.send(notification, self, *args).deliver_now
  end
end
