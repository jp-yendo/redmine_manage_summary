class ProgressSummaryController < ApplicationController

  def index
    @filters_message = ""

    render "show"
  end

  def show
    @filters_message = ""

  end
end
