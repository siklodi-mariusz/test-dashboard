class Admin::DashboardController < Admin::BaseController
  PERIODS = {
    "1h" => 1.hour,
    "1d" => 1.day,
    "7d" => 7.days,
    "1m" => 1.month,
    "all" => nil
  }.freeze

  def show
    @period = params[:period].presence_in(PERIODS.keys) || "7d"
    duration = PERIODS[@period]

    if duration
      current_range = duration.ago..Time.current
      previous_range = (duration.ago - duration)..duration.ago

      current_stats = count_users(current_range)
      previous_stats = count_users(previous_range)

      @unconfirmed_count = current_stats[:unconfirmed]
      @confirmed_count = current_stats[:confirmed]
      @unconfirmed_change = percentage_change(previous_stats[:unconfirmed], current_stats[:unconfirmed])
      @confirmed_change = percentage_change(previous_stats[:confirmed], current_stats[:confirmed])
    else
      stats = count_users(nil)
      @unconfirmed_count = stats[:unconfirmed]
      @confirmed_count = stats[:confirmed]
    end
  end

  private

  def count_users(range)
    scope = User.all
    scope = scope.where(created_at: range) if range

    result = scope.pick(
      Arel.sql("COUNT(CASE WHEN confirmed_at IS NULL THEN 1 END)"),
      Arel.sql("COUNT(CASE WHEN confirmed_at IS NOT NULL THEN 1 END)")
    )

    { unconfirmed: result[0], confirmed: result[1] }
  end

  def percentage_change(previous, current)
    return nil if previous.zero?

    ((current - previous).to_f / previous * 100).round
  end
end
