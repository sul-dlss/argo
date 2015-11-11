class RobotController < ApplicationController
  def index
    @robots = Robot.all
  end

  def show
    @robot = Robot.find_by_id(params[:id])
  end
end
