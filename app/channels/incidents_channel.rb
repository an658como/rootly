class IncidentsChannel < ApplicationCable::Channel
  def subscribed
    stream_from "incidents"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
